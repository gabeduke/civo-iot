#!/bin/bash

JOB_FLAVOR="iot-fleet-devices"
METRIC_FLAVOR="temp_celsius"
PROMETHEUS_HOST=${PROMETHEUS_HOST:-localhost}

# ensure token
[ -z "$TOKEN" ] && echo "Error: TOKEN not found" && exit 1;

# Get temp reading
echo "Info: getting temp.."
TEMP=$(curl --silent -k "https://us.wio.seeed.io/v1/node/GroveTempHumD0/temperature_f?access_token=${TOKEN}" | jq -r '.celsius_degree')

# push metric to prometheus sink
echo "Info: pushing ${TEMP} to prometheus"
echo "${METRIC_FLAVOR} ${TEMP}" | curl --silent --data-binary @- "http://${PROMETHEUS_HOST}:9091/metrics/job/${JOB_FLAVOR}"
