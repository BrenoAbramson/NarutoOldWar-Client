local OPCODE = 94
local DEPOT_CLIENT_ID = 8088
local selectorWindow
local pendingContainerTitle

local function send(action)
    local protocol = g_game.getProtocolGame()
    if protocol then
        protocol:sendExtendedOpcode(OPCODE, action)
    end
end

local function closeSelector()
    if selectorWindow then selectorWindow:hide() end
end

local function onContainerOpen(container)
    if not pendingContainerTitle or container:getName():lower() ~= 'depot chest' then return end

    local title = pendingContainerTitle
    pendingContainerTitle = nil
    scheduleEvent(function()
        if not container.window then return end
        local titleWidget = container.window:getChildById('miniwindowTitle')
        if titleWidget then
            titleWidget:setText(title)
        else
            container.window:setText(title)
        end
    end, 0)
end

local function showSelector(unlockedTabs)
    if not selectorWindow then
        selectorWindow = g_ui.displayUI('depot_selector')
    end

    for tab = 1, 3 do
        local requestedTab = tab
        local button = selectorWindow:getChildById('depotSelect' .. tab)
        local unlocked = tab <= unlockedTabs
        button:getChildById('lockedIcon'):setVisible(not unlocked)
        button:setTooltip(unlocked and tr('Deposito %d', tab) or tr('Deposito %d - requer VIP', tab))
        button.onClick = function()
            if not unlocked then
                displayErrorBox(tr('Deposito bloqueado'), tr('Esta aba requer VIP.'))
                return
            end
            closeSelector()
            pendingContainerTitle = string.format('Bau %d', requestedTab)
            send('openDepot|' .. requestedTab)
        end
    end

    selectorWindow:getChildById('depotSelectDelivery').onClick = function()
        closeSelector()
        pendingContainerTitle = 'Bau de entrega'
        send('openDelivery')
    end
    selectorWindow:show()
    selectorWindow:raise()
    selectorWindow:focus()
    g_logger.info(string.format('[DEPOT-DIAG] selector displayed unlockedTabs=%d', unlockedTabs))
end

local function onExtendedOpcode(protocol, opcode, buffer)
    if buffer == 'depotClose' then
        pendingContainerTitle = nil
        closeSelector()
        return
    end
    local unlockedTabs = buffer:match('^depotMenu|(%d+)$')
    if not unlockedTabs then return end
    g_logger.info(string.format('[DEPOT-DIAG] selector received unlockedTabs=%s', unlockedTabs))
    showSelector(tonumber(unlockedTabs) or 1)
end

function init()
    g_logger.info('[DEPOT-DIAG] depot selector module loaded')
    ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)
    connect(Container, { onOpen = onContainerOpen })
end

function terminate()
    ProtocolGame.unregisterExtendedOpcode(OPCODE)
    disconnect(Container, { onOpen = onContainerOpen })
    pendingContainerTitle = nil
    if selectorWindow then
        selectorWindow:destroy()
        selectorWindow = nil
    end
end

function tryOpen(thing, parentContainer)
    if not thing or thing:getId() ~= DEPOT_CLIENT_ID then return false end
    if parentContainer then
        g_game.open(thing, parentContainer)
    else
        g_game.open(thing)
    end
    return true
end

function close()
    closeSelector()
end
