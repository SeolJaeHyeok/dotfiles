-- 앱별 자동 입력 소스 전환 설정
-- app_sources 에 등록된 번들 ID 가 활성화될 때 해당 소스 ID 로 전환된다.

local M = {}

local ENGLISH = "com.apple.keylayout.ABC"
local KOREAN  = "com.apple.inputmethod.Korean.2SetKorean"

M.app_sources = {
    ["com.mitchellh.ghostty"]            = ENGLISH, -- Ghostty
    ["com.todesktop.230313mzl4w4u92"]    = ENGLISH, -- Cursor
    ["com.cmuxterm.app"]                 = KOREAN,  -- Cmux (Claude Code 사용 비중이 높음)
}

return M
