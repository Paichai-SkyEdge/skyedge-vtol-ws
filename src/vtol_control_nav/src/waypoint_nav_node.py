#!/usr/bin/env python3
"""
패키지명: vtol_control_nav
노드명:   waypoint_nav_node
담당자:   제어 A 담당
설명:     VTOL 웨이포인트 기반 순항 비행 제어 (PX4 uXRCE-DDS)

상태 머신:
  IDLE → ARMING → TAKEOFF → TRANSITION_TO_FW → NAVIGATE
       → TRANSITION_TO_MC → LAND → LANDING_CONFIRM → DONE

PX4 토픽 네임스페이스: /{drone_id}/fmu/in|out/...
"""

import math
from typing import Iterable

import rclpy
from rclpy.node import Node
from rclpy.qos import (
    DurabilityPolicy,
    HistoryPolicy,
    QoSProfile,
    ReliabilityPolicy,
)
from px4_msgs.msg import (
    OffboardControlMode,
    TrajectorySetpoint,
    VehicleCommand,
    VehicleLocalPosition,
    VehicleStatus,
)


# PX4 uXRCE-DDS 필수 QoS
_PX4_QOS = QoSProfile(
    reliability=ReliabilityPolicy.BEST_EFFORT,
    durability=DurabilityPolicy.TRANSIENT_LOCAL,
    history=HistoryPolicy.KEEP_LAST,
    depth=1,
)


class WaypointNavNode(Node):
    """PX4 VTOL 웨이포인트 비행 노드 (Offboard 포지션 제어)"""

    _IDLE = 'IDLE'
    _ARMING = 'ARMING'
    _TAKEOFF = 'TAKEOFF'
    _TRANSITION_TO_FW = 'TRANSITION_TO_FW'
    _NAVIGATE = 'NAVIGATE'
    _TRANSITION_TO_MC = 'TRANSITION_TO_MC'
    _LAND = 'LAND'
    _LANDING_CONFIRM = 'LANDING_CONFIRM'
    _DONE = 'DONE'

    _CTRL_DT = 0.1  # 10 Hz

    def __init__(self):
        super().__init__('waypoint_nav_node')

        # ── 파라미터 ─────────────────────────────────────────────
        self.declare_parameter('vtol.drone_id', 'drone1')
        self.declare_parameter('vtol.takeoff_altitude', 5.0)
        self.declare_parameter('vtol.cruise_altitude', 30.0)
        self.declare_parameter('vtol.waypoint_frame', 'gps')
        self.declare_parameter('vtol.waypoints', [])
        self.declare_parameter('vtol.waypoint_reached_threshold', 2.0)
        self.declare_parameter('vtol.transition_timeout_sec', 8.0)
        self.declare_parameter('vtol.landing_confirm_alt_threshold', 0.4)
        self.declare_parameter('vtol.landing_confirm_speed_threshold', 0.5)
        self.declare_parameter('vtol.landing_confirm_hold_sec', 1.0)

        drone_id = self.get_parameter('vtol.drone_id').value
        takeoff_alt = self.get_parameter('vtol.takeoff_altitude').value
        cruise_alt = self.get_parameter('vtol.cruise_altitude').value
        waypoint_frame = str(self.get_parameter('vtol.waypoint_frame').value).lower()
        raw_waypoints = self.get_parameter('vtol.waypoints').value

        # NED 좌표계: 위쪽이 음수
        self._takeoff_z = -abs(float(takeoff_alt))
        self._cruise_z = -abs(float(cruise_alt))
        self._wp_reached_thr = float(self.get_parameter('vtol.waypoint_reached_threshold').value)
        self._landing_alt_thr = float(self.get_parameter('vtol.landing_confirm_alt_threshold').value)
        self._landing_speed_thr = float(self.get_parameter('vtol.landing_confirm_speed_threshold').value)

        transition_timeout_sec = float(self.get_parameter('vtol.transition_timeout_sec').value)
        landing_confirm_hold_sec = float(self.get_parameter('vtol.landing_confirm_hold_sec').value)
        self._transition_timeout_cycles = max(1, int(math.ceil(transition_timeout_sec / self._CTRL_DT)))
        self._landing_confirm_required_cycles = max(
            1,
            int(math.ceil(landing_confirm_hold_sec / self._CTRL_DT)),
        )

        self._waypoints = self._load_waypoints(waypoint_frame, raw_waypoints)

        ns = f'/{drone_id}'

        # ── Publishers ────────────────────────────────────────────
        self._pub_offboard = self.create_publisher(
            OffboardControlMode,
            f'{ns}/fmu/in/offboard_control_mode',
            _PX4_QOS,
        )
        self._pub_setpoint = self.create_publisher(
            TrajectorySetpoint,
            f'{ns}/fmu/in/trajectory_setpoint',
            _PX4_QOS,
        )
        self._pub_cmd = self.create_publisher(
            VehicleCommand,
            f'{ns}/fmu/in/vehicle_command',
            _PX4_QOS,
        )

        # ── Subscribers ───────────────────────────────────────────
        self.create_subscription(
            VehicleStatus,
            f'{ns}/fmu/out/vehicle_status',
            self._cb_status,
            _PX4_QOS,
        )
        self.create_subscription(
            VehicleLocalPosition,
            f'{ns}/fmu/out/vehicle_local_position',
            self._cb_local_pos,
            _PX4_QOS,
        )

        # ── 상태 변수 ─────────────────────────────────────────────
        self._status = VehicleStatus()
        self._local_pos = VehicleLocalPosition()
        self._state = self._IDLE
        self._pre_arm_cnt = 0  # Offboard 모드 전환 전 setpoint 최소 10회 필요
        self._transition_wait_cnt = 0
        self._landing_confirm_cnt = 0

        self._wp_idx = 0
        self._landing_hold_sp = self._waypoints[-1]

        self._timer = self.create_timer(self._CTRL_DT, self._control_loop)
        self.get_logger().info(
            f'WaypointNavNode 시작 (ns={ns}, frame={waypoint_frame}, waypoints={len(self._waypoints)})',
        )

    # ── 콜백 ─────────────────────────────────────────────────────

    def _cb_status(self, msg: VehicleStatus) -> None:
        self._status = msg

    def _cb_local_pos(self, msg: VehicleLocalPosition) -> None:
        self._local_pos = msg

    # ── 파라미터 기반 웨이포인트 로딩 ───────────────────────────────

    def _load_waypoints(self, frame: str, raw_waypoints: Iterable[Iterable[float]]) -> list[tuple[float, float, float]]:
        waypoints = self._parse_waypoints(raw_waypoints)
        if not waypoints:
            self.get_logger().warn('vtol.waypoints가 비어있어 기본 단일 waypoint(이륙점 상공)를 사용합니다.')
            return [(0.0, 0.0, self._cruise_z)]

        if frame == 'gps':
            return self._gps_waypoints_to_local_ned(waypoints)

        if frame == 'local_ned':
            return [(x, y, -abs(z)) for x, y, z in waypoints]

        self.get_logger().warn(
            f"알 수 없는 waypoint_frame='{frame}'. local_ned로 처리합니다.",
        )
        return [(x, y, -abs(z)) for x, y, z in waypoints]

    def _parse_waypoints(self, raw_waypoints: Iterable[Iterable[float]]) -> list[tuple[float, float, float]]:
        parsed: list[tuple[float, float, float]] = []
        if not isinstance(raw_waypoints, (list, tuple)):
            return parsed

        for idx, item in enumerate(raw_waypoints):
            if not isinstance(item, (list, tuple)) or len(item) != 3:
                self.get_logger().warn(f'waypoint[{idx}] 형식 오류: [x,y,z] 3원소가 필요합니다.')
                continue
            try:
                x, y, z = float(item[0]), float(item[1]), float(item[2])
            except (TypeError, ValueError):
                self.get_logger().warn(f'waypoint[{idx}] 숫자 변환 실패: {item}')
                continue
            parsed.append((x, y, z))

        return parsed

    def _gps_waypoints_to_local_ned(
        self,
        gps_waypoints: list[tuple[float, float, float]],
    ) -> list[tuple[float, float, float]]:
        """
        GPS (lat, lon, alt_m) waypoint를 로컬 NED (north, east, down)로 변환.

        기준점은 waypoint[0]이며, 소규모 임무 구간을 가정한 등각근사(equirectangular)를 사용.
        """
        lat0, lon0, _ = gps_waypoints[0]
        lat0_rad = math.radians(lat0)
        earth_r = 6_378_137.0

        local: list[tuple[float, float, float]] = []
        for lat, lon, alt in gps_waypoints:
            d_lat = math.radians(lat - lat0)
            d_lon = math.radians(lon - lon0)

            north = d_lat * earth_r
            east = d_lon * earth_r * math.cos(lat0_rad)
            down = -abs(alt)
            local.append((north, east, down))

        return local

    # ── 제어 루프 (10 Hz) ─────────────────────────────────────────

    def _control_loop(self) -> None:
        if self._state == self._IDLE:
            # Offboard 모드 진입 전 setpoint를 연속으로 전송해야 함 (PX4 규칙)
            self._send_offboard_mode()
            self._send_setpoint(0.0, 0.0, self._takeoff_z)
            self._pre_arm_cnt += 1
            if self._pre_arm_cnt >= 10:
                self._cmd_arm()
                self._cmd_set_offboard_mode()
                self._state = self._ARMING
                self.get_logger().info('→ ARMING')

        elif self._state == self._ARMING:
            self._send_offboard_mode()
            self._send_setpoint(0.0, 0.0, self._takeoff_z)
            if self._status.arming_state == VehicleStatus.ARMING_STATE_ARMED:
                self._state = self._TAKEOFF
                self.get_logger().info('→ TAKEOFF')

        elif self._state == self._TAKEOFF:
            self._send_offboard_mode()
            self._send_setpoint(0.0, 0.0, self._takeoff_z)
            if self._reached(0.0, 0.0, self._takeoff_z, thr=0.5):
                self._cmd_vtol_to_fw()
                self._transition_wait_cnt = 0
                self._state = self._TRANSITION_TO_FW
                self.get_logger().info('→ TRANSITION_TO_FW')

        elif self._state == self._TRANSITION_TO_FW:
            self._send_offboard_mode()
            self._send_setpoint(*self._waypoints[self._wp_idx])
            self._transition_wait_cnt += 1

            if self._is_fixed_wing_mode() or self._transition_wait_cnt >= self._transition_timeout_cycles:
                if self._transition_wait_cnt >= self._transition_timeout_cycles:
                    self.get_logger().warn('고정익 전환 확인 타임아웃. NAVIGATE로 진행합니다.')
                self._state = self._NAVIGATE
                self.get_logger().info(f'→ NAVIGATE  WP {self._wp_idx} / {len(self._waypoints)}')

        elif self._state == self._NAVIGATE:
            wp = self._waypoints[self._wp_idx]
            self._send_offboard_mode()
            self._send_setpoint(*wp)
            if self._reached(*wp, thr=self._wp_reached_thr):
                self._wp_idx += 1
                if self._wp_idx >= len(self._waypoints):
                    self._landing_hold_sp = wp
                    self._cmd_vtol_to_mc()
                    self._transition_wait_cnt = 0
                    self._state = self._TRANSITION_TO_MC
                    self.get_logger().info('모든 웨이포인트 완료 → TRANSITION_TO_MC')
                else:
                    self.get_logger().info(f'→ WP {self._wp_idx}')

        elif self._state == self._TRANSITION_TO_MC:
            self._send_offboard_mode()
            self._send_setpoint(*self._landing_hold_sp)
            self._transition_wait_cnt += 1

            if self._is_multicopter_mode() or self._transition_wait_cnt >= self._transition_timeout_cycles:
                if self._transition_wait_cnt >= self._transition_timeout_cycles:
                    self.get_logger().warn('멀티콥터 전환 확인 타임아웃. LAND로 진행합니다.')
                self._state = self._LAND
                self.get_logger().info('→ LAND')

        elif self._state == self._LAND:
            self._cmd_land()
            self._landing_confirm_cnt = 0
            self._state = self._LANDING_CONFIRM
            self.get_logger().info('→ LANDING_CONFIRM')

        elif self._state == self._LANDING_CONFIRM:
            if self._is_landed():
                self._landing_confirm_cnt += 1
                if self._landing_confirm_cnt >= self._landing_confirm_required_cycles:
                    self._state = self._DONE
                    self.get_logger().info('→ DONE')
            else:
                self._landing_confirm_cnt = 0

    # ── 도달 판정 ─────────────────────────────────────────────────

    def _reached(self, x: float, y: float, z: float, thr: float = 2.0) -> bool:
        p = self._local_pos
        return math.sqrt((p.x - x) ** 2 + (p.y - y) ** 2 + (p.z - z) ** 2) < thr

    def _is_landed(self) -> bool:
        arming_state = getattr(self._status, 'arming_state', None)
        if arming_state == getattr(VehicleStatus, 'ARMING_STATE_STANDBY', None):
            return True

        z = abs(getattr(self._local_pos, 'z', 999.0))
        vx = getattr(self._local_pos, 'vx', 999.0)
        vy = getattr(self._local_pos, 'vy', 999.0)
        vz = getattr(self._local_pos, 'vz', 999.0)
        speed = math.sqrt(vx * vx + vy * vy + vz * vz)

        return z <= self._landing_alt_thr and speed <= self._landing_speed_thr

    def _is_fixed_wing_mode(self) -> bool:
        vehicle_type = getattr(self._status, 'vehicle_type', None)
        fw_type = getattr(VehicleStatus, 'VEHICLE_TYPE_FIXED_WING', None)
        return vehicle_type is not None and fw_type is not None and vehicle_type == fw_type

    def _is_multicopter_mode(self) -> bool:
        vehicle_type = getattr(self._status, 'vehicle_type', None)
        mc_type = getattr(VehicleStatus, 'VEHICLE_TYPE_ROTARY_WING', None)
        return vehicle_type is not None and mc_type is not None and vehicle_type == mc_type

    # ── OffboardControlMode / TrajectorySetpoint 퍼블리시 ─────────

    def _send_offboard_mode(self) -> None:
        msg = OffboardControlMode()
        msg.position = True
        msg.velocity = False
        msg.acceleration = False
        msg.timestamp = self._us_now()
        self._pub_offboard.publish(msg)

    def _send_setpoint(self, x: float, y: float, z: float, yaw: float = 0.0) -> None:
        msg = TrajectorySetpoint()
        msg.position = [x, y, z]
        msg.yaw = yaw
        msg.timestamp = self._us_now()
        self._pub_setpoint.publish(msg)

    # ── VehicleCommand ────────────────────────────────────────────

    def _cmd_arm(self) -> None:
        self._send_cmd(VehicleCommand.VEHICLE_CMD_COMPONENT_ARM_DISARM, param1=1.0)

    def _cmd_set_offboard_mode(self) -> None:
        # MAV_MODE_FLAG_CUSTOM_MODE_ENABLED=1, PX4 custom_mode=6(Offboard)
        self._send_cmd(
            VehicleCommand.VEHICLE_CMD_DO_SET_MODE,
            param1=1.0,
            param2=6.0,
        )

    def _cmd_vtol_to_fw(self) -> None:
        """VTOL → 고정익 전환 (이륙 후 순항 구간 진입 시 호출)"""
        self._send_cmd(VehicleCommand.VEHICLE_CMD_DO_VTOL_TRANSITION, param1=4.0)

    def _cmd_vtol_to_mc(self) -> None:
        """고정익 → 멀티콥터 전환 (착륙 전 호출)"""
        self._send_cmd(VehicleCommand.VEHICLE_CMD_DO_VTOL_TRANSITION, param1=3.0)

    def _cmd_land(self) -> None:
        self._send_cmd(VehicleCommand.VEHICLE_CMD_NAV_LAND)

    def _send_cmd(
        self,
        command: int,
        param1: float = 0.0,
        param2: float = 0.0,
        param3: float = 0.0,
        param4: float = 0.0,
    ) -> None:
        msg = VehicleCommand()
        msg.command = command
        msg.param1 = param1
        msg.param2 = param2
        msg.param3 = param3
        msg.param4 = param4
        msg.target_system = 1
        msg.target_component = 1
        msg.source_system = 1
        msg.source_component = 1
        msg.from_external = True
        msg.timestamp = self._us_now()
        self._pub_cmd.publish(msg)

    def _us_now(self) -> int:
        """현재 시각 (마이크로초) — PX4 타임스탬프 형식"""
        return self.get_clock().now().nanoseconds // 1000


def main(args=None):
    rclpy.init(args=args)
    node = WaypointNavNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
