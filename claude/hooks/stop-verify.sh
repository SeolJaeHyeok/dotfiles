#!/bin/bash
# Stop — 테스트 실행 + 검증 리마인더 (완료 선언 전 최종 확인)

INPUT=$(cat)

SESSION=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('session_id', 'default'))
" 2>/dev/null || echo "default")

# === HANDOFF 카운터 (파일 수정 여부와 무관하게 매 응답마다 실행) ===
COUNTER_FILE="/tmp/.claude-handoff-count-${SESSION}"
HANDOFF_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
HANDOFF_COUNT=$((HANDOFF_COUNT + 1))
echo "$HANDOFF_COUNT" > "$COUNTER_FILE"

HANDOFF_THRESHOLD=5
if [ $((HANDOFF_COUNT % HANDOFF_THRESHOLD)) -eq 0 ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    PROJ=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "harness")
    TODAY=$(date +%Y-%m-%d)
    echo "🔄 [HANDOFF] 응답 ${HANDOFF_COUNT}회 도달" >&2
    echo "   컨텍스트가 길어지고 있습니다. 세션 전환을 권장합니다." >&2
    echo "   1. /handoff [<slug>]  — 스킬이 경로·템플릿·5대 원칙까지 처리" >&2
    echo "      참고 경로: ~/.agents/handoffs/claude/${PROJ}/${TODAY}-<slug>/HANDOFF.md" >&2
    echo "   2. /clear 로 세션 초기화" >&2
    echo "   3. 새 세션에서 @<위 경로> 로드 후 Prompt for New Chat 섹션 실행" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
fi
# =====================================================

MODIFIED_LOG="/tmp/.claude-modified-${SESSION}"

# 이번 세션에서 수정된 파일이 없으면 패스
if [ ! -f "$MODIFIED_LOG" ]; then
    exit 0
fi

MODIFIED_COUNT=$(sort -u "$MODIFIED_LOG" | wc -l | tr -d ' ')
echo "📝 수정된 파일: ${MODIFIED_COUNT}개" >&2
sort -u "$MODIFIED_LOG" | sed 's/^/   - /' >&2
echo "ℹ️  완료 선언 전 테스트를 직접 실행하세요. (Rule 2: 검증은 필수)" >&2

rm -f "$MODIFIED_LOG"
exit 0
