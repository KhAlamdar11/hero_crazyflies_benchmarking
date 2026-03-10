import os
import yaml
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node,SetParameter


def generate_launch_description():
    launch_description = []
    
    type_name = os.environ.get('CFS_TYPE', 'sim')
    if type_name == 'sim':
        launch_description.append(SetParameter(name='use_sim_time', value=True))
        
    environment_name = os.environ.get('ENV_NAME', 'empty_world')
    if environment_name == 'empty_world':
        # empty world, no octomap needed
        pass
    else:
        world_name = "_".join(environment_name.split("_")[:-1])
        bt_file = os.path.join(
        get_package_share_directory('hero_crazyflies_benchmarking'),
        'worlds', world_name, 'meshes', world_name+'.binvox.bt')

        launch_description.append(
            Node(
               package='octomap_server',
               executable='octomap_server_node',
               name='octomap_server_node',
               parameters=[{'octomap_path': bt_file, 'frame_id': 'world'}],
               output='screen'
           ))
    
    return LaunchDescription(launch_description)
