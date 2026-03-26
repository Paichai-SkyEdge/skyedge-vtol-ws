#!/bin/bash
# 주요 토픽 Hz 일괄 측정 — Offboard 유지 조건 및 브리지 상태 확인
# 사용법: ./monitor/hz.sh [drone_id]

NS="${1:-drone1}"

G=$'\033[0;32m'
R=$'\033[0;31m'
Y=$'\033[1;33m'
W=$'\033[1m'
N=$'\033[0m'

# 토픽, 기준 Hz, 설명
CHECKS=(
    "/${NS}/fmu/in/offboard_control_mode:10:Offboard 유지 필수 (≥10 Hz)"
    "/${NS}/fmu/in/trajectory_setpoint:10:Offboard 유지 필수 (≥10 Hz)"
    "/${NS}/fmu/out/vehicle_local_position_v1:10:PX4 위치 출력"
    "/${NS}/fmu/out/vehicle_status_v1:1:PX4 상태 출력"
    "/${NS}/fmu/out/vehicle_land_detected:1:착륙 감지"
    "/vtol/yolo/detections:0:비전 (구현 전이면 0 정상)"
    "/vtol/aruco/pose:0:비전 (구현 전이면 0 정상)"
)

echo ""
echo "${W}=== 토픽 Hz 체크 ===${N}  [/${NS}]  (각 4초 측정)"
echo ""
printf "  %-52s  %8s  %s\n" "토픽" "측정값" "판정"
printf "  %s\n" "$(printf '─%.0s' {1..80})"

FAIL=0
for ENTRY in "${CHECKS[@]}"; do
    IFS=':' read -r TOPIC THRESHOLD DESC <<< "$ENTRY"

    HZ=$(timeout 5 ros2 topic hz "$TOPIC" --window 5 2>/dev/null \
         | grep "average rate" | awk '{gsub(/:/, "", $3); print $3}')

    if [ -z "$HZ" ]; then
        if [ "$THRESHOLD" = "0" ]; then
            printf "  %-52s  %8s  ${Y}-${N}  %s\n" "$TOPIC" "-" "$DESC"
        else
            printf "  %-52s  %8s  ${R}✗ FAIL${N}  %s\n" "$TOPIC" "없음" "$DESC"
            FAIL=$((FAIL+1))
        fi
    elif awk "BEGIN{exit !($HZ >= $THRESHOLD)}"; then
        printf "  %-52s  %6.1f Hz  ${G}✓ PASS${N}  %s\n" "$TOPIC" "$HZ" "$DESC"
    else
        printf "  %-52s  %6.1f Hz  ${Y}⚠ 낮음${N}  %s\n" "$TOPIC" "$HZ" "$DESC"
        FAIL=$((FAIL+1))
    fi
done

echo ""
if [ "$FAIL" -eq 0 ]; then
    echo "  ${G}전체 PASS${N}"
else
    echo "  ${R}${FAIL}개 항목 기준 미달${N} — Offboard 유지 실패 가능"
fi
echo ""
