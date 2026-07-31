local M = {}

-- 모니터 이름
local SCREEN_LAPTOP = "Built-in Retina Display"
local SCREEN_LF27 = "LF27T35"
local SCREEN_ULTRAWIDE = "S34CG50"

-- 이름에 키워드가 포함된 모니터 찾기
local function findScreen(keyword)
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() and screen:name():find(keyword, 1, true) then
            return screen
        end
    end
    return nil
end

-- 앱을 특정 화면의 특정 영역에 배치
local function placeApp(appName, screenKeyword, position, delay)
    delay = delay or 0

    hs.timer.doAfter(delay, function()
        local screen = findScreen(screenKeyword)
        if not screen then
            print("모니터를 찾을 수 없음: " .. screenKeyword)
            return
        end

        local frame = screen:frame()
        local rect

        if position == "full" then
            rect = frame
        elseif position == "left" then
            rect = hs.geometry.rect(frame.x, frame.y, frame.w / 2, frame.h)
        elseif position == "right" then
            rect = hs.geometry.rect(frame.x + frame.w / 2, frame.y, frame.w / 2, frame.h)
        end

        local app = hs.application.open(appName, 3, true)
        if app then
            local win = app:mainWindow()
            if win then
                win:moveToScreen(screen)
                win:setFrame(rect)
            else
                print("윈도우를 찾을 수 없음: " .. appName)
            end
        else
            print("앱을 찾을 수 없음: " .. appName)
        end
    end)
end

-- 코딩 모드: Cmd+Alt+1
local CODING_PLAYLIST = "https://youtu.be/Yuw8TnTei58?si=ZJjp3ajItlZ1ixqE"

local function codingMode()
    placeApp("Cursor", SCREEN_ULTRAWIDE, "left", 0)
    placeApp("cmux", SCREEN_ULTRAWIDE, "right", 1)
    placeApp("Google Chrome", SCREEN_LF27, "full", 2)
    placeApp("Slack", SCREEN_LAPTOP, "full", 3)

    -- YouTube 플레이리스트 재생
    hs.timer.doAfter(4, function()
        hs.urlevent.openURL(CODING_PLAYLIST)
    end)

    hs.alert.show("Coding Mode", 2)
end

function M.init()
    hs.hotkey.bind({"cmd", "alt"}, "1", codingMode)
end

return M
