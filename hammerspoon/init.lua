-- Hammerspoon 설정 진입점

-- 설정 리로드 핫키 (Cmd+Alt+R)
hs.hotkey.bind({"cmd", "alt"}, "r", function()
    hs.reload()
end)

-- 모듈 로드
require("modules.translator").init()
require("modules.curl_formatter").init()
require("modules.screen_modes").init()
require("modules.obsidian_archive").init()
require("modules.auto_input_source").init()
require("modules.claude_tier").init()

hs.alert.show("Hammerspoon 설정 로드 완료")
