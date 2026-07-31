-- Obsidian Inbox 노트의 LLM ingest/canonical pass 를 백그라운드 큐로 처리한다.
-- 핫키는 요약·저장까지만 동기로 끝내고, 시간이 오래 걸리는 ingest 단계는 이 큐로 위임한다.
-- 큐는 JSON 파일로 영속화돼 Hammerspoon reload 후에도 살아남는다.

local M = {}

local config = require("modules.obsidian_archive_config")

local STATE_DIR = os.getenv("HOME") .. "/.hammerspoon/state"
local QUEUE_PATH = STATE_DIR .. "/obsidian_ingest_queue.json"
local TICK_SECONDS = config.queue_tick_seconds or 300

local processor = nil
local timer = nil
local isProcessing = false

local function ensureStateDir()
    hs.execute("/bin/mkdir -p '" .. STATE_DIR .. "'")
end

local function loadQueue()
    local f = io.open(QUEUE_PATH, "r")
    if not f then
        return {}
    end
    local body = f:read("*a")
    f:close()
    if not body or body == "" then
        return {}
    end
    local ok, data = pcall(hs.json.decode, body)
    if not ok or type(data) ~= "table" then
        print("[obsidian_ingest_queue] queue file corrupt, resetting")
        return {}
    end
    return data
end

local function saveQueue(queue)
    ensureStateDir()
    local body = hs.json.encode(queue, true)
    local f, err = io.open(QUEUE_PATH, "w")
    if not f then
        print("[obsidian_ingest_queue] failed to write queue file: " .. tostring(err))
        return
    end
    f:write(body)
    f:close()
end

function M.size()
    return #loadQueue()
end

function M.enqueue(item)
    local queue = loadQueue()
    table.insert(queue, item)
    saveQueue(queue)
    return #queue
end

local function processNext()
    if isProcessing then
        return
    end
    local queue = loadQueue()
    if #queue == 0 then
        return
    end
    if not processor then
        print("[obsidian_ingest_queue] processor not set; skipping tick")
        return
    end

    isProcessing = true
    local head = queue[1]
    print(string.format("[obsidian_ingest_queue] processing head; queue size=%d note=%s",
        #queue, tostring(head.notePath)))

    local completed = false
    local finish = function()
        if completed then
            return
        end
        completed = true
        local q = loadQueue()
        table.remove(q, 1)
        saveQueue(q)
        isProcessing = false
        print(string.format("[obsidian_ingest_queue] item done; remaining=%d", #q))
    end

    local ok, runErr = pcall(processor, head, finish)
    if not ok then
        print("[obsidian_ingest_queue] processor raised: " .. tostring(runErr))
        finish()
    end
end

function M.setProcessor(fn)
    processor = fn
end

function M.start()
    if timer then
        timer:stop()
    end
    timer = hs.timer.doEvery(TICK_SECONDS, processNext)
    -- reload 직후 큐가 비어있지 않다면 5분을 기다리지 않고 곧바로 한 번 시도
    hs.timer.doAfter(10, processNext)
end

return M
