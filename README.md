# systemd-set-prop

Adjust properties of systemd units on the host OS at runtime.

## Environment Variables

To run this project, you will need the following environment variables in your container:

- `UNIT`: Name of the systemd unit to modify. For example `balena.service`.
- `PROPERTY`: Property of the systemd unit to modify. For example `WatchdogUSec`.
- `VALUE`: Value of the systemd property to apply. For example `6m`.

## Service Labels

To run this project, you will need the following labels on the `dnat` service:

- `io.balena.features.balena-socket=1`: Bind mounts the balena container engine socket into the container and
  sets the environment variable `DOCKER_HOST` with the socket location for use by docker clients.

See <https://www.balena.io/docs/reference/supervisor/docker-compose/#labels> for more info on supervisor labels.

## Usage/Examples

After a systemd unit is modified it will be restarted so use with caution!

If the systemd unit already has the desired property, nothing will be done.

Here's an example to increase the balena engine watchdog interval.

```yml
version: "2.1"
services:
  systemd-set-prop:
    build: .
    restart: no
    labels:
      io.balena.features.balena-socket: 1
    environment:
      UNIT: "balena.service"
      PROPERTY: "WatchdogUSec"
      VALUE: "600"
```

This service is expected to remain in the `Exited` state after performing it's task.
