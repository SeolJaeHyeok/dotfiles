# dotfiles

macOS 개발 환경 이식용 dotfiles. 새 머신에서 아래 두 줄로 복원한다.

```sh
git clone https://github.com/SeolJaeHyeok/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh`가 하는 일: Xcode CLT → Homebrew → `brew bundle`(CLI + GUI 앱 일괄 설치) → config symlink → Node(nvm) + 글로벌 npm 패키지.

## 구조

| 디렉토리 | 링크 대상 | 내용 |
|---|---|---|
| `zsh/` | `~/.zshrc`, `~/.zprofile` | 셸 설정 (secret은 `~/.zshrc.local`로 분리) |
| `git/` | `~/.gitconfig`, `~/.gitconfig-work`, `~/.githooks` | git 설정 |
| `hammerspoon/` | `~/.hammerspoon` | 자동화 (state/ 제외) |
| `ghostty/` | `~/.config/ghostty` | 터미널 설정 |
| `nvim/` | `~/.config/nvim` | Neovim 설정 |
| `claude/` | `~/.claude/*` 선별 링크 | CLAUDE.md, settings, hooks, output-styles, scripts |
| `codex/` | `~/.codex/config.toml`, `AGENTS.md` | Codex 설정 (`agents`는 `~/.agents/agents` symlink) |
| `agents/` | `~/.agents` | 공유 에이전트 하네스 (rules, skills, knowledge…) |
| `Brewfile` | — | brew 패키지·cask 선언 |

## Secret 정책

**이 repo에는 토큰/자격증명을 넣지 않는다.** 머신별 secret은 `~/.zshrc.local`(git 미추적)에 두고, 각 CLI는 새 머신에서 직접 로그인한다: `gh auth login`, `claude`, `codex`, `gcloud auth login`.

## 이 머신(원본)에서 config를 수정할 때

현재 원본 머신은 아직 symlink 전환 전 상태다. 전환하려면 원본 머신에서도 `./install.sh`를 실행하면 된다(기존 파일은 `.backup.*`으로 보존). 전환 전에 `~/.zshrc`의 `NOTION_TOKEN` 줄을 `~/.zshrc.local`로 옮겨둘 것.
