"""
시뮬레이션 환경 통합 launch 파일
실행: ros2 launch vtol_bringup sim_launch.py
총괄만 수정 가능
"""
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import IncludeLaunchDescription
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    config = os.path.join(
        get_package_share_directory('vtol_bringup'),
        'config', 'global_params.yaml'
    )

    return LaunchDescription([
        # 제어 A: 웨이포인트 네비게이션
        Node(
            package='vtol_control_nav',
            executable='waypoint_nav_node',
            name='waypoint_nav',
            parameters=[config],
        ),
        # 제어 B: 정밀 착륙
        Node(
            package='vtol_control_task',
            executable='precision_task_node',
            name='precision_task',
            parameters=[config],
        ),
        # 비전 A: YOLO 탐지
        Node(
            package='vtol_vision_yolo',
            executable='yolo_detect_node',
            name='yolo_detect',
            parameters=[config],
        ),
        # 비전 B: ArUco 마커
        Node(
            package='vtol_vision_aruco',
            executable='aruco_detect_node',
            name='aruco_detect',
            parameters=[config],
        ),
        # HW: 집게발
        Node(
            package='vtol_hw_gripper',
            executable='arduino_cmd_node',
            name='arduino_cmd',
            parameters=[config],
        ),
        # 통신: LTE 텔레메트리
        Node(
            package='vtol_comm_lte',
            executable='telemetry_node',
            name='telemetry',
            parameters=[config],
        ),
    ])
