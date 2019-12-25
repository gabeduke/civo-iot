FROM alpine

# Install dependencies
RUN apk --update add --no-cache bash curl jq

# Default script is healthz
ARG script=healthz.sh

# Copy script into container as 'entrypoint'
COPY shell/${script}.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create numeric nonroot user
RUN addgroup -g 9876 autopilot && \
    adduser -D -u 9876 -G autopilot autopilot

# Run container as a nonroot user
USER autopilot
WORKDIR /home/autopilot

ENTRYPOINT ["entrypoint.sh"]