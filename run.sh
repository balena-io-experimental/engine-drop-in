#!/bin/sh

set -eux

[ -z "${DISABLE_ENGINE_DROPIN:-}" ] || { echo "nothing to do" ; exit 0 ; }

# check if the current balena service has already had watchdog disabled
watchdog_usec="$(dbus-send \
    --system \
    --print-reply \
    --dest=org.freedesktop.systemd1 \
    /org/freedesktop/systemd1/unit/balena_2eservice \
    org.freedesktop.DBus.Properties.Get \
    string:org.freedesktop.systemd1.Service string:WatchdogUSec | tail -n1 | awk '{print $3}')"

[ "${watchdog_usec}" != "0" ] || { echo "nothing to do" ; exit 0 ; }

# for rpi-zero you may need to set HELPER_IMAGE=arm32v6/alpine or the
# engine may pull the wrong arch due to https://github.com/balena-os/balena-engine/issues/269
helper_image="${HELPER_IMAGE:-alpine}"

# mount the host OS /lib path as read-only and copy the balena service file for reference
docker run --rm -v /lib:/host/lib:ro "${helper_image}" sh -c 'cat /host/lib/systemd/system/balena.service' > balena.service

# parse the existing ExecStart command as it differs between devices
# exec_start="$(sed -n 's/^ExecStart=//p' balena.service)"
balenad_args="$(sed -n 's|^ExecStart=.*/usr/bin/balenad ||p' balena.service)"

# create custom drop-in to disable healthdog and watchdog
custom_conf="
[Service]
ExecStart=
ExecStart=/usr/bin/balenad ${balenad_args}
WatchdogSec=0
"

# install drop-in under the host OS /run path so it is cleared on reboot
docker run --rm -v /run:/host/run:rw "${helper_image}" sh -c "mkdir -p /host/run/systemd/system/balena.service.d"
docker run --rm -v /run:/host/run:rw "${helper_image}" sh -c "echo '${custom_conf}' > /host/run/systemd/system/balena.service.d/custom.conf"
docker run --rm -v /run:/host/run:rw "${helper_image}" sh -c "cat /host/run/systemd/system/balena.service.d/custom.conf"

# reload the systemd daemon (same as systemctl daemon-reload)
dbus-send \
    --system \
    --dest=org.freedesktop.systemd1 \
    --type=method_call \
    --print-reply \
    /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager.Reload

# restart the balena service (same as systemctl restart balena.service)
dbus-send \
    --system \
    --dest=org.freedesktop.systemd1 \
    --type=method_call \
    --print-reply \
    /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager.RestartUnit \
    string:"balena.service" string:"replace"
