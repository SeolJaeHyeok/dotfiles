local M = {}

-- 설정
local HOTKEY_MODS = {"cmd", "alt"}
local HOTKEY_KEY = "t"
local CLAUDE_PATH = "/bin/bash"
local CLAUDE_BIN = "/Users/seoljaehyeok/.local/bin/claude"
local PROMPT = "아래 영어 텍스트를 자연스러운 한국어로 번역해줘. 규칙: 1) 번역문만 출력할 것. 2) 원본의 마크다운 구조(제목, 코드 블럭, 볼드, 이탤릭, 리스트, 링크 등)를 그대로 유지할 것. 3) 코드 블럭 안의 코드는 번역하지 말고 원본 그대로 유지할 것. 4) 코드 블럭 안의 주석만 한국어로 번역할 것."

-- 번역 결과를 보여줄 WebView
local webview = nil
-- 로딩 팝업
local loadingView = nil

local function hideLoading()
    if loadingView then
        loadingView:delete()
        loadingView = nil
    end
end

local function showLoading()
    hideLoading()

    local screen = hs.screen.mainScreen():frame()
    local width = 320
    local height = 120
    local x = screen.x + (screen.w - width) / 2
    local y = screen.y + (screen.h - height) / 2

    loadingView = hs.webview.new(hs.geometry.rect(x, y, width, height))
        :windowStyle({"titled"})
        :windowTitle("")
        :level(hs.drawing.windowLevels.floating)
        :html([[
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
                background: linear-gradient(135deg, #fafafa 0%, #f2f2f7 100%);
                display: flex; flex-direction: column;
                align-items: center; justify-content: center;
                height: 100vh; padding: 20px;
                -webkit-font-smoothing: antialiased;
            }
            .label {
                font-size: 13px; font-weight: 600;
                color: #1c1c1e; margin-bottom: 12px;
            }
            .bar-bg {
                width: 100%; height: 6px;
                background: rgba(0,0,0,0.06);
                border-radius: 3px; overflow: hidden;
                margin-bottom: 8px;
            }
            .bar-fill {
                height: 100%; width: 0%;
                background: linear-gradient(90deg, #7c3aed, #a78bfa);
                border-radius: 3px;
                transition: width 0.3s ease-out;
            }
            .pct {
                font-size: 12px; color: #86868b;
                font-variant-numeric: tabular-nums;
            }
        </style>
        </head><body>
            <div class="label">Translating...</div>
            <div class="bar-bg"><div class="bar-fill" id="fill"></div></div>
            <div class="pct" id="pct">0%</div>
            <script>
                var progress = 0;
                var interval = setInterval(function() {
                    var remaining = 92 - progress;
                    var increment = remaining * 0.08;
                    if (increment < 0.3) increment = 0.3;
                    progress = Math.min(progress + increment, 92);
                    document.getElementById('fill').style.width = progress + '%';
                    document.getElementById('pct').textContent = Math.round(progress) + '%';
                }, 400);
            </script>
        </body></html>
        ]])
        :bringToFront(true)
        :show()
end

local function escapeForJS(text)
    return text
        :gsub("\\", "\\\\")
        :gsub("`", "\\`")
        :gsub("$", "\\$")
end

local function showPopup(text)
    if webview then
        webview:delete()
        webview = nil
    end

    local screen = hs.screen.mainScreen():frame()
    local width = screen.w / 2
    local height = screen.h
    local x = screen.x + (screen.w - width) / 2
    local y = screen.y

    local escapedText = escapeForJS(text)

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
            background: linear-gradient(135deg, #7c3aed, #a78bfa);
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
        /* Markdown styles */
        .content h1 { font-size: 24px; font-weight: 700; margin: 24px 0 12px; color: #1c1c1e; }
        .content h2 { font-size: 20px; font-weight: 600; margin: 20px 0 10px; color: #1c1c1e; }
        .content h3 { font-size: 17px; font-weight: 600; margin: 16px 0 8px; color: #1c1c1e; }
        .content h1:first-child, .content h2:first-child, .content h3:first-child { margin-top: 0; }
        .content p { margin: 0 0 12px; }
        .content strong { font-weight: 600; color: #1c1c1e; }
        .content em { font-style: italic; color: #48484a; }
        .content a { color: #7c3aed; text-decoration: none; }
        .content a:hover { text-decoration: underline; }
        .content ul, .content ol { margin: 0 0 12px; padding-left: 24px; }
        .content li { margin: 4px 0; }
        .content li > p { margin: 0; }
        .content blockquote {
            border-left: 3px solid #d1d1d6;
            margin: 0 0 12px;
            padding: 8px 16px;
            color: #636366;
            background: rgba(0,0,0,0.02);
            border-radius: 0 8px 8px 0;
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
        .content code {
            background: rgba(124,58,237,0.08);
            color: #7c3aed;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: "SF Mono", Menlo, monospace;
            font-size: 13px;
        }
        .content img { max-width: 100%; border-radius: 8px; }
        .content hr {
            border: none;
            height: 0.5px;
            background: rgba(0,0,0,0.1);
            margin: 20px 0;
        }
        .content table {
            border-collapse: collapse;
            width: 100%;
            margin: 0 0 12px;
            font-size: 14px;
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
        /* dark mode code highlight overrides */
        .content pre .hljs { background: #1c1c1e; }
    </style>
    </head>
    <body>
        <div class="header">
            <div class="title-area">
                <div class="title-icon">T</div>
                <span class="title">Translation</span>
            </div>
            <div class="actions">
                <button class="action-btn" id="copyBtn" onclick="copyText()">Copy</button>
            </div>
        </div>
        <div class="content" id="content"></div>
        <script>
            var raw = `]] .. escapedText .. [[`;
            marked.setOptions({
                highlight: function(code, lang) {
                    if (lang && hljs.getLanguage(lang)) {
                        return hljs.highlight(code, { language: lang }).value;
                    }
                    return hljs.highlightAuto(code).value;
                },
                breaks: true,
                gfm: true
            });
            document.getElementById('content').innerHTML = marked.parse(raw);

            function copyText() {
                var el = document.getElementById('content');
                var range = document.createRange();
                range.selectNodeContents(el);
                var sel = window.getSelection();
                sel.removeAllRanges();
                sel.addRange(range);
                document.execCommand('copy');
                sel.removeAllRanges();
                var btn = document.getElementById('copyBtn');
                btn.textContent = 'Copied!';
                btn.classList.add('copy-done');
                setTimeout(function() {
                    btn.textContent = 'Copy';
                    btn.classList.remove('copy-done');
                }, 1500);
            }
        </script>
    </body>
    </html>
    ]]

    webview = hs.webview.new(hs.geometry.rect(x, y, width, height))
        :windowStyle({"titled", "closable", "resizable"})
        :windowTitle("Translation")
        :html(html)
        :bringToFront(true)
        :show()
        :level(hs.drawing.windowLevels.floating)
end

local function shellQuote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function translate(text)
    local promptText = PROMPT .. "\n\n" .. text
    local args = {
        "-l", "-c",
        CLAUDE_BIN .. " -p " .. shellQuote(promptText)
    }

    showLoading()

    local task = hs.task.new(CLAUDE_PATH, function(exitCode, stdout, stderr)
        hideLoading()
        if stdout and stdout:match("%S") then
            showPopup(stdout)
        else
            local errMsg = "번역 실패"
            if stderr and stderr ~= "" then
                errMsg = errMsg .. ": " .. stderr
            end
            hs.alert.show(errMsg, 3)
        end
    end, args)

    task:start()
end

function M.init()
    hs.hotkey.bind(HOTKEY_MODS, HOTKEY_KEY, function()
        -- 기존 클립보드 내용 백업
        local originalClipboard = hs.pasteboard.getContents()

        -- 선택된 텍스트 복사
        hs.eventtap.keyStroke({"cmd"}, "c")

        -- 클립보드에 복사될 시간을 약간 대기
        hs.timer.doAfter(0.2, function()
            local selectedText = hs.pasteboard.getContents()

            if selectedText and selectedText ~= "" and selectedText ~= originalClipboard then
                -- 선택된 텍스트가 있으면 그것만 번역
                translate(selectedText)
                if originalClipboard then
                    hs.pasteboard.setContents(originalClipboard)
                end
            else
                -- 선택된 텍스트가 없으면 전체 선택 후 번역
                hs.eventtap.keyStroke({"cmd"}, "a")
                hs.timer.doAfter(0.1, function()
                    hs.eventtap.keyStroke({"cmd"}, "c")
                    hs.timer.doAfter(0.2, function()
                        local allText = hs.pasteboard.getContents()
                        if allText and allText ~= "" then
                            translate(allText)
                        else
                            hs.alert.show("번역할 텍스트를 찾을 수 없습니다", 2)
                        end
                        -- 선택 해제 및 클립보드 원복
                        hs.eventtap.keyStroke({}, "right")
                        if originalClipboard then
                            hs.pasteboard.setContents(originalClipboard)
                        end
                    end)
                end)
            end
        end)
    end)
end

return M
