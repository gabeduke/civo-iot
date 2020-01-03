include .env

CLUSTER_NAME = civo-iot
CLUSTER_ID = $(shell curl -H "Authorization: bearer $(CIVO_TOKEN)" https://api.civo.com/v2/kubernetes/clusters | jq '.items[] | select(.name == "$(CLUSTER_NAME)") | .id')
NAMESPACE = default

ifeq ($(INGRESS),)
INGRESS = $(CLUSTER_ID).k8s.civo.com
endif

FAAS_BUILD_ARGS = --tag=branch
FAAS_FN = fn-mock.yml
# FAAS_FN = fn-wio.yml
FAAS_GATEWAY = http://$(INGRESS):31112

.DEFAULT_GOAL := help
.PHONY: all

all:													## Deploy stack end to end
all: provision deploy-core faas-create-secrets faas-up

##########################################################
##@ CLUSTER
##########################################################
.PHONY: provision

provision:												## Provision Cluster
	$(info Provisioning cluster..)
	@civo kubernetes create \
		--nodes 2 \
		--save --switch --wait \
		$(CLUSTER_NAME) 

##########################################################
##@ CORE APPS
##########################################################
.PHONY: deploy-core prometheus-operator prometheus pushgateway grafana openfaas cron-connector mock-server

deploy-core: 											## Deploy all core applications
deploy-core: prometheus-operator prometheus pushgateway grafana openfaas cron-connector mock-server

prometheus-operator:									## Deploy Prometheus Operator
	$(info Deploying Prometheus Operator)
	kubectl create namespace monitoring --dry-run -o yaml | kubectl apply -f -
	helm repo update
	helm upgrade --install \
		--namespace monitoring \
		--values deploy/prometheus-operator/values.yaml \
		--version 8.5.0 \
		--wait \
		prometheus-operator stable/prometheus-operator

prometheus:												## Deploy Prometheus
	$(info Deploying Prometheus)
	kubectl kustomize deploy/prometheus | kubectl apply -n $(NAMESPACE) -f -

pushgateway:											## Deploy Push Gateway
	$(info Deploying Push Gateway)
	helm repo update
	helm upgrade --install \
		--namespace $(NAMESPACE) \
		--values deploy/pushgateway/values.yaml \
		--version 1.2.5 \
		--wait \
		metrics-sink stable/prometheus-pushgateway
	 
grafana:												## Deploy Grafana
	$(info Deploying Grafana)
	@docker run -it \
		--env-file .env \
		--volume $(CURDIR):/home \
		--workdir /home \
		jwilder/dockerize -template deploy/grafana/values.yaml > /tmp/grafana.yaml
	@helm upgrade --install \
		--namespace $(NAMESPACE) \
		--set adminPassword=$(ADMIN_PASSWORD) \
  		--set ingress.hosts[0]="grafana.$(INGRESS)" \
  		--set ingress.path="/" \
		--values /tmp/grafana.yaml \
		--version 4.0.4 \
		--wait \
		grafana stable/grafana
	@kubectl apply -f deploy/grafana/fleet-dashboard.yaml -n $(NAMESPACE)

openfaas:												## Deploy OpenFaaS
	@kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

	@helm repo add openfaas https://openfaas.github.io/faas-netes/

	@kubectl -n openfaas create secret generic basic-auth \
	--from-literal=basic-auth-user=admin \
	--from-literal=basic-auth-password="$(ADMIN_PASSWORD)" \
	--dry-run -o yaml | kubectl apply -f -

	@helm repo update
	@helm upgrade --install \
		--namespace openfaas  \
		--set basic_auth=true \
		--set functionNamespace=openfaas-fn \
		--version 5.4.0 \
		--wait \
		openfaas openfaas/openfaas

cron-connector:											## Deploy Cron Connector
	$(info Deploying Cron Connector)
	kubectl apply -f deploy/cron-connector

mock-server:											## Deploy Mock Server
	$(info Deploying Mock Server)
	kubectl kustomize \
		https://github.com/gabeduke/wio-mock/deploy?ref=master | kubectl apply -n $(NAMESPACE) -f -

##########################################################
##@ Faas
##########################################################
.PHONY: faas-build faas-push faas-deploy faas-up faas-down faas-create-secrets faas-login

faas-build: export DOCKER_BUILDKIT=1
faas-build: faas-login										## Build Docker images using Buildkit
	faas build --gateway $(FAAS_GATEWAY) $(FAAS_BUILD_ARGS) -f $(FAAS_FN)

faas-push: faas-login										## Push Docker images to registry
	faas push --gateway $(FAAS_GATEWAY) $(FAAS_BUILD_ARGS) -f $(FAAS_FN)

faas-deploy: faas-login										## Deploy functions to cluster
	faas deploy --gateway $(FAAS_GATEWAY) $(FAAS_BUILD_ARGS) -f $(FAAS_FN)

faas-up: export DOCKER_BUILDKIT=1
faas-up: faas-login											## Build, push and deploy all functions
	faas up --gateway $(FAAS_GATEWAY) $(FAAS_BUILD_ARGS) -f $(FAAS_FN)

faas-down: faas-login										## Remove all functions
	faas remove --gateway $(FAAS_GATEWAY) -f $(FAAS_FN)

faas-create-secrets: faas-login								## Create FaaS secrets
	faas --gateway $(FAAS_GATEWAY) secret create --from-literal=$(WIO1) wio1
	faas --gateway $(FAAS_GATEWAY) secret create --from-literal=$(WIO2) wio2
	faas --gateway $(FAAS_GATEWAY) secret create --from-literal=$(WIO3) wio3

faas-login:												## Log in to OpenFaaS
	faas login --gateway $(FAAS_GATEWAY) -u admin -p $(ADMIN_PASSWORD)

##########################################################
##@ UTIL
##########################################################
.PHONY: proxies kill-proxies help clean

proxies:												## Proxy all services
	@kubectl port-forward svc/grafana -n $(NAMESPACE) 8080:80 &
	@echo http://localhost:8080

	@kubectl port-forward svc/prometheus-operated -n $(NAMESPACE) 9090:9090 &
	@echo http://localhost:9090

	@kubectl port-forward svc/metrics-sink-prometheus-pushgateway -n $(NAMESPACE) 9091:9091 &
	@echo http://localhost:9091

	@kubectl port-forward svc/wio-mock -n $(NAMESPACE) 8081:8080 &
	@echo http://localhost:8081

	@kubectl port-forward svc/gateway -n openfaas 8082:8080 &
	@echo http://localhost:8082

kill-proxies:											## Kill proxies (kills all kubectl proceses)
	pkill kubectl

help:													## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m 	%s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

clean:													## Destroy cluster
	civo k8s delete $(CLUSTER_NAME)