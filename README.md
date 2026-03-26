# Paichai SkyEdge VTOL

[![Build Check](https://github.com/Paichai-SkyEdge/skyedge-vtol-ws/actions/workflows/build_check.yml/badge.svg?branch=main)](https://github.com/Paichai-SkyEdge/skyedge-vtol-ws/actions/workflows/build_check.yml)

> 배재대학교 SkyEdge 동아리 전용 저장소입니다. 동아리 구성원이 아닌 경우 PR을 생성하지 마세요.

ROS 2 Humble + PX4 기반 VTOL 자율 비행 시스템

---

## 패키지 구조

```
src/
├── vtol/          # 메인 패키지 — 웨이포인트 항법, 런치, 전역 설정
└── vtol_vision/   # 비전 패키지 (Git 서브모듈) — YOLO, ArUco
```

자세한 구조 및 토픽 목록 → [docs/architecture.md](docs/architecture.md)

---

## 빠른 시작

### 시뮬레이션 (Docker)

```bash
# 서브모듈 초기화
git submodule update --init --recursive

# PX4 SITL + XRCE-DDS + ROS2 전체 스택 실행
docker compose -f docker/docker-compose.yml --profile sim up
```

### 로컬 빌드

```bash
git submodule update --init --recursive

source /opt/ros/humble/setup.bash
colcon build --symlink-install
source install/setup.bash

ros2 launch vtol sim_launch.py
```

### 실기체

```bash
docker compose -f docker/docker-compose.yml --profile real up
```

### Foxglove 모니터링

```bash
docker compose -f docker/docker-compose.yml up foxglove_bridge
# 브라우저 → Foxglove Studio → ws://localhost:8765
```

---

## 테스트

```bash
# 계약 + 단위 테스트 (통합은 자동 skip)
python3 -m unittest discover -s test -v

# 시뮬 실행 중 통합 테스트
SIM_RUNNING=1 python3 -m unittest discover -s test -v
```

---

## 브랜치 전략

```
main          ← 안정 버전
  └── develop ← 통합 개발
        └── feature/<이름>-<기능> ← 개인 작업
```

| 브랜치 | 직접 push | PR | CI |
|--------|-----------|----|----|
| `main` | 긴급 hotfix만 | 필수 | 필수 |
| `develop` | 가능 | 권장 | 권장 |

작업 절차 → [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 문서

| 문서 | 내용 |
|------|------|
| [docs/architecture.md](docs/architecture.md) | 패키지 구조, 상태 머신, 토픽 목록 |
| [docs/simulation.md](docs/simulation.md) | PX4 SITL 시뮬 실행 방법 |
| [docs/docker.md](docs/docker.md) | Docker Compose 서비스 구성 |
| [docs/test_spec.md](docs/test_spec.md) | 테스트 정책 및 TC 목록 |
| [docs/foxglove_setup.md](docs/foxglove_setup.md) | Foxglove 모니터링 설정 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 브랜치 전략, PR 절차 |
