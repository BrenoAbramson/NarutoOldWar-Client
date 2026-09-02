local OPCODE = 94
local inventoryButton
local actionsWindow

local function send(action)
    local protocol = g_game.getProtocolGame()
    if protocol then
        protocol:sendExtendedOpcode(OPCODE, action)
    end
end

local function openInventory()
    send('open')
end

local function showActions()
    if not actionsWindow then
        actionsWindow = g_ui.displayUI('permanent_inventory')
    end
    actionsWindow:show()
    actionsWindow:raise()
    actionsWindow:focus()
end

function init()
    connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    if g_game.isOnline() then
        onGameStart()
    end
end

function terminate()
    disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    onGameEnd()
    if actionsWindow then
        actionsWindow:destroy()
        actionsWindow = nil
    end
end

function onGameStart()
    if inventoryButton then return end
    inventoryButton = modules.client_topmenu.addRightGameButton(
        'permanentInventoryButton', tr('Inventario permanente'),
        '/images/topbuttons/inventory', openInventory)
    inventoryButton.onMousePress = function(widget, mousePos, mouseButton)
        if mouseButton == MouseRightButton then
            showActions()
            return true
        end
        return false
    end
end

function onGameEnd()
    if inventoryButton then
        inventoryButton:destroy()
        inventoryButton = nil
    end
    if actionsWindow then
        actionsWindow:hide()
    end
end

function sortByName()
    send('sortName')
    actionsWindow:hide()
end

function sortByType()
    send('sortType')
    actionsWindow:hide()
end

function openDepot(tab)
    send('openDepot|' .. tostring(tab))
    actionsWindow:hide()
end

function openDelivery()
    send('openDelivery')
    actionsWindow:hide()
end

function closeActions()
    if actionsWindow then actionsWindow:hide() end
end
