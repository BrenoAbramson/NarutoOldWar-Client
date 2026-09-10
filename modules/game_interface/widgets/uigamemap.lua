UIGameMap = extends(UIMap, 'UIGameMap')

local function logDragDiagnostic(message, ...)
    if modules.game_interface and modules.game_interface.isClientDiagnosticsEnabled and
       modules.game_interface.isClientDiagnosticsEnabled() then
        g_logger.info(string.format('[DRAG-DIAG] ' .. message, ...))
    end
end

local function describeDragThing(thing)
    if not thing then
        return 'none'
    end

    local position = thing:getPosition()
    local positionText = position and string.format('%d,%d,%d', position.x, position.y, position.z) or 'none'
    local stack = -1
    local tile = thing:getTile()
    if tile then
        stack = tile:getThingStackPos(thing)
    end

    return string.format('id=%s item=%s creature=%s notMoveable=%s position=%s stack=%s',
        thing:getId(), tostring(thing:isItem()), tostring(thing:isCreature()),
        tostring(thing:isNotMoveable()), positionText, stack)
end

function UIGameMap.create()
    local gameMap = UIGameMap.internalCreate()
    gameMap:setKeepAspectRatio(true)
    gameMap:setVisibleDimension({
        width = 15,
        height = 11
    })
    gameMap:setDrawLights(true)
    return gameMap
end

function UIGameMap:onDragEnter(mousePos)
    local tile = self:getTile(mousePos)
    if not tile then
        logDragDiagnostic('enter rejected reason=no-tile mouse=%d,%d', mousePos.x, mousePos.y)
        return false
    end

    local thing = tile:getTopMoveThing()
    if not thing then
        local position = tile:getPosition()
        logDragDiagnostic('enter rejected reason=no-thing tile=%d,%d,%d', position.x, position.y, position.z)
        return false
    end

    logDragDiagnostic('enter selected %s', describeDragThing(thing))

    if thing:isItem() and not thing:isNotMoveable() then
        UIDragIcon:display(thing)
    end

    self.currentDragThing = thing

    -- Use native cursor when enabled, otherwise use custom cursor
    if modules.client_options and modules.client_options.getOption('nativeCursor') then
        g_window.setSystemCursor('cross')
    else
        g_mouse.pushCursor('target')
    end
    self.allowNextRelease = false
    return true
end

function UIGameMap:onDragLeave(droppedWidget, mousePos)
    logDragDiagnostic('leave droppedWidget=%s current=%s', tostring(droppedWidget ~= nil),
        describeDragThing(self.currentDragThing))
    self.currentDragThing = nil
    self.hoveredWho = nil
    -- Restore cursor
    if modules.client_options and modules.client_options.getOption('nativeCursor') then
        g_window.restoreMouseCursor()
    else
        g_mouse.popCursor('target')
    end
    UIDragIcon:hide()
    return true
end

function UIGameMap:onDrop(widget, mousePos)
    if not self:canAcceptDrop(widget, mousePos) then
        logDragDiagnostic('drop rejected reason=target-widget current=%s',
            describeDragThing(widget and widget.currentDragThing))
        return false
    end

    local tile = self:getTile(mousePos)
    if not tile then
        logDragDiagnostic('drop rejected reason=no-destination-tile')
        return false
    end

    local thing = widget.currentDragThing
    local thingPos = thing:getPosition()
    if not thingPos then
        logDragDiagnostic('drop rejected reason=no-source-position current=%s', describeDragThing(thing))
        return false
    end

    local thingTile = thing:getTile()
    if thingPos.x ~= 65535 then
        if not thingTile then
            logDragDiagnostic('drop rejected reason=no-source-tile current=%s', describeDragThing(thing))
            return false
        end
        if thingTile:getThingStackPos(thing) == -1 then
            logDragDiagnostic('drop rejected reason=source-thing-missing current=%s', describeDragThing(thing))
            return false
        end
    end

    local toPos = tile:getPosition()
    if thingPos.x == toPos.x and thingPos.y == toPos.y and thingPos.z == toPos.z then
        logDragDiagnostic('drop rejected reason=same-position current=%s', describeDragThing(thing))
        return false
    end

    logDragDiagnostic('drop sending %s destination=%d,%d,%d count=%s', describeDragThing(thing),
        toPos.x, toPos.y, toPos.z, thing:isItem() and thing:getCount() or 1)

    if thing:isItem() and thing:getCount() > 1 then
        modules.game_interface.moveStackableItem(thing, toPos)
    else
        g_game.move(thing, toPos, 1)
    end

    UIDragIcon:hide()
    return true
end

function UIGameMap:onMousePress()
    if not self:isDragging() then
        self.allowNextRelease = true
    end
end

function UIGameMap:onMouseMove()
    return false
end

function UIGameMap:onMouseRelease(mousePosition, mouseButton)
    if not self.allowNextRelease then
        return true
    end

    local autoWalkPos = self:getPosition(mousePosition)

    -- happens when clicking outside of map boundaries
    if not autoWalkPos then
        return false
    end

    local localPlayerPos = g_game.getLocalPlayer():getPosition()
    if autoWalkPos.z ~= localPlayerPos.z then
        local dz = autoWalkPos.z - localPlayerPos.z
        autoWalkPos.x = autoWalkPos.x + dz
        autoWalkPos.y = autoWalkPos.y + dz
        autoWalkPos.z = localPlayerPos.z
    end

    local lookThing
    local useThing
    local creatureThing
    local multiUseThing
    local attackCreature

    local tile = self:getTile(mousePosition)
    if tile then
        lookThing = tile:getTopLookThing()
        useThing = tile:getTopUseThing()
        creatureThing = tile:getTopCreature()
    end

    local autoWalkTile = g_map.getTile(autoWalkPos)
    if autoWalkTile then
        attackCreature = autoWalkTile:getTopCreature()
    end

    local ret = modules.game_interface.processMouseAction(mousePosition, mouseButton, autoWalkPos, lookThing, useThing,
        creatureThing, attackCreature)
    if ret then
        self.allowNextRelease = false
    end

    return ret
end

function UIGameMap:canAcceptDrop(widget, mousePos)
    if not widget or not widget.currentDragThing then
        logDragDiagnostic('accept rejected reason=no-drag-widget-or-thing')
        return false
    end

    local children = rootWidget:recursiveGetChildrenByPos(mousePos)
    for i = 1, #children do
        local child = children[i]
        if child == self then
            return true
        elseif not child:isPhantom() then
            logDragDiagnostic('accept rejected reason=blocking-widget class=%s id=%s',
                child:getClassName(), child:getId())
            return false
        end
    end

    error('Widget ' .. self:getId() .. ' not in drop list.')
    return false
end
