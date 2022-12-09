ARG ROS_DISTRO=galactic

FROM ros:$ROS_DISTRO-ros-base AS package-builder

RUN apt-get update -y && apt-get install -y git ros-$ROS_DISTRO-webots-ros2 python3-colcon-common-extensions \
        ros-$ROS_DISTRO-robot-localization \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd / && git clone https://github.com/husarion/webots.git webots -b husarion
WORKDIR /ros2_ws

# TODO: Develop
COPY webots_ros2/ src/webots_ros2

# TODO: Deploy
# RUN cd  /ros2_ws && \
#     git clone https://github.com/husarion/webots_ros2.git src/webots_ros2 -b husarion && \
#     cd src/webots_ros2 && git submodule update --init webots_ros2_husarion/rosbot_ros && cd /ros2_ws

SHELL ["/bin/bash", "-c"]
RUN source /opt/ros/$ROS_DISTRO/setup.bash && colcon build --packages-select webots_ros2_husarion rosbot_description rosbot_bringup

FROM cyberbotics/webots:R2023a-ubuntu20.04
SHELL ["/bin/bash", "-c"]
ARG ROS_DISTRO
ENV ROS_DISTRO $ROS_DISTRO

RUN apt-get update && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg2 \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
RUN echo "deb http://packages.ros.org/ros2/ubuntu focal main" > /etc/apt/sources.list.d/ros2-latest.list

COPY --from=package-builder /webots/projects/appearances/ /usr/local/webots/projects/appearances/
COPY --from=package-builder /webots/projects/devices/orbbec/ /usr/local/webots/projects/devices/orbbec/
COPY --from=package-builder /webots/projects/devices/tdk/ /usr/local/webots/projects/devices/tdk/protos/
COPY --from=package-builder /webots/projects/objects/ /usr/local/webots/projects/objects/
COPY --from=package-builder /webots/projects/objects/backgrounds/ /usr/local/webots/projects/objects/backgrounds/
COPY --from=package-builder /webots/projects/objects/floors/ /usr/local/webots/projects/objects/floors/


WORKDIR /ros2_ws
RUN apt-get update -y && apt-get install -y git wget ros-$ROS_DISTRO-ros-base ros-$ROS_DISTRO-webots-ros2 \
        ros-$ROS_DISTRO-xacro ros-$ROS_DISTRO-robot-localization  \
        ros-$ROS_DISTRO-rmw-fastrtps-cpp \
        ros-$ROS_DISTRO-rmw-cyclonedds-cpp \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=package-builder /webots/projects/default/worlds/textures/cubic/ /usr/local/webots/projects/default/worlds/textures/cubic/
COPY --from=package-builder /webots/projects/devices/tdk/ /usr/local/webots/projects/devices/tdk/

COPY --from=package-builder /ros2_ws /ros2_ws
COPY --from=husarnet/ros:galactic-ros-core-0.1.0  /ros_entrypoint.sh /ros_entrypoint.sh

ENTRYPOINT [ "/ros_entrypoint.sh" ]