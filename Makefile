REPO = dukeman
IMAGE = civo-iot
TAG = 1.1.0
CLUSTER_NAME = civo-iot
NAMESPACE = default
TARGETS = $(shell find ./shell -name "*.sh" -type f -exec basename \{} .sh \;)

DOCKER_CTX = .

.DEFAULT_GOAL := help

##########################################################
##@ DOCKER
##########################################################
.PHONY: build push

build: export DOCKER_BUILDKIT=1
build:													## Build Dockerfile
	@for i in $(TARGETS); do \
		docker build \
			--build-arg script=$$i \
			-t $(REPO)/$(IMAGE)-$$i:$(TAG) \
			$(DOCKER_CTX) ; \
		done

push:													## Push Dockerfile
	@for i in $(TARGETS); do \
		docker push $(REPO)/$(IMAGE)-$$i:$(TAG) ; \
	done

##########################################################
##@ CLUSTER
##########################################################
.PHONY: provision

provision:												## Provision Cluster
	$(info Provisioning cluster..)
	@civo kubernetes create \
		--applications=openfaas \
		--applications=prometheus-operator \
		--nodes 2 \
		--save --switch --wait \
		$(CLUSTER_NAME) 

##########################################################
##@ APPS
##########################################################
.PHONY: deploy-grafana deploy-prometheus deploy-pushgateway deploy-all

deploy-cron-connector:									## Deploy Cron Connector
	$(info Deploying Cron Connector)
	kubectl apply -f deploy/cron-connector

deploy-grafana:											## Deploy Grafana
	$(info Deploying Grafana)
	docker run -it \
		--env-file .env \
		--volume $(CURDIR):/home \
		--workdir /home \
		jwilder/dockerize -template deploy/grafana/grafana.yaml | kubectl apply -f -
	kubectl apply -f deploy/grafana/fleet-dashboard.yaml

deploy-prometheus:										## Deploy Prometheus
	$(info Deploying Prometheus)
	kubectl kustomize deploy/prometheus | kubectl apply -n $(NAMESPACE) -f -

deploy-prometheus-operator:											## Deploy Grafana
	$(info Deploying Prometheus Operator)
	kubectl apply -f deploy/prometheus-operator

deploy-pushgateway:										## Deploy Push Gateway
	$(info Deploying Push Gateway)
	kubectl apply -f deploy/pushgateway

deploy-all: 											## Deploy all applications
deploy-all: deploy-grafana deploy-prometheus deploy-pushgateway
	$(info Deploying applications..)

##########################################################
##@ UTIL
##########################################################
.PHONY: proxies kill-proxies help clean

proxies:												## Open proxies to Grafana and Prometheus
	@kubectl port-forward svc/grafana -n $(NAMESPACE) 8080:80 &
	@echo http://localhost:8080

	@kubectl port-forward svc/prometheus-operated -n $(NAMESPACE) 9090:9090 &
	@echo http://localhost:9090

	@kubectl port-forward svc/metrics-sink-prometheus-pushgateway -n $(NAMESPACE) 9091:9091 &
	@echo http://localhost:9091

	@kubectl port-forward svc/wio-mock -n $(NAMESPACE) 8081:8080 &
	@echo http://localhost:8081

kill-proxies:											## Kill proxies (kills all kubectl proceses)
	pkill kubectl

backup-grafana:
	@docker run --rm --name grafana-backup-tool \
	-e GRAFANA_TOKEN="${GRAFANA_TOKEN}" \
	-e GRAFANA_URL="http://localhost:8080" \
	-v dashboards:/opt/grafana-backup-tool/_OUTPUT_  \
	ysde/docker-grafana-backup-tool

help:													## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m 	%s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

clean:													## Destroy cluster
	civo k8s delete $(CLUSTER_NAME)