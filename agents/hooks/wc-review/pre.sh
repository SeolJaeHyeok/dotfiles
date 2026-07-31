#!/usr/bin/env bash
# wc:review pre-hook — Hunk 라이브 세션 감지 및 안내.
#
# 계약 (wellcheck-plugins wc:review SKILL.md "Pre-hook (사용자 확장 슬롯)" 절):
#   - exit 0   : 정상 — dispatcher 가 Phase 0 진입
#   - exit 2   : 사용자 중단 요청 (TTY 모드에서 hook 이 직접 받음) — dispatcher 즉시 종료
#   - exit 10  : dispatcher 가 host 블로킹 질문 도구로 사용자에게 물어야 함
#                stdout = JSON payload (question / header / options / on_abort_label)
#   - 그 외    : graceful fallback (한 줄 경고 후 Phase 0 진입)
#
# 두 모드:
#   TTY     : 사람이 standalone shell 에서 실행 — hook 이 직접 prompt → exit 0/2
#   Non-TTY : Claude Code / Cursor / Codex 의 bash — exit 10 + JSON 으로 dispatcher 위임
#
# 전달받는 환경변수:
#   WC_REVIEW_ARGS / WC_REVIEW_REPO_ROOT / WC_REVIEW_BRANCH / WC_REVIEW_DEFAULT_BRANCH

set -u

DEFAULT_BRANCH="${WC_REVIEW_DEFAULT_BRANCH:-main}"

if ! command -v hunk >/dev/null 2>&1; then
  exit 0
fi

session_count() {
  hunk session list --json 2>/dev/null \
    | grep -v '^warn:' \
    | grep -v 'Reinstall\|baseline' \
    | python3 -c 'import json,sys
try:
  data=json.load(sys.stdin)
  print(len(data.get("sessions",[])))
except Exception:
  print(0)' 2>/dev/null
}

count=$(session_count)
count=${count:-0}

if [ "$count" -gt 0 ]; then
  printf '✅ Hunk 라이브 세션 %s개 감지 — hunk session 명령으로 narrate 가능.\n' "$count"
  exit 0
fi

# 세션 0 — 모드별 분기
if [ -t 0 ]; then
  # TTY 모드: hook 이 직접 prompt
  printf '\n'
  printf '⚠️  Hunk 라이브 세션이 없습니다.\n'
  printf '   별도 터미널에서 아래 중 하나를 띄우면 narrate 모드로 리뷰 가능:\n'
  printf '     hunk diff                   # 워킹 트리\n'
  printf '     hunk diff --staged          # staged 변경\n'
  printf '     hunk diff %s...HEAD     # 브랜치 vs default\n' "$DEFAULT_BRANCH"
  printf '\n'
  printf '   Hunk 없이 wc:review 를 계속할까요? [Y/n]: '

  if ! read -r ans </dev/tty 2>/dev/null; then
    printf '\n(stdin 미접근 — 기본값 Y 로 진행)\n'
    exit 0
  fi

  case "${ans:-y}" in
    [nN]*)
      printf '중단 — Hunk 세션을 띄운 뒤 wc:review 를 다시 호출해주세요.\n'
      exit 2
      ;;
    *)
      printf 'Hunk 없이 진행합니다.\n'
      exit 0
      ;;
  esac
fi

# Non-TTY 모드: dispatcher 가 host 블로킹 질문 도구로 물어야 함 — JSON payload 로 위임
cat <<JSON
{
  "question": "Hunk 라이브 세션이 없습니다. wc:review 를 어떻게 진행할까요?",
  "header": "Hunk 세션",
  "options": [
    {
      "label": "Hunk 없이 진행",
      "description": "TUI narrate 없이 일반 wc:review 만 수행"
    },
    {
      "label": "중단",
      "description": "Hunk 세션을 직접 띄운 뒤 wc:review 를 다시 호출 (예: hunk diff ${DEFAULT_BRANCH}...HEAD)"
    }
  ],
  "on_abort_label": "중단"
}
JSON
exit 10
