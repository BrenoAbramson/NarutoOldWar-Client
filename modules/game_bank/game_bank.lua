local OPCODE = 92
local bankWindow

local function formatCompact(value)
    local digits = tostring(value or '0'):gsub('[^0-9]', ''):gsub('^0+', '')
    if digits == '' then return '0' end
    if #digits <= 3 then return digits end

    local groups = math.floor((#digits - 1) / 3)
    local wholeLength = #digits - groups * 3
    local compact = digits:sub(1, wholeLength)
    local decimal = digits:sub(wholeLength + 1, wholeLength + 1)
    if decimal ~= '' and decimal ~= '0' then
        compact = compact .. ',' .. decimal
    end

    local full = digits:reverse():gsub('(%d%d%d)', '%1.'):gsub('%.$', ''):reverse()
    return full .. ' (' .. compact .. string.rep('k', groups) .. ')'
end

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

local function send(action)
    local protocol = g_game.getProtocolGame()
    if protocol then
        protocol:sendExtendedOpcode(OPCODE, action)
    end
end

local function numericValue(widgetId)
    if not bankWindow then return nil end
    local text = bankWindow:getChildById(widgetId):getText():gsub('[^0-9]', '')
    if text == '' or text == '0' then return nil end
    return text
end

local function clearFields()
    if not bankWindow then return end
    bankWindow:getChildById('depositValue'):setText('')
    bankWindow:getChildById('withdrawValue'):setText('')
    bankWindow:getChildById('targetName'):setText('')
    bankWindow:getChildById('transferValue'):setText('')
end

local function showState(payload)
    if not bankWindow then
        bankWindow = g_ui.displayUI('game_bank')
        bankWindow:hide()
        bankWindow:getChildById('balanceTitle'):setText('Saldo no Banco:')
        bankWindow:getChildById('inventoryBalanceTitle'):setText('Saldo no Invent\225rio:')
        bankWindow:getChildById('historyTitle'):setText('\218ltimas opera\231\245es')
        bankWindow:recursiveGetChildById('operationHeader'):setText('Opera\231\227o')
        bankWindow:getChildById('depositValue'):setValidCharacters('0123456789')
        bankWindow:getChildById('withdrawValue'):setValidCharacters('0123456789')
        bankWindow:getChildById('transferValue'):setValidCharacters('0123456789')
    end

    local fields = split(payload, '|')
    bankWindow:getChildById('balance'):setText(formatCompact(fields[1]))
    bankWindow:getChildById('inventoryBalance'):setText(formatCompact(fields[2]))
    bankWindow:getChildById('message'):setText(fields[3] or '')

    local history = bankWindow:getChildById('history')
    history:destroyChildren()
    for _, line in ipairs(split(fields[4] or '', '\n')) do
        if line ~= '' then
            local entry = split(line, '\t')
            if #entry >= 3 then
                local row = g_ui.createWidget('BankHistoryRow', history)
                row:getChildById('date'):setText(os.date('%d/%m %H:%M', tonumber(entry[1]) or 0))
                row:getChildById('operation'):setText(entry[2])
                row:getChildById('amount'):setText(formatCompact(entry[3]))
                row:getChildById('other'):setText(entry[4] or '')
            end
        end
    end

    bankWindow:show()
    bankWindow:raise()
    bankWindow:focus()
end

local function onExtendedOpcode(protocol, opcode, buffer)
    local action, payload = buffer:match('^([^|]+)|?(.*)$')
    if action == 'state' then showState(payload) end
end

function init()
    ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)
    connect(g_game, { onGameEnd = onGameEnd })
end

function terminate()
    disconnect(g_game, { onGameEnd = onGameEnd })
    ProtocolGame.unregisterExtendedOpcode(OPCODE)
    if bankWindow then bankWindow:destroy() bankWindow = nil end
end

function onGameEnd()
    hide()
end

function hide()
    if bankWindow then
        clearFields()
        bankWindow:hide()
    end
end

function deposit()
    local amount = numericValue('depositValue')
    if amount then
        send('deposit|' .. amount)
        bankWindow:getChildById('depositValue'):setText('')
    end
end

function depositAll()
    send('depositAll')
    if bankWindow then bankWindow:getChildById('depositValue'):setText('') end
end

function withdraw()
    local amount = numericValue('withdrawValue')
    if amount then
        send('withdraw|' .. amount)
        bankWindow:getChildById('withdrawValue'):setText('')
    end
end

function transfer()
    if not bankWindow then return end
    local name = bankWindow:getChildById('targetName'):getText():gsub('|', ' ')
    local amount = numericValue('transferValue')
    if name ~= '' and amount then
        send('transfer|' .. name .. '|' .. amount)
        bankWindow:getChildById('targetName'):setText('')
        bankWindow:getChildById('transferValue'):setText('')
    end
end

function refresh()
    send('refresh')
end
