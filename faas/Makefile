FAAS_BUILD_ARGS = --tag=branch
.PHONY: build push deploy up run cron-connector 

build: export DOCKER_BUILDKIT=1
build:
	faas build $(FAAS_BUILD_ARGS) -f wio.yml

push:
	faas push $(FAAS_BUILD_ARGS) -f wio.yml

deploy:
	faas deploy $(FAAS_BUILD_ARGS) -f wio.yml

up: export DOCKER_BUILDKIT=1
up:
	faas up $(FAAS_BUILD_ARGS) -f wio.yml