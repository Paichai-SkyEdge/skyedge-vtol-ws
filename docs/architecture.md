# VTOL 시스템 아키텍처

## 개요

본 문서는 Paichai SkyEdge VTOL 자율비행 시스템의 패키지 구조, 통신 토픽, 실행 방법을 설명합니다.

---

## 패키지 구조

```
vtol_ws/
├── src/
│   ├── vtol/              # 통합 메인 패키지 (제어 + 런치 + 설정)
│   └── vtol_vision/       # 비전 패키지 (Git 서브모듈)
├── test/
│   ├── contract/          # 구조 계약 테스트
│   ├── unit/              # 단위 테스트
│   └── integration/       # 통합 테스트 (시뮬 실행 필요)
├── docker/                # Docker 컨테이너 설정
└── docs/                  # 문서
```

### vtol (통합 메인 패키지)

웨이포인트 네비게이션, 런치 파일, 전역 설정을 하나의 패키지로 통합합니다.

```
src/vtol/
├── package.xml
├── CMakeLists.txt
├── launch/
│   ├── sim_launch.py      # 시뮬레이션 런치
│   └── real_launch.py     # 실기체 런치
├── config/
│   └── global_params.yaml # 전역 파라미터 (모든 노드 공통)
└── src/
    ├── waypoint_nav_node.py        # 웨이포인트 네비게이션 노드
    ├── trajectory_planners/        # 궤적 계획 알고리즘
    │   ├── base.py                 # 추상 인터페이스
    │   ├── factory.py              # 팩토리 함수
    │   ├── simple.py               # PointJump / Linear / Smoothstep
    │   └── mpc_planner.py          # MPC 플래너
    ├── precision_landing/          # 정밀 착륙 인터페이스 (확장용)
    │   └── base.py
    └── mission_executor/           # 웨이포인트별 임무 인터페이스 (확장용)
        └── base.py
```

**빌드 진입점:**
- `ros2 launch vtol sim_launch.py`
- `ros2 launch vtol real_launch.py`

### vtol_vision (비전 서브모듈)

YOLO 객체 탐지와 ArUco 마커 인식을 담당하는 독립 Git 레포지토리입니다.

```
src/vtol_vision/           # Git 서브모듈
├── package.xml
├── CMakeLists.txt
└── src/
    ├── yolo_detect_node.py     # YOLO v8/v11 객체 탐지
    └── aruco_detect_node.py    # ArUco 마커 6-DOF pose 추정
```

**서브모듈 초기화:**
```bash
git submodule update --init --recursive
```

---

## 노드 목록

| 노드명 | 패키지 | 실행파일 | 상태 |
|--------|--------|---------|------|
| `waypoint_nav` | `vtol` | `waypoint_nav_node` | ✅ 구현 완료 |
| `yolo_detect` | `vtol_vision` | `yolo_detect_node` | ⏸ 구현 예정 |
| `aruco_detect` | `vtol_vision` | `aruco_detect_node` | ⏸ 구현 예정 |

---

## PX4 통신 구조

```
PX4 SITL / 실기체
    │ UDP 8888
    ▼
Micro XRCE-DDS Agent  ←─ PX4 ↔ ROS2 브리지
    │ DDS
    ▼
ROS2 토픽 네트워크
    ├─ /drone1/fmu/out/*   (PX4 → ROS2)
    │   ├─ vehicle_status
    │   ├─ vehicle_local_position
    │   └─ vehicle_odometry
    └─ /drone1/fmu/in/*    (ROS2 → PX4)
        ├─ offboard_control_mode
        ├─ trajectory_setpoint
        └─ vehicle_command
```

## 인터-노드 토픽

| 토픽 | 타입 | 발행자 | 설명 |
|------|------|--------|------|
| `/vtol/yolo/detections` | `vision_msgs/Detection2DArray` | `yolo_detect` | YOLO 탐지 결과 |
| `/vtol/aruco/pose` | `geometry_msgs/PoseStamped` | `aruco_detect` | ArUco 마커 pose |

---

## waypoint_nav 상태 머신

```
IDLE
 └→ ARMING
     └→ TAKEOFF
         └→ TRANSITION_TO_FW
             └→ NAVIGATE ──→ [MISSION_EXEC] (웨이포인트별 임무)
                 └→ TRANSITION_TO_MC ──→ [PRECISION_LAND]
                     └→ LAND
                         └→ LANDING_CONFIRM
                             └→ DONE

오류 발생 시 → FAILSAFE_LAND
```

### 궤적 계획 알고리즘

`global_params.yaml`의 `vtol.trajectory.type`으로 선택합니다.

| 값 | 알고리즘 | 설명 |
|----|---------|------|
| `point_jump` | PointJumpPlanner | 즉시 목표 웨이포인트로 이동 |
| `linear` | LinearPlanner | 일정 속도 선형 보간 |
| `smoothstep` | SmoothstepPlanner | Smoothstep 3차 곡선 보간 (기본값) |
| `mpc` | MPCPlanner | 모델 예측 제어 (이중 적분기 모델) |

---

## 실행 방법

### 시뮬레이션

```bash
# 1. 서브모듈 초기화
git submodule update --init --recursive

# 2. 전체 스택 실행 (PX4 SITL + XRCE-DDS + ROS2 노드)
docker compose -f docker/docker-compose.yml --profile sim up

# 또는 ROS2 노드만 직접 실행
source /opt/ros/humble/setup.bash
colcon build --symlink-install
source install/setup.bash
ros2 launch vtol sim_launch.py
```

### 실기체

```bash
docker compose -f docker/docker-compose.yml --profile real up
```

### Foxglove 시각화

```bash
docker compose -f docker/docker-compose.yml up foxglove_bridge
# 브라우저에서 Foxglove Studio → ws://localhost:8765
```

---

## 테스트

```bash
# 전체 테스트 (계약 + 단위, 통합은 자동 skip)
python3 -m unittest discover -s test -v

# 시뮬 실행 중 통합 테스트
SIM_RUNNING=1 python3 -m unittest discover -s test -v
```

### 테스트 레이어

| 레이어 | 경로 | 실행 조건 | 상태 |
|--------|------|---------|------|
| 계약 | `test/contract/` | 항상 | ✅ PASS 필수 |
| 단위 | `test/unit/` | 항상 | ✅ waypoint_nav PASS |
| 통합 | `test/integration/` | `SIM_RUNNING=1` | CI에서는 skip |

---

## 전역 파라미터 (global_params.yaml)

주요 파라미터 목록입니다. 수정 권한은 총괄에게 있습니다.

| 파라미터 | 기본값 | 설명 |
|---------|--------|------|
| `vtol.use_sim` | `true` | 시뮬/실기체 전환 |
| `vtol.takeoff_altitude` | `5.0` | 이륙 고도 (m) |
| `vtol.cruise_altitude` | `30.0` | 순항 고도 (m) |
| `vtol.max_velocity` | `15.0` | 최대 속도 (m/s) |
| `vtol.waypoint_frame` | `"gps"` | `gps` 또는 `local_ned` |
| `vtol.trajectory.type` | `"smoothstep"` | 궤적 알고리즘 선택 |
| `vtol.waypoints` | `[[lat,lon,alt], ...]` | 비행 웨이포인트 목록 |

전체 파라미터는 [src/vtol/config/global_params.yaml](../src/vtol/config/global_params.yaml)을 참고하세요.
