FROM openfaas/classic-watchdog:0.18.1 as watchdog

FROM alpine:3.10

RUN apk add --no-cache bash jq curl

RUN mkdir -p /home/app

COPY wio /tmp/wio
COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

# Add non root user
RUN addgroup -S app && adduser app -S -G app
RUN chown app /home/app

WORKDIR /home/app

USER app

# execute script
ENV fprocess="xargs bash /tmp/wio"
ENV write_debug="false"

EXPOSE 8080

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]
