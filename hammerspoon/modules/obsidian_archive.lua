-- Obsidian Vault: 브라우저 탭 URL 을 Claude CLI 로 요약해 주제별 폴더에 저장
-- Claude CLI 가 실패하거나 빈 응답이면 Codex CLI 로 fallback 한다.
-- Documents 쓰기: 시스템 설정 > 개인정보 보호에서 Hammerspoon 에 Vault 경로 허용

local M = {}

local config = require("modules.obsidian_archive_config")
local queue = require("modules.obsidian_ingest_queue")

local function expandPath(p)
    if p:sub(1, 2) == "~/" then
        return os.getenv("HOME") .. p:sub(2)
    end
    if p:sub(1, 1) == "~" then
        return os.getenv("HOME") .. p:sub(2)
    end
    return p
end

local function shellSingleQuote(s)
    return "'".. s:gsub("'", "'\\''") .. "'"
end

-- translator.lua 의 shellQuote 와 동일 (claude -p 인자용)
local function shellQuote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function tmpPath(prefix, ext)
    return string.format("/tmp/%s_%d_%d%s", prefix, os.time(), math.random(1000, 9999), ext or "")
end

local function dirname(path)
    local dir = path:match("^(.*)/[^/]+$")
    if not dir or dir == "" then
        return "."
    end
    return dir
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local body = f:read("*a")
    f:close()
    return body
end

local function relativePath(basePath, fullPath)
    if fullPath:sub(1, #basePath + 1) == basePath .. "/" then
        return fullPath:sub(#basePath + 2)
    end
    return fullPath
end

local function removeFile(path)
    hs.execute("/bin/rm -f " .. shellQuote(path))
end

local function runShellTask(shellPath, args, timeoutSeconds, callback)
    local completed = false
    local task
    local timer = hs.timer.doAfter(timeoutSeconds or 180, function()
        if completed then
            return
        end
        completed = true
        if task then
            task:terminate()
        end
        callback(-1, "", "timeout after " .. tostring(timeoutSeconds or 180) .. "s")
    end)

    task = hs.task.new(shellPath, function(exitCode, stdOut, stdErr)
        if completed then
            return
        end
        completed = true
        if timer then
            timer:stop()
        end
        callback(exitCode, stdOut, stdErr)
    end, args)

    if not task or not task:start() then
        if timer then
            timer:stop()
        end
        if not completed then
            completed = true
            callback(-1, "", "failed to start task")
        end
    end
end

-- hs.osascript.applescript 실패 시 err/out 이 NSError 딕셔너리(테이블)로 올 수 있음.
-- tostring(테이블) 은 "table: 0x..." 만 나와 원인 파악이 불가능하므로 메시지를 꺼냄.
local function describeOsaValue(v)
    if v == nil then
        return ""
    end
    local tv = type(v)
    if tv == "string" then
        return v
    end
    if tv == "number" then
        return tostring(v)
    end
    if tv == "table" then
        local msg = v.NSAppleScriptErrorMessage
        if type(msg) == "string" and msg ~= "" then
            return msg
        end
        local num = v.NSAppleScriptErrorNumber
        if num ~= nil then
            local m2 = v.NSAppleScriptErrorMessage
            local suffix = (type(m2) == "string" and m2 ~= "") and (": " .. m2) or ""
            return "AppleScript 오류 " .. tostring(num) .. suffix
        end
        return hs.inspect(v, { depth = 4 })
    end
    return tostring(v)
end

--- @return string|nil url, string|nil title, string|nil err
local function getFrontBrowserUrlAndTitle()
    local app = hs.application.frontmostApplication()
    if not app then
        return nil, nil, "앱을 찾을 수 없습니다."
    end
    local name = app:name()
    if not name then
        return nil, nil, "앱 이름을 알 수 없습니다."
    end

    -- 한 줄 `if ... then return "" end if` 는 OSAScript 에서 "Expected 'with' but found 'if'" (-2741) 로 깨질 수 있음 → 여러 줄로 분리
    local scripts = {
        Safari = [[
tell application "Safari"
  if (count of windows) is 0 then
    return ""
  end if
  set u to URL of current tab of front window
  set t to name of current tab of front window
  return u & "|||" & t
end tell
]],
        ["Google Chrome"] = [[
tell application "Google Chrome"
  if (count of windows) is 0 then
    return ""
  end if
  set u to URL of active tab of front window
  set t to title of active tab of front window
  return u & "|||" & t
end tell
]],
        Arc = [[
tell application "Arc"
  if (count of windows) is 0 then
    return ""
  end if
  set u to URL of active tab of front window
  set t to title of active tab of front window
  return u & "|||" & t
end tell
]],
        ["Brave Browser"] = [[
tell application "Brave Browser"
  if (count of windows) is 0 then
    return ""
  end if
  set u to URL of active tab of front window
  set t to title of active tab of front window
  return u & "|||" & t
end tell
]],
        ["Microsoft Edge"] = [[
tell application "Microsoft Edge"
  if (count of windows) is 0 then
    return ""
  end if
  set u to URL of active tab of front window
  set t to title of active tab of front window
  return u & "|||" & t
end tell
]],
    }

    local sc = scripts[name]
    if not sc then
        return nil, nil, "지원 브라우저가 아닙니다: " .. name .. " (Safari, Chrome, Arc, Brave, Edge)"
    end

    local ok, out, err = hs.osascript.applescript(sc)
    if not ok then
        local detail = describeOsaValue(err)
        if detail == "" then
            detail = describeOsaValue(out)
        end
        if detail == "" then
            detail = "osascript 실패 (상세 없음)"
        end
        return nil, nil, "URL 을 가져오지 못했습니다: " .. detail
    end
    if type(out) ~= "string" or out == "" then
        -- 빈 응답 = AppleScript 가 `count of windows is 0` 으로 반환한 경우.
        -- 같은 번들 ID 의 인스턴스가 여러 개면 (예: Playwright/MCP 자동화 Chrome),
        -- Apple Event 가 창 없는 인스턴스로 전달됐을 수 있다.
        local bundleID = app:bundleID()
        local instances = bundleID and hs.application.applicationsForBundleID(bundleID) or {}
        if #instances > 1 then
            return nil, nil, name .. " 인스턴스가 " .. #instances ..
                "개 감지됨 — 자동화/MCP 브라우저로 명령이 전달됐을 수 있습니다. 자동화 브라우저를 종료한 뒤 다시 시도하세요."
        end
        return nil, nil, "URL 을 가져오지 못했습니다: 활성 창을 찾을 수 없습니다 (" .. name .. " 창이 열려 있는지 확인하세요)"
    end

    local sep = out:find("|||", 1, true)
    if not sep then
        return nil, nil, "URL 파싱 실패"
    end
    local url = out:sub(1, sep - 1)
    local title = out:sub(sep + 3)
    if url == "" then
        return nil, nil, "빈 URL"
    end
    return url, title, nil
end

local function slugify(s)
    local x = s:gsub("^%s+", ""):gsub("%s+$", "")
    x = x:gsub("[/\\%:%*%?\"<>|]", "-")
    x = x:gsub("%s+", "-")
    if #x > 80 then
        x = x:sub(1, 80)
    end
    if x == "" then
        x = "untitled"
    end
    return x
end

local function yamlEscape(s)
    s = s:gsub("\r?\n", " "):gsub('"', '\\"')
    return '"' .. s .. '"'
end

-- 마크다운 링크 라벨용: ] 는 이스케이프
local function markdownLinkLabelEscape(s)
    return (s or ""):gsub("%]", "\\]")
end

local function writeNote(vaultPath, relFolder, url, title, summaryMd)
    local dateStr = os.date("%Y-%m-%d")
    local folderPath = vaultPath .. "/" .. relFolder
    hs.execute("/bin/mkdir -p " .. shellSingleQuote(folderPath))

    local base = dateStr .. "-" .. slugify(title)
    local path = folderPath .. "/" .. base .. ".md"

    local linkLabel = markdownLinkLabelEscape(title)
    local originLink = "[" .. linkLabel .. "](" .. url .. ")"
    local body = table.concat({
        "---",
        "created: " .. dateStr,
        "source: 외부 링크",
        "topic: 기타",
        "type: raw",
        "status: draft",
        "title: " .. yamlEscape(title),
        "url: " .. yamlEscape(url),
        "archived: " .. dateStr,
        "---",
        "",
        summaryMd,
        "",
        "## 원문",
        "",
        originLink,
        "",
    }, "\n")

    local f, ferr = io.open(path, "w")
    if not f then
        hs.alert.show("파일 저장에 실패했습니다: " .. tostring(ferr), 3)
        return
    end
    f:write(body)
    f:close()
    hs.alert.show("저장되었습니다: " .. relFolder .. "/" .. base .. ".md", 2)
    print("[obsidian_archive] wrote " .. path)
    return path
end

local function buildPrompt(url, title)
    return table.concat({
        config.summarize_instruction,
        "",
        "제목: " .. title,
        "URL: " .. url,
    }, "\n")
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function truncate(s, maxLen)
    if not s then
        return ""
    end
    if #s <= maxLen then
        return s
    end
    return s:sub(1, maxLen) .. "\n..."
end

local function formatDuration(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    if seconds < 60 then
        return string.format("%.1f초", seconds)
    end
    local minutes = math.floor(seconds / 60)
    local rest = seconds - (minutes * 60)
    return string.format("%d분 %.1f초", minutes, rest)
end

local function showCompletionPopup(title, message)
    local shortMessage = truncate(message, 900)
    hs.alert.show(title .. "\n\n" .. shortMessage, 10)

    if hs.notify and hs.notify.new then
        pcall(function()
            hs.notify.new({
                title = title,
                informativeText = truncate(message:gsub("\n", " "), 450),
            }):send()
        end)
    end

    if hs.dialog and hs.dialog.blockAlert then
        hs.timer.doAfter(0.2, function()
            pcall(hs.dialog.blockAlert, title, message, "확인", "", "informational")
        end)
    end

    if hs.execute then
        pcall(function()
            hs.execute("/usr/bin/osascript -e " .. shellQuote("display notification " .. string.format("%q", "LLM Wiki ingest가 완료되었습니다.") .. " with title " .. string.format("%q", title)))
        end)
    end
end

local function showFailurePopup(title, message)
    hs.alert.show(title .. "\n\n" .. truncate(message, 900), 10)
    if hs.notify and hs.notify.new then
        pcall(function()
            hs.notify.new({
                title = title,
                informativeText = truncate(message:gsub("\n", " "), 450),
            }):send()
        end)
    end
    if hs.dialog and hs.dialog.blockAlert then
        hs.timer.doAfter(0.2, function()
            pcall(hs.dialog.blockAlert, title, message, "확인", "", "critical")
        end)
    end
end

local function isFetchFailed(stdOut)
    if not stdOut then return false end
    local first = stdOut:match("([^\n]*)") or ""
    return trim(first) == "FETCH_FAILED"
end

local function hasOutput(stdOut)
    return stdOut and stdOut:match("%S") ~= nil
end

local function isLikelyCliUnavailable(stdOut, stdErr)
    local text = trim((stdOut or "") .. "\n" .. (stdErr or "")):lower()
    if text == "" or #text > 800 then
        return false
    end
    return text:find("usage limit", 1, true)
        or text:find("rate limit", 1, true)
        or text:find("quota", 1, true)
        or text:find("subscription", 1, true)
        or text:find("billing", 1, true)
        or text:find("credit balance", 1, true)
        or text:find("not logged in", 1, true)
        or text:find("authentication", 1, true)
end

local function runClaude(promptText, allowedTools, callback)
    local cmd = shellQuote(config.claude_bin) .. " -p " .. shellQuote(promptText)
    if allowedTools and allowedTools ~= "" then
        cmd = cmd .. " --allowedTools " .. shellQuote(allowedTools)
    end

    runShellTask(config.claude_shell, { "-l", "-c", cmd }, config.ai_timeout_seconds, callback)
end

local function buildCodexPrompt(promptText)
    return table.concat({
        "다음 지시를 수행해. 최종 답변에는 생성된 Obsidian용 마크다운 본문만 출력해.",
        "진행 설명, 사과문, 코드블록 래핑, 추가 안내는 쓰지 마.",
        "필요하면 읽기 전용 shell 명령으로 URL 또는 파일 경로의 내용을 확인해도 된다.",
        "",
        promptText,
    }, "\n")
end

local function runCodex(promptText, callback)
    local outputPath = tmpPath("obsidian_archive_codex", ".md")
    local codexDir = dirname(config.codex_bin)
    local cmd = "PATH=" .. shellQuote(codexDir) .. ":${PATH:-/usr/bin:/bin:/usr/sbin:/sbin} " .. table.concat({
        shellQuote(config.codex_bin),
        "exec",
        "--skip-git-repo-check",
        "--ephemeral",
        "--color never",
        "-c " .. shellQuote("approval_policy=\"never\""),
        "-C " .. shellQuote("/tmp"),
        "--sandbox read-only",
        "--output-last-message " .. shellQuote(outputPath),
        shellQuote(buildCodexPrompt(promptText)),
    }, " ")

    runShellTask(config.codex_shell or config.claude_shell, { "-l", "-c", cmd }, config.ai_timeout_seconds, function(exitCode, stdOut, stdErr)
        local finalMessage = readFile(outputPath)
        removeFile(outputPath)
        if hasOutput(finalMessage) then
            stdOut = finalMessage
        end
        callback(exitCode, stdOut, stdErr)
    end)
end

local function buildIngestPrompt(vaultPath, notePath)
    local relPath = relativePath(vaultPath, notePath)
    return table.concat({
        "다음 파일을 LLM Wiki 방식으로 자동 ingest해.",
        "",
        "대상 파일: " .. relPath,
        "",
        "규칙:",
        "- AGENTS.md를 반드시 따른다.",
        "- 이 요청은 AGENTS.md의 Hammerspoon 자동 Ingest 예외에 해당한다.",
        "- `.obsidian/`, `회사/`, `업무/configuration/`은 읽거나 쓰지 않는다.",
        "- `업무/개발/AI Prompts/`는 수정하지 않는다.",
        "- 대상 파일은 raw source로 보존하되, ingest가 끝나면 `Inbox/`에 남기지 않는다.",
        "- 유사 노트를 먼저 검색한다.",
        "- 적절한 topic을 판단한다.",
        "- 대상 파일을 적절한 `Reference/` 하위 폴더로 승격 이동한다. 예: AI, Claude와 Codex, FE, 생산성 도구, 기타.",
        "- 이동한 대상 파일의 frontmatter를 Phase 2 표준에 맞게 보정한다.",
        "- 이동한 대상 파일은 `type: reference`, `status: active`로 둔다.",
        "- 자동 ingest 중에는 별도 canonical wiki 노트를 생성하지 않는다.",
        "- 관련 `MOC - *.md`가 이미 있으면 그 MOC 하나에만 `[[wikilink]] — 1줄 요약` 형식으로 추가한다.",
        "- 적절한 MOC가 없으면 MOC를 새로 만들지 말고 대상 파일 이동만 수행한다.",
        "- 기존 reference/wiki 노트는 명확한 보강만 append/update한다.",
        "- 대상 파일 외 파일 삭제, 파일 이동, 이름 변경, 대규모 재작성은 하지 않는다.",
        "- 새 노트는 Phase 2 표준 frontmatter를 사용한다.",
        "- 최종 상태에서 대상 파일이 `Inbox/`에 남아 있으면 ingest 실패로 간주한다.",
        "- 전체 작업은 3분 안에 끝내는 것을 우선한다.",
        "- 최종 답변에는 이동한 파일, 갱신한 MOC, 소요 작업 요약만 5줄 이내로 출력한다.",
    }, "\n")
end

local function buildCanonicalPrompt(vaultPath, notePath, url, title)
    local relPath = relativePath(vaultPath, notePath)
    return table.concat({
        "다음 웹 아카이브 노트를 기준으로 canonical wiki pass를 수행해.",
        "",
        "원래 대상 파일: " .. relPath,
        "제목: " .. title,
        "URL: " .. url,
        "",
        "규칙:",
        "- AGENTS.md를 반드시 따른다.",
        "- 이 요청은 AGENTS.md의 Hammerspoon 자동 Ingest 예외에 해당한다.",
        "- `.obsidian/`, `회사/`, `업무/configuration/`은 읽거나 쓰지 않는다.",
        "- `업무/개발/AI Prompts/`는 수정하지 않는다.",
        "- 먼저 URL 또는 title로 이미 `Reference/`로 승격된 대상 노트를 찾는다. 원래 대상 파일 경로가 없어도 실패로 보지 않는다.",
        "- 이 자료가 반복 참조될 개념이면 기존 canonical wiki 노트를 갱신하거나 새 canonical wiki 노트를 하나만 만든다.",
        "- 단일 아티클 요약으로 충분하면 canonical wiki를 만들지 말고, 그 판단을 최종 답변에 적는다.",
        "- canonical wiki를 만들거나 갱신할 때는 raw/reference 노트 링크를 반드시 남긴다.",
        "- 관련 `MOC - *.md`가 있으면 canonical wiki 링크를 추가하거나 기존 항목을 보강한다.",
        "- 파일 삭제와 대상 외 파일 이동은 하지 않는다.",
        "- 기존 노트 대규모 재작성은 하지 말고 명확한 보강만 append/update한다.",
        "- 새 노트는 Phase 2 표준 frontmatter를 사용한다.",
        "- 최종 답변에는 canonical 판단, 변경한 파일 목록, 요약만 8줄 이내로 출력한다.",
    }, "\n")
end

local function runCodexIngest(vaultPath, notePath, callback)
    local outputPath = tmpPath("obsidian_archive_ingest_codex", ".txt")
    local codexDir = dirname(config.codex_bin)
    local cmd = "PATH=" .. shellQuote(codexDir) .. ":${PATH:-/usr/bin:/bin:/usr/sbin:/sbin} " .. table.concat({
        shellQuote(config.codex_bin),
        "exec",
        "--skip-git-repo-check",
        "--ephemeral",
        "--color never",
        "-c " .. shellQuote("approval_policy=\"never\""),
        "-C " .. shellQuote(vaultPath),
        "--sandbox workspace-write",
        "--output-last-message " .. shellQuote(outputPath),
        shellQuote(buildIngestPrompt(vaultPath, notePath)),
    }, " ")

    runShellTask(config.codex_shell or config.claude_shell, { "-l", "-c", cmd }, config.ingest_timeout_seconds or config.ai_timeout_seconds, function(exitCode, stdOut, stdErr)
        local finalMessage = readFile(outputPath)
        removeFile(outputPath)
        if hasOutput(finalMessage) then
            stdOut = finalMessage
        end
        callback(exitCode, stdOut, stdErr)
    end)
end

local function runCodexCanonical(vaultPath, notePath, url, title, callback)
    local outputPath = tmpPath("obsidian_archive_canonical_codex", ".txt")
    local codexDir = dirname(config.codex_bin)
    local cmd = "PATH=" .. shellQuote(codexDir) .. ":${PATH:-/usr/bin:/bin:/usr/sbin:/sbin} " .. table.concat({
        shellQuote(config.codex_bin),
        "exec",
        "--skip-git-repo-check",
        "--ephemeral",
        "--color never",
        "-c " .. shellQuote("approval_policy=\"never\""),
        "-C " .. shellQuote(vaultPath),
        "--sandbox workspace-write",
        "--output-last-message " .. shellQuote(outputPath),
        shellQuote(buildCanonicalPrompt(vaultPath, notePath, url, title)),
    }, " ")

    runShellTask(config.codex_shell or config.claude_shell, { "-l", "-c", cmd }, config.canonical_timeout_seconds or config.ingest_timeout_seconds or config.ai_timeout_seconds, function(exitCode, stdOut, stdErr)
        local finalMessage = readFile(outputPath)
        removeFile(outputPath)
        if hasOutput(finalMessage) then
            stdOut = finalMessage
        end
        callback(exitCode, stdOut, stdErr)
    end)
end

local function runClaudeIngest(vaultPath, notePath, callback)
    local prompt = buildIngestPrompt(vaultPath, notePath):gsub("AGENTS.md", "CLAUDE.md")
    local cmd = "cd " .. shellQuote(vaultPath) .. " && " .. shellQuote(config.claude_bin) .. " -p " .. shellQuote(prompt)
        .. " --allowedTools " .. shellQuote("Read,Grep,Glob,Write,Edit,MultiEdit,Bash")
    runShellTask(config.claude_shell, { "-l", "-c", cmd }, config.ingest_timeout_seconds or config.ai_timeout_seconds, callback)
end

local function runClaudeCanonical(vaultPath, notePath, url, title, callback)
    local prompt = buildCanonicalPrompt(vaultPath, notePath, url, title):gsub("AGENTS.md", "CLAUDE.md")
    local cmd = "cd " .. shellQuote(vaultPath) .. " && " .. shellQuote(config.claude_bin) .. " -p " .. shellQuote(prompt)
        .. " --allowedTools " .. shellQuote("Read,Grep,Glob,Write,Edit,MultiEdit,Bash")
    runShellTask(config.claude_shell, { "-l", "-c", cmd }, config.canonical_timeout_seconds or config.ingest_timeout_seconds or config.ai_timeout_seconds, callback)
end

local function enqueueForIngest(notePath, url, title)
    if not notePath or config.auto_ingest == false then
        return
    end
    local size = queue.enqueue({
        notePath = notePath,
        url = url or "",
        title = title or "",
        queuedAt = hs.timer.secondsSinceEpoch(),
    })
    hs.alert.show(string.format("Inbox 저장 완료. ingest 큐에 추가됨 (대기 %d건)", size), 2.5)
    print(string.format("[obsidian_archive] enqueued for ingest; queue size=%d note=%s", size, notePath))
end

-- 큐 워커가 호출. ingest → canonical 을 순차 실행하고 onComplete() 로 큐를 진행시킨다.
function M.processQueueItem(item, onComplete)
    if not item or not item.notePath then
        onComplete()
        return
    end

    local vaultPath = expandPath(config.vault_path)
    local notePath = item.notePath
    local url = item.url or ""
    local title = item.title or ""
    local engine = config.ingest_engine or "codex"
    local relPath = relativePath(vaultPath, notePath)
    local ingestStartedAt = hs.timer.secondsSinceEpoch()
    local canonicalStartedAt = nil

    hs.alert.show("백그라운드 ingest 시작: " .. relPath .. " (" .. engine .. ")", 2)

    local finishSuccess = function(ingestSummary, canonicalSummary, completedAt, canonicalStatus)
        local popupTitle = "Obsidian LLM Wiki ingest가 완료되었습니다"
        if canonicalStatus == "실패" then
            popupTitle = "Obsidian LLM Wiki ingest는 완료되었고 canonical pass는 확인이 필요합니다"
        end

        local message = table.concat({
            "대상 노트: " .. relPath,
            "엔진: " .. engine,
            "canonical 상태: " .. canonicalStatus,
            "",
            "소요시간:",
            "- ingest: " .. formatDuration((canonicalStartedAt or completedAt) - ingestStartedAt),
            "- canonical: " .. formatDuration(completedAt - (canonicalStartedAt or completedAt)),
            "",
            "Ingest 결과:",
            truncate(ingestSummary ~= "" and ingestSummary or "(변경 요약 출력 없음)", 900),
            "",
            "Canonical 결과:",
            truncate(canonicalSummary ~= "" and canonicalSummary or "(canonical 요약 출력 없음)", 900),
        }, "\n")
        showCompletionPopup(popupTitle, message)
        onComplete()
    end

    local finishFailure = function(msg)
        showFailurePopup("LLM Wiki ingest에 실패했습니다", msg .. "\n대상: " .. relPath)
        print("[obsidian_archive] queued ingest failed: " .. msg)
        onComplete()
    end

    local done = function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            local ingestSummary = trim(stdOut or "")
            print("[obsidian_archive] ingest complete: " .. tostring(stdOut or ""))
            if config.auto_canonical == false then
                finishSuccess(ingestSummary, "canonical pass가 비활성화되어 있습니다.", hs.timer.secondsSinceEpoch(), "건너뜀")
                return
            end

            canonicalStartedAt = hs.timer.secondsSinceEpoch()
            hs.alert.show("canonical wiki pass 진행 중… (" .. engine .. ")", 2)
            local canonicalDone = function(cExit, cOut, cErr)
                local completedAt = hs.timer.secondsSinceEpoch()
                if cExit == 0 then
                    finishSuccess(ingestSummary, trim(cOut or ""), completedAt, "완료")
                    print("[obsidian_archive] canonical complete: " .. tostring(cOut or ""))
                    return
                end

                local canonicalMsg = "canonical wiki pass에 실패했습니다"
                if cExit ~= nil then
                    canonicalMsg = canonicalMsg .. " (exit " .. tostring(cExit) .. ")"
                end
                if cErr and cErr ~= "" then
                    canonicalMsg = canonicalMsg .. ": " .. cErr
                end
                finishSuccess(ingestSummary, canonicalMsg, completedAt, "실패")
                print("[obsidian_archive] canonical failed: " .. canonicalMsg)
            end

            if engine == "claude" then
                runClaudeCanonical(vaultPath, notePath, url, title, canonicalDone)
            else
                runCodexCanonical(vaultPath, notePath, url, title, canonicalDone)
            end
            return
        end

        local msg = "LLM Wiki ingest에 실패했습니다"
        if exitCode ~= nil then
            msg = msg .. " (exit " .. tostring(exitCode) .. ")"
        end
        if stdErr and stdErr ~= "" then
            msg = msg .. ": " .. stdErr
        end
        finishFailure(msg)
    end

    if engine == "claude" then
        runClaudeIngest(vaultPath, notePath, done)
    else
        runCodexIngest(vaultPath, notePath, done)
    end
end

local function summarizeWithFallback(promptText, claudeAllowedTools, fallbackAlert, onSuccess, onFetchFailed)
    runClaude(promptText, claudeAllowedTools, function(exitCode, stdOut, stdErr)
        if exitCode == 0 and hasOutput(stdOut) and not isLikelyCliUnavailable(stdOut, stdErr) then
            if isFetchFailed(stdOut) then
                onFetchFailed()
            else
                onSuccess(trim(stdOut))
            end
            return
        end

        print("[obsidian_archive] Claude unavailable; falling back to Codex. exit=" .. tostring(exitCode) .. " stderr=" .. tostring(stdErr or ""))
        hs.alert.show(fallbackAlert or "Claude 응답이 없습니다. Codex fallback을 실행합니다…", 2)

        runCodex(promptText, function(codexExit, codexOut, codexErr)
            if codexExit == 0 and hasOutput(codexOut) then
                if isFetchFailed(codexOut) then
                    onFetchFailed()
                else
                    onSuccess(trim(codexOut))
                end
                return
            end

            local msg = "Codex fallback에 실패했습니다"
            if codexExit ~= 0 then
                msg = msg .. " (exit " .. tostring(codexExit) .. ")"
            end
            if codexErr and codexErr ~= "" then
                msg = msg .. ": " .. codexErr
            elseif not hasOutput(codexOut) then
                msg = msg .. ": 출력이 없습니다"
            end
            hs.alert.show(msg, 5)
        end)
    end)
end

-- Fallback: 브라우저 User-Agent 로 HTML 을 직접 받은 뒤 Claude, Codex 순서로 요약한다.
local function runFallback(url, title, vaultPath, inboxFolder, startedAt)
    hs.alert.show("봇 차단이 감지되었습니다. 직접 다운로드 후 다시 요약합니다…", 2)

    local tmpFile = tmpPath("obsidian_archive", ".html")
    local downloadCmd = "curl -sS -L -A " .. shellQuote(config.fallback_user_agent)
        .. " -o " .. shellQuote(tmpFile)
        .. " " .. shellQuote(url)

    local curlArgs = { "-l", "-c", downloadCmd }

    local curlTask = hs.task.new(config.claude_shell, function(curlExit, _, curlErr)
        if curlExit ~= 0 then
            removeFile(tmpFile)
            local msg = "본문 다운로드에 실패했습니다 (curl exit " .. tostring(curlExit) .. ")"
            if curlErr and curlErr ~= "" then
                msg = msg .. ": " .. curlErr
            end
            hs.alert.show(msg, 5)
            return
        end

        local fallbackPrompt = table.concat({
            config.fallback_instruction,
            "",
            "제목: " .. title,
            "URL: " .. url,
            "파일 경로: " .. tmpFile,
        }, "\n")

        summarizeWithFallback(fallbackPrompt, "Read", "Claude HTML 요약 응답이 없습니다. Codex fallback을 실행합니다…", function(summaryMd)
            removeFile(tmpFile)
            local notePath = writeNote(vaultPath, inboxFolder, url, title, summaryMd)
            enqueueForIngest(notePath, url, title)
        end, function()
            removeFile(tmpFile)
            hs.alert.show("Fallback 요약에 실패했습니다: 본문에 접근할 수 없습니다", 4)
        end)
    end, curlArgs)

    curlTask:start()
end

function M.archiveCurrentTab()
    local url, title, err = getFrontBrowserUrlAndTitle()
    if err then
        hs.alert.show(err, 3)
        return
    end

    local vaultPath = expandPath(config.vault_path)
    local inboxFolder = config.inbox_folder
    local startedAt = hs.timer.secondsSinceEpoch()
    hs.alert.show("요약을 진행하고 있습니다… (Claude CLI)", 1.5)

    local promptText = buildPrompt(url, title)
    summarizeWithFallback(promptText, "WebFetch,WebSearch", "Claude 응답이 없습니다. Codex fallback을 실행합니다…", function(summaryMd)
        local notePath = writeNote(vaultPath, inboxFolder, url, title, summaryMd)
        enqueueForIngest(notePath, url, title)
    end, function()
        runFallback(url, title, vaultPath, inboxFolder, startedAt)
    end)
end

function M.init()
    hs.hotkey.bind(config.hotkey_mods, config.hotkey_key, function()
        M.archiveCurrentTab()
    end)
    queue.setProcessor(function(item, onComplete)
        M.processQueueItem(item, onComplete)
    end)
    queue.start()
end

return M
