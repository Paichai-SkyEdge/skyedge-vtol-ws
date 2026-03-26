#!/bin/bash
# Gazebo 디버깅용 프리플라이트 체크
# 노드 alive, 토픽 존재, 주요 Hz, 현재 arming/nav 상태를 한 번에 확인
# 사용법: ./monitor/health.sh [drone_id]

NS="${1:-drone1}"

G=$'\033[0;32m'  # green
R=$'\033[0;31m'  # red
Y=$'\033[1;33m'  # yellow
C=$'\033[0;36m'  # cyan
W=$'\033[1m'     # bold
N=$'\033[0m'     # reset

OK="${G}✓${N}"
NG="${R}✗${N}"
WN="${Y}⚠${N}"

_decode_arming() {
    case "$1" in
        1) echo "STANDBY" ;;
        2) echo "ARMED"   ;;
        4) echo "STANDBY_ERROR" ;;
        *) echo "UNKNOWN($1)" ;;
    esac
}

_decode_nav() {
    case "$1" in
        0)  echo "MANUAL"      ;;
        2)  echo "ALTCTL"      ;;
        3)  echo "POSCTL"      ;;
        14) echo "OFFBOARD"    ;;
        17) echo "AUTO_TAKEOFF";;
        18) echo "AUTO_LAND"   ;;
        20) echo "VTOL_TAKEOFF";;
        *) echo "OTHER($1)"    ;;
    esac
}

_hz_check() {
    local TOPIC="$1" THRESHOLD="$2"
    local HZ
    HZ=$(timeout 4 ros2 topic hz "$TOPIC" --window 5 2>/dev/null \
         | grep "average rate" | awk '{gsub(/:/, "", $3); print $3}')
    if [ -z "$HZ" ]; then
        printf "%-54s %s\n" "$TOPIC" "${R}수신 없음${N}"
    elif awk "BEGIN{exit !($HZ >= $THRESHOLD)}"; then
        printf "%-54s ${G}%.1f Hz${N}  (≥%s)\n" "$TOPIC" "$HZ" "$THRESHOLD"
    else
        printf "%-54s ${Y}%.1f Hz${N}  ${R}기준 미달 (≥%s)${N}\n" "$TOPIC" "$HZ" "$THRESHOLD"
    fi
}

# ────────────────────────────────────────────────
echo ""
echo "${W}=== VTOL Gazebo 헬스 체크 ===${N}  [/${NS}]  $(date '+%H:%M:%S')"
echo ""

# ── 1. XRCE-DDS 브리지 연결 확인 ─────────────────
echo "${W}[XRCE-DDS 브리지]${N}"
TOPIC_LIST=$(ros2 topic list 2>/dev/null)
if echo "$TOPIC_LIST" | grep -q "/${NS}/fmu"; then
    echo "  ${OK} 브리지 연결됨 (/${NS}/fmu 토픽 감지)"
else
    echo "  ${NG} 브리지 연결 없음 — xrce_agent 실행 여부 확인"
fi
echo ""

# ── 2. 노드 확인 ──────────────────────────────────
echo "${W}[ROS2 노드]${N}"
NODES=$(ros2 node list 2>/dev/null)
for NODE in waypoint_nav yolo_detect aruco_detect; do
    if echo "$NODES" | grep -q "$NODE"; then
        echo "  ${OK} $NODE"
    else
        echo "  ${NG} $NODE"
    fi
done
echo ""

# ── 3. PX4 토픽 존재 확인 ─────────────────────────
echo "${W}[PX4 토픽]${N}"
for TOPIC in \
    "/${NS}/fmu/out/vehicle_status_v1" \
    "/${NS}/fmu/out/vehicle_local_position_v1" \
    "/${NS}/fmu/out/vehicle_land_detected" \
    "/${NS}/fmu/in/offboard_control_mode" \
    "/${NS}/fmu/in/trajectory_setpoint" \
    "/${NS}/fmu/in/vehicle_command"; do
    if echo "$TOPIC_LIST" | grep -qF "$TOPIC"; then
        echo "  ${OK} $TOPIC"
    else
        echo "  ${NG} $TOPIC"
    fi
done
echo ""

# ── 4. 주요 토픽 Hz 체크 ──────────────────────────
echo "${W}[토픽 Hz]${N}  (각 4초 측정)"
_hz_check "/${NS}/fmu/in/offboard_control_mode"       10
_hz_check "/${NS}/fmu/in/trajectory_setpoint"         10
_hz_check "/${NS}/fmu/out/vehicle_local_position_v1"  10
_hz_check "/${NS}/fmu/out/vehicle_status_v1"           1
echo ""

# ── 5. 현재 기체 상태 스냅샷 ──────────────────────
echo "${W}[현재 기체 상태]${N}"
STATUS=$(ros2 topic echo "/${NS}/fmu/out/vehicle_status_v1" --once 2>/dev/null)
if [ -z "$STATUS" ]; then
    echo "  ${NG} 상태 토픽 수신 불가"
else
    ARMING=$(echo "$STATUS" | awk '/arming_state:/{print $2}')
    NAV=$(echo "$STATUS"    | awk '/nav_state:/{print $2}')
    PREFLIGHT=$(echo "$STATUS" | awk '/pre_flight_checks_pass:/{print $2}')
    VTYPE=$(echo "$STATUS"  | awk '/vehicle_type:/{print $2}')

    ARM_LABEL=$(_decode_arming "$ARMING")
    NAV_LABEL=$(_decode_nav    "$NAV")

    [ "$ARM_LABEL" = "ARMED" ]    && ARM_COLOR="$G" || ARM_COLOR="$Y"
    [ "$NAV_LABEL" = "OFFBOARD" ] && NAV_COLOR="$G" || NAV_COLOR="$C"
    [ "$PREFLIGHT" = "true" ]     && PF_COLOR="$G"  || PF_COLOR="$R"
    [ "$VTYPE" = "0" ] && VTYPE_LABEL="MC" || VTYPE_LABEL="FW($VTYPE)"

    echo "  arming_state        : ${ARM_COLOR}${ARM_LABEL}${N} (${ARMING})"
    echo "  nav_state           : ${NAV_COLOR}${NAV_LABEL}${N} (${NAV})"
    echo "  pre_flight_checks   : ${PF_COLOR}${PREFLIGHT}${N}"
    echo "  vehicle_type        : ${VTYPE_LABEL}"
fi
echo ""
