cmake_minimum_required(VERSION 3.8)
project(vtol)

find_package(ament_cmake REQUIRED)
find_package(rclpy REQUIRED)

# 노드 실행 파일 + bare import 서브모듈 디렉토리 (런타임에 같은 경로에 있어야 함)
install(PROGRAMS
  src/waypoint_nav_node.py
  DESTINATION lib/${PROJECT_NAME}
)

install(DIRECTORY
  src/trajectory_planners
  src/precision_landing
  src/mission_executor
  DESTINATION lib/${PROJECT_NAME}
)

# 런치 파일과 설정은 share 에 설치 (get_package_share_directory 로 접근)
install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
