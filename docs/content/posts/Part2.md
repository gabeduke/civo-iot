---
title: "Part2"
date: 2020-01-09T09:30:08-05:00
draft: false
---

## TL/DR

This guide documents a simple Prometheus PushGateway setup on top of [Civo's k3s](https://www.civo.com/kube100) offering. We will then push some data to the gateway and visualize it in Grafana.

The end result for this project is an environmental monitoring system that gathers sensor data. I won't actually deploy the scrape jobs in this guide, but we will send a metric with curl and visualize it in each of the core components. The subsequent blogs will document building a native kubernetes operator to manage the sensor inputs.

![Civo IOT Design](/project.png)

## Table of Contents

<!-- TOC -->

- [TL/DR](#tldr)
- [Table of Contents](#table-of-contents)
- [Summary](#summary)
- [Pre-requisites](#pre-requisites)
  - [Tools](#tools)
  - [Setup](#setup)
- [Provision Operator](#provision-operator)
- [Visualize data](#visualize-data)
- [Wrapping up](#wrapping-up)

<!-- /TOC -->

## Summary

Prometheus PushGateway is a very useful tool to visualize batch metrics. This guide will walk through setting up a pushgateway instance and logging metrics from a simple BASH script. This is a great way to quickly visualize data _external_ to kubernetes in a dead simple, sysadmin friendly way. The actual purpose of this project is to pull IOT sensor data into Prometheus, but I have tried to keep things as generic as possible in this first guide. In the next post I will begin building out the data logging functions into a kubernetes native operator.

The stack is deployed to [Civo](https://www.civo.com/) cloud which runs a slimmed down flavor of kubernetes, called [k3s](https://github.com/rancher/k3s).

Components:

- K3s Cluster installed through Civo Cloud
- Prometheus Operator (installed alongside the cluster via Civo marketplace)
- PushGateway (installed via Helm)
- Grafana (installed via Helm)

## Pre-requisites

### Tools

| Tool                                                               | Version |
| ------------------------------------------------------------------ | ------- |
| [Civo-CLI](https://github.com/civo/cli#set-up)                     | v0.5.1  |
| [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) | v1.16.3 |

**Notes**:

- [Kustomize](https://kustomize.io/): is part of the kubectl binary since v1.15. Generally helm is used for doing the heavy lifting creating an application, and kustomize steps in for the lighter pieces that require last minute transforms.
- K3s ships with a helm operator that takes a CRD which can be applied with `kubectl`. This guide will deploy grafana and pushgateway using this method. More information can be found [here](https://rancher.com/docs/k3s/latest/en/configuration/#auto-deploying-manifests)

### Setup

Before getting started let's export some variables so they will be available throughout this guide. We also want to update our helm repo with the latest charts:

```bash
export CLUSTER_NAME=civo-iot-$(whoami)
export NAMESPACE=default
```

## Provision Operator

## Visualize data

## Wrapping up

Congradulations! You now have the foundation for a batch metrics monitoring system! Keep an eye out for the next post where I will walk thorugh connecting real sensor data.
