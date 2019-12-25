#!/bin/bash

: ${TOKEN:=default}

# TARGET is the sensor being scraped
: ${TARGET_BASE_URL:=wio-mock}
: ${TARGET_BASE_PORT:=8080}
: ${TARGET_BASE_PATH:=v1/node}

: ${TARGET_SENSOR:=GroveTempHumD0}
: ${TARGET_SENSOR_PATH:=temperature}
: ${TARGET_READING_KEY:=celsius_degree}
: ${TARGET_METRIC_GROUP:=iot-fleet-devices}

# Prometheus is the metrics sink
: ${PROMETHEUS_HOST:=localhost}
: ${PROMETHEUS_PORT:=9091}

# Get temp reading
echo "Info: getting temp.."

URL="${TARGET_BASE_URL}:${TARGET_BASE_PORT}/${TARGET_BASE_PATH}/${TARGET_SENSOR}/${TARGET_SENSOR_PATH}?access_token=${TOKEN}"
echo "Info: ${URL}"

METRIC=$(curl --silent -k "${URL}" 2>&1 | jq -r ".${TARGET_READING_KEY}")

# push metric to prometheus sink
echo "Info: pushing ${METRIC} to prometheus"
echo "${TARGET_READING_KEY} ${METRIC}" | curl --silent --data-binary @- "${PROMETHEUS_HOST}:${PROMETHEUS_PORT}/metrics/job/${TARGET_METRIC_GROUP}"
