#!/bin/bash
#
# set-claude-tier.sh <tier>
#
# 현재 활성 cmux surface(사용자가 보고 있는 pane)의 Claude Code 세션만
# 지정 tier(model + effort)로 재시작한다.
#
#   - 전역 ~/.claude/settings.json 은 절대 건드리지 않는다 (다른 세션 무영향).
#   - model/effort 는 --model/--effort CLI 플래그로 세션별 주입.
#   - 같은 pane 의 zsh 에 명령을 보내므로 cwd 가 자동 보존된다.
#   - cmux 의 zsh `claude()` 래퍼가 --settings(hooks) 를 자동 주입하므로
#     재실행 명령은 순수 `claude ...` 만 보낸다.
#
set -u

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

CMUX="/Applications/cmux.app/Contents/Resources/bin/cmux"
[ -x "$CMUX" ] || CMUX="cmux"

LOG="/tmp/claude-tier.log"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }
_ppid="$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')"
_pcomm="$(ps -o comm= -p "$_ppid" 2>/dev/null)"
log "=== args=[$*] ppid=$_ppid parent=$_pcomm ==="

TIER="${1:-}"

# tier -> model + effort
case "$TIER" in
  1) MODEL="opus";   EFFORT="max"    ;;
  2) MODEL="opus";   EFFORT="xhigh"  ;;
  3) MODEL="sonnet"; EFFORT="medium" ;;
  4) MODEL="sonnet"; EFFORT="low"    ;;
  5) MODEL="haiku";  EFFORT="low"    ;;
  *) echo "Invalid tier '$TIER'. Use 1-5" >&2; exit 1 ;;
esac

# cmux 바이너리 확인
if ! "$CMUX" version >/dev/null 2>&1; then
  echo "cmux 를 실행할 수 없습니다 (path=$CMUX)." >&2
  exit 4
fi

# 1) 포커스된 surface: identify.focused.surface_ref 가 1순위(권위),
#    실패 시 tree 의 '◀ active' 마커로 fallback.
SURFACE="$("$CMUX" identify 2>/dev/null | grep -oE 'surface:[0-9]+' | head -1)"
if [ -z "$SURFACE" ]; then
  SURFACE="$("$CMUX" tree --all 2>/dev/null | grep -E 'surface surface:[0-9]+' | grep 'active' | grep -oE 'surface:[0-9]+' | head -1)"
fi
if [ -z "$SURFACE" ]; then
  log "FAIL: focused surface 없음. identify=[$("$CMUX" identify 2>&1 | tr '\n' ' ')]"
  echo "포커스된 cmux surface 를 찾지 못했습니다." >&2
  exit 3
fi
log "SURFACE=$SURFACE"

# 2) 해당 surface 의 tty (surface:1 이 surface:10 에 오매칭되지 않도록 grep -w)
TTY="$("$CMUX" tree --all 2>/dev/null | grep -w "$SURFACE" | grep -oE 'ttys[0-9]+' | head -1)"
if [ -z "$TTY" ]; then
  echo "surface($SURFACE) 의 tty 를 찾지 못했습니다." >&2
  exit 3
fi

# 2) 해당 tty 의 login shell(-zsh 등, comm 이 '-' 로 시작) pid 목록
login_pids=" $(ps -t "$TTY" -o pid=,comm= 2>/dev/null | awk '$2 ~ /^-/ {print $1}' | tr '\n' ' ') "

# 3) 그 login shell 을 부모로 갖는 top-level claude 프로세스 찾기
#    (서브에이전트/MCP node 프로세스는 claude 의 자식이라 제외됨)
CLAUDE_PID="$(ps -t "$TTY" -o pid=,ppid=,args= 2>/dev/null | awk -v L="$login_pids" '
  /\.local\/bin\/claude/ { if (index(L, " " $2 " ")) { print $1; exit } }')"

log "TTY=$TTY login_pids=[$login_pids] CLAUDE_PID=$CLAUDE_PID"
if [ -z "$CLAUDE_PID" ]; then
  echo "활성 pane(surface=$SURFACE tty=$TTY)에 Claude 세션이 없습니다. (dev 서버 등)" >&2
  exit 2
fi

# dry-run: 탐지 결과만 확인하고 종료 (kill/send 안 함)
if [ -n "${CLAUDE_TIER_DRY_RUN:-}" ]; then
  echo "[DRY_RUN] tier=$TIER model=$MODEL effort=$EFFORT surface=$SURFACE tty=$TTY claude_pid=$CLAUDE_PID"
  log "DRY_RUN end"
  exit 0
fi

# 4) claude 종료 (SIGTERM → 필요 시 SIGKILL)
kill "$CLAUDE_PID" 2>/dev/null
for _ in $(seq 1 60); do
  kill -0 "$CLAUDE_PID" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$CLAUDE_PID" 2>/dev/null; then
  kill -9 "$CLAUDE_PID" 2>/dev/null
  sleep 0.3
fi

# 5) shell 프롬프트 렌더 대기 후, 같은 pane 에 재실행 명령 주입
#    cwd 는 그 zsh 에 그대로 유지됨. cmux claude() 래퍼가 hooks 주입.
sleep 0.4
"$CMUX" send --surface "$SURFACE" \
  "claude --dangerously-skip-permissions --continue --model $MODEL --effort $EFFORT\n"

log "SENT restart: model=$MODEL effort=$EFFORT surface=$SURFACE"
echo "Tier $TIER → model=$MODEL effort=$EFFORT (surface=$SURFACE tty=$TTY)"
