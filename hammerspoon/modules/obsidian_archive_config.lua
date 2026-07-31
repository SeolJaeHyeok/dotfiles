-- Obsidian 링크 아카이브 설정
-- 모든 아카이브는 Vault 의 Inbox 폴더에 저장되며, 이후 사용자가 직접 분류한다.

local M = {}

M.vault_path = os.getenv("HOME") .. "/Documents/Obsidian Vault"
M.inbox_folder = "Inbox"

M.hotkey_mods = { "cmd", "alt", "shift" }
M.hotkey_key = "a"

-- Claude CLI 를 먼저 사용하고, Claude 가 실패하거나 빈 응답이면 Codex CLI 로 fallback 한다.
M.claude_shell = "/bin/bash"
M.claude_bin = "/Users/seoljaehyeok/.local/bin/claude"
M.codex_shell = "/bin/bash"
M.codex_bin = "/Users/seoljaehyeok/.nvm/versions/node/v22.12.0/bin/codex"
M.ai_timeout_seconds = 300

-- 저장된 Inbox 노트를 Vault 루트에서 LLM Wiki 방식으로 자동 ingest 한다.
-- Claude/CLAUDE.md 기준으로 ingest 와 canonical pass 를 모두 수행한다.
M.auto_ingest = true
M.ingest_engine = "claude"
M.ingest_timeout_seconds = 600
M.auto_canonical = true
M.canonical_timeout_seconds = 1800

-- 요약 지시문 (제목·URL 줄은 buildPrompt 에서 붙음). ## 원문 은 출력하지 말 것 — 파일 저장 시 자동 추가.
M.summarize_instruction = [[
다음 웹 페이지를 Obsidian 노트용으로 한국어로 정리해 줘.

반드시 아래 네 개의 섹션 헤더만 사용하고, 순서와 헤더 표기를 정확히 지킬 것.
(## 원문 섹션은 쓰지 말 것. 나중에 시스템이 링크를 붙인다.)

## TL;DR
한두 문단으로 핵심만 (3~6문장 수준도 가능). 독자가 글을 안 읽어도 주제·가치를 알 수 있게.

## 요약
본문을 단락으로 나누어 상세히 요약. 인용·명령어·숫자는 원문에 가깝게 유지.

## 핵심 인사이트
- 불릿으로 3~7개. 행동·결론·기억에 남을 포인트 위주.

규칙: 위 세 섹션의 마크다운만 출력할 것. 코드 블록이 필요하면 마크다운 코드 펜스 사용. URL/제목만으로 알 수 있는 범위에서 쓰고 과장된 추측은 넣지 말 것.

만약 WebFetch 또는 WebSearch 등 어떤 방법으로도 페이지 본문에 접근할 수 없다면(403, 권한 거부, 네트워크 실패 등), 다른 설명·사과·안내 없이 첫 줄에 정확히 다음 한 줄만 출력하고 즉시 종료할 것:
FETCH_FAILED
]]

-- Fallback 에서 curl 로 HTML 을 받을 때 사용할 브라우저 User-Agent (봇 차단 우회)
M.fallback_user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

-- Fallback 에서 HTML 파일을 받아 요약할 때 쓰는 지시문
M.fallback_instruction = [[
아래 파일은 웹페이지의 전체 HTML 을 그대로 저장한 것이다. Read 도구로 파일을 읽고, 광고·네비게이션·스크립트·스타일 태그는 무시하고 핵심 본문만 추려서 Obsidian 노트용으로 한국어로 정리해 줘.

반드시 아래 세 개의 섹션 헤더만 사용하고, 순서와 헤더 표기를 정확히 지킬 것.
(## 원문 섹션은 쓰지 말 것. 나중에 시스템이 링크를 붙인다.)

## TL;DR
한두 문단으로 핵심만. 독자가 글을 안 읽어도 주제·가치를 알 수 있게.

## 요약
본문을 단락으로 나누어 상세히 요약. 인용·명령어·숫자는 원문에 가깝게 유지.

## 핵심 인사이트
- 불릿으로 3~7개. 행동·결론·기억에 남을 포인트 위주.

규칙: 위 세 섹션의 마크다운만 출력할 것. 코드 블록이 필요하면 마크다운 코드 펜스 사용.
]]

return M
