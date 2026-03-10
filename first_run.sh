#!/bin/bash
set -e


# Argument check
if [ $# -ne 1 ]; then
    echo "Usage: $0 [sim|real]"
    exit 1
fi

TYPE=$1

if [[ "$TYPE" != "sim" && "$TYPE" != "real" ]]; then
    echo "Invalid type: $TYPE"
    echo "Use: sim or real"
    exit 1
fi

IMAGE_NAME="crazy_${TYPE}"
CONTAINER_NAME="crazy_${TYPE}_container"


# X11 setup
XAUTH=/tmp/.docker.xauth

echo "Preparing Xauthority data..."

xauth_list=$(xauth nlist :0 | tail -n 1 | sed -e 's/^..../ffff/')

if [ ! -f "$XAUTH" ]; then
    if [ -n "$xauth_list" ]; then
        echo "$xauth_list" | xauth -f "$XAUTH" nmerge -
    else
        touch "$XAUTH"
    fi
    chmod a+r "$XAUTH"
fi

echo "Done."

echo ""
echo "Verifying file contents:"
file "$XAUTH"
echo "--> It should say \"X11 Xauthority data\"."
echo ""

echo "Permissions:"
ls -FAlh "$XAUTH"
echo ""


# SSH agent forwarding
echo "Linking ssh-agent..."
ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock


# Run container
echo "Starting container: $CONTAINER_NAME"
echo "Using image: $IMAGE_NAME"

docker run -it \
    --env DISPLAY=$DISPLAY \
    --env QT_X11_NO_MITSHM=1 \
    --env TERM=xterm-256color \
    --env SSH_AUTH_SOCK=/ssh-agent \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --volume /dev:/dev \
    --volume /var/run/dbus:/var/run/dbus:z \
    --volume ~/.ssh/ssh_auth_sock:/ssh-agent \
    --volume "$(pwd)":/root/ros2_ws/src/hero_crazyflies_benchmarking:rw \
    --net host \
    --privileged \
    --gpus all \
    --name "$CONTAINER_NAME" \
    "$IMAGE_NAME"