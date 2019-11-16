#!/bin/bash

JOB_FLAVOR="healthz"
METRIC="1"
METRIC_FLAVOR="heartbeat"
PROMETHEUS_HOST=${PROMETHEUS_HOST:-localhost}

# push metric to prometheus sink
echo "Info: pushing ${METRIC} to prometheus"
echo "${METRIC_FLAVOR} ${METRIC}" | curl --silent --data-binary @- "http://${PROMETHEUS_HOST}:9091/metrics/job/${JOB_FLAVOR}"
