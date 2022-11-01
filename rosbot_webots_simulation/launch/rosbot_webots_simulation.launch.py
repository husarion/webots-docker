import os
import pathlib
import launch
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
from webots_ros2_driver.webots_launcher import WebotsLauncher
from webots_ros2_driver.webots_launcher import Ros2SupervisorLauncher
from launch.event_handlers import OnProcessExit
from launch.actions import RegisterEventHandler


def generate_launch_description():
    package_dir = get_package_share_directory('rosbot_webots_simulation')
    robot_description = pathlib.Path(os.path.join(
        package_dir, 'resource', 'rosbot.urdf')).read_text()
    robot_webots_description = pathlib.Path(os.path.join(
        package_dir, 'resource', 'rosbot_webots.urdf')).read_text()

    ros2_control_params = os.path.join(
        package_dir, 'resource', 'rosbot_controllers.yaml')

    webots = WebotsLauncher(
        world=os.path.join(package_dir, 'worlds', 'rosbot.wbt')
    )

    ros2_supervisor = Ros2SupervisorLauncher()

    webots_robot_driver = Node(
        package='webots_ros2_driver',
        executable='driver',
        additional_env={'WEBOTS_CONTROLLER_URL': 'rosbot'},
        parameters=[
            {'robot_description': robot_webots_description,
             'set_robot_state_publisher': True},
            ros2_control_params
        ],
        remappings=[
            ("rosbot_base_controller/cmd_vel_unstamped", "cmd_vel")
        ]
    )

    robot_state_publisher = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        output='screen',
        parameters=[{
            'robot_description': robot_description
        }],
    )

    joint_state_broadcaster_spawner = Node(
        package="controller_manager",
        executable="spawner",
        arguments=[
            "joint_state_broadcaster",
            "--controller-manager",
            "/controller_manager",
            "--controller-manager-timeout",
            "120",
        ],
    )

    robot_controller_spawner = Node(
        package="controller_manager",
        executable="spawner",
        arguments=[
            "rosbot_base_controller",
            "--controller-manager",
            "/controller_manager",
            "--controller-manager-timeout",
            "120",
        ],
    )

    # Delay start of robot_controller after joint_state_broadcaster
    delay_robot_controller_spawner_after_joint_state_broadcaster_spawner = (
        RegisterEventHandler(
            event_handler=OnProcessExit(
                target_action=joint_state_broadcaster_spawner,
                on_exit=[robot_controller_spawner],
            )
        )
    )

    # Standard ROS 2 launch description
    return launch.LaunchDescription([

        # Start the Webots node
        webots,

        # Start the Ros2Supervisor node
        ros2_supervisor,

        # Start the Webots robot driver
        webots_robot_driver,

        # Start the robot_state_publisher
        robot_state_publisher,

        # Start the ros2_controllers
        joint_state_broadcaster_spawner,
        delay_robot_controller_spawner_after_joint_state_broadcaster_spawner,

        # This action will kill all nodes once the Webots simulation has exited
        RegisterEventHandler(
            event_handler=launch.event_handlers.OnProcessExit(
                target_action=webots,
                on_exit=[launch.actions.EmitEvent(
                    event=launch.events.Shutdown())],
            )
        )
    ])
