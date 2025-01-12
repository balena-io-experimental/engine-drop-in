FROM alpine:3.12.8

# hadolint ignore=DL3018
RUN apk add --no-cache dbus docker findmnt

COPY run.sh /

RUN chmod +x /run.sh

CMD [ "/run.sh" ]
# CMD [ "tail", "-f", "/dev/null"]
