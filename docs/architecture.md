# VTOL 시스템 아키텍처

## 패키지 의존 관계

```
[vtol_bringup] ← 전체 통합 진입점
      |
      ├── [vtol_control_nav]    ← GPS/웨이포인트 제어
      │         ↑ px4_msgs
      ├── [vtol_control_task]   ← 정밀 착륙
      │         ↑ vision_msgs (from vtol_vision_aruco)
      ├── [vtol_vision_yolo]    → /vtol/yolo/detections
      ├── [vtol_vision_aruco]   → /vtol/aruco/pose
      ├── [vtol_hw_gripper]     ← arduino serial
      └── [vtol_comm_lte]       → GCS telemetry
```

## 주요 토픽 목록

| 토픽 | 타입 | 발행자 | 구독자 |
|------|------|--------|--------|
| `/drone1/fmu/out/vehicle_odometry` | `px4_msgs/VehicleOdometry` | PX4 | vtol_control_nav |
| `/drone1/fmu/in/vehicle_command` | `px4_msgs/VehicleCommand` | vtol_control_nav | PX4 |
| `/drone1/camera/image_raw` | `sensor_msgs/Image` | 카메라 | vtol_vision_yolo, vtol_vision_aruco |
| `/vtol/yolo/detections` | `vision_msgs/Detection2DArray` | vtol_vision_yolo | vtol_control_task |
| `/vtol/aruco/pose` | `geometry_msgs/PoseStamped` | vtol_vision_aruco | vtol_control_task |
| `/vtol/gripper/command` | `std_msgs/Int32` | vtol_control_task | vtol_hw_gripper |
| `/drone1/fmu/out/monitoring` | `px4_msgs/...` | PX4 | vtol_comm_lte |
