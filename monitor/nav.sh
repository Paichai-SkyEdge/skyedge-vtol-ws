#!/bin/bash
# 항법 실시간 대시보드 — NED 위치, 속도, setpoint, 위치 오차
# 사용법: ./monitor/nav.sh [drone_id]

NS="${1:-drone1}"

G=$'\033[0;32m'
R=$'\033[0;31m'
Y=$'\033[1;33m'
C=$'\033[0;36m'
W=$'\033[1m'
N=$'\033[0m'

_show() {
    local NS="$1"
    POS=$(ros2 topic echo "/${NS}/fmu/out/vehicle_local_position_v1" --once 2>/dev/null)
    SP=$(ros2 topic echo  "/${NS}/fmu/in/trajectory_setpoint"        --once 2>/dev/null)

    echo ""
    echo "${W}=== 항법 상태 ===${N}  [/${NS}]  $(date '+%H:%M:%S')"
    echo ""

    if [ -z "$POS" ]; then
        echo "  ${R}[위치 토픽 수신 없음]${N}"
        echo ""
        return
    fi

    # 위치 파싱
    PX=$(echo "$POS" | awk '/^x:/{print $2}')
    PY=$(echo "$POS" | awk '/^y:/{print $2}')
    PZ=$(echo "$POS" | awk '/^z:/{print $2}')
    VX=$(echo "$POS" | awk '/^vx:/{print $2}')
    VY=$(echo "$POS" | awk '/^vy:/{print $2}')
    VZ=$(echo "$POS" | awk '/^vz:/{print $2}')

    # 고도 (NED z 음수 → 양수로 변환)
    ALT=$(awk "BEGIN{printf \"%.2f\", -($PZ)}")

    # 속도 크기
    VMAG=$(awk "BEGIN{printf \"%.2f\", sqrt(($VX)^2 + ($VY)^2 + ($VZ)^2)}")

    echo "  ${W}--- 현재 위치 (NED) ---${N}"
    printf "  %-12s %8.2f m   (North)\n" "x :" "$PX"
    printf "  %-12s %8.2f m   (East)\n"  "y :" "$PY"
    printf "  %-12s %8.2f m   (Down)   → 고도: ${C}%.2f m${N}\n" "z :" "$PZ" "$ALT"
    echo ""

    echo "  ${W}--- 현재 속도 (NED) ---${N}"
    printf "  vx: %6.2f  vy: %6.2f  vz: %6.2f  |v|: ${C}%.2f m/s${N}\n" \
           "$VX" "$VY" "$VZ" "$VMAG"
    echo ""

    # Setpoint
    if [ -z "$SP" ]; then
        echo "  ${Y}[setpoint 토픽 수신 없음 — offboard 비활성 또는 노드 미실행]${N}"
    else
        SPX=$(echo "$SP" | awk '/position:/{getline; print $2}' | head -1)
        SPY=$(echo "$SP" | awk '/position:/{getline; getline; print $2}' | head -1)
        SPZ=$(echo "$SP" | awk '/position:/{getline; getline; getline; print $2}' | head -1)

        # position 배열로 파싱 (- [x, y, z] 형식)
        POS_ARR=$(echo "$SP" | grep -A1 "position:" | tail -1)
        SPX=$(echo "$POS_ARR" | awk '{gsub(/[\[\],]/,""); print $1}')
        SPY=$(echo "$POS_ARR" | awk '{gsub(/[\[\],]/,""); print $2}')
        SPZ=$(echo "$POS_ARR" | awk '{gsub(/[\[\],]/,""); print $3}')

        # 오차 계산
        DX=$(awk "BEGIN{printf \"%.2f\", ($PX)-($SPX)}")
        DY=$(awk "BEGIN{printf \"%.2f\", ($PY)-($SPY)}")
        DZ=$(awk "BEGIN{printf \"%.2f\", ($PZ)-($SPZ)}")
        DIST=$(awk "BEGIN{printf \"%.2f\", sqrt(($DX)^2+($DY)^2+($DZ)^2)}")

        # 거리에 따른 색상
        DIST_COLOR=$(awk "BEGIN{print ($DIST < 2.0) ? 0 : ($DIST < 5.0) ? 1 : 2}")
        case "$DIST_COLOR" in
            0) DC="$G" ;; 1) DC="$Y" ;; *) DC="$R" ;;
        esac

        echo "  ${W}--- 목표 setpoint ---${N}"
        printf "  %-12s %8.2f    오차: %+.2f\n" "x :" "$SPX" "$DX"
        printf "  %-12s %8.2f    오차: %+.2f\n" "y :" "$SPY" "$DY"
        printf "  %-12s %8.2f    오차: %+.2f   (고도 목표: %.2f m)\n" \
               "z :" "$SPZ" "$DZ" "$(awk "BEGIN{printf \"%.2f\", -($SPZ)}")"
        echo ""
        printf "  목표까지 거리 : ${DC}%.2f m${N}\n" "$DIST"
    fi
    echo ""
}

if [ "$1" = "--show" ]; then
    _show "${2:-drone1}"
else
    watch -c -n 0.5 "bash '$0' --show '${NS}'"
fi
