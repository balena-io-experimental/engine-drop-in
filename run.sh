#!/bin/sh

set -eux

# use chroot to make most host commands available
host_cmd() {
    docker exec "${host_container:-}" chroot /host sh -c "$*"
}

object_path() {
    echo /org/freedesktop/systemd1/unit/"$(echo "${1}" | sed -e 's/\./_2e/g' -e 's/-/_2d/g' -e 's/@/_40/g')"
}

cleanup() {
    [ -n "${host_container:-}" ] && (docker rm --force "${host_container}" || true)
}

trap "cleanup" EXIT

path="$(object_path "${UNIT}")"
echo "Using object path ${path} for ${UNIT}..."

echo "Getting property ${PROPERTY}..."
ret="$(dbus-send \
    --system \
    --print-reply \
    --dest=org.freedesktop.systemd1 \
    "${path}" \
    org.freedesktop.DBus.Properties.Get \
    string:org.freedesktop.systemd1.Service string:"${PROPERTY}"| tail -n1)"

type="$(echo "${ret}" | awk '{print $1":"$2}')"
val="$(echo "${ret}" | awk '{print $3}')"

echo "${type}:${val}"

# # exit if the property is already set
if [ "${val}" = "${VALUE}" ]
then
    echo "Nothing to do..."
    exit 0
fi

echo "Setting property ${PROPERTY} ${type}:${VALUE}..."
ret="$(dbus-send \
    --system \
    --print-reply \
    --dest=org.freedesktop.systemd1 \
    "${path}" \
    org.freedesktop.DBus.Properties.Set \
    string:org.freedesktop.systemd1.Service string:"${PROPERTY}" "${type}:${VALUE}")"

# # use our current image as the helper image
# helper_image="$(docker inspect --format '{{ .Image }}' "$(hostname)")"

# # start the host container detached to eliminate container startup time overhead
# host_container="$(docker run -it --rm -d --privileged -v /:/host "${helper_image}" /bin/sh)"

# # set property in runtime only so it is cleared on reboot
# host_cmd systemctl set-property "${UNIT}" "${PROPERTY}=${VALUE}" --runtime

# # restart the target unit
# host_cmd systemctl restart "${UNIT}"
