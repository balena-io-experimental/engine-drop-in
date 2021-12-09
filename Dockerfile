FROM alpine:3.12.8

# hadolint ignore=DL3018
RUN apk add --no-cache dbus docker

ENV DBUS_SYSTEM_BUS_ADDRESS "unix:path=/host/run/dbus/system_bus_socket"

COPY run.sh /

RUN chmod +x /run.sh

CMD [ "/run.sh" ]
