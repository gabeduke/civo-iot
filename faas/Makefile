FAAS_BUILD_ARGS = --tag=branch
.PHONY: build push deploy up run cron-connector 

build: export DOCKER_BUILDKIT=1
build:
	faas build $(FAAS_BUILD_ARGS) -f wio.yml

push:
	faas push $(FAAS_BUILD_ARGS) -f wio.yml

deploy:
	faas deploy $(FAAS_BUILD_ARGS) -f wio.yml

up:
	faas up $(FAAS_BUILD_ARGS) -f wio.yml

run:
	docker run -p 8089:8080 -p 8081:8081 -it dukeman/wio:latest

cron-connector:
	curl -s https://raw.githubusercontent.com/openfaas-incubator/cron-connector/master/yaml/kubernetes/connector-dep.yml | kubectl apply -f - 


