#!/bin/bash
# PostToolUse(Read) — 읽은 파일을 세션 상태에 기록

INPUT=$(cat)

FILE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null || echo "")

SESSION=$(echo "$INPUT" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('session_id', 'default'))
" 2>/dev/null || echo "default")

if [ -n "$FILE" ]; then
    echo "$FILE" >> "/tmp/.claude-reads-${SESSION}"
fi

exit 0
