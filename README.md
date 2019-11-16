# Civo IOT

IOT Prometheus sink on top of Civo k3s.

## Pre-requisites

* Kubernetes: This project built on top of K3s managed by [Civo Cloud](https://www.civo.com "Civo")
* [Helm3](https://helm.sh/docs/intro/install/ "Helm Installation"): to avoid Tiller
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/ "Kubectl Installation")

## Build

Build a new Docker image & push it up

`make build && make push`

## Provision

Provision a Civo K3s cluster.

`make provision`

## Deploy

Deploy the applications into the cluster. This will also merge in the KUBECONFIG to your existing config file.

`make deploy`
