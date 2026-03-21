# Git 기초 가이드

이 문서는 "Git을 한 번도 안 써본 사람"을 기준으로 작성했습니다.

목표는 다음 세 가지입니다.

1. Git이 무엇인지 아주 간단히 이해하기
2. 이 저장소에서 실수 없이 작업 브랜치를 만들기
3. 수정한 내용을 GitHub에 올리고 PR까지 만들기

## Git과 GitHub는 무엇이 다른가

- Git: 내 컴퓨터에서 파일 변경 이력을 관리하는 도구
- GitHub: Git 저장소를 인터넷에서 공유하고 협업하는 서비스

쉽게 말하면:

- Git은 기록 도구
- GitHub는 공유 공간

입니다.

## 왜 Git을 써야 하나

Git을 쓰면 다음이 가능합니다.

- 누가 무엇을 바꿨는지 기록할 수 있음
- 실수했을 때 이전 상태를 추적할 수 있음
- 여러 사람이 동시에 작업해도 내용을 분리할 수 있음
- 코드를 합치기 전에 리뷰를 받을 수 있음

## 처음 보면 헷갈리는 용어

### clone

GitHub 저장소를 내 컴퓨터로 복사하는 것

```bash
git clone <저장소주소>
```

### status

현재 어떤 파일이 바뀌었는지 보는 것

```bash
git status
```

### add

커밋에 넣을 파일을 선택하는 것

```bash
git add 파일명
```

### commit

선택한 변경 사항을 하나의 기록으로 저장하는 것

```bash
git commit -m "설명"
```

### push

내 컴퓨터의 커밋을 GitHub에 올리는 것

```bash
git push
```

### pull

GitHub의 최신 변경 내용을 내 컴퓨터로 가져오는 것

```bash
git pull
```

## 이 프로젝트에서는 어디서 작업해야 하나

이 저장소에서는 보통 `develop`에서 시작해서 `feature/...` 브랜치를 만들어 작업합니다.

즉, 초보자는 아래 한 줄만 먼저 기억해도 됩니다.

```text
main 에서 직접 작업하지 말고, develop 에서 feature 브랜치를 만들어 작업한다.
```

## 가장 기본적인 하루 작업 흐름

아래 순서를 복사해서 따라 해도 됩니다.

### 1. 저장소 폴더로 이동

```bash
cd ~/vtol_ws
```

### 2. 현재 브랜치 확인

```bash
git branch --show-current
```

### 3. `develop` 으로 이동

```bash
git switch develop
```

### 4. 최신 내용 받기

```bash
git pull
```

### 5. 새 브랜치 만들기

```bash
git switch -c feature/<이름>
```

예시:

```bash
git switch -c feature/yolo-threshold
```

### 6. 작업하기

- 코드 수정
- 문서 수정
- 설정 파일 수정

### 7. 상태 보기

```bash
git status
```

### 8. 커밋할 파일 추가

```bash
git add .
```

### 9. 커밋 만들기

```bash
git commit -m "feat: add yolo threshold parameter"
```

### 10. GitHub에 브랜치 올리기

```bash
git push -u origin feature/yolo-threshold
```

### 11. GitHub에서 PR 만들기

- 기준 브랜치: `develop`
- 내 작업 브랜치: `feature/yolo-threshold`

## `git status`를 읽는 법

초보자에게 가장 중요한 명령은 `git status` 입니다.

```bash
git status
```

자주 보는 표현:

- `On branch develop`
  - 현재 `develop` 브랜치에 있다는 뜻
- `Changes not staged for commit`
  - 수정했지만 아직 `git add` 하지 않은 파일
- `Changes to be committed`
  - 이미 `git add` 해서 커밋 준비가 된 파일
- `working tree clean`
  - 현재 수정 중인 파일이 없다는 뜻

## 커밋 메시지는 어떻게 쓰나

좋은 커밋 메시지는 "무엇을 왜 바꿨는지" 짧게 드러납니다.

예시:

```text
feat: add yolo confidence threshold
fix: prevent serial crash on empty input
docs: explain PR workflow for beginners
```

너무 모호한 메시지는 피합니다.

예시:

```text
fix
update
1차 수정
완료
```

## 자주 하는 질문

### Q1. `main`에서 작업했는데 어떡하나요?

당황하지 말고 먼저 현재 변경 사항을 잃지 않는 것이 중요합니다.

아직 커밋하지 않았다면 새 브랜치를 바로 만들어도 수정 내용이 그대로 따라갑니다.

```bash
git switch -c feature/<이름>
```

### Q2. `git add .`는 위험한가요?

편리하지만 원하지 않는 파일까지 들어갈 수 있습니다.

가능하면 `git status` 로 확인한 뒤 사용하세요.

### Q3. push 했는데 PR은 자동으로 생기나요?

아닙니다.

보통은 GitHub 웹사이트에서 직접 PR을 생성해야 합니다.

### Q4. merge, rebase는 꼭 알아야 하나요?

초보 단계에서는 꼭 그렇지 않습니다.

우선은 아래 흐름만 익히면 충분합니다.

- `develop`으로 이동
- `git pull`
- `feature/...` 브랜치 생성
- 작업
- `git add`
- `git commit`
- `git push`
- PR 생성

## 실수를 줄이는 습관

- 작업 시작 전에 `git branch --show-current` 실행하기
- 커밋 전에 `git status` 확인하기
- push 전에 PR 대상이 `develop`인지 생각하기
- 큰 수정 전에 팀에 먼저 공유하기
- 한 번에 너무 많은 파일을 바꾸지 않기

## 이 저장소에서 꼭 기억할 문서

- [README.md](../README.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [architecture.md](architecture.md)
- [foxglove_setup.md](foxglove_setup.md)
