import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node, SetParameter

def generate_launch_description():

    aruco_params = os.path.join(
        get_package_share_directory('hero_crazyflies_benchmarking'),
        'config',
        'aruco_parameters.yaml'
        )
    
    launch_description = []
    type_name = os.environ.get('CFS_TYPE', 'sim')
    if type_name == 'sim':
        launch_description.append(SetParameter(name='use_sim_time', value=True))
        
    for i in range(1, int(os.environ.get('NUM_ROBOTS', '4')) + 1):
        aruco_node = Node(
            package='ros2_aruco',
            namespace = f'cf_{i}',
            executable='aruco_node',
            parameters=[aruco_params]
        )
        launch_description.append(aruco_node)

    return LaunchDescription(launch_description)
