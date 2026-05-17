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
CONTAINER_NAME="crazy_test_${TYPE}_container"


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
    --volume "/home/khawaja/HERO/hero_mrs_control_stack:/root/ros2_ws/src/hero_mrs_control_stack:rw" \
    --volume "/home/khawaja/HERO/meta_packages_hero/icuas26_evaluation:/root/ros2_ws/src/icuas26_evaluation:rw" \
    --volume "/home/khawaja/HERO/meta_packages_hero/crazyflie_hardware_utils:/root/ros2_ws/src/crazyflie_hardware_utils:rw" \
    --volume "/home/khawaja/HERO/meta_packages_hero/agilex_sitl/agilex_sitl:/root/ros2_ws/src/agilex_sitl:rw" \
    --volume "/home/khawaja/HERO/meta_packages_hero/agilex_sitl/hero_sitl:/root/ros2_ws/src/hero_sitl:rw" \
    --volume "/home/khawaja/HERO/meta_packages_hero/agilex_sitl/dummy_crazyflie_server:/root/ros2_ws/src/dummy_crazyflie_server:rw" \
    --net host \
    --privileged \
    --gpus all \
    --name "$CONTAINER_NAME" \
    "$IMAGE_NAME" \
    bash -c "

        source /opt/ros/\$ROS2_DISTRO/setup.bash

        cd /root/ros2_ws

        # Build workspace if not built
        if [ ! -d install ]; then
            echo 'Building ROS2 workspace...'
            colcon build --symlink-install
        else
            echo 'Workspace already built.'
        fi

        source install/setup.bash

        exec bash
    "