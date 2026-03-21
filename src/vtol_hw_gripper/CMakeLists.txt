cmake_minimum_required(VERSION 3.8)
project(vtol_hw_gripper)

find_package(ament_cmake REQUIRED)
find_package(rclpy REQUIRED)

install(PROGRAMS
  src/arduino_cmd_node.py
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
