local M = {}

-- 저장된 요청 정보
local storedRequest = nil
local waitingForResponse = false
local responseTimer = nil

-- 클립보드 감시
local clipboardWatcher = nil
local lastClipboard = ""

-- cURL 명령어 파싱
local function parseCurl(curlCmd)
    local result = {
        method = "GET",
        url = "",
        headers = {},
        body = nil,
        queryParams = {}
    }

    -- URL 추출
    local url = curlCmd:match("curl%s+'([^']+)'") or curlCmd:match('curl%s+"([^"]+)"') or curlCmd:match("curl%s+(%S+)")
    if not url then return nil end

    -- 메서드 추출
    local method = curlCmd:match("%-X%s+'([^']+)'") or curlCmd:match('%-X%s+"([^"]+)"') or curlCmd:match("%-X%s+(%S+)")
    if method then
        result.method = method:upper()
    elseif curlCmd:match("%-%-data") or curlCmd:match("%-d%s") then
        result.method = "POST"
    end

    -- 헤더 추출
    for header in curlCmd:gmatch("%-H%s+'([^']+)'") do
        local key, value = header:match("^([^:]+):%s*(.+)$")
        if key then
            table.insert(result.headers, { key = key, value = value })
        end
    end
    for header in curlCmd:gmatch('%-H%s+"([^"]+)"') do
        local key, value = header:match("^([^:]+):%s*(.+)$")
        if key then
            table.insert(result.headers, { key = key, value = value })
        end
    end

    -- Body 추출
    local body = curlCmd:match("%-%-data%-raw%s+'(.-)'%s*")
        or curlCmd:match("%-%-data%-raw%s+'(.*)'%s*$")
        or curlCmd:match('%-%-data%-raw%s+"(.-)"')
        or curlCmd:match("%-%-data%s+'(.-)'")
        or curlCmd:match('%-%-data%s+"(.-)"')
        or curlCmd:match("%-d%s+'(.-)'")
        or curlCmd:match('%-d%s+"(.-)"')
    if body then
        result.body = body
    end

    -- URL에서 query params 분리
    local baseUrl, queryString = url:match("^([^?]+)%?(.+)$")
    if baseUrl and queryString then
        result.url = baseUrl
        for param in queryString:gmatch("[^&]+") do
            local key, value = param:match("^([^=]+)=(.*)$")
            if key then
                -- URL 디코딩 간단 처리
                value = value:gsub("%%(%x%x)", function(h)
                    return string.char(tonumber(h, 16))
                end)
                table.insert(result.queryParams, { key = key, value = value })
            end
        end
    else
        result.url = url
    end

    return result
end

-- JSON 포맷팅 (들여쓰기)
local function formatJSON(str)
    if not str or str == "" then return str end

    local ok, _ = pcall(function() return hs.json.decode(str) end)
    if ok then
        local decoded = hs.json.decode(str)
        return hs.json.encode(decoded, true)
    end
    return str
end

-- 마크다운 생성
local function generateMarkdown(request, response)
    local lines = {}

    -- 제목
    table.insert(lines, "## " .. request.method .. " `" .. request.url .. "`")
    table.insert(lines, "")

    -- Query Parameters
    if #request.queryParams > 0 then
        table.insert(lines, "### Query Parameters")
        table.insert(lines, "")
        table.insert(lines, "| Key | Value |")
        table.insert(lines, "|-----|-------|")
        for _, param in ipairs(request.queryParams) do
            table.insert(lines, "| `" .. param.key .. "` | `" .. param.value .. "` |")
        end
        table.insert(lines, "")
    end

    -- Headers (주요 헤더만)
    if #request.headers > 0 then
        table.insert(lines, "### Headers")
        table.insert(lines, "")
        table.insert(lines, "| Key | Value |")
        table.insert(lines, "|-----|-------|")
        local skipHeaders = {
            ["sec-ch-ua"] = true,
            ["sec-ch-ua-mobile"] = true,
            ["sec-ch-ua-platform"] = true,
            ["sec-fetch-dest"] = true,
            ["sec-fetch-mode"] = true,
            ["sec-fetch-site"] = true,
            ["user-agent"] = true,
            ["accept-encoding"] = true,
            ["accept-language"] = true,
            ["connection"] = true,
            ["cookie"] = true,
        }
        for _, header in ipairs(request.headers) do
            if not skipHeaders[header.key:lower()] then
                local displayValue = header.value
                -- 긴 값 축약
                if #displayValue > 80 then
                    displayValue = displayValue:sub(1, 77) .. "..."
                end
                table.insert(lines, "| `" .. header.key .. "` | `" .. displayValue .. "` |")
            end
        end
        table.insert(lines, "")
    end

    -- Request Body
    if request.body and request.body ~= "" then
        table.insert(lines, "### Request Body")
        table.insert(lines, "")
        table.insert(lines, "```json")
        table.insert(lines, formatJSON(request.body))
        table.insert(lines, "```")
        table.insert(lines, "")
    end

    -- Response
    if response and response ~= "" then
        table.insert(lines, "### Response")
        table.insert(lines, "")
        table.insert(lines, "```json")
        table.insert(lines, formatJSON(response))
        table.insert(lines, "```")
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

-- 마크다운 결과 팝업
local popupView = nil
local lastMarkdown = nil

local function showPopup(markdown)
    lastMarkdown = markdown

    if popupView then
        popupView:delete()
        popupView = nil
    end

    local screen = hs.screen.mainScreen():frame()
    local width = screen.w / 2
    local height = screen.h
    local x = screen.x + (screen.w - width) / 2
    local y = screen.y

    local escapedMarkdown = markdown:gsub("\\", "\\\\"):gsub("`", "\\`"):gsub("%$", "\\$")

    local html = [[
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/styles/github.min.css">
    <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/highlight.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { height: 100%; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            font-size: 15px;
            line-height: 1.8;
            color: #2c2c2e;
            background: linear-gradient(135deg, #fafafa 0%, #f2f2f7 100%);
            -webkit-font-smoothing: antialiased;
            display: flex;
            flex-direction: column;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 16px 24px;
            background: rgba(255,255,255,0.85);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border-bottom: 0.5px solid rgba(0,0,0,0.08);
            position: sticky;
            top: 0;
            z-index: 10;
        }
        .title-area {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .title-icon {
            width: 28px;
            height: 28px;
            background: linear-gradient(135deg, #0ea5e9, #38bdf8);
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
        }
        .title {
            font-size: 14px;
            font-weight: 600;
            color: #1c1c1e;
        }
        .actions {
            display: flex;
            gap: 6px;
        }
        .action-btn {
            background: rgba(0,0,0,0.04);
            border: none;
            font-size: 12px;
            color: #6e6e73;
            cursor: pointer;
            padding: 6px 12px;
            border-radius: 6px;
            font-weight: 500;
            transition: all 0.15s;
        }
        .action-btn:hover {
            background: rgba(0,0,0,0.08);
            color: #1c1c1e;
        }
        .action-btn.copy-done {
            background: rgba(52,199,89,0.12);
            color: #34c759;
        }
        .content {
            flex: 1;
            overflow-y: auto;
            padding: 24px;
        }
        .content h2 { font-size: 18px; font-weight: 700; margin: 0 0 16px; color: #1c1c1e; }
        .content h3 { font-size: 15px; font-weight: 600; margin: 20px 0 8px; color: #1c1c1e; }
        .content p { margin: 0 0 12px; }
        .content table {
            border-collapse: collapse;
            width: 100%;
            margin: 0 0 12px;
            font-size: 13px;
        }
        .content th, .content td {
            border: 0.5px solid #d1d1d6;
            padding: 8px 12px;
            text-align: left;
        }
        .content th {
            background: rgba(0,0,0,0.03);
            font-weight: 600;
        }
        .content code {
            background: rgba(14,165,233,0.08);
            color: #0369a1;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: "SF Mono", Menlo, monospace;
            font-size: 13px;
        }
        .content pre {
            background: #1c1c1e;
            color: #f2f2f7;
            border-radius: 10px;
            padding: 16px;
            margin: 0 0 12px;
            overflow-x: auto;
            font-size: 13px;
            line-height: 1.6;
        }
        .content pre code {
            background: none;
            padding: 0;
            color: inherit;
            font-size: inherit;
        }
    </style>
    </head>
    <body>
        <div class="header">
            <div class="title-area">
                <div class="title-icon">A</div>
                <span class="title">API Document</span>
            </div>
            <div class="actions">
                <button class="action-btn" id="copyMdBtn" onclick="copyMarkdown()">Copy MD</button>
                <button class="action-btn" id="copySlackBtn" onclick="copySlack()">Copy for Slack</button>
                <button class="action-btn" id="dlBtn" onclick="downloadMd()">Download</button>
            </div>
        </div>
        <div class="content" id="content"></div>
        <script>
            var rawMd = `]] .. escapedMarkdown .. [[`;
            marked.setOptions({
                highlight: function(code, lang) {
                    if (lang && hljs.getLanguage(lang)) {
                        return hljs.highlight(code, { language: lang }).value;
                    }
                    return hljs.highlightAuto(code).value;
                },
                gfm: true
            });
            document.getElementById('content').innerHTML = marked.parse(rawMd);

            function downloadMd() {
                window.webkit.messageHandlers.hammerspoon.postMessage('download');
                var btn = document.getElementById('dlBtn');
                btn.textContent = 'Saved!';
                btn.classList.add('copy-done');
                setTimeout(function() {
                    btn.textContent = 'Download';
                    btn.classList.remove('copy-done');
                }, 1500);
            }

            function copySlack() {
                // 렌더링된 HTML을 리치 텍스트로 복사 (Slack이 서식 유지)
                var el = document.getElementById('content');
                var range = document.createRange();
                range.selectNodeContents(el);
                var sel = window.getSelection();
                sel.removeAllRanges();
                sel.addRange(range);
                document.execCommand('copy');
                sel.removeAllRanges();
                var btn = document.getElementById('copySlackBtn');
                btn.textContent = 'Copied!';
                btn.classList.add('copy-done');
                setTimeout(function() {
                    btn.textContent = 'Copy for Slack';
                    btn.classList.remove('copy-done');
                }, 1500);
            }

            function copyMarkdown() {
                var ta = document.createElement('textarea');
                ta.value = rawMd;
                document.body.appendChild(ta);
                ta.select();
                document.execCommand('copy');
                document.body.removeChild(ta);
                var btn = document.getElementById('copyMdBtn');
                btn.textContent = 'Copied!';
                btn.classList.add('copy-done');
                setTimeout(function() {
                    btn.textContent = 'Copy MD';
                    btn.classList.remove('copy-done');
                }, 1500);
            }
        </script>
    </body>
    </html>
    ]]

    local uc = hs.webview.usercontent.new("hammerspoon")
    uc:setCallback(function(msg)
        if msg.body == "download" and lastMarkdown then
            local timestamp = os.date("%Y%m%d-%H%M%S")
            local filePath = os.getenv("HOME") .. "/Downloads/api-doc-" .. timestamp .. ".md"
            local f = io.open(filePath, "w")
            if f then
                f:write(lastMarkdown)
                f:close()
                hs.alert.show("Saved: " .. filePath, 2)
            end
        end
    end)

    popupView = hs.webview.new(hs.geometry.rect(x, y, width, height), { developerExtrasEnabled = false }, uc)
        :windowStyle({"titled", "closable", "resizable"})
        :windowTitle("API Document")
        :html(html)
        :bringToFront(true)
        :show()
        :level(hs.drawing.windowLevels.floating)
end

-- 응답 대기 타이머 취소
local function cancelResponseWait()
    waitingForResponse = false
    storedRequest = nil
    if responseTimer then
        responseTimer:stop()
        responseTimer = nil
    end
end

-- 클립보드 변경 처리
local function onClipboardChange()
    local current = hs.pasteboard.getContents()
    if not current or current == "" or current == lastClipboard then
        return
    end
    lastClipboard = current

    -- Step 2: 응답 대기 중이면 → 마크다운 생성
    if waitingForResponse and storedRequest then
        local markdown = generateMarkdown(storedRequest, current)
        hs.pasteboard.setContents(markdown)
        lastClipboard = markdown
        showPopup(markdown)
        cancelResponseWait()
        return
    end

    -- Step 1: curl 명령어 감지
    if current:match("^curl%s") then
        local parsed = parseCurl(current)
        if parsed then
            storedRequest = parsed
            waitingForResponse = true
            hs.alert.show("요청 정보 저장 완료\nResponse를 복사해주세요 (10초)", 3)

            -- 10초 타이머
            if responseTimer then responseTimer:stop() end
            responseTimer = hs.timer.doAfter(10, function()
                if waitingForResponse then
                    local markdown = generateMarkdown(storedRequest, nil)
                    hs.pasteboard.setContents(markdown)
                    lastClipboard = markdown
                    showPopup(markdown)
                    cancelResponseWait()
                end
            end)
        end
    end
end

function M.init()
    -- 클립보드 감시 (0.5초 간격)
    lastClipboard = hs.pasteboard.getContents() or ""
    clipboardWatcher = hs.timer.doEvery(0.5, onClipboardChange)
end

return M
