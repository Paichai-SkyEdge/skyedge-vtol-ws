"""
실기체 환경 통합 launch 파일
실행: ros2 launch vtol_bringup real_launch.py
총괄만 수정 가능
"""
from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    config = os.path.join(
        get_package_share_directory('vtol_bringup'),
        'config', 'global_params.yaml'
    )
    # sim_launch.py와 동일하되 use_sim=false 오버라이드
    return LaunchDescription([
        Node(package='vtol_control_nav', executable='waypoint_nav_node',
             name='waypoint_nav', parameters=[config, {'vtol.use_sim': False}]),
        Node(package='vtol_control_task', executable='precision_task_node',
             name='precision_task', parameters=[config, {'vtol.use_sim': False}]),
        Node(package='vtol_vision_yolo', executable='yolo_detect_node',
             name='yolo_detect', parameters=[config, {'vtol.use_sim': False}]),
        Node(package='vtol_vision_aruco', executable='aruco_detect_node',
             name='aruco_detect', parameters=[config, {'vtol.use_sim': False}]),
        Node(package='vtol_hw_gripper', executable='arduino_cmd_node',
             name='arduino_cmd', parameters=[config, {'vtol.use_sim': False}]),
        Node(package='vtol_comm_lte', executable='telemetry_node',
             name='telemetry', parameters=[config, {'vtol.use_sim': False}]),
    ])
