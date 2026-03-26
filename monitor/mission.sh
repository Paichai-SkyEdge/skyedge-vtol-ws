#!/bin/bash
# 미션 파라미터 덤프 — 현재 waypoint_nav 파라미터 확인
# 사용법: ./monitor/mission.sh

W=$'\033[1m'
C=$'\033[0;36m'
G=$'\033[0;32m'
Y=$'\033[1;33m'
N=$'\033[0m'

NODE="/waypoint_nav"

echo ""
echo "${W}=== 미션 파라미터 ===${N}  [${NODE}]  $(date '+%H:%M:%S')"
echo ""

# 노드 존재 확인
if ! ros2 node list 2>/dev/null | grep -q "waypoint_nav"; then
    echo "  ${Y}[waypoint_nav 노드가 실행 중이 아닙니다]${N}"
    echo "  파라미터를 읽으려면 노드를 먼저 실행하세요."
    echo ""
    exit 1
fi

_param() {
    local NAME="$1"
    local VAL
    VAL=$(ros2 param get "$NODE" "$NAME" 2>/dev/null | awk '{print $NF}')
    echo "$VAL"
}

echo "  ${W}--- 비행 설정 ---${N}"
printf "  %-35s %s\n" "takeoff_altitude"     "${C}$(_param vtol.takeoff_altitude) m${N}"
printf "  %-35s %s\n" "cruise_altitude"      "${C}$(_param vtol.cruise_altitude) m${N}"
printf "  %-35s %s\n" "max_altitude_m"       "${C}$(_param vtol.max_altitude_m) m${N}"
printf "  %-35s %s\n" "max_velocity"         "${C}$(_param vtol.max_velocity) m/s${N}"
printf "  %-35s %s\n" "waypoint_frame"       "${C}$(_param vtol.waypoint_frame)${N}"
printf "  %-35s %s\n" "trajectory.type"      "${C}$(_param vtol.trajectory.type)${N}"
printf "  %-35s %s\n" "takeoff_timeout_sec"  "${C}$(_param vtol.takeoff_timeout_sec) s${N}"
echo ""

echo "  ${W}--- 판정 파라미터 ---${N}"
printf "  %-35s %s\n" "waypoint_reached_threshold" "${C}$(_param vtol.waypoint_reached_threshold) m${N}"
printf "  %-35s %s\n" "transition_timeout_sec"     "${C}$(_param vtol.transition_timeout_sec) s${N}"
printf "  %-35s %s\n" "comm_loss_timeout_sec"      "${C}$(_param vtol.comm_loss_timeout_sec) s${N}"
echo ""

echo "  ${W}--- 웨이포인트 ---${N}"
WPS=$(ros2 param get "$NODE" vtol.waypoints 2>/dev/null)
if [ -z "$WPS" ]; then
    echo "  ${Y}[웨이포인트 파라미터를 읽을 수 없음]${N}"
else
    echo "$WPS" | awk '
    BEGIN { idx=0 }
    /String value:/ { next }
    /\[/ {
        gsub(/[\[\]"'\'']/,"")
        gsub(/,/, "")
        printf "  [%d]  %s\n", idx, $0
        idx++
    }
    ' 2>/dev/null || echo "  $WPS"
fi
echo ""

echo "  ${W}--- 착륙 판정 ---${N}"
printf "  %-35s %s\n" "landing_confirm_alt_threshold"   "${C}$(_param vtol.landing_confirm_alt_threshold) m${N}"
printf "  %-35s %s\n" "landing_confirm_speed_threshold" "${C}$(_param vtol.landing_confirm_speed_threshold) m/s${N}"
printf "  %-35s %s\n" "landing_confirm_hold_sec"        "${C}$(_param vtol.landing_confirm_hold_sec) s${N}"
echo ""
