# Docker 환경 사용 가이드

Docker Compose를 이용해 시뮬레이션 및 실기체 환경을 실행하는 방법을 안내합니다.

---

## 1. 전제 조건

Docker와 Docker Compose가 설치되어 있어야 합니다.

```bash
sudo apt install docker.io docker-compose-plugin
sudo usermod -aG docker $USER  # 재로그인 필요
```

> `usermod` 명령 후 반드시 로그아웃 후 재로그인해야 `docker` 명령을 `sudo` 없이 사용할 수 있습니다.

---

## 2. 서비스 구성

`docker/docker-compose.yml`에 정의된 서비스 목록입니다.

| 서비스 | 프로필 | 역할 |
|--------|--------|------|
| `px4_sitl` | `sim` | PX4 SITL + Gazebo Classic (headless) |
| `xrce_agent` | `sim` | Micro XRCE-DDS Agent (PX4 ↔ ROS2) |
| `vtol_sim` | `sim` | 우리 ROS2 노드 (비전, 제어, 통신) |
| `vtol_real` | `real` | 실기체 ROS2 노드 |
| `foxglove_bridge` | (없음) | Foxglove WebSocket 브릿지 |

---

## 3. 자주 쓰는 명령어

```bash
# 시뮬 전체 실행
docker compose -f docker/docker-compose.yml --profile sim up

# 백그라운드 실행
docker compose -f docker/docker-compose.yml --profile sim up -d

# 실기체 실행
docker compose -f docker/docker-compose.yml --profile real up

# Foxglove만 실행
docker compose -f docker/docker-compose.yml up foxglove_bridge

# 로그 확인
docker compose -f docker/docker-compose.yml logs -f vtol_sim

# 컨테이너 접속
docker compose -f docker/docker-compose.yml exec vtol_sim bash

# 전체 종료
docker compose -f docker/docker-compose.yml --profile sim down
```

---

## 4. 이미지 빌드

```bash
# 전체 재빌드 (코드 바뀐 경우)
docker compose -f docker/docker-compose.yml build

# 캐시 없이 재빌드 (의존성 바뀐 경우)
docker compose -f docker/docker-compose.yml build --no-cache
```

> 주의: Micro XRCE-DDS Agent 소스 빌드가 포함되어 있어 **처음 빌드는 10~15분** 소요됩니다. `--no-cache` 옵션은 꼭 필요한 경우에만 사용하세요.

---

## 5. 코드 수정 후 반영

`src/` 폴더는 볼륨 마운트(`../src:/vtol_ws/src`)되어 있어 컨테이너 재시작 없이 `colcon build`만 다시 실행하면 됩니다.

```bash
docker compose -f docker/docker-compose.yml exec vtol_sim bash -c \
  "source /opt/ros/humble/setup.bash && colcon build --symlink-install"
```

---

## 6. 자주 발생하는 문제

| 증상 | 원인 및 해결 방법 |
|------|------------------|
| `permission denied` | `sudo usermod -aG docker $USER` 후 재로그인 |
| 포트 충돌 | 8765 (foxglove), 8888 (xrce_agent) 포트를 사용 중인 프로세스 확인 후 종료 |
| 빌드가 느림 | `--no-cache` 없이 빌드, Docker BuildKit 활성화 권장 (`DOCKER_BUILDKIT=1`) |

---

## 7. 관련 문서

- [simulation.md](simulation.md) — PX4 + Gazebo 시뮬레이션 실행 방법
- [foxglove_setup.md](foxglove_setup.md) — Foxglove 시각화 도구 사용법
