#!/usr/bin/env bash
# triple-crown.sh — 5-phase team orchestration for a feature
set -euo pipefail

FEATURE="${1:?사용법: $0 <기능명>}"

echo "🏆 Triple Crown 시작: $FEATURE"
echo "================================================"

# Phase 1: 팀장 — 전략 수립
echo ""
echo "📋 Phase 1: 전략 수립 (/cso, /autoplan)"
tmux send-keys -t team:0.0 "/cso $FEATURE" Enter
sleep 3
tmux send-keys -t team:0.0 "/autoplan $FEATURE" Enter
echo "  → 팀장: /cso + /autoplan 실행 완료"
sleep 5

# Phase 2: 민준 (구조화) + 지훈 (기술 조사) — 병렬
echo ""
echo "🔍 Phase 2: 구조화 & 기술 조사 (민준 + 지훈)"
tmux send-keys -t team:0.1 "민준, '$FEATURE' 기능에 대해 GSD 프로젝트 구조화를 진행해줘. 디렉토리 구조, 모듈 분리, 인터페이스 설계를 포함해서 정리해줘." Enter
tmux send-keys -t team:0.2 "지훈, '$FEATURE' 구현에 필요한 기술 스택, 라이브러리, 레퍼런스를 조사해줘. 유사 구현 사례와 추천 접근법도 정리해줘." Enter
echo "  → 민준: GSD 프로젝트 구조화 지시 완료"
echo "  → 지훈: 기술 조사 지시 완료"
echo "  (Phase 2 완료 대기 중... 30초)"
sleep 30

# Phase 3: 서연 (TDD 구현) + 수아 (UI 구현) — 병렬
echo ""
echo "⚙️  Phase 3: 구현 (서연 + 수아)"
tmux send-keys -t team:0.4 "서연, '$FEATURE' 기능을 TDD 방식으로 구현해줘. 테스트 먼저 작성하고, 테스트를 통과하는 코드를 구현해줘. 민준과 지훈의 결과물을 참고해." Enter
tmux send-keys -t team:0.3 "수아, '$FEATURE' 기능의 UI/UX를 구현해줘. 사용자 흐름, 컴포넌트 설계, 화면 레이아웃을 포함해서 구현해줘. 민준과 지훈의 결과물을 참고해." Enter
echo "  → 서연: TDD 구현 지시 완료"
echo "  → 수아: UI/UX 구현 지시 완료"
echo "  (Phase 3 완료 대기 중... 60초)"
sleep 60

# Phase 4: 태양 (리뷰 + QA) + 민준 (validate) — 병렬
echo ""
echo "🔬 Phase 4: 검증 (태양 + 민준)"
tmux send-keys -t team:0.5 "태양, '$FEATURE' 구현물을 /review 하고 /qa 테스트를 수행해줘. 버그, 코드 품질 이슈, 엣지 케이스를 모두 점검해줘." Enter
tmux send-keys -t team:0.1 "민준, /gsd:validate-phase 를 실행해서 '$FEATURE' 의 전체 구현이 설계 스펙에 맞는지 검증해줘." Enter
echo "  → 태양: /review + /qa 지시 완료"
echo "  → 민준: /gsd:validate-phase 지시 완료"
echo "  (Phase 4 완료 대기 중... 30초)"
sleep 30

# Phase 5: 팀장 — 배포
echo ""
echo "🚀 Phase 5: 배포 (/ship)"
tmux send-keys -t team:0.0 "/ship $FEATURE" Enter
echo "  → 팀장: /ship 실행 완료"

echo ""
echo "================================================"
echo "✅ Triple Crown 완료: $FEATURE"
echo "  Phase 1: 전략 수립 (팀장)"
echo "  Phase 2: 구조화 + 기술 조사 (민준 + 지훈)"
echo "  Phase 3: TDD 구현 + UI 구현 (서연 + 수아)"
echo "  Phase 4: 리뷰/QA + 검증 (태양 + 민준)"
echo "  Phase 5: 배포 (팀장)"
