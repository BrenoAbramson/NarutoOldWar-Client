local OPCODE = 95
local tradeWindow
local requestBox
local bankUpdateEvent
local applyingState = false

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

local function send(message)
    local protocol = g_game.getProtocolGame()
    if protocol then protocol:sendExtendedOpcode(OPCODE, message) end
end

function request(creatureId)
    send('request|' .. creatureId)
end

function cancel()
    send('cancel')
end

function approve()
    send('approve')
end

function confirm()
    send('confirm')
end

local function formatValue(value)
    local text = tostring(math.floor(tonumber(value) or 0))
    local formatted = text:reverse():gsub('(%d%d%d)', '%1.'):gsub('%.$', ''):reverse()
    return formatted
end

local function addItem(item)
    if not item or not item:getPosition() then return false end
    local position = item:getPosition()
    local submit = function(count)
        send(string.format('add|%d|%d|%d|%d|%d|%d', position.x, position.y, position.z,
            item:getStackPos(), item:getId(), count))
    end
    modules.game_interface.chooseItemCount(item, submit)
    return true
end

local function onOfferDrop(panel, draggedWidget, mousePos)
    local item = draggedWidget and draggedWidget.currentDragThing
    if not item and draggedWidget and draggedWidget.getItem then item = draggedWidget:getItem() end
    if not item or not item:isItem() then return false end
    return addItem(item)
end

local function fillOffer(panel, serialized, own)
    panel:destroyChildren()
    local entries = serialized == '' and {} or split(serialized, ';')
    for index = 1, math.max(20, #entries) do
        local slot = g_ui.createWidget('Item', panel)
        slot:setVirtual(true)
        slot:setWidth(40)
        slot:setHeight(40)
        slot.onDrop = onOfferDrop
        local entry = entries[index]
        if entry then
            local fields = split(entry, ',')
            slot:setItem(Item.create(tonumber(fields[1]), tonumber(fields[2]) or 1))
            local offerIndex = tonumber(fields[3]) or (index - 1)
            local depth = tonumber(fields[4]) or 0
            if own and depth == 0 then
                slot:setTooltip(tr('Clique para remover da oferta'))
                slot.onClick = function() send('remove|' .. offerIndex) end
            elseif depth > 0 then
                slot:setTooltip(tr('Conteudo do recipiente negociado'))
            end
        end
    end
    panel.onDrop = onOfferDrop
end

local function updateOffers(ownOffer, partnerOffer)
    if not tradeWindow then return end
    fillOffer(tradeWindow:recursiveGetChildById('ownOffer'), ownOffer or '', true)
    fillOffer(tradeWindow:recursiveGetChildById('partnerOffer'), partnerOffer or '', false)
end

local function updateState(fields)
    if not tradeWindow then return end
    local ownItems, partnerItems = fields[2] or '', fields[3] or ''
    local ownBank, partnerBank = tonumber(fields[4]) or 0, tonumber(fields[5]) or 0
    local ownBalance = tonumber(fields[6]) or 0
    local ownApproved, partnerApproved = fields[7] == '1', fields[8] == '1'
    local ownConfirmed, partnerConfirmed = fields[9] == '1', fields[10] == '1'
    updateOffers(ownItems, partnerItems)

    applyingState = true
    local bankInput = tradeWindow:recursiveGetChildById('bankInput')
    bankInput:setText(tostring(ownBank))
    bankInput:setEnabled(not ownApproved)
    applyingState = false
    tradeWindow:recursiveGetChildById('ownBalance'):setText(tr('Saldo disponivel: %s Ryou', formatValue(ownBalance)))
    tradeWindow:recursiveGetChildById('partnerBank'):setText(formatValue(partnerBank) .. ' Ryou')

    local hasOffer = ownItems ~= '' or partnerItems ~= '' or ownBank > 0 or partnerBank > 0
    tradeWindow:recursiveGetChildById('approveButton'):setEnabled(hasOffer and not ownApproved)
    tradeWindow:recursiveGetChildById('confirmButton'):setEnabled(ownApproved and partnerApproved and not ownConfirmed)
    local status
    if ownApproved and partnerApproved then
        status = ownConfirmed and tr('Confirmacao enviada. Aguardando o outro jogador.') or tr('Ofertas aprovadas. Confirme a troca.')
    elseif ownApproved then
        status = tr('Oferta aprovada. Aguardando o outro jogador.')
    elseif partnerApproved then
        status = tr('O outro jogador aprovou. Revise e aprove sua oferta.')
    else
        status = tr('Revise as duas ofertas antes de aprovar.')
    end
    tradeWindow:recursiveGetChildById('approvalStatus'):setText(status)
end

local function answerRequest(action)
    if requestBox then
        requestBox:destroy()
        requestBox = nil
    end
    send(action)
end

local function closeWindows()
    if bankUpdateEvent then removeEvent(bankUpdateEvent); bankUpdateEvent = nil end
    if requestBox then requestBox:destroy(); requestBox = nil end
    if tradeWindow then tradeWindow:destroy(); tradeWindow = nil end
end

local function openTrade(partnerName)
    closeWindows()
    tradeWindow = g_ui.createWidget('ModernTradeWindow', rootWidget)
    tradeWindow:recursiveGetChildById('statusLabel'):setText(tr('Negociando com %s', partnerName))
    tradeWindow:recursiveGetChildById('partnerLabel'):setText(partnerName)
    local bankInput = tradeWindow:recursiveGetChildById('bankInput')
    bankInput:setValidCharacters('0123456789')
    bankInput.onTextChange = function(widget, text)
        if applyingState then return end
        if bankUpdateEvent then removeEvent(bankUpdateEvent) end
        bankUpdateEvent = scheduleEvent(function()
            bankUpdateEvent = nil
            send('bank|' .. (text == '' and '0' or text))
        end, 250)
    end
    updateState({ 'state', '', '', '0', '0', '0', '0', '0', '0', '0' })
    tradeWindow.onClose = function()
        local window = tradeWindow
        tradeWindow = nil
        send('cancel')
        window:destroy()
    end
    tradeWindow.onDestroy = function() tradeWindow = nil end
    tradeWindow:show()
    tradeWindow:raise()
    tradeWindow:focus()
end

local function onExtendedOpcode(protocol, opcode, buffer)
    local fields = split(buffer, '|')
    local action, first, second = fields[1], fields[2], fields[3]
    if action == 'request' then
        closeWindows()
        requestBox = displayGeneralBox(tr('Solicitacao de troca'),
            tr('%s quer negociar com voce.', second), {
                { text = tr('Aceitar'), callback = function() answerRequest('accept') end },
                { text = tr('Recusar'), callback = function() answerRequest('reject') end }
            }, function() answerRequest('accept') end, function() answerRequest('reject') end)
    elseif action == 'pending' then
        displayInfoBox(tr('Troca'), tr('Solicitacao enviada para %s.', second))
    elseif action == 'open' then
        openTrade(second)
    elseif action == 'state' then
        updateState(fields)
    elseif action == 'cancel' then
        closeWindows()
        displayErrorBox(tr('Troca'), first)
    elseif action == 'error' then
        displayErrorBox(tr('Troca'), first)
    elseif action == 'complete' then
        closeWindows()
        displayInfoBox(tr('Troca'), first)
    end
end

function init()
    g_ui.importStyle('modern_trade')
    ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)
    connect(g_game, { onGameEnd = closeWindows })
end

function terminate()
    ProtocolGame.unregisterExtendedOpcode(OPCODE)
    disconnect(g_game, { onGameEnd = closeWindows })
    closeWindows()
end
