# 시뮬레이션 실행 가이드

PX4 + Gazebo 기반 VTOL 시뮬레이션 환경을 실행하는 방법을 안내합니다.

---

## 1. 시뮬레이션 스택 구조

세 가지 서비스가 함께 동작하며, 모두 `network_mode: host`를 사용합니다.

| 서비스 | 역할 |
|--------|------|
| `px4_sitl` | `jonasvautherin/px4-gazebo-headless` 이미지로 PX4 SITL + Gazebo Classic 실행. `VEHICLE=standard_vtol`, `PX4_UXRCE_DDS_NS=drone1` |
| `xrce_agent` | Micro XRCE-DDS Agent (UDP 8888). PX4 내부 uORB 토픽 ↔ ROS2 토픽 브리지 |
| `vtol_sim` | ROS2 노드들 (`waypoint_nav`, `yolo_detect`, `aruco_detect`) |

> `network_mode: host`를 사용하기 때문에 세 서비스가 별도 포트 포워딩 없이 서로 통신합니다.

---

## 2. 방법 A: Docker (권장, headless)

```bash
git submodule update --init --recursive
docker compose -f docker/docker-compose.yml --profile sim up
```

동작 확인:

```bash
ros2 topic list | grep drone1
```

`/drone1/fmu/out/...` 형태의 토픽이 보이면 정상입니다.

---

## 3. 방법 B: Gazebo GUI 보기

방법 A로 Docker 시뮬을 실행 중인 상태에서 호스트 머신에 `gzclient`를 별도 실행합니다.

```bash
sudo apt install gazebo
gzclient
```

`network_mode: host` 덕분에 gzclient가 자동으로 Docker 내부의 gzserver에 연결됩니다.

---

## 4. 방법 C: 네이티브 실행 (개발용)

**터미널 1: PX4-Autopilot + Gazebo**

```bash
git clone --depth 1 --branch v1.14.3 https://github.com/PX4/PX4-Autopilot.git ~/PX4-Autopilot
cd ~/PX4-Autopilot
bash Tools/setup/ubuntu.sh
make px4_sitl_default gazebo-classic_standard_vtol
```

**터미널 2: Micro XRCE-DDS Agent**

```bash
MicroXRCEAgent udp4 -p 8888
```

**터미널 3: ROS2 노드**

```bash
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch vtol sim_launch.py
```

---

## 5. 동작 확인

```bash
# PX4 토픽 확인
ros2 topic list | grep drone1

# 기체 상태 확인
ros2 topic echo /drone1/fmu/out/vehicle_status_v1 --once

# 위치 확인
ros2 topic echo /drone1/fmu/out/vehicle_local_position_v1 --once
```

---

## 6. 자주 발생하는 문제

| 증상 | 원인 및 해결 방법 |
|------|------------------|
| `drone1` 토픽이 안 보임 | `xrce_agent` 실행 여부 확인. `PX4_UXRCE_DDS_NS=drone1` 환경변수 설정 확인 |
| 기체가 arm 안 됨 | PX4 SITL이 완전히 부팅될 때까지 대기 (약 10~15초) |
| `gzclient` 연결 안 됨 | Gazebo 버전 확인, gzserver와 같은 머신에서 실행 중인지 확인 |

---

## 관련 문서

- [docker.md](docker.md) — Docker 환경 사용법
- [architecture.md](architecture.md) — 전체 시스템 아키텍처
