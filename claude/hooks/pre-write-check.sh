#!/bin/bash
# PreToolUse(Edit/Write/MultiEdit) — 읽지 않은 파일 수정 시 차단 (추측 기반 수정 방지)
# 탈출구: CLAUDE_FORCE_WRITE=1 환경변수로 차단 우회 가능

INPUT=$(cat)

FILE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
inp = d.get('tool_input', {})
print(inp.get('file_path', inp.get('path', '')))
" 2>/dev/null || echo "")

SESSION=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('session_id', 'default'))
" 2>/dev/null || echo "default")

# 존재하는 파일에 대해서만 체크 (신규 파일 생성은 패스)
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    exit 0
fi

STATE_FILE="/tmp/.claude-reads-${SESSION}"

if [ ! -f "$STATE_FILE" ] || ! grep -qF "$FILE" "$STATE_FILE" 2>/dev/null; then
    echo "🚫 [guard] '$(basename "$FILE")' 파일을 이 세션에서 읽지 않고 수정하려 합니다." >&2
    echo "   → 먼저 파일을 Read 도구로 읽은 후 수정하세요. (Rule 1: 추측 금지)" >&2
    echo "   → 우회가 필요하면: CLAUDE_FORCE_WRITE=1 환경변수를 설정하세요." >&2

    # CLAUDE_FORCE_WRITE=1 이면 경고만 하고 허용
    if [ "${CLAUDE_FORCE_WRITE}" = "1" ]; then
        echo "   ⚠️  CLAUDE_FORCE_WRITE=1 — 차단 우회됨" >&2
        exit 0
    fi

    exit 2
fi

exit 0
