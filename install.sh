#!/usr/bin/env bash
# 새 macOS 머신 부트스트랩: git clone <repo> ~/dotfiles && cd ~/dotfiles && ./install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# 기존 파일이 있으면 백업 후 symlink 생성
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.backup.$(date +%Y%m%d%H%M%S)"
    echo "backup: $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "link:   $dst -> $src"
}

echo "==> 1/5 Xcode Command Line Tools"
xcode-select -p >/dev/null 2>&1 || xcode-select --install

echo "==> 2/5 Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon / Intel 경로 분기
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
fi

echo "==> 3/5 brew bundle (패키지 + 앱 설치)"
brew bundle install --file "$DOTFILES/Brewfile"

echo "==> 4/5 config symlink"
# zsh
link "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
link "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"
# git
link "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"
link "$DOTFILES/git/.gitconfig-work" "$HOME/.gitconfig-work"
link "$DOTFILES/git/githooks" "$HOME/.githooks"
# 앱별 config
link "$DOTFILES/hammerspoon" "$HOME/.hammerspoon"
link "$DOTFILES/ghostty" "$HOME/.config/ghostty"
link "$DOTFILES/nvim" "$HOME/.config/nvim"
# 공유 에이전트 하네스
link "$DOTFILES/agents" "$HOME/.agents"
# Claude Code (디렉토리 전체가 아닌 선별 링크 — 세션/캐시는 로컬 유지)
mkdir -p "$HOME/.claude"
for f in CLAUDE.md settings.json keybindings.json hooks output-styles scripts; do
  link "$DOTFILES/claude/$f" "$HOME/.claude/$f"
done
# Codex
mkdir -p "$HOME/.codex"
link "$DOTFILES/codex/config.toml" "$HOME/.codex/config.toml"
link "$DOTFILES/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link "$HOME/.agents/agents" "$HOME/.codex/agents"

echo "==> 5/5 Node + 글로벌 npm 패키지"
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
source "$(brew --prefix nvm)/nvm.sh"
nvm install 24
nvm alias default 24
npm install -g @openai/codex

cat <<'EOF'

완료. 남은 수동 단계:
  1. ~/.zshrc.local 생성 — 머신별 secret 환경변수 (예: export NOTION_TOKEN=...)
  2. 로그인: gh auth login / claude / codex / gcloud auth login
  3. Alfred 라이선스, 은행/보안 앱은 필요 시 수동 설치
EOF
