# VTOL 프로젝트

> VTOL 기체(고정익 ↔ 호버링 전환)를 이용한 자율 임무 수행 시스템

## 시스템 구성

| 패키지 | 역할 | 담당 |
|--------|------|------|
| `vtol_bringup` | 전체 실행 통합 | 총괄 |
| `vtol_vision_yolo` | YOLO 객체 인식 | 비전 A |
| `vtol_vision_aruco` | ArUco 마커 인식 | 비전 B |
| `vtol_control_nav` | GPS/웨이포인트 제어 | 제어 A |
| `vtol_control_task` | 정밀 착륙 | 제어 B |
| `vtol_hw_gripper` | 집게발 제어 | HW A |
| `vtol_comm_lte` | LTE 텔레메트리 | 통신 B |

## 빠른 시작

### 1. 레포 클론

```bash
git clone https://github.com/<org>/vtol_ws.git
cd vtol_ws
git checkout develop
```

### 2. Docker 빌드 및 실행

```bash
# 시뮬레이션
docker compose --profile sim up

# 실기체
docker compose --profile real up

# Foxglove 모니터링 (별도 터미널)
docker compose up foxglove_bridge
```

### 3. Foxglove 접속

브라우저 또는 데스크탑 앱에서 `ws://localhost:8765` 접속

## 브랜치 전략

```
main          ← 안정 버전만 (직접 push 금지)
  └── develop ← 통합 개발
        └── feature/<기능명>  ← 개인 개발
```

## 기여 방법

1. `develop`에서 `feature/<패키지명>-<기능>` 브랜치 분기
2. 작업 완료 후 `develop`으로 PR 생성
3. 총괄 또는 핵심 인원 1명 이상 리뷰 후 병합
4. CI(빌드 + 린트) 통과 필수

## 문서

- [시스템 아키텍처](docs/architecture.md)
- [Foxglove 모니터링 설정](docs/foxglove_setup.md)
- [ROS2 학습 링크](docs/ros2_study_links.md)
