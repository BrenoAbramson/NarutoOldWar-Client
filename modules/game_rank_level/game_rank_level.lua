local OPCODE = 91
local ONLINE_INTERVAL = 30000

local rankWindow
local onlineEvent

local function split(value, separator)
    local result = {}
    local start = 1
    while true do
        local first, last = value:find(separator, start, true)
        if not first then
            table.insert(result, value:sub(start))
            return result
        end
        table.insert(result, value:sub(start, first - 1))
        start = last + 1
    end
end

local function requestOnlinePlayers()
    onlineEvent = nil
    if g_game.isOnline() then
        local protocol = g_game.getProtocolGame()
        if protocol then
            protocol:sendExtendedOpcode(OPCODE, 'online')
        end
        onlineEvent = scheduleEvent(requestOnlinePlayers, ONLINE_INTERVAL)
    end
end

local function showRanking(payload)
    if not rankWindow then
        rankWindow = g_ui.displayUI('game_rank_level')
        rankWindow:hide()
    end
    local entries = rankWindow:getChildById('entries')
    entries:destroyChildren()

    local localPlayer = g_game.getLocalPlayer()
    local localName = localPlayer and localPlayer:getName():lower() or ''
    for _, line in ipairs(split(payload, '\n')) do
        if line ~= '' then
            local fields = split(line, '\t')
            if #fields >= 3 then
                local row = g_ui.createWidget('RankLevelRow', entries)
                row:getChildById('position'):setText(fields[1])
                row:getChildById('name'):setText(fields[2])
                row:getChildById('level'):setText(fields[3])
                if fields[2]:lower() == localName then
                    for _, child in ipairs(row:getChildren()) do
                        child:setColor('#57d957')
                    end
                end
            end
        end
    end

    rankWindow:show()
    rankWindow:raise()
    rankWindow:focus()
end

local function onExtendedOpcode(protocol, opcode, buffer)
    local action, payload = buffer:match('^([^|]+)|?(.*)$')
    if action == 'online' then
        local count = tonumber(payload) or 0
        modules.client_topmenu.setPlayersOnline(count)
    elseif action == 'rank' then
        showRanking(payload)
    end
end

function init()
    ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)
    connect(g_game, { onGameStart = requestOnlinePlayers, onGameEnd = onGameEnd })
    if g_game.isOnline() then
        requestOnlinePlayers()
    end
end

function terminate()
    disconnect(g_game, { onGameStart = requestOnlinePlayers, onGameEnd = onGameEnd })
    ProtocolGame.unregisterExtendedOpcode(OPCODE)
    if onlineEvent then
        removeEvent(onlineEvent)
        onlineEvent = nil
    end
    if rankWindow then
        rankWindow:destroy()
        rankWindow = nil
    end
end

function onGameEnd()
    if onlineEvent then
        removeEvent(onlineEvent)
        onlineEvent = nil
    end
    modules.client_topmenu.setPlayersOnline('-')
    hide()
end

function hide()
    if rankWindow then
        rankWindow:hide()
    end
end
