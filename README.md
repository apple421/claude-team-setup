# Claude AI 멀티에이전트 팀 구축 가이드

Claude CLI 인스턴스 6개를 tmux 세션에 띄워 역할별로 분업하는 AI 팀 환경을 구축합니다.

---

## 팀 구성

| 이름 | 역할 | 담당 업무 | tmux pane |
|------|------|-----------|-----------|
| 쭌 | 팀장 | 지시 수령 → 분석 → 팀원 배분 → 결과 통합 → 보고 | `team:0.0` |
| 민준 | 아키텍트 | 시스템 설계, 기술 스택 선정, API 설계, 성능 검토 | `team:0.1` |
| 지훈 | 리서쳐 | 기술 조사, 레퍼런스 수집, 트렌드 분석 | `team:0.2` |
| 수아 | UI/UX 디자이너 | 화면 설계, 컴포넌트 구조, 사용자 플로우 | `team:0.3` |
| 서연 | 개발자 | 프론트엔드/백엔드 구현, TDD | `team:0.4` |
| 태양 | QA·리뷰어 | 코드 리뷰, 테스트, 버그 리포트 | `team:0.5` |

> 쭌(팀장)은 직접 코드를 작성하거나 파일을 수정하지 않습니다. 모든 작업은 팀원에게 위임됩니다.

---

## 필요한 것들

```bash
# 필수
brew install tmux          # 터미널 멀티플렉서
npm install -g @anthropic-ai/claude-code  # Claude CLI

# 권장
brew install bun           # JS 런타임 (빠른 스크립트 실행)
claude mcp install gstack  # 헤드리스 브라우저 QA 도구
```

**Claude Code 확장 스킬 (claude.ai에서 설치):**

| 스킬 | 용도 |
|------|------|
| `superpowers` | brainstorming, TDD, 코드 리뷰, 디버깅 등 고급 역량 |
| `gsd` | 프로젝트 구조화 및 단계별 검증 (`/gsd:validate-phase`) |

---

## 설치 방법

### 1. 저장소 클론

```bash
git clone <repo-url> ~/Projects/claude-team-setup
cd ~/Projects/claude-team-setup
```

### 2. 스크립트 실행 권한 부여

```bash
chmod +x setup-team.sh triple-crown.sh team-status.sh
```

### 3. 팀 환경 초기화

```bash
./setup-team.sh
```

`setup-team.sh`가 하는 일:
- `~/.claude/roles/` 아래 팀원별 역할 파일(`.md`) 생성
- `~/.claude-roles/<role>/CLAUDE.md` 조합 생성
- tmux `team` 세션 생성 및 6개 pane 레이아웃 구성
- 각 pane에 역할별 모델로 Claude 병렬 실행

초기화가 완료되면 자동으로 tmux `team` 세션에 attach됩니다.

---

## 사용법

### team-status.sh — 팀원 상태 확인

```bash
~/Projects/claude-team-setup/team-status.sh
# 또는
~/team-status.sh
```

각 pane의 현재 상태(대기 중 / 작업 중 / 오류)를 한눈에 확인합니다.  
팀 모니터링 규칙에 따라 **5분마다** 실행을 권장합니다.

---

### triple-crown.sh — 5단계 기능 개발 파이프라인

기능명 하나를 인자로 넘기면 팀 전체가 5단계로 협업합니다.

```bash
~/Projects/claude-team-setup/triple-crown.sh "기능명"

# 예시
~/Projects/claude-team-setup/triple-crown.sh "소셜 로그인"
```

**파이프라인 흐름:**

```
Phase 1 │ 팀장       │ /cso + /autoplan          → 전략 수립
Phase 2 │ 민준 + 지훈 │ GSD 구조화 + 기술 조사    → 병렬 실행
Phase 3 │ 서연 + 수아 │ TDD 구현 + UI 구현        → 병렬 실행
Phase 4 │ 태양 + 민준 │ /review + /qa + /gsd:validate-phase
Phase 5 │ 팀장       │ /ship                     → 배포
```

Phase별 완료 보고 형식:
```
✅ Phase N 완료 / 기능명 / 테스트 N개 GREEN / 다음: Phase N+1
```

---

## 팀원에게 직접 지시하기

tmux 명령으로 특정 팀원에게 바로 메시지를 보낼 수 있습니다.

```bash
tmux send-keys -t team:0.1 "민준, 인증 모듈 아키텍처 설계해줘" Enter
tmux send-keys -t team:0.2 "지훈, Next.js App Router 레퍼런스 조사해줘" Enter
tmux send-keys -t team:0.4 "서연, /src/auth 디렉터리에 로그인 API 구현해줘" Enter
```

---

## 컨텍스트 관리

| 상황 | 대응 |
|------|------|
| 팀원 컨텍스트 70% 초과 | 해당 pane에서 `/context-save` 후 `/clear` |
| Rate limit 발생 | Telegram으로 사용자에게 즉시 보고 |
| 2분 이상 소요 작업 | 중간 진행 상황 보고 필수 |

---

## 디렉터리 구조

```
~/Projects/claude-team-setup/
├── README.md           # 이 파일
├── setup-team.sh       # 팀 환경 초기화 스크립트
├── triple-crown.sh     # 5단계 기능 개발 파이프라인
└── team-status.sh      # 팀원 상태 모니터링

~/.claude/
├── CLAUDE.md.base      # 공통 Bot Mode 규칙
└── roles/
    ├── jun.md          # 쭌 (팀장)
    ├── minjun.md       # 민준 (아키텍트)
    ├── jihun.md        # 지훈 (리서쳐)
    ├── sua.md          # 수아 (UI/UX)
    ├── seoyeon.md      # 서연 (개발자)
    └── taeyang.md      # 태양 (QA·리뷰어)

~/.claude-roles/
├── jun/CLAUDE.md       # 팀장 실행 환경
├── minjun/CLAUDE.md
└── ...
```
