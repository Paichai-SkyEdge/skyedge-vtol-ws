cmake_minimum_required(VERSION 3.8)
project(vtol_control_task)

find_package(ament_cmake REQUIRED)
find_package(rclpy REQUIRED)

install(PROGRAMS
  src/precision_task_node.py
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
