ARG ROS_DISTRO=galactic

# from https://github.com/cyberbotics/webots-docker
ARG BASE_IMAGE=nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04
FROM ${BASE_IMAGE} AS downloader

# Determine Webots version to be used and set default argument

# Disable dpkg/gdebi interactive dialogs
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes wget && rm -rf /var/lib/apt/lists/
ENV WEBOTS_NIGHTLY_DATE=$WEBOTS_NIGHTLY_DATE

RUN wget \
    https://github.com/cyberbotics/webots/releases/download/nightly_28_10_2022/webots-R2023a-x86-64.tar.bz2 && \
    tar xjf webots-*.tar.bz2 && rm webots-*.tar.bz2

FROM ${BASE_IMAGE}
ARG ROS_DISTRO=galactic

SHELL ["/bin/bash", "-c"]


# Disable dpkg/gdebi interactive dialogs
ENV DEBIAN_FRONTEND=noninteractive

# Install Webots runtime dependencies
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/ && \
  wget https://raw.githubusercontent.com/cyberbotics/webots/master/scripts/install/linux_runtime_dependencies.sh && \
  chmod +x linux_runtime_dependencies.sh && ./linux_runtime_dependencies.sh && rm ./linux_runtime_dependencies.sh && rm -rf /var/lib/apt/lists/

# Install X virtual framebuffer to be able to use Webots without GPU and GUI (e.g. CI)
RUN apt-get update && apt-get install --yes xvfb && rm -rf /var/lib/apt/lists/

# Install Webots
WORKDIR /usr/local
COPY --from=downloader /webots /usr/local/webots/
ENV QTWEBENGINE_DISABLE_SANDBOX=1
ENV WEBOTS_HOME /usr/local/webots
ENV PATH /usr/local/webots:${PATH}

# Install ROS2
RUN apt-get update -y && apt-get install -y curl gnupg lsb-release && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu \
    $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update -y && apt-get install -y ros-${ROS_DISTRO}-ros-base ros-${ROS_DISTRO}-webots-ros2 python3-colcon-common-extensions \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]
RUN chmod +x /ros_entrypoint.sh
COPY ./rosbot_webots_simulation /ros2_ws/src/rosbot_webots_simulation
WORKDIR /ros2_ws
ENV ROS_DISTRO ${ROS_DISTRO}
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build