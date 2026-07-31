#!/bin/bash
# PostToolUse(Edit/Write/MultiEdit) — Lint/Format 체크 + 수정 범위 기록 (Side Effect 추적)

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

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    exit 0
fi

# 수정된 파일 기록 (Side Effect 추적용)
MODIFIED_LOG="/tmp/.claude-modified-${SESSION}"
echo "$FILE" >> "$MODIFIED_LOG"

# === 신호 기록 헬퍼 ===
SIGNAL_LOG="$HOME/.agents/signals/log.jsonl"

append_signal() {
    local sig_type="$1" detail="$2" sig_file="${3:-}"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%S")
    printf '{"ts":"%s","session":"%s","type":"%s","source":"hook","detail":"%s","file":"%s"}\n' \
        "$ts" "$SESSION" "$sig_type" "$detail" "$sig_file" >> "$SIGNAL_LOG" 2>/dev/null
}

# 수정된 파일이 여러 디렉토리에 걸쳐 있는지 확인
if [ -f "$MODIFIED_LOG" ]; then
    DIRS=$(awk -F/ 'NF>1{OFS="/"; $NF=""; print $0}' "$MODIFIED_LOG" | sort -u | wc -l | tr -d ' ')
    if [ "$DIRS" -gt 3 ]; then
        echo "⚠️  [scope] 이번 세션에서 ${DIRS}개 디렉토리가 수정됐습니다. 범위가 의도한 것보다 넓지 않은지 확인하세요." >&2
        append_signal "scope-warning" "${DIRS}개 디렉토리 수정" "$FILE"
    fi
fi

# 프로젝트 루트 탐색 및 Lint/Format 실행
run_quality_check() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"

    while [ "$dir" != "/" ]; do
        # Node.js
        if [ -f "$dir/package.json" ]; then
            if [ -f "$dir/node_modules/.bin/eslint" ]; then
                "$dir/node_modules/.bin/eslint" "$file" --quiet 2>&1 && \
                    echo "✅ ESLint 통과: $(basename "$file")" || \
                    echo "⚠️  ESLint 경고: $(basename "$file") — 확인이 필요합니다."
            fi
            if [ -f "$dir/node_modules/.bin/prettier" ]; then
                "$dir/node_modules/.bin/prettier" --check "$file" --log-level warn 2>&1 | grep -v "^$" || \
                    echo "⚠️  Prettier: $(basename "$file") 포맷 수정이 필요합니다."
            fi
            return

        # Ruby
        elif [ -f "$dir/Gemfile" ]; then
            if command -v rubocop &>/dev/null; then
                rubocop "$file" --no-color -f simple 2>&1 | tail -3 && \
                    echo "✅ RuboCop 통과: $(basename "$file")" || \
                    echo "⚠️  RuboCop 경고: $(basename "$file")"
            fi
            return

        # Python
        elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/requirements.txt" ]; then
            if command -v ruff &>/dev/null; then
                ruff check "$file" 2>&1 && \
                    echo "✅ Ruff 통과: $(basename "$file")" || \
                    echo "⚠️  Ruff 경고: $(basename "$file")"
            elif command -v flake8 &>/dev/null; then
                flake8 "$file" 2>&1 && \
                    echo "✅ Flake8 통과: $(basename "$file")" || \
                    echo "⚠️  Flake8 경고: $(basename "$file")"
            fi
            return

        # Go
        elif [ -f "$dir/go.mod" ]; then
            if command -v gofmt &>/dev/null; then
                DIFF=$(gofmt -l "$file" 2>/dev/null)
                if [ -n "$DIFF" ]; then
                    echo "⚠️  gofmt: $(basename "$file") 포맷 수정이 필요합니다."
                else
                    echo "✅ gofmt 통과: $(basename "$file")"
                fi
            fi
            return
        fi

        dir="$(dirname "$dir")"
    done
}

run_quality_check "$FILE" >&2

# AI 슬롭 패턴 탐지
detect_ai_slop() {
    local file="$1"
    local ext="${file##*.}"
    local warnings=()

    # 코드 파일만 검사 (마크다운, JSON, YAML 제외)
    case "$ext" in
        md|json|yaml|yml|toml|lock|txt) return ;;
    esac

    # 1. 자명한 코드에 달린 불필요한 주석
    #    패턴: 변수명/함수명을 그대로 반복하는 주석
    OBVIOUS_COMMENTS=$(grep -n "# Initialize\|# Set \|# Get \|# Return\|// Initialize\|// Set \|// Get \|// Return" "$file" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$OBVIOUS_COMMENTS" -gt 3 ]; then
        warnings+=("💬 자명한 주석 ${OBVIOUS_COMMENTS}개 — 코드가 이미 설명하는 내용의 주석은 제거를 검토하세요")
    fi

    # 2. TODO/FIXME/HACK 과다 (AI가 구현 없이 플레이스홀더를 남긴 신호)
    TODO_COUNT=$(grep -n "TODO\|FIXME\|HACK\|XXX\|PLACEHOLDER" "$file" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TODO_COUNT" -gt 2 ]; then
        warnings+=("📌 TODO/FIXME ${TODO_COUNT}개 — 미완성 플레이스홀더가 남아있습니다")
    fi

    # 3. 과도한 중첩 (복잡도 신호) — 들여쓰기 6단계 이상
    DEEP_NESTING=$(grep -n "^\s\{24\}" "$file" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DEEP_NESTING" -gt 0 ]; then
        warnings+=("🔀 깊은 중첩 ${DEEP_NESTING}줄 — 로직 단순화를 검토하세요")
    fi

    # 4. 한 번만 쓰이는 단순 래퍼 함수 (과도한 추상화 프록시 탐지)
    #    함수 정의 수 대비 파일 크기가 극단적으로 작은 경우
    if command -v wc &>/dev/null; then
        LINE_COUNT=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
        case "$ext" in
            py|rb|js|ts|go)
                FUNC_COUNT=$(grep -c "^\s*def \|^\s*function \|^\s*func \|^\s*const .* = (" "$file" 2>/dev/null || echo 0)
                if [ "$FUNC_COUNT" -gt 0 ] && [ "$LINE_COUNT" -gt 0 ]; then
                    AVG_LINES=$((LINE_COUNT / FUNC_COUNT))
                    if [ "$AVG_LINES" -lt 4 ] && [ "$FUNC_COUNT" -gt 5 ]; then
                        warnings+=("🧩 함수당 평균 ${AVG_LINES}줄 — 지나치게 잘게 쪼개진 함수가 있을 수 있습니다")
                    fi
                fi
                ;;
        esac
    fi

    # 결과 출력 + 신호 기록
    if [ ${#warnings[@]} -gt 0 ]; then
        echo "🤖 [slop-check] $(basename "$file") — AI 슬롭 패턴 감지:" >&2
        for w in "${warnings[@]}"; do
            echo "   $w" >&2
        done
        echo "   → /ai-slop-gc 스킬로 심층 검토 가능" >&2
        append_signal "slop" "$(basename "$file"): ${#warnings[@]}개 슬롭 패턴" "$file"
    fi
}

detect_ai_slop "$FILE"

exit 0
