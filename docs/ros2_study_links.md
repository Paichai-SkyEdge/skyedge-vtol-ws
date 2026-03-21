# ROS 2 학습 링크 모음

이 문서는 팀원이 공부를 시작할 때 참고할 만한 링크를 정리한 문서입니다.

중요한 점:

- 처음부터 모든 링크를 다 볼 필요는 없습니다.
- 본인 담당 파트에 맞는 링크부터 보는 것이 더 효율적입니다.
- Git과 작업 절차가 먼저라면 [CONTRIBUTING.md](../CONTRIBUTING.md) 와 [git_basics.md](git_basics.md) 를 먼저 읽는 것을 권장합니다.

## 초보자 추천 학습 순서

1. Git / 브랜치 / PR 흐름 이해
2. ROS 2 기본 개념 이해
3. 우리 프로젝트 구조 이해
4. 담당 파트별 심화 학습

## 1. ROS 2 기초

처음 보는 팀원은 아래 주제를 먼저 이해하면 좋습니다.

- 노드(Node)
- 토픽(Topic)
- 퍼블리셔 / 서브스크라이버
- 메시지 타입
- launch
- workspace / colcon build

학습 링크:

- 네이버 카페 강좌: https://cafe.naver.com/openrt/24070
- 심화 자료: https://cafe.naver.com/openrt/25288

## 2. Gazebo / 시뮬레이션

시뮬레이션 환경을 이해하려면 Gazebo 자료가 도움이 됩니다.

- Guided Tutorial B1: https://classic.gazebosim.org/tutorials?cat=guided_b&tut=guided_b1
- Guided Tutorial B2: https://classic.gazebosim.org/tutorials?cat=guided_b&tut=guided_b2

추천 대상:

- 시뮬레이션 담당자
- launch / 환경 구성 담당자
- PX4 시뮬레이터 연동 담당자

## 3. PX4

PX4는 비행 제어와 관련된 핵심 시스템입니다.

먼저 아래 문서를 통해 전체 구조를 보는 것을 권장합니다.

- PX4 공식 문서: https://docs.px4.io
- x500 파라미터 참고: https://docs.px4.io/main/en/complete_vehicles/

추천 대상:

- 항법 제어 담당
- 실기체 세팅 담당
- 시뮬레이션 / PX4 연동 담당

## 4. Docker

Docker는 팀 환경을 맞추기 쉽게 해줍니다.

이 저장소에도 Docker 기반 실행 구성이 포함되어 있으므로, 로컬 환경 차이를 줄이고 싶다면 Docker 개념을 함께 익히는 것이 좋습니다.

- 팀 기준 이미지 참고: https://hub.docker.com/r/aware4docker/qtr-px4-ros2-docker-foxy

추천 대상:

- 환경 세팅 담당
- 새 팀원 온보딩 담당
- 실습 환경 통일이 필요한 팀원

## 5. 영상처리 / 비전

비전 파트 담당자는 아래 자료가 도움이 됩니다.

- OpenCV ArUco: `cv2.aruco` 모듈 사용
- YOLO 공식 문서: https://docs.ultralytics.com
- 데이터셋 관리: https://roboflow.com

주의:

- 데이터셋 업로드 / 다운로드는 저장 공간과 캐시 문제를 일으킬 수 있습니다.
- 무분별하게 데이터를 올리거나 새 프로젝트를 만들지 말고, 팀에서 먼저 합의하는 것을 권장합니다.

## 담당별 추천 시작점

### 비전 담당

- ROS 2 기초
- OpenCV ArUco
- YOLO 문서
- Foxglove로 토픽 시각화 확인

### 제어 담당

- ROS 2 기초
- PX4 문서
- 아키텍처 문서
- 토픽 흐름 확인

### 하드웨어 / 통신 담당

- ROS 2 기초
- 시리얼 통신 관련 코드 확인
- 아키텍처 문서
- Foxglove 및 로그 확인 방법 익히기

## 같이 보면 좋은 저장소 내 문서

- [README.md](../README.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [architecture.md](architecture.md)
- [foxglove_setup.md](foxglove_setup.md)
