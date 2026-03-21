# Foxglove 모니터링 설정 가이드

## 1. Foxglove 브릿지 실행

도커 환경에서 실행:
```bash
docker compose up foxglove_bridge
```

또는 직접 실행:
```bash
ros2 run foxglove_bridge foxglove_bridge --ros-args -p port:=8765
```

## 2. Foxglove 앱 접속

- **데스크탑 앱**: foxglove.dev 에서 다운로드
- **웹**: https://app.foxglove.dev
- 접속 주소: `ws://localhost:8765`

## 3. 커스텀 패널 (My Drone Status) 설치

```bash
cd ~/my-status-panel
npm run local-install
```

Foxglove에서 `Ctrl+R` 새로고침 후 Add Panel → My Drone Status 선택

## 4. 모니터링 항목

| 항목 | 토픽 | 설명 |
|------|------|------|
| 배터리 | `/drone1/fmu/out/monitoring` | 배터리 % |
| 속도 | `/drone1/fmu/out/vehicle_odometry` | m/s |
| 노드 상태 | lifecycle transition_event | ACTIVE/INACTIVE/OFFLINE |
| 카메라 | `/drone1/camera/image_raw` | 실시간 영상 |
| 라이다 | 3D 포인트클라우드 | RGB 장애물 매핑 |
