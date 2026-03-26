#!/bin/bash
# 비전 토픽 실시간 모니터링 — YOLO 탐지 결과 / ArUco 마커 위치
# 사용법: ./monitor/vision.sh

G=$'\033[0;32m'
R=$'\033[0;31m'
Y=$'\033[1;33m'
C=$'\033[0;36m'
W=$'\033[1m'
N=$'\033[0m'

_show() {
    YOLO=$(ros2 topic echo /vtol/yolo/detections --once 2>/dev/null)
    ARUCO=$(ros2 topic echo /vtol/aruco/pose --once 2>/dev/null)

    echo ""
    echo "${W}=== 비전 상태 ===${N}  $(date '+%H:%M:%S')"
    echo ""

    # YOLO
    echo "  ${W}--- YOLO 탐지 (/vtol/yolo/detections) ---${N}"
    if [ -z "$YOLO" ]; then
        echo "  ${Y}[수신 없음 — yolo_detect 노드 미실행]${N}"
    else
        COUNT=$(echo "$YOLO" | grep -c "id:" || true)
        echo "  탐지 수: ${C}${COUNT}개${N}"
        echo "$YOLO" | awk '
            /id:/{id=$2}
            /score:/{score=$2}
            /class_id:/{
                printf "  → class_id: %-4s  score: %s\n", $2, score
            }
        '
    fi
    echo ""

    # ArUco
    echo "  ${W}--- ArUco 마커 (/vtol/aruco/pose) ---${N}"
    if [ -z "$ARUCO" ]; then
        echo "  ${Y}[수신 없음 — aruco_detect 노드 미실행]${N}"
    else
        echo "$ARUCO" | awk '
            /frame_id:/{print "  frame_id : " $2}
            /^  x:/{print "  x        : " $2}
            /^  y:/{print "  y        : " $2}
            /^  z:/{print "  z        : " $2}
        '
    fi
    echo ""
}

if [ "$1" = "--show" ]; then
    _show
else
    watch -c -n 1 "bash '$0' --show"
fi
