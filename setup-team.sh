#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
SESSION="team"
MEMBER_NAMES=("쭌" "민준" "지훈" "수아" "서연" "태양")
MEMBER_MODELS=("claude-sonnet-4-6" "claude-opus-4-6" "claude-sonnet-4-6" "claude-sonnet-4-6" "claude-sonnet-4-6" "claude-sonnet-4-6")
MEMBER_ROLES=("jun" "minjun" "jihun" "sua" "seoyeon" "taeyang")
wait_for_pane() {
    local pane="$1" pattern="$2" timeout="${3:-30}" waited=0
    while [ $waited -lt $timeout ]; do
        tmux capture-pane -t "$pane" -p 2>/dev/null | grep -q "$pattern" && return 0
        sleep 1; waited=$((waited + 1))
    done
    return 1
}
start_claude_in_pane() {
    local pane="$1" model="${2:-claude-sonnet-4-6}" role="${3:-jun}"
    local claude_bin; claude_bin="$(command -v claude)"
    local workdir="$HOME/.claude-roles/$role"
    mkdir -p "$workdir"
    cat ~/.claude/CLAUDE.md.base ~/.claude/roles/${role}.md > "$workdir/CLAUDE.md"
    cp ~/.claude/settings.json "$workdir/settings.json"
    local rc_flag=""
    case "$role" in
        jun)     rc_flag="--remote-control '팀장-쭌'" ;;
        minjun)  rc_flag="--remote-control '아키텍트-민준'" ;;
        jihun)   rc_flag="--remote-control '리서쳐-지훈'" ;;
        sua)     rc_flag="--remote-control '디자이너-수아'" ;;
        seoyeon) rc_flag="--remote-control '개발자-서연'" ;;
        taeyang) rc_flag="--remote-control '리뷰어-태양'" ;;
    esac
    tmux send-keys -t "$pane" C-c 2>/dev/null; sleep 0.3
    tmux send-keys -t "$pane" C-u 2>/dev/null; sleep 0.2
    tmux send-keys -t "$pane" "cd $workdir && unset CLAUDECODE && $claude_bin $rc_flag --model $model --dangerously-skip-permissions" Enter
    wait_for_pane "$pane" "trust this folder" 20 && { tmux send-keys -t "$pane" Enter; sleep 1; }
    wait_for_pane "$pane" "I accept" 20 && { tmux send-keys -t "$pane" Down; sleep 0.5; tmux send-keys -t "$pane" Enter; sleep 1; }
    wait_for_pane "$pane" "❯" 30 || true
}
setup_claude_md() {
    mkdir -p ~/.claude/roles
    cat > ~/.claude/CLAUDE.md.base << 'CLAUDEEOF'
## Bot Mode (최우선 규칙)
메시지가 `[{CHANNEL}:{ID}]` 접두사로 시작하면:
1. `{CHANNEL}` 과 `{ID}` 추출
2. 지시된 작업 수행
3. 완료 후 반드시 응답 전송
4. 모든 응답은 🔗 로 시작
5. 전송 완료 후 `Sent` 출력

## 브릿지 명령어 (응답 금지)
`@cc`, `@ccn`, `@ccu`, `/cc`, `/ccn`, `/ccu` 로 시작하는 메시지는
이 텍스트만 출력: 🔗 Delivered to Claude CLI. Reply will arrive shortly.
CLAUDEEOF

    cat > ~/.claude/roles/jun.md << 'ROLEEOF'
## 나의 역할: 쭌 (팀장)
- 직접 작업 금지: 코드 작성, 파일 수정, 명령 실행은 팀원에게 위임
- 역할: 지시 수령 → 분석 → 팀원 배분 → 결과 통합 → 사용자에게 보고

## 팀원 역할 및 호출 방법
- 민준 (아키텍트): 시스템 설계, 기술 스택 → tmux send-keys -t team:0.1 "민준, 내용" Enter
- 지훈 (리서쳐): 기술 조사, 자료 수집 → tmux send-keys -t team:0.2 "지훈, 내용" Enter
- 수아 (UI/UX): 화면 설계, 디자인 → tmux send-keys -t team:0.3 "수아, 내용" Enter
- 서연 (개발자): 코드 작성, 구현 → tmux send-keys -t team:0.4 "서연, 내용" Enter
- 태양 (QA): 코드 리뷰, 테스트 → tmux send-keys -t team:0.5 "태양, 내용" Enter

## 보고 규칙
- 팀원에게서 결과 받으면 반드시 사용자에게 요약 보고
- 보고 형식: "✅ [팀원이름] 완료: [결과 요약]"

## Skill routing
When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec

## 사용 가능한 MCP 도구
- telegram: 작업 완료 보고, 팀원 결과 전달

## MCP 활용 규칙
- 모든 작업 완료 시 Telegram으로 사용자에게 보고

## 컨텍스트 관리 규칙
- 팀원 컨텍스트가 70% 넘으면 즉시 /context-save 후 /clear
- Rate limit 발생 시 즉시 Telegram으로 사용자에게 보고
- 2분 이상 소요 작업은 중간 보고 필수

## 팀 모니터링 규칙
- 5분마다 팀원 상태 확인 (~/team-status.sh 활용)
- Phase 완료 보고 형식:
  ✅ Phase N 완료 / 기능명 / 테스트 N개 GREEN / 다음: Phase N+1
ROLEEOF

    cat > ~/.claude/roles/minjun.md << 'ROLEEOF'
## 나의 역할: 민준 (아키텍트)
- 시스템 아키텍처 설계, 기술 스택 선정, API 설계, 성능 검토
- 완료 후: tmux send-keys -t team:0.0 "쭌, 아키텍처 설계 완료: [요약]" Enter

## Superpowers 스킬
superpowers:brainstorming
superpowers:writing-plans

## 사용 가능한 MCP 도구
- github: 이슈 생성, 마일스톤 관리
- filesystem: /Users/dongsungkim 디렉터리 접근

## MCP 활용 규칙
- 작업 시작 시 GitHub 이슈 생성
- 완료 시 이슈 댓글 작성

## 산출물 경로
- /docs/architecture.md
- /docs/api-spec.md
- /docs/data-model.md
ROLEEOF

    cat > ~/.claude/roles/jihun.md << 'ROLEEOF'
## 나의 역할: 지훈 (리서쳐)
- 기술 조사, 레퍼런스 수집, 트렌드 분석
- 완료 후: tmux send-keys -t team:0.0 "쭌, 리서치 완료: [요약]" Enter

## Superpowers 스킬
superpowers:brainstorming
superpowers:writing-plans

## 사용 가능한 MCP 도구
- filesystem: /Users/dongsungkim 디렉터리 접근

## MCP 활용 규칙
- 리서치 결과는 filesystem에 저장

## 산출물 경로
- /docs/research/ 디렉터리에 저장
ROLEEOF

    cat > ~/.claude/roles/sua.md << 'ROLEEOF'
## 나의 역할: 수아 (UI/UX 디자이너)
- 화면 설계, 컴포넌트 구조, 사용자 플로우 담당
- 완료 후: tmux send-keys -t team:0.0 "쭌, 디자인 완료: [요약]" Enter

## 사용 가능한 MCP 도구
- filesystem: /Users/dongsungkim 디렉터리 접근 (assets 관리)

## MCP 활용 규칙
- 디자인 파일은 ~/Projects 디렉터리에 저장

## 건드리지 않는 영역
- src/features/, src/utils/ — 서연 담당

## 산출물 경로
- /docs/design/user-flow.md
- /docs/design/component-spec.md
ROLEEOF

    cat > ~/.claude/roles/seoyeon.md << 'ROLEEOF'
## 나의 역할: 서연 (개발자)
- 프론트엔드/백엔드 구현, 코드 작성 및 수정
- 완료 후: tmux send-keys -t team:0.0 "쭌, 개발 완료: [요약]" Enter

## Superpowers 스킬
superpowers:test-driven-development
superpowers:systematic-debugging

## 사용 가능한 MCP 도구
- github: 이슈 확인, PR 생성·업데이트
- filesystem: /Users/dongsungkim 디렉터리 접근

## MCP 활용 규칙
- PR 생성 전 반드시 테스트 통과 확인
- 이슈 댓글은 작업 시작 시와 완료 시 2회 작성
- 구현 완료 후 git add, commit, push까지 수행

## 건드리지 않는 영역
- src/styles/, assets/ — 수아 담당
- docs/ — 민준 담당
- 충돌 발견 시 독단 해결 금지, 민준에게 보고
ROLEEOF

    cat > ~/.claude/roles/taeyang.md << 'ROLEEOF'
## 나의 역할: 태양 (QA·리뷰어)
- 코드 리뷰, 테스트, 버그 리포트
- 완료 후: tmux send-keys -t team:0.0 "쭌, 리뷰 완료: [요약]" Enter

## Superpowers 스킬
superpowers:code-reviewer
superpowers:verification-before-completion

## 사용 가능한 MCP 도구
- github: PR 코멘트 작성, 코드 리뷰

## MCP 활용 규칙
- PR 리뷰 시 GitHub에 직접 코멘트 작성
- 버그 발견 시 GitHub 이슈 생성

## 리뷰 체크리스트
- [ ] 코드 컨벤션 준수
- [ ] 에러 핸들링 적절성
- [ ] 보안 취약점 (인젝션, XSS 등)
- [ ] 성능 저하 요소
- [ ] 테스트 커버리지
ROLEEOF

    echo "  ✅ CLAUDE.md 설정 완료"
}
echo -e "${YELLOW}[0/4] 사전 요구사항 확인...${NC}"
command -v tmux &>/dev/null || { echo "tmux 없음"; exit 1; }
command -v claude &>/dev/null || { echo "claude 없음"; exit 1; }
echo "  ✅ tmux $(tmux -V | awk '{print $2}')"
echo "  ✅ claude $(claude --version 2>/dev/null | head -1)"
echo -e "\n${YELLOW}[1/4] CLAUDE.md 설정...${NC}"
setup_claude_md
echo -e "\n${YELLOW}[2/4] TMUX 세션 & 레이아웃 구성...${NC}"
tmux kill-session -t "$SESSION" 2>/dev/null || true
tmux new-session -d -s "$SESSION" -x 220 -y 50
tmux split-window -t "$SESSION:0.0" -h
tmux split-window -t "$SESSION:0.1" -h
tmux split-window -t "$SESSION:0.2" -h
tmux split-window -t "$SESSION:0.3" -h
tmux split-window -t "$SESSION:0.4" -h
tmux select-layout -t "$SESSION:0" even-horizontal
tmux select-layout -t "$SESSION:0" main-vertical
tmux set-option -t "$SESSION" main-pane-width 80
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux set-option -t "$SESSION" allow-rename off
tmux select-pane -t "$SESSION:0.0" -T "쭌"
tmux select-pane -t "$SESSION:0.1" -T "민준 아키텍트"
tmux select-pane -t "$SESSION:0.2" -T "지훈 리서쳐"
tmux select-pane -t "$SESSION:0.3" -T "수아 UI/UX디자이너"
tmux select-pane -t "$SESSION:0.4" -T "서연 개발자"
tmux select-pane -t "$SESSION:0.5" -T "태양 QA·리뷰어"
echo "  ✅ 레이아웃 구성 완료 (6 panes)"
echo -e "\n${YELLOW}[3/4] Claude 병렬 실행 중...${NC}"
for pane in 0 1 2 3 4 5; do
    start_claude_in_pane "$SESSION:0.$pane" "${MEMBER_MODELS[$pane]}" "${MEMBER_ROLES[$pane]}" &
done
wait
echo -e "${GREEN}  ✅ 전체 실행 완료${NC}"
echo -e "\n${YELLOW}[4/4] 상태 확인...${NC}"
sleep 3
for pane in 0 1 2 3 4 5; do
    tmux capture-pane -t "$SESSION:0.$pane" -p 2>/dev/null | grep -q "❯" \
        && echo -e "  Pane $pane (${MEMBER_NAMES[$pane]}): ${GREEN}✅ 준비 완료${NC}" \
        || echo -e "  Pane $pane (${MEMBER_NAMES[$pane]}): ${RED}⚠️  확인 필요${NC}"
done
echo -e "\n${GREEN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║   ✅ 팀 환경 구성 완료!              ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"
[ -t 1 ] && tmux attach -t "$SESSION"
