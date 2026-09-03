local OPCODE = 94
local inventoryButton
local actionsWindow
local permanentContainerId
local inventoryCapacity = 20
local maximumCapacity = 100

local function send(action)
    local protocol = g_game.getProtocolGame()
    if protocol then
        protocol:sendExtendedOpcode(OPCODE, action)
    end
end

local function openInventory()
    send('open')
end

local function onExtendedOpcode(protocol, opcode, buffer)
    local kind, containerId, capacity, maximum = buffer:match('^(%a+)|(%d+)|(%d+)|(%d+)$')
    if kind ~= 'inventory' then return end
    permanentContainerId = tonumber(containerId)
    inventoryCapacity = tonumber(capacity) or 20
    maximumCapacity = tonumber(maximum) or 100
end

function isPermanentContainer(container)
    return container and permanentContainerId == container:getId()
end

function configureContainer(container)
    if not isPermanentContainer(container) or not container.window then return false end

    local window = container.window
    local title = window:getChildById('miniwindowTitle')
    if title then
        title:setText(string.format('%s %d/%d', tr('Inventario'), container:getItemsCount(), inventoryCapacity))
    end

    local closeButton = window:recursiveGetChildById('closeButton')
    local minimizeButton = window:recursiveGetChildById('minimizeButton')
    local upButton = window:recursiveGetChildById('upButton')
    if closeButton then closeButton:setVisible(false) end
    if minimizeButton then minimizeButton:setVisible(false) end
    if upButton then upButton:setVisible(false) end

    window:setDraggable(false)
    window:setId('permanentInventoryWindow')
    window:setText(tr('Inventario permanente'))
    window.onClose = function() return false end
    window.onMousePress = function() return false end
    window.onMouseRelease = function() window:setDraggable(false) end
    window.maximumCapacity = maximumCapacity
    return true
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
    ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)
    connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    if g_game.isOnline() then
        onGameStart()
    end
end

function terminate()
    ProtocolGame.unregisterExtendedOpcode(OPCODE)
    disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    onGameEnd()
    if actionsWindow then
        actionsWindow:destroy()
        actionsWindow = nil
    end
end

function onGameStart()
    permanentContainerId = nil
    if not inventoryButton then
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
    scheduleEvent(openInventory, 500)
end

function onGameEnd()
    permanentContainerId = nil
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
