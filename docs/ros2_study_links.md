# ROS2 학습 링크 모음

본인 담당 파트에 맞는 링크부터 보는 것이 효율적입니다.

---

## 1. ROS2 기초

처음이라면 아래 주제를 먼저 이해하면 좋습니다: 노드, 토픽, 퍼블리셔/서브스크라이버, 메시지 타입, launch, colcon build

- 네이버 카페 강좌: https://cafe.naver.com/openrt/24070
- 심화 자료: https://cafe.naver.com/openrt/25288

---

## 2. PX4

항법 제어, 실기체 세팅, PX4 연동 담당자에게 필요합니다.

- PX4 공식 문서: https://docs.px4.io
- uXRCE-DDS 브리지: https://docs.px4.io/main/en/middleware/uxrce_dds.html

---

## 3. Gazebo / 시뮬레이션

- Guided Tutorial B1: https://classic.gazebosim.org/tutorials?cat=guided_b&tut=guided_b1
- Guided Tutorial B2: https://classic.gazebosim.org/tutorials?cat=guided_b&tut=guided_b2

---

## 4. 비전

비전 파트 (`vtol_vision`) 담당자에게 필요합니다.

- OpenCV ArUco: `cv2.aruco` 모듈
- YOLO 공식 문서: https://docs.ultralytics.com
- 데이터셋 관리: https://roboflow.com

---

## 5. Docker

팀 환경 통일을 위해 Docker 개념도 함께 익히는 것을 권장합니다.

- Docker 공식 문서: https://docs.docker.com/get-started/
- Docker Compose: https://docs.docker.com/compose/

---

## 관련 문서

- [architecture.md](architecture.md) — 패키지 구조 및 토픽 목록
- [simulation.md](simulation.md) — 시뮬 환경 실행
