-- 지정된 앱이 활성화될 때마다 config 에 매핑된 입력 소스로 자동 전환.
-- 이미 타겟 소스 상태면 아무것도 하지 않는다.

local M = {}

local config = require("modules.auto_input_source_config")

local watcher

local function switchIfNeeded(bundleID)
    if bundleID == nil then
        return
    end
    local target = config.app_sources[bundleID]
    if target == nil then
        return
    end
    if hs.keycodes.currentSourceID() == target then
        return
    end
    hs.keycodes.currentSourceID(target)
end

function M.init()
    local front = hs.application.frontmostApplication()
    if front then
        switchIfNeeded(front:bundleID())
    end

    watcher = hs.application.watcher.new(function(_, event, app)
        if event == hs.application.watcher.activated and app then
            switchIfNeeded(app:bundleID())
        end
    end)
    watcher:start()
end

return M
