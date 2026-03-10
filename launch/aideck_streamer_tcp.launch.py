import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    aideck_config_path = os.path.join(get_package_share_directory('hero_crazyflies_benchmarking'),
                                                                  'config',
                                                                  'aideck_streamer.yaml')
    launch_description = []
    launch_description.append(Node(
                                package="hero_crazyflies_benchmarking",
                                executable="aideck_streamer_tcp.py",
                                name="aideck_streamer_tcp",
                                parameters=[{"aideck_config_path": aideck_config_path}]))
    return LaunchDescription(launch_description)