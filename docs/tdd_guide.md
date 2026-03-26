# TDD 개발 가이드

> 대상 독자: 코드 작성이 처음인 팀원 — Python 기초 수준이면 충분합니다.

---

## 핵심 원칙

- 기본 브랜치는 항상 초록 상태를 유지합니다.
- 아직 구현하지 않은 기능 테스트는 `@unittest.skip`으로 처리되어 있습니다.
- 담당자가 구현을 시작할 때 `skip`을 제거하고, 구현과 테스트를 함께 PASS로 만듭니다.

먼저 전체 테스트를 한 번 실행해보세요:

```bash
python3 -m unittest discover -s test -v
```

기대 결과: contract PASS + waypoint_nav PASS + 나머지 **skip** (빨간색 없음)

---

## 1. TDD가 뭔가요?

```
일반 개발:  코드 짜기 → 직접 실행해서 확인 → 버그 발견 → 코드 수정
TDD:        테스트 먼저 (FAIL) → 코드 짜기 → 테스트 PASS → 완료
```

이 프로젝트에서 TDD를 쓰는 이유:
- 드론 코드는 직접 실행하려면 시뮬레이터, PX4, ROS2가 전부 켜져 있어야 함
- 테스트는 **노트북에서도, ROS2 없이도** 1초 만에 확인 가능
- 토픽 이름, 파라미터 이름 등 인터페이스 규칙 자동 검증

---

## 2. 테스트가 내 코드를 어떻게 가져오나요?

테스트 파일이 `sys.path`를 조작해 실제 `src/` 폴더를 Python 경로에 추가한 뒤 직접 import합니다.

예: `test/unit/test_vision_aruco.py` 상단

```python
sys.path.insert(0, str(Path(__file__).parents[1]))           # test/ 폴더
from mock_ros2 import install
install()                                                      # rclpy 등을 가짜로 교체

sys.path.insert(0, str(Path(__file__).parents[2] / 'src' / 'vtol_vision' / 'src'))
from aruco_detect_node import ArucoDetectNode
```

경로 구조:

```
vtol_ws/
  test/unit/test_vision_aruco.py
  src/vtol_vision/src/aruco_detect_node.py  ← 내가 구현하는 파일
```

**결론**: 테스트 파일은 건드리지 않아도 됩니다. `src/.../내파일.py` 안에 코드를 채우면 됩니다.

---

## 3. ROS2 없이 어떻게 테스트가 실행되나요?

`test/mock_ros2.py`가 `rclpy`, `px4_msgs` 등을 가짜 객체로 교체합니다.

```
install() 실행
  sys.modules['rclpy']      = 가짜 객체
  sys.modules['px4_msgs']   = 가짜 객체
  sys.modules['rclpy.node'] = { Node: MockNode }
```

내 코드가 `class MyNode(Node)`라고 써도, 테스트 중에는 실제로 `MockNode`를 상속받습니다.

---

## 4. MockNode가 내 코드를 어떻게 감시하나요?

`MockNode`는 `create_publisher`, `create_subscription`, `declare_parameter` 호출 시 딕셔너리에 기록합니다.

```python
class MockNode:
    def __init__(self, name):
        self._publishers    = {}  # { 토픽이름: Mock객체 }
        self._subscriptions = {}  # { 토픽이름: (콜백, Mock객체) }
        self._parameters    = {}  # { 파라미터이름: 기본값 }
```

내 노드에서:

```python
self.create_publisher(PoseStamped, '/vtol/aruco/pose', 10)
```

테스트에서:

```python
self.assertIn('/vtol/aruco/pose', self.node._publishers)  # PASS
```

---

## 5. FAIL 메시지 읽는 법

```
AssertionError: '/vtol/aruco/pose' not found in {}
                                              ^^
                              현재 _publishers 딕셔너리 (비어 있음)
```

해석: `__init__`에서 `create_publisher('/vtol/aruco/pose', ...)` 를 한 번도 안 불렀다는 뜻
수정: `__init__` 안에 퍼블리셔 생성 코드를 추가합니다.

---

## 6. 노드 구현 단계별 가이드

ArucoDetectNode를 예로 설명합니다. 다른 노드도 같은 패턴으로 작성합니다.

**파일: `src/vtol_vision/src/aruco_detect_node.py`**

### Step 1. import

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from geometry_msgs.msg import PoseStamped
```

### Step 2. 파라미터 선언

```python
def __init__(self):
    super().__init__('aruco_detect_node')
    self.declare_parameter('vtol.aruco_marker_id', 0)
```

### Step 3. 구독

```python
    self.create_subscription(Image, '/drone1/camera/image_raw', self._cb_image, 10)
```

### Step 4. 퍼블리셔

```python
    self._pub_pose = self.create_publisher(PoseStamped, '/vtol/aruco/pose', 10)
```

### Step 5. 콜백

```python
def _cb_image(self, msg: Image) -> None:
    # TODO: cv2.aruco로 실제 마커 검출
    pose_msg = PoseStamped()
    self._pub_pose.publish(pose_msg)
```

### Step 6. 테스트 실행

```bash
python3 -m unittest test.unit.test_vision_aruco -v
```

---

## 7. 완성 예시 — WaypointNavNode

이미 모든 테스트가 통과된 WaypointNavNode를 참고하세요.

파일: `src/vtol/src/waypoint_nav_node.py`

핵심 패턴:

```python
# 파라미터 선언
self.declare_parameter('vtol.drone_id', 'drone1')

# PX4 QoS Publisher
self._pub_offboard = self.create_publisher(
    OffboardControlMode,
    f'/{drone_id}/fmu/in/offboard_control_mode',
    _PX4_QOS,
)

# PX4 QoS Subscription
self.create_subscription(
    VehicleStatus,
    f'/{drone_id}/fmu/out/vehicle_status_v1',
    self._cb_status,
    _PX4_QOS,
)

# 제어 루프 타이머
self._timer = self.create_timer(0.1, self._control_loop)  # 10 Hz
```

---

## 8. 테스트 실행 방법

```bash
# 특정 파일만
python3 -m unittest test.unit.test_vision_aruco -v

# 특정 테스트 하나만
python3 -m unittest test.unit.test_vision_aruco.TestArucoInit.test_subscribes_to_camera_image -v

# 단위 테스트 전체
python3 -m unittest discover -s test/unit -v

# 계약 + 단위 전체
python3 -m unittest discover -s test -v
```

담당별 테스트 파일:

| 테스트 파일 | 구현 파일 |
|-------------|-----------|
| `test/unit/test_vision_yolo.py` | `src/vtol_vision/src/yolo_detect_node.py` |
| `test/unit/test_vision_aruco.py` | `src/vtol_vision/src/aruco_detect_node.py` |

---

## 9. 자주 하는 실수

**토픽 이름 오타** — 테스트 파일에 있는 토픽 이름을 복사해서 붙여넣기 하세요. 대소문자, 슬래시, 언더스코어가 한 글자라도 다르면 FAIL입니다.

**파라미터 이름 접두사 누락:**

```python
# 잘못됨
self.declare_parameter('aruco_marker_id', 0)

# 올바름
self.declare_parameter('vtol.aruco_marker_id', 0)
```

**mock 주입 전에 import:**

```python
# 올바른 순서
from mock_ros2 import install
install()
from aruco_detect_node import ArucoDetectNode  # install() 이후에
```

---

## 관련 문서

- [test_spec.md](test_spec.md) — TC 목록 및 각 노드 테스트 명세
- [architecture.md](architecture.md) — 토픽 목록 및 노드 관계도
