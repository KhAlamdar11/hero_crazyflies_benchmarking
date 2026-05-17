# Ubuntu 22.04 base
FROM ubuntu:jammy AS base


# Build arguments & environment

ARG DEBIAN_FRONTEND=noninteractive
ARG HOME=/root

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ROS2_DISTRO=humble \
    GZ_RELEASE=garden \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute \
    TZ=Europe/Zagreb

WORKDIR $HOME


# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # General tools
    atop \
    build-essential \ 
    clang \
    cmake \
    cppcheck \ 
    curl \
    expect \
    gdb \
    git \
    gnutls-bin \
    htop \
    iputils-ping \
    jq \
    openssh-client \
    nano \
    vim \
    tmux \
    tmuxinator \ 
    ranger \
    wget \
    xvfb \
    sudo \
    software-properties-common \
    # Boost, libusb, graphics
    libboost-filesystem-dev \
    libboost-program-options-dev \ 
    libboost-regex-dev \
    libboost-system-dev \ 
    libboost-thread-dev \
    libbz2-dev \
    libconsole-bridge-dev \ 
    libccd-dev \
    libcwiid-dev \
    libfcl-dev \
    libgl1-mesa-dri \ 
    libgl1-mesa-glx \
    libgoogle-glog-dev \
    libgpgme-dev \
    libpoco-dev \
    liblog4cxx-dev \ 
    libspnav-dev \
    libspdlog-dev \
    libtinyxml2-dev \
    libusb-dev \
    uuid-dev \
    libbluetooth-dev \
    liblz4-dev \
    libgtest-dev \
    libxcb-xinerama0 \ 
    libxcb-cursor0 \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxkbcommon-dev \ 
    libxkbcommon-x11-dev \ 
    libxrender-dev \
    libfontconfig1-dev \
    libfreetype-dev \
    libx11-dev \
    libx11-xcb-dev \ 
    libxcb-cursor-dev \ 
    libxcb-glx0-dev  \
    libxcb-icccm4-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \ 
    libxcb-randr0-dev  \
    libxcb-render-util0-dev \ 
    libxcb-shape0-dev  \
    libxcb-shm0-dev \
    libxcb-sync-dev \
    libxcb-util-dev \
    libxcb-xfixes0-dev \ 
    libxcb-xinerama0-dev \ 
    libxcb-xkb-dev  \
    libxcb1-dev \
    && add-apt-repository universe \
    && apt-get clean -qq


# Python tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-dbg \
    python3-empy \
    python3-nose \
    python3-mock \
    python3-netifaces \ 
    python3-psutil \
    python3-pycryptodome \
    python3-gnupg \
    python3-flake8 \
    python3-flake8-blind-except \ 
    python3-flake8-builtins \
    python3-flake8-class-newline \
    python3-flake8-comprehensions \ 
    python3-flake8-deprecated \
    python3-flake8-docstrings \
    python3-flake8-import-order \
    python3-flake8-quotes \
    python3-pytest \
    python3-pytest-cov \ 
    python3-pytest-repeat \ 
    python3-pytest-rerunfailures \
    python-is-python3\
    && pip install --upgrade pip rowan transforms3d nicegui


# SSH agent forwarding setup
ENV GIT_SSH_COMMAND="ssh -v"
USER root
RUN --mount=type=ssh id=default mkdir -p ~/.ssh/ && ssh-keyscan -H github.com >> ~/.ssh/known_hosts

# ROS2 Humble setup
RUN apt-get update && apt-get install -y locales curl gnupg lsb-release \
    && locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
       | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt-get update && apt-get install -y \
        ros-${ROS2_DISTRO}-desktop \
        python3-rosdep \
        ros-dev-tools \
        python3-colcon-common-extensions \
    && apt-get clean -qq


# MCAP CLI
RUN VERSION="releases/mcap-cli/v0.0.55" && \
    RELEASE_URL=$(curl -s https://api.github.com/repos/foxglove/mcap/releases | jq -r --arg VERSION "$VERSION" '.[] | select(.tag_name == $VERSION) | .assets[0].browser_download_url') && \
    curl -L -o /bin/mcap "$RELEASE_URL" && chmod +x /bin/mcap

#Avoiding venv issues with ROS2 Humble and Python 3.10
RUN PYTHON_VERSION=$(python --version | cut -d " " -f2 | cut -d "." -f1,2) && \
    rm -rf /usr/lib/python${PYTHON_VERSION}/EXTERNALLY-MANAGED

RUN apt-get update &&  apt-get upgrade -y && apt-get install -y \
                   ros-${ROS2_DISTRO}-tf-transformations \
                   ros-${ROS2_DISTRO}-nav2-map-server \
                   ros-${ROS2_DISTRO}-nav2-lifecycle-manager \
                   ros-${ROS2_DISTRO}-rosbridge-suite \
                   ros-${ROS2_DISTRO}-rosbag2-storage-mcap \
                   ros-${ROS2_DISTRO}-octomap \
                   ros-${ROS2_DISTRO}-octomap-ros \
                   ros-${ROS2_DISTRO}-octomap-server \
                   ros-${ROS2_DISTRO}-octomap-msgs \
                   ros-${ROS2_DISTRO}-foxglove-bridge


# ROS2 Workspace
RUN mkdir -p $HOME/ros2_ws/src \
    && cd $HOME/ros2_ws/src \
    && git clone https://github.com/IMRCLab/crazyswarm2 --recursive \
    && git clone https://github.com/JMU-ROBOTICS-VIVA/ros2_aruco.git \
    && git clone https://github.com/larics/icuas25_msgs.git \
    && git clone --recurse-submodules https://github.com/IMRCLab/motion_capture_tracking.git

RUN --mount=type=ssh cd $HOME/ros2_ws/src && git clone git@github.com:larics/hero_evaluation_benchmarking.git


# Bash environment & aliases
RUN echo "alias ros2_ws='source $HOME/ros2_ws/install/setup.bash'" >> $HOME/.bashrc && \
    echo "alias source_ros2='source /opt/ros/${ROS2_DISTRO}/setup.bash'" >> $HOME/.bashrc && \
    echo "export ROS_LOCALHOST_ONLY=1" >> $HOME/.bashrc && \
    echo "export ROS_DOMAIN_ID=$(shuf -i 1-101 -n 1)" >> $HOME/.bashrc && \
    echo "ros2_ws" >> $HOME/.bashrc && \
    echo "source_ros2" >> $HOME/.bashrc


# User config files
COPY to_copy/aliases $HOME/.bash_aliases
COPY to_copy/nanorc $HOME/.nanorc
COPY to_copy/tmux $HOME/.tmux.conf
COPY to_copy/ranger $HOME/.config/ranger/rc.conf





# Simulation setup (CFS_TYPE=sim)
FROM base AS sim

ENV CFS_TYPE=sim

#Install Gazebo
RUN /bin/sh -c ' curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg' \
  && /bin/sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null'
RUN  apt-get update \
  && apt-get install -y gz-${GZ_RELEASE}

#Install additional packages
RUN apt-get update && apt-get install -y libusb-1.0-0-dev \
        ros-${ROS2_DISTRO}-ros-gz-interfaces \
        ros-${ROS2_DISTRO}-ros-gz-bridge      
RUN apt install -y ros-${ROS2_DISTRO}-ros-gz${GZ_RELEASE}

WORKDIR $HOME

#Install CrazySim
RUN git clone https://github.com/gtfactslab/CrazySim.git \
    && cd CrazySim \
    && git checkout 3246b07269c20413530269955ca054dab4426c15 \
    && git submodule update --init --recursive \
    && cd crazyflie-lib-python \
    && pip install -e .

# Layer 3: increase cflib resend timeout from 0.2s -> 1.0s.
# At low Gazebo RTF the firmware (sim-time paced) takes longer than 0.2s to
# answer cflib's TOC/param queries; the default fires resends every 0.2s and
# floods the firmware, making it even slower. 1.0s breaks that feedback loop.
RUN sed -i 's/def send_packet(self, pk, expected_reply=(), resend=False, timeout=0.2):/def send_packet(self, pk, expected_reply=(), resend=False, timeout=1.0):/' \
    $HOME/CrazySim/crazyflie-lib-python/cflib/crazyflie/__init__.py \
    && grep -q "timeout=1.0" $HOME/CrazySim/crazyflie-lib-python/cflib/crazyflie/__init__.py \
    || (echo "FAILED: cflib send_packet timeout sed patch did not apply" && exit 1)

# Layer 1: patched Gazebo plugin (unified blocking queue, sleeps instead of busy-wait,
# 256-element capacity). Must overlay BEFORE the firmware/plugin compile step below.
# Header is overlaid too because the pinned upstream commit predates fields used
# by the patched .cpp (cfLibAddrInitialized_, recvCfLib signature).
COPY to_copy/crazysim_plugin/crazysim_plugin.cpp \
     $HOME/CrazySim/crazyflie-firmware/tools/crazyflie-simulation/simulator_files/gazebo/plugins/CrazySim/crazysim_plugin.cpp
COPY to_copy/crazysim_plugin/crazysim_plugin.h \
     $HOME/CrazySim/crazyflie-firmware/tools/crazyflie-simulation/simulator_files/gazebo/plugins/CrazySim/crazysim_plugin.h

RUN pip install Jinja2
RUN cd $HOME/CrazySim/crazyflie-firmware \
    &&  mkdir -p sitl_make/build && cd sitl_make/build \
    &&  cmake .. \
    &&  make all

# Replace with custom models
RUN rm -rf $HOME/CrazySim/crazyflie-firmware/tools/crazyflie-simulation/simulator_files/gazebo/models
COPY to_copy/models $HOME/CrazySim/crazyflie-firmware/tools/crazyflie-simulation/simulator_files/gazebo/models

WORKDIR $HOME/ros2_ws/src/crazyswarm2/crazyflie/scripts
RUN rm $HOME/ros2_ws/src/crazyswarm2/crazyflie_interfaces/CMakeLists.txt
COPY to_copy/CMakeLists.txt $HOME/ros2_ws/src/crazyswarm2/crazyflie_interfaces/
COPY to_copy/AttitudeSetpoint.msg $HOME/ros2_ws/src/crazyswarm2/crazyflie_interfaces/msg/



# Final setup
USER root
WORKDIR $HOME
CMD ["/bin/bash"]


# Crazyflies setup (CFS_TYPE=real)
FROM base AS real

ENV CFS_TYPE=real

RUN  apt install -y\
    libfontconfig1-dev \
    libfreetype-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxcb-cursor-dev \
    libxcb-glx0-dev \
    libxcb-icccm4-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxcb-shape0-dev \
    libxcb-shm0-dev \
    libxcb-sync-dev \
    libxcb-util-dev \
    libxcb-xfixes0-dev \
    libxcb-xinerama0-dev \
    libxcb-xkb-dev \
    libxcb1-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libxrender-dev \
    libusb-1.0-0-dev \
    libxcb-xinerama0 \
    libxcb-cursor0 \
    make gcc-arm-none-eabi \
    swig3.0 \
    && ln -s /usr/bin/swig3.0 /usr/bin/swig

RUN pip install --upgrade pip

RUN cd $HOME && git clone https://github.com/bitcraze/crazyflie-clients-python \
    && cd crazyflie-clients-python \
    && pip install --ignore-installed  -e .

RUN cd $HOME && git clone --recursive https://github.com/bitcraze/crazyflie-firmware.git \
    && cd crazyflie-firmware && git submodule init && git submodule update \
    && make cf2_defconfig \
    && make -j 12 \
    && make bindings_python \
    && cd build \
    && python3 setup.py install --user \
    && export PYTHONPATH=$HOME/crazyflie-firmware/build:$PYTHONPATH

RUN cd $HOME && git clone https://github.com/bitcraze/lps-tools.git \
    && cd $HOME/lps-tools \
    && pip install --ignore-installed -e .


# Final setup
ENV USERNAME=root
RUN usermod -aG plugdev $USERNAME && adduser $USERNAME dialout
COPY to_copy/99-bitcraze.rules /etc/udev/rules.d/.
COPY to_copy/99-lps.rules /etc/udev/rules.d/.

USER root  
WORKDIR $HOME
CMD ["/bin/bash"]