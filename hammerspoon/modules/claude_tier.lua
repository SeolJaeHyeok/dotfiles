local M = {}

-- Claude Code tier(모델+추론) 전환 (cmd+option+shift+1 ~ 6)
--
-- cmd+shift+3/4/5 는 macOS 기본 스크린샷 단축키(전체/영역 캡처, 캡처 도구막대)와
-- 겹쳐 hotkey 를 누르면 캡처가 함께 발동했다. cmd+option+shift 조합으로 회피
-- (다른 Hammerspoon 모듈·macOS 기본 단축키와 미충돌 확인).
--
-- cmux 소켓은 "cmux 자신의 프로세스 트리(=pane pty를 가진 자손)"에서 온 연결만
-- 허용한다. Hammerspoon/launchd 자손은 broken pipe 로 거부되므로 cmux CLI 를
-- Hammerspoon 에서 호출할 수 없다. 그래서 소켓을 우회하고, 포커스된 pane 에
-- 실제 키 이벤트를 주입한다(사용자가 직접 타이핑하는 것과 동일):
--   1) Ctrl+C 반복 → 실행 중인 claude 종료 → pane 의 zsh 프롬프트로 복귀
--   2) `claude --continue --model <m> --effort <e>` 입력 후 Enter
-- cwd 는 같은 zsh 라 그대로 보존되고, cmux 의 zsh claude() 래퍼가 hooks 를
-- 자동 주입한다. model/effort 는 세션별 CLI 플래그라 전역 설정을 건드리지 않는다.
--
-- 주의: 키 주입에는 Hammerspoon 의 손쉬운 사용(Accessibility) 권한이 필요하다.
-- (시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 > Hammerspoon 허용)

local TIERS = {
  [1] = { model = "fable",  effort = "max",    name = "Tier 1: Fable + max" },
  [2] = { model = "fable",  effort = "medium", name = "Tier 2: Fable + medium" },
  [3] = { model = "opus",   effort = "max",    name = "Tier 3: Opus + max" },
  [4] = { model = "opus",   effort = "medium", name = "Tier 4: Opus + medium" },
  [5] = { model = "sonnet", effort = "medium", name = "Tier 5: Sonnet + medium" },
  [6] = { model = "haiku",  effort = "medium", name = "Tier 6: Haiku + medium" },
}

function M.init()
  local function runTier(tier)
    local t = TIERS[tier]
    if not t then return end

    local cmd = "claude --dangerously-skip-permissions --continue"
      .. " --model " .. t.model .. " --effort " .. t.effort

    -- 1) 실행 중인 claude 종료: Ctrl+C 반복.
    --    (mid-task=취소 후 종료, idle=종료. 종료 후 여분의 ^C 는 프롬프트에서 무해)
    hs.eventtap.keyStroke({ "ctrl" }, "c", 0)
    hs.timer.doAfter(0.25, function() hs.eventtap.keyStroke({ "ctrl" }, "c", 0) end)
    hs.timer.doAfter(0.50, function() hs.eventtap.keyStroke({ "ctrl" }, "c", 0) end)

    -- 2) shell 프롬프트 복귀 후 재실행 명령 입력 + Enter
    --    (claude 종료 시 SessionEnd 훅이 최대 ~1s 걸릴 수 있어 넉넉히 대기)
    hs.timer.doAfter(1.60, function()
      hs.eventtap.keyStrokes(cmd)
      hs.timer.doAfter(0.15, function() hs.eventtap.keyStroke({}, "return", 0) end)
    end)

    hs.alert.show(t.name .. "\n(세션 전환 중...)")
  end

  hs.hotkey.bind({ "cmd", "alt", "shift" }, "1", function() runTier(1) end)
  hs.hotkey.bind({ "cmd", "alt", "shift" }, "2", function() runTier(2) end)
  hs.hotkey.bind({ "cmd", "alt", "shift" }, "3", function() runTier(3) end)
  hs.hotkey.bind({ "cmd", "alt", "shift" }, "4", function() runTier(4) end)
  hs.hotkey.bind({ "cmd", "alt", "shift" }, "5", function() runTier(5) end)
  hs.hotkey.bind({ "cmd", "alt", "shift" }, "6", function() runTier(6) end)
end

return M
