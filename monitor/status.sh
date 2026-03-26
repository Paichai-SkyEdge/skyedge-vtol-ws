#!/bin/bash
# 기체 상태 실시간 대시보드 — arming / nav / VTOL 전환 상태
# 사용법: ./monitor/status.sh [drone_id]

NS="${1:-drone1}"

G=$'\033[0;32m'
R=$'\033[0;31m'
Y=$'\033[1;33m'
C=$'\033[0;36m'
W=$'\033[1m'
N=$'\033[0m'

_decode_arming() {
    case "$1" in
        0) echo "${Y}INIT${N}"           ;;
        1) echo "${Y}STANDBY${N}"        ;;
        2) echo "${G}ARMED${N}"          ;;
        4) echo "${R}STANDBY_ERROR${N}"  ;;
        *) echo "${R}UNKNOWN($1)${N}"    ;;
    esac
}

_decode_nav() {
    case "$1" in
        0)  echo "${C}MANUAL${N}"       ;;
        2)  echo "${C}ALTCTL${N}"       ;;
        3)  echo "${C}POSCTL${N}"       ;;
        14) echo "${G}OFFBOARD${N}"     ;;
        17) echo "${G}AUTO_TAKEOFF${N}" ;;
        18) echo "${G}AUTO_LAND${N}"    ;;
        20) echo "${G}VTOL_TAKEOFF${N}" ;;
        *)  echo "${Y}OTHER($1)${N}"    ;;
    esac
}

_show() {
    local NS="$1"
    STATUS=$(ros2 topic echo "/${NS}/fmu/out/vehicle_status_v1" --once 2>/dev/null)
    LAND=$(ros2 topic echo "/${NS}/fmu/out/vehicle_land_detected" --once 2>/dev/null \
           | awk '/^landed:/{print $2}')

    echo ""
    echo "${W}=== 기체 상태 ===${N}  [/${NS}]  $(date '+%H:%M:%S')"
    echo ""

    if [ -z "$STATUS" ]; then
        echo "  ${R}[토픽 수신 없음 — xrce_agent 또는 waypoint_nav 실행 여부 확인]${N}"
        echo ""
        return
    fi

    ARMING=$(echo "$STATUS" | awk '/arming_state:/{print $2}')
    NAV=$(echo "$STATUS"    | awk '/nav_state:/{print $2}')
    PREFLIGHT=$(echo "$STATUS" | awk '/pre_flight_checks_pass:/{print $2}')
    VTYPE=$(echo "$STATUS"  | awk '/vehicle_type:/{print $2}')
    TS=$(echo "$STATUS"     | awk 'NR==1{print $2}')

    [ "$VTYPE" = "0" ] && VTYPE_LABEL="${C}MC (멀티콥터)${N}" \
                       || VTYPE_LABEL="${G}FW (고정익)${N}"
    [ "$PREFLIGHT" = "true" ] && PF_STR="${G}PASS${N}" \
                               || PF_STR="${R}FAIL${N}"
    [ "$LAND" = "true" ]  && LAND_STR="${Y}착지${N}" \
                          || LAND_STR="${G}비행 중${N}"

    printf "  %-22s %s\n" "arming_state"       "$(_decode_arming "$ARMING")  (${ARMING})"
    printf "  %-22s %s\n" "nav_state"           "$(_decode_nav    "$NAV")  (${NAV})"
    printf "  %-22s %s\n" "vehicle_type"        "$VTYPE_LABEL"
    printf "  %-22s %s\n" "pre_flight_checks"   "$PF_STR"
    printf "  %-22s %s\n" "land_detected"       "$LAND_STR"
    echo ""
    echo "  ${W}arming_state 값:${N}  1=STANDBY  2=ARMED"
    echo "  ${W}nav_state 값:${N}     14=OFFBOARD  17=TAKEOFF  18=LAND"
    echo ""
}

# watch 모드 진입
if [ "$1" = "--show" ]; then
    _show "${2:-drone1}"
else
    watch -c -n 0.5 "bash '$0' --show '${NS}'"
fi
