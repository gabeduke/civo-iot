# Civo IOT

IOT Prometheus sink on top of Civo k3s.

## Pre-requisites

* Kubernetes: This project built on top of K3s managed by [Civo Cloud](https://www.civo.com "Civo"). However It may also be run against a mixed arch cluster (must contain at least 1 decently capable AMD64 node). If running against a non Civo cluster simply skip the cluster provisioning step.

* [Helm3](https://helm.sh/docs/intro/install/ "Helm Installation"): to avoid Tiller
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/ "Kubectl Installation")

## End 2 End

To build a stack end to end:

    make all

To build a dummy stack end to end:

    make all-mock

## Provision Cluster

Provision a Civo K3s cluster.

    make provision

## Deploy Core Applications

Deploy the core applications into the cluster.

    make deploy-core

* **Prometheus-Operator**: orchestrates the lifecycle for prometheus components
* **Prometheus**: is a time-series database that scales incredibly well. This is our 'backend'. Prometheus is generally configured to scrape metrics data from applications on regular intervals.
* **PushGateway**: is a 'sink' or 'buffer' for metric data that is too short lived for Prometheus to scrape. This is what our cron jobs will log data to since the containers wont live long enough for Prometheus to ever see them.
* **Grafana**: is a powerful visualization tool we will use for displaying our metrics. This could be considered the 'frontend' of our application.
* **OpenFaaS**: OpenFaaS provides a framework to easily build our scraping functions
* **Cron-Connector**: is a small shim utility to execute OpenFaaS functions on a schedule
* **Mock-Server**: This is a dummy server to mimic data being returned from IOT sensor endpoints

## Deploy Functions (OpenFaaS)

__Note__: You will have to adjust the `image` repository in `fn-mock.yml` in order to push to your own registry

Build, push and deploy the functions:

    make faas-up

Or simply deploy the prebuild images:

    make faas-deploy
