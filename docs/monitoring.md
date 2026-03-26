# 모니터링 스크립트 가이드

Gazebo 시뮬레이션 디버깅용 터미널 모니터링 스크립트 모음입니다.
프로젝트 루트에서 실행합니다.

```bash
source /opt/ros/humble/setup.bash
source install/setup.bash
```

---

## 스크립트 목록

| 스크립트 | 방식 | 용도 |
|----------|------|------|
| `monitor/health.sh` | 1회 실행 | 프리플라이트 체크 — 노드/토픽/Hz/기체 상태 한 번에 확인 |
| `monitor/status.sh` | 실시간 | arming_state / nav_state / VTOL 전환 상태 |
| `monitor/nav.sh`    | 실시간 | NED 위치·속도 + setpoint + 위치 오차 |
| `monitor/hz.sh`     | 1회 실행 | 주요 토픽 Hz 측정 + Offboard 유지 가능 여부 판정 |
| `monitor/mission.sh`| 1회 실행 | waypoint_nav ROS2 파라미터 덤프 (웨이포인트, 고도, 궤적 설정 등) |
| `monitor/vision.sh` | 실시간 | YOLO 탐지 결과 / ArUco 마커 위치 |

모든 스크립트는 `[drone_id]` 인자 지원 (기본값: `drone1`)

---

## 1. 프리플라이트 체크 — `health.sh`

시뮬 기동 후 가장 먼저 실행합니다.

```bash
./monitor/health.sh
```

확인 항목:
- XRCE-DDS 브리지 연결 여부
- ROS2 노드 alive (`waypoint_nav`, `yolo_detect`, `aruco_detect`)
- PX4 토픽 존재 여부
- 주요 토픽 Hz (Offboard 유지 조건: `offboard_control_mode`, `trajectory_setpoint` ≥ **10 Hz**)
- 현재 arming_state / nav_state 스냅샷

---

## 2. 기체 상태 실시간 확인 — `status.sh`

```bash
./monitor/status.sh
```

arming_state 값:

| 값 | 의미 |
|----|------|
| 1 | STANDBY — ARM 대기 |
| 2 | **ARMED** — 비행 중 |
| 4 | STANDBY_ERROR |

nav_state 주요 값:

| 값 | 의미 |
|----|------|
| 14 | **OFFBOARD** — 우리 노드가 제어 중 |
| 17 | AUTO_TAKEOFF |
| 18 | AUTO_LAND |
| 0  | MANUAL — Offboard 아님 |

0.5초 간격 갱신. `Ctrl+C`로 종료.

---

## 3. 항법 실시간 확인 — `nav.sh`

```bash
./monitor/nav.sh
```

표시 정보:
- **NED 위치** (x=North, y=East, z=Down) + 고도 환산 (m)
- **NED 속도** + 속도 크기 |v|
- **현재 setpoint** + 위치 오차 Δ (목표까지 거리)

위치 오차 색상:
- 초록: < 2 m (정상 추종)
- 노랑: 2~5 m (허용 범위)
- 빨강: > 5 m (이탈)

---

## 4. 토픽 Hz 체크 — `hz.sh`

```bash
./monitor/hz.sh
```

PX4 Offboard 모드 유지 조건: `offboard_control_mode` 및 `trajectory_setpoint` 모두 **≥ 10 Hz** 필요.
이 조건이 깨지면 PX4가 자동으로 Offboard 해제합니다.

각 토픽 4초 측정 후 PASS / FAIL / 낮음 표시.

---

## 5. 미션 파라미터 덤프 — `mission.sh`

```bash
./monitor/mission.sh
```

`waypoint_nav` 노드가 실행 중일 때 현재 로드된 파라미터를 출력합니다.

출력 항목: 이륙/순항/최대 고도, 최대 속도, waypoint 목록, 궤적 알고리즘, 착륙 판정 임계값

---

## 6. 비전 토픽 확인 — `vision.sh`

```bash
./monitor/vision.sh
```

YOLO/ArUco 노드 구현 전에는 `[수신 없음]`이 정상입니다.

---

## 동시 실행 예시 (멀티 터미널)

```
터미널 1: ./monitor/status.sh      # arming/nav 상태
터미널 2: ./monitor/nav.sh         # 위치 추종 확인
터미널 3: ./monitor/hz.sh          # Offboard Hz 주기적 체크
```

---

## 주요 디버깅 시나리오

### ARM이 안 될 때
```bash
./monitor/health.sh       # pre_flight_checks 확인
./monitor/status.sh       # arming_state 변화 관찰
```

### 기체가 목표 위치로 안 갈 때
```bash
./monitor/nav.sh          # setpoint vs 실제 위치 오차 확인
./monitor/hz.sh           # trajectory_setpoint Hz 확인
```

### Offboard 모드 해제될 때
```bash
./monitor/hz.sh           # offboard_control_mode Hz ≥ 10 인지 확인
./monitor/status.sh       # nav_state 전환 관찰
```

### 파라미터 설정값 확인
```bash
./monitor/mission.sh      # 현재 로드된 waypoint, 고도 설정 확인
```
