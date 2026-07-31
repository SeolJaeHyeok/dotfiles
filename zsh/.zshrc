export PATH="$PATH:/Users/seoljaehyeok/flutter_dev/flutter/bin"
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
_conda_setup="$('/Users/seoljaehyeok/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/seoljaehyeok/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/seoljaehyeok/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/seoljaehyeok/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
export PATH="$PATH:/Users/seoljaehyeok/Developer/flutter/bin"
export PATH="$PATH:/usr/local/Cellar/mongodb-community@4.2/4.2.12/bin"

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

# export NVM_DIR="$PATH:/Users/seoljaehyeok/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm


# pnpm
export PNPM_HOME="/Users/seoljaehyeok/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# nvm auto use
autoload -U add-zsh-hook
load-nvmrc() {
  [[ -a .nvmrc ]] || return
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

PATH=~/.console-ninja/.bin:$PATH
# Task Master aliases added on 2025. 7. 13.
alias tm='task-master'
alias taskmaster='task-master'
alias t='tmux'
alias y='yazi'
alias codex="$HOME/.nvm/versions/node/v22.12.0/bin/codex"

. "$HOME/.local/bin/env"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Added by Antigravity
export PATH="/Users/seoljaehyeok/.antigravity/antigravity/bin:$PATH"

# Added by Antigravity
export PATH="/Users/seoljaehyeok/.antigravity/antigravity/bin:$PATH"

# bun completions
[ -s "/Users/seoljaehyeok/.bun/_bun" ] && source "/Users/seoljaehyeok/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='/Users/seoljaehyeok/.bun/bin/bun "/Users/seoljaehyeok/.claude/plugins/cache/thedotmack/claude-mem/10.4.0/scripts/worker-service.cjs"'

# claude 단축키
# cc           → claude
# cc -dsp ...  → claude --dangerously-skip-permissions ...
# cc -c ...    → claude --continue ...
# cc -dsp -c ... -> claude -dangerously-skip-permissions --continue ...
function cc() {
  if [[ "$1" == "-dsp" && "$2" == "-c" ]]; then
    shift 2
    claude --dangerously-skip-permissions --continue "$@"
  elif [[ "$1" == "-dsp" ]]; then
    shift
    claude --dangerously-skip-permissions "$@"
  elif [[ "$1" == "-c" ]]; then
    shift
    claude --continue "$@"
  else
    claude "$@"
  fi
}

# codex 단축키
# cx           -> codex
# cx -dsp ...  -> codex --dangerously-bypass-approvals-and-sandbox ...
# cx -c ...    -> codex resume --last ...
# cx -dsp -c ... -> codex --dangerously-bypass-approvals-and-sandbox resume --last ...
function cx() {
  if [[ "$1" == "-dsp" && "$2" == "-c" ]]; then
    shift 2
    codex --dangerously-bypass-approvals-and-sandbox resume --last "$@"
  elif [[ "$1" == "-dsp" ]]; then
    shift
    codex --dangerously-bypass-approvals-and-sandbox "$@"
  elif [[ "$1" == "-c" ]]; then
    shift
    codex resume --last "$@"
  else
    codex "$@"
  fi
}

# zoxide
# eval "$(zoxide init zsh)"
eval "$(zoxide init zsh --hook pwd)"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


# Notion MCP

# corepack auto pin
export COREPACK_ENABLE_AUTO_PIN=0

# gh CLI account auto-switch by directory
# - ~/projects/mcircle/*  → milkboy2564 (work, mcircle.biz)
# - else                   → SeolJaeHyeok (personal)
autoload -Uz add-zsh-hook

_gh_account_for_pwd() {
  case "$PWD/" in
    "$HOME"/projects/mcircle/*) echo "milkboy2564" ;;
    *)                          echo "SeolJaeHyeok" ;;
  esac
}

_gh_auto_switch() {
  command -v gh >/dev/null 2>&1 || return
  local want current
  want=$(_gh_account_for_pwd)
  current=$(gh api user -q .login 2>/dev/null)
  [[ "$current" == "$want" ]] && return
  gh auth switch -h github.com -u "$want" >/dev/null 2>&1
}

add-zsh-hook chpwd _gh_auto_switch
_gh_auto_switch

# Claude tier settings (cmd+fn+1 to cmd+fn+5)
tier1() { ~/.config/ghostty/set-claude-tier.sh 1; }
tier2() { ~/.config/ghostty/set-claude-tier.sh 2; }
tier3() { ~/.config/ghostty/set-claude-tier.sh 3; }
tier4() { ~/.config/ghostty/set-claude-tier.sh 4; }
tier5() { ~/.config/ghostty/set-claude-tier.sh 5; }

# 머신별/비밀 설정 (git 미추적)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
