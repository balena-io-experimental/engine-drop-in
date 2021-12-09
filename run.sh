#!/bin/sh

set -eu

# use our current image as the helper image
helper_image="$(docker inspect --format '{{ .Image }}' "$(hostname)")"

# start the host container detached to eliminate container startup time overhead
host_container="$(docker run -it --rm -d --pid host --privileged -v /:/host "${helper_image}" /bin/sh)"

# use chroot to make most host commands available
host_cmd() {
    docker exec "${host_container}" chroot /host sh -c "$*"
}

cleanup() {
    docker rm --force "${host_container}" || true
}

trap "cleanup" EXIT

echo "Getting properties of ${UNIT}..."
val="$(host_cmd systemctl show "${UNIT}" --property="${PROPERTY}")"
echo "Property '${PROPERTY}' is '${val#*=}'."

# exit if the property is already set
if [ "${val#*=}" = "${VALUE}" ]
then
    echo "Nothing to do..."
    exit 0
fi

# set property in runtime only so it is cleared on reboot
echo "Setting ${PROPERTY} to ${VALUE}..."
host_cmd systemctl set-property "${UNIT}" "${PROPERTY}=${VALUE}" --runtime

# restart the target unit
echo "Restarting ${UNIT}..."
host_cmd systemctl restart "${UNIT}"
