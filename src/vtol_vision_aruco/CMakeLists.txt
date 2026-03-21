cmake_minimum_required(VERSION 3.8)
project(vtol_vision_aruco)

find_package(ament_cmake REQUIRED)
find_package(rclpy REQUIRED)

install(PROGRAMS
  src/aruco_detect_node.py
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
