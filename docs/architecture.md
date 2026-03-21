# VTOL 시스템 아키텍처

이 문서는 이 저장소 안에 있는 패키지들이 어떤 역할을 하고, 서로 어떤 데이터를 주고받는지 설명합니다.

처음 보는 사람이 빠르게 이해해야 할 핵심은 아래와 같습니다.

- `vtol_bringup` 이 전체 실행 진입점입니다.
- 비전 패키지들이 카메라 입력을 처리합니다.
- 제어 패키지들이 PX4 또는 비전 결과를 바탕으로 기체를 제어합니다.
- 하드웨어 / 통신 패키지는 외부 장치와 연결됩니다.

## 큰 흐름으로 보기

```text
카메라 입력
  ├─> vtol_vision_yolo   ──> 객체 탐지 결과
  └─> vtol_vision_aruco  ──> 마커 위치 추정 결과

PX4 상태 정보
  └─> vtol_control_nav   ──> 기체 명령 전송

비전 결과 + 상태 정보
  └─> vtol_control_task  ──> 정밀 작업 / 착륙 / 그리퍼 명령

작업 결과 / 상태
  └─> vtol_comm_lte      ──> 지상국 또는 외부 시스템 전송
```

## 패키지 의존 관계

```text
[vtol_bringup] ← 전체 통합 진입점
      |
      ├── [vtol_control_nav]    ← GPS/웨이포인트 제어
      │         ↑ px4_msgs
      ├── [vtol_control_task]   ← 정밀 착륙 / 작업 제어
      │         ↑ vision_msgs (from vtol_vision_yolo / vtol_vision_aruco)
      ├── [vtol_vision_yolo]    → /vtol/yolo/detections
      ├── [vtol_vision_aruco]   → /vtol/aruco/pose
      ├── [vtol_hw_gripper]     ← arduino serial
      └── [vtol_comm_lte]       → GCS telemetry
```

## 패키지별 설명

### `vtol_bringup`

전체 시스템을 실행하는 시작점입니다.

- 시뮬레이션 런치
- 실기체 런치
- 여러 노드를 함께 실행하는 진입점

처음 실행할 때는 보통 이 패키지의 launch 파일을 기준으로 전체 시스템이 올라갑니다.

### `vtol_vision_yolo`

카메라 영상을 받아 YOLO 기반 객체 탐지를 수행합니다.

주요 역할:

- 이미지 구독
- 객체 탐지
- 탐지 결과 발행

### `vtol_vision_aruco`

카메라 영상에서 ArUco 마커를 인식하고 위치 정보를 계산합니다.

주요 역할:

- 이미지 구독
- 마커 검출
- 자세 또는 위치 정보 발행

### `vtol_control_nav`

GPS, 위치, 웨이포인트 정보를 바탕으로 기체 이동 명령을 담당합니다.

주요 역할:

- PX4 상태 정보 구독
- 이동 관련 명령 생성
- PX4 제어 명령 발행

### `vtol_control_task`

정밀 작업이나 정밀 착륙처럼 상위 임무 제어를 담당합니다.

주요 역할:

- 비전 결과 활용
- 특정 임무 단계 판단
- 필요 시 그리퍼나 기체 제어로 연결

### `vtol_hw_gripper`

집게발 같은 하드웨어 장치를 직접 제어하는 패키지입니다.

주요 역할:

- 시리얼 통신
- 그리퍼 열기 / 닫기 명령 처리

### `vtol_comm_lte`

LTE를 통해 상태나 텔레메트리 정보를 외부 시스템으로 보내는 패키지입니다.

주요 역할:

- 상태 정보 수집
- 외부 전송

## 주요 토픽 목록

| 토픽 | 타입 | 발행자 | 구독자 | 설명 |
|------|------|--------|--------|------|
| `/drone1/fmu/out/vehicle_odometry` | `px4_msgs/VehicleOdometry` | PX4 | `vtol_control_nav` | 기체 위치 / 속도 정보 |
| `/drone1/fmu/in/vehicle_command` | `px4_msgs/VehicleCommand` | `vtol_control_nav` | PX4 | 기체 제어 명령 |
| `/drone1/camera/image_raw` | `sensor_msgs/Image` | 카메라 | `vtol_vision_yolo`, `vtol_vision_aruco` | 원본 카메라 영상 |
| `/vtol/yolo/detections` | `vision_msgs/Detection2DArray` | `vtol_vision_yolo` | `vtol_control_task` | 객체 탐지 결과 |
| `/vtol/aruco/pose` | `geometry_msgs/PoseStamped` | `vtol_vision_aruco` | `vtol_control_task` | 마커 기반 위치 추정 |
| `/vtol/gripper/command` | `std_msgs/Int32` | `vtol_control_task` | `vtol_hw_gripper` | 그리퍼 제어 명령 |
| `/drone1/fmu/out/monitoring` | `px4_msgs/...` | PX4 | `vtol_comm_lte` | 모니터링용 상태 데이터 |

## 초보자가 읽을 때 추천 순서

1. `vtol_bringup` 이 전체 시작점이라는 점 이해
2. 카메라 입력이 `vtol_vision_yolo`, `vtol_vision_aruco` 로 들어간다는 점 이해
3. 제어 패키지가 PX4 또는 비전 결과를 사용한다는 점 이해
4. 하드웨어 / 통신 패키지가 외부 장치와 연결된다는 점 이해

## 문서 읽는 팁

- 특정 패키지를 맡았다면 해당 패키지 이름이 들어간 토픽부터 먼저 보면 이해가 빠릅니다.
- 전체 실행이 안 될 때는 `vtol_bringup` 과 입력 토픽 연결부터 점검하는 것이 좋습니다.
