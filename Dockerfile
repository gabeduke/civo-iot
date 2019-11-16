FROM alpine

RUN apk --update add --no-cache bash curl jq

ARG script=healthz.sh

COPY cmd/${script}.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN addgroup -g 9876 autopilot && \
    adduser -D -u 9876 -G autopilot autopilot

USER autopilot
WORKDIR /home/autopilot

ENTRYPOINT ["entrypoint.sh"]