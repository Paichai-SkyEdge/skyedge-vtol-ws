#!/usr/bin/env python3
"""
패키지명: vtol_control_nav
노드명:   waypoint_nav_node
담당자:   제어 A 담당
설명:     GPS 웨이포인트 기반 고정익 순항 비행 제어
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class WaypointNavNode(Node):
    def __init__(self):
        super().__init__('waypoint_nav_node')
        self.get_logger().info('WaypointNavNode 시작됨')

        # TODO: 구현 필요
        # - px4_msgs/VehicleOdometry 구독
        # - GPS 웨이포인트 순서 관리
        # - 고정익 ↔ 호버링 전환 명령
        # - px4_msgs/VehicleCommand 퍼블리시


def main(args=None):
    rclpy.init(args=args)
    node = WaypointNavNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
