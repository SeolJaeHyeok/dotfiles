#!/usr/bin/env bash
# Claude Code statusLine script
# Receives JSON on stdin with session context

input=$(cat)

# ── 1. Current directory (shortened) ─────────────────────────────────────────
raw_cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
# Replace $HOME with ~
home_re=$(printf '%s' "$HOME" | sed 's/[.[\*^$]/\\&/g')
short_cwd=$(echo "$raw_cwd" | sed "s|^$HOME|~|")
# If more than 3 path segments after ~/ (or /), shorten middle sections
shorten_path() {
  local p="$1"
  # Split on /
  local prefix=""
  local rest=""
  if [[ "$p" == ~* ]]; then
    prefix="~"
    rest="${p:1}"  # strip leading ~
  else
    prefix=""
    rest="$p"
  fi
  IFS='/' read -ra parts <<< "${rest#/}"
  local n=${#parts[@]}
  if [ "$n" -le 3 ]; then
    echo "$p"
  else
    # Keep first 1 + last 1, collapse middle with ...
    local first="${parts[0]}"
    local last="${parts[$((n-1))]}"
    echo "${prefix}/${first}/.../${last}"
  fi
}
dir_display=$(shorten_path "$short_cwd")

# ── 2. Git branch ─────────────────────────────────────────────────────────────
git_branch=""
if git_ref=$(git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch="$git_ref"
elif git_sha=$(git -C "$raw_cwd" rev-parse --short HEAD 2>/dev/null); then
  git_branch="(${git_sha})"
fi

# ── 3. Git status (modified count + staged indicator) ────────────────────────
git_status_display=""
if [ -n "$git_branch" ]; then
  # Count unstaged modified/deleted/untracked files
  modified=$(git -C "$raw_cwd" status --porcelain 2>/dev/null | grep -c '^.[MD?]' || echo 0)
  # Count staged files
  staged=$(git -C "$raw_cwd" status --porcelain 2>/dev/null | grep -c '^[MADRC]' || echo 0)

  parts_git=""
  if [ "$staged" -gt 0 ] && [ "$modified" -gt 0 ]; then
    parts_git="+${staged} ~${modified}"
  elif [ "$staged" -gt 0 ]; then
    parts_git="+${staged}"
  elif [ "$modified" -gt 0 ]; then
    parts_git="~${modified}"
  else
    parts_git="clean"
  fi
  git_status_display="$parts_git"
fi

# ── 4. Model name ─────────────────────────────────────────────────────────────
model_display=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')

# ── 5. Context usage ──────────────────────────────────────────────────────────
ctx_display=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  ctx_display=$(printf "ctx %.0f%%" "$used_pct")
fi

# ── 6. Reset countdowns (5-hour and 7-day) ───────────────────────────────────
format_countdown() {
  local resets_at="$1"
  local now
  now=$(date +%s)
  local diff=$(( resets_at - now ))
  if [ "$diff" -le 0 ]; then
    echo "now"
    return
  fi
  local h=$(( diff / 3600 ))
  local m=$(( (diff % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then
    printf "%dh%02dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

reset_display=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

five_part=""
week_part=""

if [ -n "$five_pct" ] && [ -n "$five_resets" ]; then
  five_countdown=$(format_countdown "$five_resets")
  five_part=$(printf "5h:%.0f%%(%s)" "$five_pct" "$five_countdown")
fi

if [ -n "$week_pct" ] && [ -n "$week_resets" ]; then
  week_countdown=$(format_countdown "$week_resets")
  week_part=$(printf "7d:%.0f%%(%s)" "$week_pct" "$week_countdown")
fi

if [ -n "$five_part" ] && [ -n "$week_part" ]; then
  reset_display="${five_part} ${week_part}"
elif [ -n "$five_part" ]; then
  reset_display="$five_part"
elif [ -n "$week_part" ]; then
  reset_display="$week_part"
fi

# ── Assemble status line ──────────────────────────────────────────────────────
SEP=" · "
line=""

append() {
  local val="$1"
  [ -z "$val" ] && return
  if [ -z "$line" ]; then
    line="$val"
  else
    line="${line}${SEP}${val}"
  fi
}

append "$dir_display"

if [ -n "$git_branch" ]; then
  git_segment=" ${git_branch}"
  if [ -n "$git_status_display" ]; then
    git_segment="${git_segment} [${git_status_display}]"
  fi
  append "$git_segment"
fi

append "$model_display"
append "$ctx_display"
append "$reset_display"

printf '%s\n' "$line"
