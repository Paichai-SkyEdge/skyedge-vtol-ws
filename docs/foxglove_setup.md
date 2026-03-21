# Foxglove 모니터링 설정 가이드

이 문서는 Foxglove를 이용해 ROS 2 데이터를 시각화하는 방법을 설명합니다.

Foxglove는 다음 상황에서 유용합니다.

- 카메라 영상이 정상적으로 들어오는지 확인할 때
- PX4 상태 토픽이 발행되는지 확인할 때
- 비전 인식 결과나 위치 정보를 실시간으로 보고 싶을 때

## 먼저 알아둘 점

Foxglove를 사용하려면 ROS 2 토픽을 WebSocket 형태로 연결해주는 브릿지가 필요합니다.

이 저장소에서는 `foxglove_bridge` 를 사용합니다.

기본 포트는 `8765` 입니다.

즉, Foxglove 앱은 아래 주소로 접속합니다.

```text
ws://localhost:8765
```

## 1. 브릿지 실행

실행 방법은 두 가지가 있습니다.

### 방법 A. Docker Compose 사용

저장소 루트에서 실행:

```bash
docker compose -f docker/docker-compose.yml up foxglove_bridge
```

이 방식은 Docker 환경 안에서 브릿지를 띄웁니다.

### 방법 B. 로컬에서 직접 실행

이미 ROS 2 환경이 준비되어 있다면 아래처럼 직접 실행할 수 있습니다.

```bash
source /opt/ros/humble/setup.bash
ros2 run foxglove_bridge foxglove_bridge --ros-args -p port:=8765
```

## 2. Foxglove 앱 열기

사용 가능한 방식:

- 데스크탑 앱
- 웹 앱

접속 주소:

```text
ws://localhost:8765
```

브릿지가 정상 실행 중이라면 연결에 성공해야 합니다.

## 3. 처음 연결할 때 확인할 것

- 브릿지가 켜져 있는가
- 포트 `8765` 를 다른 프로그램이 사용하고 있지 않은가
- ROS 2 노드들이 실제로 실행 중인가
- 같은 머신에서 접속 중인가, 아니면 원격 접속 환경인가

원격 환경이라면 `localhost` 대신 실제 IP 주소가 필요할 수 있습니다.

예시:

```text
ws://192.168.0.10:8765
```

## 4. 어떤 데이터를 보면 되는가

Foxglove에서 아래 항목들을 주로 확인합니다.

| 항목 | 토픽 | 설명 |
|------|------|------|
| 배터리 / 상태 | `/drone1/fmu/out/monitoring` | 기체 상태 점검용 |
| 속도 / 위치 | `/drone1/fmu/out/vehicle_odometry` | 항법 상태 확인 |
| 카메라 | `/drone1/camera/image_raw` | 실시간 영상 확인 |
| YOLO 결과 | `/vtol/yolo/detections` | 객체 탐지 결과 확인 |
| ArUco 위치 | `/vtol/aruco/pose` | 마커 기반 위치 추정 확인 |
| 노드 상태 | lifecycle 관련 토픽 | 노드 활성 상태 확인 |

## 5. 커스텀 패널 설치

프로젝트에서 별도 패널을 사용하는 경우 아래처럼 설치할 수 있습니다.

```bash
cd ~/my-status-panel
npm run local-install
```

이후 Foxglove에서 새로고침한 뒤 패널을 추가합니다.

예시 흐름:

1. Foxglove 새로고침
2. `Add Panel` 클릭
3. `My Drone Status` 선택

## 6. 추천 확인 순서

Foxglove가 처음인 팀원은 아래 순서로 확인하면 좋습니다.

1. `/drone1/camera/image_raw` 가 들어오는지 확인
2. `/vtol/yolo/detections` 가 발행되는지 확인
3. `/vtol/aruco/pose` 가 발행되는지 확인
4. `/drone1/fmu/out/vehicle_odometry` 값이 변하는지 확인
5. `/drone1/fmu/out/monitoring` 으로 상태 정보 확인

## 7. 자주 발생하는 문제

### 연결이 안 될 때

확인할 것:

- 브릿지 프로세스가 실행 중인지
- 포트 번호가 `8765` 인지
- 접속 주소가 `ws://localhost:8765` 인지
- 방화벽이나 네트워크 제약이 없는지

### 토픽이 안 보일 때

확인할 것:

- 실제 ROS 2 노드가 실행 중인지
- 토픽 이름을 정확히 입력했는지
- 브릿지는 실행했지만 실제 발행 노드가 없는 상태는 아닌지

### 카메라만 안 보일 때

확인할 것:

- 카메라 노드가 정상 실행 중인지
- `/drone1/camera/image_raw` 가 실제 발행되는지
- 이미지 토픽이 다른 이름으로 바뀌지 않았는지

## 8. 함께 보면 좋은 명령

Foxglove를 보기 전에 터미널에서 아래 명령으로 토픽 상태를 먼저 점검하면 좋습니다.

```bash
ros2 topic list
ros2 topic echo /vtol/aruco/pose
ros2 topic echo /vtol/yolo/detections
```
