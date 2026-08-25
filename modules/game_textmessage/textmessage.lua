MessageSettings = {
    none = {},
    consoleYellow = {
        color = TextColors.yellow,
        consoleTab = 'Local Chat'
    },
    consoleRed = {
        color = TextColors.red,
        consoleTab = 'Local Chat'
    },
    consoleOrange = {
        color = TextColors.orange,
        consoleTab = 'Local Chat'
    },
    consoleBlue = {
        color = TextColors.blue,
        consoleTab = 'Local Chat'
    },
    centerRed = {
        color = TextColors.red,
        consoleTab = 'Server Log',
        screenTarget = 'lowCenterLabel'
    },
    centerGreen = {
        color = TextColors.green,
        consoleTab = 'Server Log',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showInfoMessagesInConsole'
    },
    centerHKGreen = {
        color = TextColors.green,
        consoleTab = 'Server Log',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showHotkeyMessagesInConsole'
    },
    centerWhite = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'middleCenterLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    bottomWhite = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'statusLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    status = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'statusLabel',
        consoleOption = 'showStatusMessagesInConsole'
    },
    statusOwn = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        consoleOption = 'showStatusMessagesInConsole'
    },
    statusBoosted = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'statusLabel',
        consoleOption = 'showBoostedMessagesInConsole'
    },
    othersStatus = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        consoleOption = 'showOthersStatusMessagesInConsole'
    },
    statusSmall = {
        color = TextColors.white,
        screenTarget = 'statusLabel'
    },
    private = {
        color = TextColors.lightblue,
        consoleTab = 'Local Chat',
        screenTarget = 'privateLabel'
    },
    privateRed = {
        color = TextColors.red,
        consoleTab = 'Local Chat',
        private = true
    },
    privatePlayerToPlayer = {
        color = TextColors.blue,
        consoleTab = 'Local Chat',
        private = true
    },
    privatePlayerToNpc = {
        color = TextColors.blue,
        consoleTab = 'Local Chat',
        private = true,
        npcChat = true
    },
    privateNpcToPlayer = {
        color = TextColors.lightblue,
        consoleTab = 'Local Chat',
        private = true,
        npcChat = true
    },
    channelYellow = {
        color = TextColors.yellow
    },
    channelWhite = {
        color = TextColors.white
    },
    channelRed = {
        color = TextColors.red
    },
    channelOrange = {
        color = TextColors.orange
    },
    monsterSay = {
        color = TextColors.orange,
        hideInConsole = true
    },
    monsterYell = {
        color = TextColors.orange,
        hideInConsole = true
    },
    potion = {
        color = TextColors.orange,
        hideInConsole = true
    },
    loot = {
        color = TextColors.white,
        consoleTab = 'Loot',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showInfoMessagesInConsole',
        colored = true
    },
    valuableLoot = {
        color = TextColors.white,
        consoleTab = 'Loot',
        screenTarget = 'statusLabel',
        consoleOption = 'showInfoMessagesInConsole',
        colored = true
    }
}

MessageTypes = {
    [MessageModes.Say] = MessageSettings.consoleYellow,
    [MessageModes.Whisper] = MessageSettings.consoleYellow,
    [MessageModes.Yell] = MessageSettings.consoleYellow,
    [MessageModes.MonsterSay] = MessageSettings.monsterSay,
    [MessageModes.MonsterYell] = MessageSettings.monsterYell,
    [MessageModes.BarkLow] = MessageSettings.consoleOrange,
    [MessageModes.BarkLoud] = MessageSettings.consoleOrange,
    [MessageModes.Failure] = MessageSettings.statusSmall,
    [MessageModes.Login] = MessageSettings.bottomWhite,
    [MessageModes.Game] = MessageSettings.centerWhite,
    [MessageModes.Status] = MessageSettings.status,
    [MessageModes.Warning] = MessageSettings.centerRed,
    [MessageModes.Look] = MessageSettings.centerGreen,
    [MessageModes.Loot] = MessageSettings.loot,
    [MessageModes.Red] = MessageSettings.consoleRed,
    [MessageModes.Blue] = MessageSettings.consoleBlue,
    [MessageModes.PrivateFrom] = MessageSettings.private,
    [MessageModes.PrivateTo] = MessageSettings.privatePlayerToPlayer,
    [MessageModes.GamemasterPrivateFrom] = MessageSettings.privateRed,
    [MessageModes.NpcTo] = MessageSettings.privatePlayerToNpc,
    [MessageModes.NpcFrom] = MessageSettings.privateNpcToPlayer,
    [MessageModes.NpcFromStartBlock] = MessageSettings.privateNpcToPlayer,
    [MessageModes.Channel] = MessageSettings.channelYellow,
    [MessageModes.ChannelManagement] = MessageSettings.channelWhite,
    [MessageModes.GamemasterChannel] = MessageSettings.channelRed,
    [MessageModes.ChannelHighlight] = MessageSettings.channelOrange,
    [MessageModes.Spell] = MessageSettings.consoleYellow,
    [MessageModes.RVRChannel] = MessageSettings.channelWhite,
    [MessageModes.RVRContinue] = MessageSettings.consoleYellow,

    [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,

    [MessageModes.DamageDealed] = MessageSettings.statusOwn,
    [MessageModes.DamageReceived] = MessageSettings.statusOwn,
    [MessageModes.Heal] = MessageSettings.statusOwn,
    [MessageModes.Exp] = MessageSettings.statusOwn,

    [MessageModes.DamageOthers] = MessageSettings.statusOwn,
    [MessageModes.HealOthers] = MessageSettings.statusOwn,
    [MessageModes.ExpOthers] = MessageSettings.statusOwn,
    [MessageModes.Potion] = MessageSettings.potion,

    [MessageModes.TradeNpc] = MessageSettings.centerGreen,
    [MessageModes.Guild] = MessageSettings.statusOwn,
    [MessageModes.Party] = MessageSettings.statusOwn,
    [MessageModes.PartyManagement] = MessageSettings.centerGreen,
    [MessageModes.TutorialHint] = MessageSettings.statusSmall,
    [MessageModes.BeyondLast] = MessageSettings.centerWhite,
    [MessageModes.Report] = MessageSettings.centerWhite,
    [MessageModes.GameHighlight] = MessageSettings.centerRed,
    [MessageModes.HotkeyUse] = MessageSettings.centerGreen,
    [MessageModes.Attention] = MessageSettings.bottomWhite,
    [MessageModes.BoostedCreature] = MessageSettings.centerWhite,
    [MessageModes.OfflineTrainning] = MessageSettings.centerWhite,
    [MessageModes.Transaction] = MessageSettings.centerWhite,
    [MessageModes.ValuableLoot] = MessageSettings.valuableLoot,

    [254] = MessageSettings.private
}

messagesPanel = nil
houseManagementWindow = nil

local function setHouseButtonState(isOn)
    if modules.game_cyclopedia and modules.game_cyclopedia.setHouseButtonState then
        modules.game_cyclopedia.setHouseButtonState(isOn)
    end
end

function closeHouseManagementWindow()
    if houseManagementWindow then
        local window = houseManagementWindow
        houseManagementWindow = nil
        window:destroy()
    end
    setHouseButtonState(false)
end

local function prepareHouseManagementWindow()
    if houseManagementWindow then
        local window = houseManagementWindow
        houseManagementWindow = nil
        window:destroy()
    end
    setHouseButtonState(true)
end

function init()
    for messageMode, _ in pairs(MessageTypes) do
        registerMessageMode(messageMode, displayMessage)
    end

    connect(g_game, 'onGameEnd', clearMessages)
    messagesPanel = g_ui.loadUI('textmessage', modules.game_interface.getRootPanel())
end

function terminate()
    for messageMode, _ in pairs(MessageTypes) do
        unregisterMessageMode(messageMode, displayMessage)
    end

    disconnect(g_game, 'onGameEnd', clearMessages)
    clearMessages()
    messagesPanel:destroy()
    messagesPanel = nil
end

function calculateVisibleTime(text)
    return math.max(#text * 50, 4000)
end

function displayMessage(mode, text)

    if not g_game.isOnline() then
        return
    end
    if modules.game_cyclopedia and modules.game_cyclopedia.onOrganizationMessage and
        modules.game_cyclopedia.onOrganizationMessage(text) then
        return
    end
    if text == 'HOUSE_NONE' then
        prepareHouseManagementWindow()
        local function closeWindow()
            closeHouseManagementWindow()
        end
        houseManagementWindow = displayGeneralBox('Casas', 'Voc\234 ainda n\227o possui uma casa.', {
            { text = 'Ok', callback = closeWindow }
        }, closeWindow, closeWindow)
        return
    end
    if text:sub(1, 13) == 'HOUSE_MANAGE|' then
        prepareHouseManagementWindow()
        local fields = text:split('|')
        local name = fields[2] ~= '' and fields[2] or 'Casa'
        local rent = fields[3] or '0'
        local paidUntil = tonumber(fields[4]) or 0
        local isGuildHouse = fields[5] == '1'
        local houseType = isGuildHouse and 'Casa de guilda' or 'Casa de jogador'
        local members = fields[6] or ''
        local dueDate = paidUntil > 0 and os.date('%d/%m/%Y', paidUntil) or 'N\227o definido'
        local description = string.format('%s\n\n%s\n%s: %s Ryous\n%s: %s',
            name, houseType, 'Aluguel mensal', rent, 'Pr\243ximo pagamento', dueDate)
        if isGuildHouse then
            description = description .. '\n\nMembros autorizados:\n' .. (members ~= '' and members or 'Nenhum')
        end
        local function closeManageWindow()
            closeHouseManagementWindow()
        end
        local buttons = {{ text = 'Fechar', callback = closeManageWindow }}
        table.insert(buttons, 1, { text = 'Transferir', callback = function()
            closeManageWindow()
            displayTextInputBox('Transferir casa', 'Nome do jogador:', function(value)
                if value and value ~= '' then g_game.talk('/sellhouse ' .. value) end
            end)
        end })
        if isGuildHouse then
            table.insert(buttons, 1, { text = 'Remover', callback = function()
                closeManageWindow()
                displayTextInputBox('Remover membro', 'Nome do jogador:', function(value)
                    if value and value ~= '' then g_game.talk('/removermembrocasa ' .. value) end
                end)
            end })
            table.insert(buttons, 1, { text = 'Adicionar', callback = function()
                closeManageWindow()
                displayTextInputBox('Adicionar membro', 'Nome do jogador:', function(value)
                    if value and value ~= '' then g_game.talk('/adicionarmembrocasa ' .. value) end
                end)
            end })
        end
        houseManagementWindow = displayGeneralBox('Gerenciamento da Casa', description, buttons,
            closeManageWindow, closeManageWindow)
        return
    end
    if text:sub(1, 10) == 'HOUSE_BUY|' then
        local fields = text:split('|')
        local houseId = fields[2] or '0'
        local name = fields[3] ~= '' and fields[3] or 'Casa'
        local price = fields[4] or '0'
        local rent = fields[5] or '0'
        local premium = fields[6] == '1' and 'Sim' or 'N\227o'
        local guild = fields[7] == '1' and 'L\237der de guilda' or 'N\227o'
        local description = string.format('%s\n\nPre\231o de compra: %s Ryous\nAluguel mensal: %s Ryous\nPremium: %s\nGuilda: %s',
            name, price, rent, premium, guild)
        local buyWindow
        local function closeBuyWindow()
            if buyWindow then buyWindow:destroy() buyWindow = nil end
        end
        local function confirmPurchase()
            closeBuyWindow()
            g_game.talk('/confirmarcomprarcasa ' .. houseId)
        end
        buyWindow = displayGeneralBox('Comprar Casa', description, {
            { text = 'Cancelar', callback = closeBuyWindow },
            { text = 'Comprar', callback = confirmPurchase }
        }, confirmPurchase, closeBuyWindow)
        return
    end
    if g_game.getClientVersion() >= 1300 then
        MessageTypes[MessageModes.Loot] = MessageSettings.loot
        MessageTypes[MessageModes.ValuableLoot] = MessageSettings.valuableLoot
        MessageTypes[MessageModes.Guild] = MessageSettings.statusOwn
        MessageTypes[MessageModes.Party] = MessageSettings.statusOwn
    else
        MessageTypes[MessageModes.PrivateFrom] = MessageSettings.privateNpcToPlayer
        MessageTypes[MessageModes.Loot] = MessageSettings.centerGreen
        MessageTypes[MessageModes.ValuableLoot] = MessageSettings.centerGreen
        MessageTypes[MessageModes.Guild] = MessageSettings.centerGreen
        MessageTypes[MessageModes.Party] = MessageSettings.centerGreen
        MessageTypes[MessageModes.MonsterSay] = MessageSettings.consoleOrange
        MessageTypes[MessageModes.MonsterYell] = MessageSettings.consoleOrange
    end
    local msgtype = MessageTypes[mode]
    if not msgtype then
        return
    end

    if msgtype == MessageSettings.none then
        return
    end

    if msgtype.consoleTab ~= nil and
        (msgtype.consoleOption == nil or modules.client_options.getOption(msgtype.consoleOption)) then
        if msgtype == MessageSettings.loot or msgtype == MessageSettings.valuableLoot then
            local lootColoredText = ItemsDatabase.setColorLootMessage(text)
            local lootTabName = tr(msgtype.consoleTab)
            local targetTab = modules.game_console.getTab(lootTabName) and lootTabName or tr("Server Log")
            modules.game_console.addText(lootColoredText, msgtype, targetTab)
        else
            modules.game_console.addText(text, msgtype, tr(msgtype.consoleTab))
        end
    end

    if msgtype.screenTarget then
        local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
        if msgtype == MessageSettings.loot and not modules.client_options.getOption('showLootMessagesOnScreen') then
            return
        elseif msgtype == MessageSettings.loot or msgtype == MessageSettings.valuableLoot then
            local coloredText = ItemsDatabase.setColorLootMessage(text)
            label:setColoredText(coloredText)
        else
            label:setText(text)
            label:setColor(msgtype.color)
        end

        label:setVisible(true)
        removeEvent(label.hideEvent)
        label.hideEvent = scheduleEvent(function()
            label:setVisible(false)
        end, calculateVisibleTime(text))
    end
end

function displayPrivateMessage(text)
    if not g_game.isOnline() then
        return
    end
    
    local msgtype = MessageSettings.private
    if not msgtype or not msgtype.screenTarget then
        return
    end
    
    local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
    if not label then
        return
    end
    
    label:setText(text)
    label:setColor(msgtype.color)
    label:setVisible(true)
    removeEvent(label.hideEvent)
    label.hideEvent = scheduleEvent(function()
        label:setVisible(false)
    end, calculateVisibleTime(text))
end

function displayStatusMessage(text)
    displayMessage(MessageModes.Status, text)
end

function displayFailureMessage(text)
    displayMessage(MessageModes.Failure, text)
end

function displayGameMessage(text)
    displayMessage(MessageModes.Game, text)
end

function displayBroadcastMessage(text)
    displayMessage(MessageModes.Warning, text)
end

function clearMessages()
    closeHouseManagementWindow()
    for _i, child in pairs(messagesPanel:recursiveGetChildren()) do
        if child:getId():match('Label') then
            child:hide()
            removeEvent(child.hideEvent)
        end
    end
end

function LocalPlayer:onAutoWalkFail(player)
    modules.game_textmessage.displayFailureMessage(tr('There is no way.'))
end
