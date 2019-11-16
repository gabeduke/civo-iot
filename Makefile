REPO = dukeman
IMAGE = civo-iot
TAG = 0.1.0
CLUSTER_NAME = civo-iot
NAMESPACE = default
TARGETS = $(shell find . -name "*.sh" -type f -exec basename \{} .sh \;)

DOCKER_CTX = .

.DEFAULT_GOAL := help

##########################################################
##@ DOCKER
##########################################################
.PHONY: build push

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
		--applications=prometheus-operator \
		--nodes 2 \
		--save --switch --wait \
		$(CLUSTER_NAME) 

##########################################################
##@ APPS
##########################################################
.PHONY: deploy-grafana deploy-prometheus deploy-pushgateway deploy-all

deploy-grafana:											## Deploy Grafana
	$(info Deploying Grafana)
	kubectl apply -f deploy/charts/grafana.yaml

deploy-prometheus:										## Deploy Prometheus
	$(info Deploying Prometheus)
	kubectl kustomize deploy/manifest | kubectl apply -n $(NAMESPACE)-f -

deploy-pushgateway:										## Deploy Push Gateway
	$(info Deploying Push Gateway)
	kubectl apply -f deploy/charts/pushgateway.yaml

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

kill-proxies:											## Kill proxies (kills all kubectl proceses)
	pkill kubectl

help:													## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m 	%s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

clean:													## Destroy cluster
	civo k8s delete $(CLUSTER_NAME)