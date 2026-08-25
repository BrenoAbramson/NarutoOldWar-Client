Cyclopedia = {}

trackerButton = nil
trackerMiniWindow = nil
trackerButtonBosstiary = nil
trackerMiniWindowBosstiary = nil
contentContainer = nil

local buttonSelection = nil
local items = nil
local bestiary = nil
local charms = nil
local map = nil
local houses = nil
local character = nil
local CyclopediaButton = nil
local HouseButton = nil
local OrganizationButton = nil
local OrganizationWindow = nil
local organizationState = { members = {}, invitations = {}, outgoingInvitations = {}, role = 0 }
local organizationSelected = nil
local organizationSection = 'members'
local bosstiary = nil
local bossSlot = nil
local ButtonBossSlot = nil
local ButtonBestiary = nil
local tabStack = {}
local previousType = nil
local windowTypes = {}
local magicalArchives = nil
function toggle(defaultWindow)
    if not controllerCyclopedia.ui then
        return
    end
    if controllerCyclopedia.ui:isVisible() then
        return hide()
    end
    show(defaultWindow)
end

controllerCyclopedia = Controller:new()
controllerCyclopedia:setUI('game_cyclopedia')

function controllerCyclopedia:onInit()
    -- pre m_gameInitialized
    self:registerEvents(g_game, {
        onParseCyclopediaTracker = function(trackerType, data)
            if Cyclopedia.onParseCyclopediaTracker then
                Cyclopedia.onParseCyclopediaTracker(trackerType, data)
            end
        end
    })
end

function hideOrganizationWindow()
    if OrganizationWindow then
        OrganizationWindow:hide()
    end
    if OrganizationButton then
        OrganizationButton:setOn(false)
    end
end

function toggleOrganizationWindow()
    if not OrganizationWindow then
        return
    end

    if OrganizationWindow:isVisible() then
        hideOrganizationWindow()
        return
    end

    OrganizationWindow:show()
    OrganizationWindow:raise()
    OrganizationWindow:focus()
    if OrganizationButton then
        OrganizationButton:setOn(true)
    end
    g_game.talk('/organizacaojanela refresh')
end

local function organizationWidget(id)
    return OrganizationWindow and OrganizationWindow:recursiveGetChildById(id) or nil
end

local function organizationRoleName(role)
    if role == 3 then return 'L\237der' end
    if role == 2 then return 'Vice-l\237der' end
    return 'Membro'
end

local function organizationClearActions()
    for _, id in ipairs({'playerNameEdit', 'inviteButton', 'acceptButton', 'declineButton', 'promoteButton', 'demoteButton', 'kickButton'}) do
        local widget = organizationWidget(id)
        if widget then widget:setVisible(false) end
    end
end

local function organizationAddOption(text, section)
    local list = organizationWidget('optionList')
    if not list then return end
    local button = g_ui.createWidget('Button', list)
    button:setText(text)
    button:setHeight(28)
    button.onClick = function()
        organizationSection = section
        modules.game_cyclopedia.renderOrganizationWindow()
    end
end

local function organizationSelect(entry, kind)
    organizationSelected = { entry = entry, kind = kind }
    modules.game_cyclopedia.renderOrganizationWindow()
end

local function organizationAddRow(text, entry, kind)
    local list = organizationWidget('contentList')
    if not list then return end
    local row = g_ui.createWidget('Button', list)
    row:setText(text)
    row:setHeight(27)
    row:setTextAlign(AlignLeft)
    row.onClick = function() organizationSelect(entry, kind) end
end

local function organizationAddMembersHeader()
    local list = organizationWidget('contentList')
    if not list then return end
    local header = g_ui.createWidget('OrganizationMemberHeader', list)
    header:getChildById('levelColumn'):setText('N\237vel')
end

local function organizationAddMemberRow(member)
    local list = organizationWidget('contentList')
    if not list then return end
    local row = g_ui.createWidget('OrganizationMemberRow', list)
    row:getChildById('nameColumn'):setText(member.name)
    row:getChildById('roleColumn'):setText(organizationRoleName(member.role))
    row:getChildById('statusColumn'):setText(member.online and 'Online' or 'Offline')
    row:getChildById('levelColumn'):setText(tostring(member.level))
    row.onClick = function() organizationSelect(member, 'member') end
end

function renderOrganizationWindow()
    if not OrganizationWindow then return end
    local options = organizationWidget('optionList')
    local content = organizationWidget('contentList')
    if options then options:destroyChildren() end
    if content then content:destroyChildren() end
    organizationClearActions()

    local nameLabel = organizationWidget('organizationName')
    local title = organizationWidget('sectionTitle')
    local detail = organizationWidget('detailText')
    local leave = organizationWidget('leaveButton')
    if nameLabel then nameLabel:setText(organizationState.name or 'Sem organiza\231\227o') end
    if leave then leave:setVisible(organizationState.id ~= nil) end

    if not organizationState.id then
        organizationSection = 'invitations'
        organizationAddOption('Convites', 'invitations')
        if title then title:setText('Convites recebidos') end
        if detail then detail:setText('Selecione um convite para aceitar ou recusar.') end
        for _, invite in ipairs(organizationState.invitations) do
            organizationAddRow(invite.name .. ' - convidado por ' .. invite.inviter, invite, 'invite')
        end
        if #organizationState.invitations == 0 and detail then detail:setText('Voc\234 n\227o possui convites ativos.') end
    else
        organizationAddOption('Resumo', 'summary')
        organizationAddOption('Membros', 'members')
        if organizationState.role >= 2 then
            organizationAddOption('Convites', 'outgoing')
            organizationAddOption('Gerenciamento', 'management')
        end

        if organizationSection == 'summary' then
            if title then title:setText('Resumo') end
            if detail then
                detail:setText(string.format('%s\nSeu cargo: %s\nMembros: %d/%d\nCriada em: %s',
                    organizationState.name, organizationRoleName(organizationState.role),
                    organizationState.memberCount or #organizationState.members, organizationState.memberLimit or 10,
                    os.date('%d/%m/%Y', organizationState.createdAt or 0)))
            end
        elseif organizationSection == 'outgoing' then
            if title then title:setText('Convites enviados') end
            if detail then detail:setText('Convites ativos enviados pela organiza\231\227o.') end
            for _, invite in ipairs(organizationState.outgoingInvitations) do
                organizationAddRow(invite.playerName .. ' - expira em ' .. os.date('%d/%m/%Y', invite.expiresAt), invite, 'outgoing')
            end
            if #organizationState.outgoingInvitations == 0 and detail then detail:setText('Nenhum convite ativo enviado.') end
        elseif organizationSection == 'management' then
            if title then title:setText('Gerenciamento') end
            if detail then detail:setText('Digite o nome de um jogador ou clique com o bot\227o direito nele para convidar.') end
            organizationWidget('playerNameEdit'):setVisible(true)
            organizationWidget('inviteButton'):setVisible(true)
        else
            organizationSection = 'members'
            if title then title:setText('Membros') end
            if detail then detail:setText('Selecione um membro para visualizar os dados.') end
            organizationAddMembersHeader()
            table.sort(organizationState.members, function(a, b)
                if a.role ~= b.role then return a.role > b.role end
                return a.name:lower() < b.name:lower()
            end)
            for _, member in ipairs(organizationState.members) do
                organizationAddMemberRow(member)
            end
        end
    end

    if organizationSelected then
        local selected = organizationSelected.entry
        if organizationSelected.kind == 'member' and organizationSection == 'members' then
            if detail then detail:setText(string.format('Nome: %s\nCargo: %s\nEstado: %s\nN\237vel: %d\nEntrou em: %s',
                selected.name, organizationRoleName(selected.role), selected.online and 'Online' or 'Offline',
                selected.level, os.date('%d/%m/%Y', selected.joinedAt))) end
            if organizationState.role == 3 and selected.role == 1 then organizationWidget('promoteButton'):setVisible(true) end
            if organizationState.role == 3 and selected.role == 2 then organizationWidget('demoteButton'):setVisible(true) end
            if organizationState.role >= 2 and selected.role < organizationState.role then organizationWidget('kickButton'):setVisible(true) end
        elseif organizationSelected.kind == 'invite' and not organizationState.id then
            if detail then detail:setText('Organiza\231\227o: ' .. selected.name .. '\nConvidado por: ' .. selected.inviter ..
                '\nExpira em: ' .. os.date('%d/%m/%Y', selected.expiresAt)) end
            organizationWidget('acceptButton'):setVisible(true)
            organizationWidget('declineButton'):setVisible(true)
        end
    end
end

function onOrganizationMessage(text)
    if text == 'ORG_BEGIN' then
        organizationState = { members = {}, invitations = {}, outgoingInvitations = {}, role = 0 }
        organizationSelected = nil
        return true
    elseif text == 'ORG_NONE' then
        return true
    elseif text == 'ORG_END' then
        renderOrganizationWindow()
        return true
    elseif text:sub(1, 9) == 'ORG_INFO|' then
        local f = text:split('|')
        organizationState.id = tonumber(f[2])
        organizationState.name = f[3]
        organizationState.role = tonumber(f[4]) or 0
        organizationState.createdAt = tonumber(f[5]) or 0
        organizationState.memberCount = tonumber(f[6]) or 0
        organizationState.memberLimit = tonumber(f[7]) or 10
        return true
    elseif text:sub(1, 11) == 'ORG_MEMBER|' then
        local f = text:split('|')
        table.insert(organizationState.members, { guid = tonumber(f[2]), name = f[3], role = tonumber(f[4]) or 1,
            online = f[5] == '1', level = tonumber(f[6]) or 0, joinedAt = tonumber(f[7]) or 0, title = f[8] or '' })
        return true
    elseif text:sub(1, 11) == 'ORG_INVITE|' then
        local f = text:split('|')
        table.insert(organizationState.invitations, { id = tonumber(f[2]), name = f[3], inviter = f[4], expiresAt = tonumber(f[5]) or 0 })
        return true
    elseif text:sub(1, 15) == 'ORG_OUT_INVITE|' then
        local f = text:split('|')
        table.insert(organizationState.outgoingInvitations, { playerName = f[2], inviter = f[3], expiresAt = tonumber(f[4]) or 0 })
        return true
    end
    return false
end

function organizationInvitePlayer(name)
    if name and name ~= '' and organizationState.role >= 2 then
        g_game.talk('/organizacaojanela invite ' .. name)
    end
end

function organizationInviteFromField()
    local edit = organizationWidget('playerNameEdit')
    if edit then organizationInvitePlayer(edit:getText()) end
end

function canInviteToOrganization()
    return organizationState.id ~= nil and organizationState.role >= 2
end

function organizationAcceptSelected()
    if organizationSelected then g_game.talk('/organizacaojanela accept ' .. organizationSelected.entry.id) end
end

function organizationDeclineSelected()
    if organizationSelected then g_game.talk('/organizacaojanela decline ' .. organizationSelected.entry.id) end
end

function organizationPromoteSelected()
    if organizationSelected then g_game.talk('/organizacaojanela promote ' .. organizationSelected.entry.name) end
end

function organizationDemoteSelected()
    if organizationSelected then g_game.talk('/organizacaojanela demote ' .. organizationSelected.entry.name) end
end

function organizationKickSelected()
    if organizationSelected then g_game.talk('/organizacaojanela kick ' .. organizationSelected.entry.name) end
end

function organizationConfirmLeave()
    if not organizationState.name then return end
    local first
    local function closeFirst() if first then first:destroy() first = nil end end
    local function continueLeave()
        closeFirst()
        displayTextInputBox('Confirmar sa\237da', 'Digite exatamente o nome da organiza\231\227o:\n' .. organizationState.name, function(value)
            if value and value ~= '' then g_game.talk('/organizacaojanela leave ' .. value) end
        end)
    end
    first = displayGeneralBox('Sair da organiza\231\227o', 'Tem certeza de que deseja sair de ' .. organizationState.name .. '?', {
        { text = 'Cancelar', callback = closeFirst }, { text = 'Continuar', callback = continueLeave }
    }, continueLeave, closeFirst)
end

function setHouseButtonState(isOn)
    if HouseButton then
        HouseButton:setOn(isOn)
    end
end

function toggleHouseWindow()
    if not HouseButton then
        return
    end

    if HouseButton:isOn() then
        if modules.game_textmessage and modules.game_textmessage.closeHouseManagementWindow then
            modules.game_textmessage.closeHouseManagementWindow()
        end
        HouseButton:setOn(false)
        return
    end

    HouseButton:setOn(true)
    g_game.talk('/gerenciarcasa')
end

function controllerCyclopedia:onGameStart()
    local versionClient = g_game.getClientVersion()
    if not OrganizationWindow then
        OrganizationWindow = g_ui.displayUI('organization')
        OrganizationWindow:setText('Organiza' .. string.char(0xE7, 0xF5) .. 'es')
        OrganizationWindow.onClose = hideOrganizationWindow
        OrganizationWindow:hide()
    end
    HouseButton = modules.game_mainpanel.addToggleButton('HouseButton', 'Casas',
        '/images/options/house', toggleHouseWindow, false, 8)
    HouseButton:setOn(false)
    HouseButton:setVisible(true)
    local organizationTooltip = 'Organiza' .. string.char(0xE7, 0xF5) .. 'es'
    OrganizationButton = modules.game_mainpanel.addToggleButton('OrganizationButton', organizationTooltip,
        '/images/options/button_organization', toggleOrganizationWindow, false, 10)
    OrganizationButton:setOn(false)
    OrganizationButton:setVisible(true)
    if versionClient < 1310 then
        return
    else
        CyclopediaButton = modules.game_mainpanel.addToggleButton('CyclopediaButton', tr('Cyclopedia'),
            '/images/options/cooldowns', function() toggle("items") end, false, 7)
        CyclopediaButton:setOn(false)

        contentContainer = controllerCyclopedia.ui:recursiveGetChildById('contentContainer')
        buttonSelection = controllerCyclopedia.ui:recursiveGetChildById('buttonSelection')
        items = buttonSelection:recursiveGetChildById('items')
        bestiary = buttonSelection:recursiveGetChildById('bestiary')
        charms = buttonSelection:recursiveGetChildById('charms')
        map = buttonSelection:recursiveGetChildById('map')
        houses = buttonSelection:recursiveGetChildById('houses')
        character = buttonSelection:recursiveGetChildById('character')
        bosstiary = buttonSelection:recursiveGetChildById('bosstiary')
        bossSlot = buttonSelection:recursiveGetChildById('bossSlot')
        magicalArchives = buttonSelection:recursiveGetChildById('magicalArchives')

        windowTypes = {
            items = { obj = items, func = showItems },
            bestiary = { obj = bestiary, func = showBestiary },
            charms = { obj = charms, func = showCharms },
            map = { obj = map, func = showMap },
            houses = { obj = houses, func = showHouse },
            character = { obj = character, func = showCharacter },
            bosstiary = { obj = bosstiary, func = showBosstiary },
            bossSlot = { obj = bossSlot, func = showBossSlot },
            magicalArchives = { obj = magicalArchives, func = showMagicalArchives },
        }

        g_ui.importStyle("cyclopedia_widgets")
        g_ui.importStyle("cyclopedia_pages")

        controllerCyclopedia:registerEvents(g_game, {
            onResourcesBalanceChange = Cyclopedia.onResourcesBalanceChange,
            -- bestiary
            onParseBestiaryRaces = Cyclopedia.loadBestiaryCategories,
            onParseBestiaryOverview = Cyclopedia.loadBestiaryOverview,
            onUpdateBestiaryMonsterData = Cyclopedia.loadBestiarySelectedCreature,
            -- bosstiary
            onParseSendBosstiary = Cyclopedia.LoadBosstiaryCreatures,
            -- boss_slot
            onParseBosstiarySlots = Cyclopedia.loadBossSlots,
            -- character
            onParseCyclopediaCharacterGeneralStats = Cyclopedia.loadCharacterGeneralStats,
            onParseCyclopediaCharacterCombatStats = Cyclopedia.loadCharacterCombatStats,
            onParseCyclopediaCharacterBadges = Cyclopedia.loadCharacterBadges,
            onCyclopediaCharacterRecentDeaths = Cyclopedia.loadCharacterRecentDeaths,
            onCyclopediaCharacterRecentKills = Cyclopedia.loadCharacterRecentKills,
            onUpdateCyclopediaCharacterItemSummary = Cyclopedia.loadCharacterItems,
            onParseCyclopediaCharacterAppearances = Cyclopedia.loadCharacterAppearances,
            onParseCyclopediaStoreSummary = Cyclopedia.onParseCyclopediaStoreSummary,
            -- character 14.10
            onCyclopediaCharacterOffenceStats = Cyclopedia.onCyclopediaCharacterOffenceStats,
            onCyclopediaCharacterDefenceStats = Cyclopedia.onCyclopediaCharacterDefenceStats,
            onCyclopediaCharacterMiscStats = Cyclopedia.onCyclopediaCharacterMiscStats,


            -- charms
            onUpdateBestiaryCharmsData = Cyclopedia.loadCharms,
            -- items
            onParseItemDetail = Cyclopedia.loadItemDetail
        })

        --[[===================================================
    =               Tracker Bestiary                      =
    =================================================== ]] --

        -- Only create if it doesn't exist
        if not trackerButton then
            trackerButton = modules.game_mainpanel.addToggleButton("trackerButton", tr("Bestiary Tracker"),
                "/images/options/bestiaryTracker", Cyclopedia.toggleBestiaryTracker, false, 17)
        end
        
        trackerButton:setOn(false)
        
        -- Only create if it doesn't exist
        if not trackerMiniWindow then
            trackerMiniWindow = g_ui.createWidget('BestiaryTracker', modules.game_interface.getRightPanel())

            -- Set the title with length limit like in containers
            local titleWidget = trackerMiniWindow:getChildById('miniwindowTitle')
            if titleWidget then
                local title = tr('Bestiary Tracker')
                if title:len() > 12 then
                    title = title:sub(1, 12) .. "..."
                end
                titleWidget:setText(title)
            end

            -- Set up contextMenuButton positioning and click handler
            local contextMenuButton = trackerMiniWindow:recursiveGetChildById('contextMenuButton')
            local newWindowButton = trackerMiniWindow:recursiveGetChildById('newWindowButton')
            local minimizeButton = trackerMiniWindow:recursiveGetChildById('minimizeButton')
            
            if contextMenuButton then
                contextMenuButton:setVisible(true)
                
                -- Position contextMenuButton like in ImbuementTracker
                if minimizeButton then
                    contextMenuButton:breakAnchors()
                    contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
                    contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
                    contextMenuButton:setMarginRight(7)
                    contextMenuButton:setMarginTop(0)
                end
                
                contextMenuButton.onClick = function(widget, mousePos, mouseButton)
                    return Cyclopedia.createTrackerContextMenu("bestiary", mousePos)
                end
            end

            if newWindowButton then
                newWindowButton:setVisible(true)
                newWindowButton.onClick = function(widget, mousePos, mouseButton)
                    toggle("bestiary")
                    return true
                end
            end

            trackerMiniWindow.onOpen = function()
                trackerButton:setOn(true)
                Cyclopedia.refreshBestiaryTracker()
            end

            trackerMiniWindow.onClose = function()
                trackerButton:setOn(false)
            end

            trackerMiniWindow:setup()
            trackerMiniWindow:hide()
        end

        --[[===================================================
    =               Tracker Bosstiary                     =
    =================================================== ]] --

        -- Only create if it doesn't exist
        if not trackerButtonBosstiary then
            trackerButtonBosstiary = modules.game_mainpanel.addToggleButton("bosstiarytrackerButton",
                tr("Bosstiary Tracker"), "/images/options/bosstiaryTracker", Cyclopedia.toggleBosstiaryTracker, false, 17)
        end
        
        trackerButtonBosstiary:setOn(false)
        
        -- Only create if it doesn't exist
        if not trackerMiniWindowBosstiary then
            trackerMiniWindowBosstiary = g_ui.createWidget('BestiaryTracker', modules.game_interface.getRightPanel())
            
            -- Set the title with length limit like in containers
            local titleWidgetBosstiary = trackerMiniWindowBosstiary:getChildById('miniwindowTitle')
            if titleWidgetBosstiary then
                local title = tr('Bosstiary Tracker')
                if title:len() > 12 then
                    title = title:sub(1, 12) .. "..."
                end
                titleWidgetBosstiary:setText(title)
            end

            -- Set the icon for Bosstiary Tracker
            local iconWidgetBosstiary = trackerMiniWindowBosstiary:getChildById('miniwindowIcon')
            if iconWidgetBosstiary then
                iconWidgetBosstiary:setImageSource('/images/icons/icon-bosstracker-widget')
            end

            -- Set up contextMenuButton positioning and click handler for Bosstiary
            local contextMenuButtonBosstiary = trackerMiniWindowBosstiary:recursiveGetChildById('contextMenuButton')
            local newWindowButtonBosstiary = trackerMiniWindowBosstiary:recursiveGetChildById('newWindowButton')
            local minimizeButtonBosstiary = trackerMiniWindowBosstiary:recursiveGetChildById('minimizeButton')
            
            if contextMenuButtonBosstiary then
                contextMenuButtonBosstiary:setVisible(true)
                
                -- Position contextMenuButton like in ImbuementTracker
                if minimizeButtonBosstiary then
                    contextMenuButtonBosstiary:breakAnchors()
                    contextMenuButtonBosstiary:addAnchor(AnchorTop, minimizeButtonBosstiary:getId(), AnchorTop)
                    contextMenuButtonBosstiary:addAnchor(AnchorRight, minimizeButtonBosstiary:getId(), AnchorLeft)
                    contextMenuButtonBosstiary:setMarginRight(7)
                    contextMenuButtonBosstiary:setMarginTop(0)
                end
                
                contextMenuButtonBosstiary.onClick = function(widget, mousePos, mouseButton)
                    return Cyclopedia.createTrackerContextMenu("bosstiary", mousePos)
                end
            end

            if newWindowButtonBosstiary then
                newWindowButtonBosstiary:setVisible(true)
                newWindowButtonBosstiary.onClick = function(widget, mousePos, mouseButton)
                    toggle("bosstiary")
                    return true
                end
            end

            trackerMiniWindowBosstiary.onOpen = function()
                trackerButtonBosstiary:setOn(true)
                if not Cyclopedia.BosstiaryTrackerPending then
                    if trackerMiniWindowBosstiary.contentsPanel then
                        trackerMiniWindowBosstiary.contentsPanel:destroyChildren()
                    end
                    Cyclopedia.refreshBosstiaryTracker()
                end
                Cyclopedia.scheduleBosstiaryTrackerRetry(1000)
            end

            trackerMiniWindowBosstiary.onClose = function()
                trackerButtonBosstiary:setOn(false)
            end

            trackerMiniWindowBosstiary:setup()
            trackerMiniWindowBosstiary:hide()
        end
        trackerMiniWindow:setupOnStart()
        trackerMiniWindowBosstiary:setupOnStart()
        Cyclopedia.loadTrackerFilters("bestiary")
        Cyclopedia.loadTrackerFilters("bosstiary")

        if trackerMiniWindow:isVisible() then
            trackerButton:setOn(true)
        end
        if trackerMiniWindowBosstiary:isVisible() then
            trackerButtonBosstiary:setOn(true)
        end
        
        Cyclopedia.BossSlots.UnlockBosses = {}
        Keybind.new("Windows", "Show/hide Bosstiary Tracker", "", "")

        Keybind.bind("Windows", "Show/hide Bosstiary Tracker", {{
            type = KEY_DOWN,
            callback = Cyclopedia.toggleBosstiaryTracker
        }})

        Keybind.new("Windows", "Show/hide Bestiary Tracker", "", "")
        Keybind.bind("Windows", "Show/hide Bestiary Tracker", {{
            type = KEY_DOWN,
            callback = Cyclopedia.toggleBestiaryTracker
        }})
    end
    if versionClient >= 1410 then
        controllerCyclopedia.ui.CharmsBase.Icon:setImageSource("/game_cyclopedia/images/monster-icon-bonuspoints")
    end
end


function controllerCyclopedia:onGameEnd()
    hideOrganizationWindow()
    organizationState = { members = {}, invitations = {}, outgoingInvitations = {}, role = 0 }
    organizationSelected = nil
    organizationSection = 'members'
    setHouseButtonState(false)
    hide()
    
    if Cyclopedia.saveTrackerFilters then
        Cyclopedia.saveTrackerFilters("bestiary")
        Cyclopedia.saveTrackerFilters("bosstiary")
    end

    if Cyclopedia.clearTrackerDataForCharacterChange then
        Cyclopedia.clearTrackerDataForCharacterChange()
    end

    Keybind.delete("Windows", "Show/hide Bosstiary Tracker")
    Keybind.delete("Windows", "Show/hide Bestiary Tracker")
end

function controllerCyclopedia:onTerminate()
    if trackerButton then
        trackerButton:destroy()
        trackerButton = nil
    end

    if trackerMiniWindow then
        trackerMiniWindow:destroy()
        trackerMiniWindow = nil
    end

    if trackerButtonBosstiary then
        trackerButtonBosstiary:destroy()
        trackerButtonBosstiary = nil
    end

    if trackerMiniWindowBosstiary then
        trackerMiniWindowBosstiary:destroy()
        trackerMiniWindowBosstiary = nil
    end

    if CyclopediaButton then
        CyclopediaButton:destroy()
        CyclopediaButton = nil
    end
    if HouseButton then
        HouseButton:destroy()
        HouseButton = nil
    end
    if OrganizationButton then
        OrganizationButton:destroy()
        OrganizationButton = nil
    end
    if OrganizationWindow then
        OrganizationWindow:destroy()
        OrganizationWindow = nil
    end
    if ButtonBossSlot then
        ButtonBossSlot:destroy()
        ButtonBossSlot = nil
    end
    if ButtonBestiary then
        ButtonBestiary:destroy()
        ButtonBestiary = nil
    end
    
    -- Save items data if available
    if Cyclopedia and Cyclopedia.Items and Cyclopedia.Items.terminate then
        Cyclopedia.Items.terminate()
    end
    
    onTerminateCharm()
end

function hide()
    if not controllerCyclopedia.ui then
        return
    end
    resetCyclopediaTabs()
    controllerCyclopedia.ui:hide()
    if CyclopediaButton then
        CyclopediaButton:setOn(false)
    end
    if ButtonBossSlot then
        ButtonBossSlot:setOn(false)
    end
    if ButtonBestiary then
        ButtonBestiary:setOn(false)
    end
end

function resetCyclopediaTabs()
    tabStack = {}
    controllerCyclopedia.ui.BackButton:setEnabled(false)
    if previousType then
        local previousWindow = windowTypes[previousType]
        previousWindow.obj:enable()
        previousWindow.obj:setOn(false)
        previousType = nil;
    end
end

function show(defaultWindow)
    if not controllerCyclopedia.ui then
        return
    end

    controllerCyclopedia.ui:show()
    controllerCyclopedia.ui:raise()
    controllerCyclopedia.ui:focus()
    SelectWindow(defaultWindow, false)
    controllerCyclopedia.ui.GoldBase.Value:setText(Cyclopedia.formatGold(g_game.getLocalPlayer():getTotalMoney()))
end

function Cyclopedia.openTab(tabName)
    if not controllerCyclopedia.ui then
        return false
    end

    if not controllerCyclopedia.ui:isVisible() then
        show(tabName)
        return true
    end

    if previousType ~= tabName then
        SelectWindow(tabName, false)
    end

    return true
end

function toggleBack()
    local previousTab = table.remove(tabStack, #tabStack)
    if #tabStack < 1 then
        controllerCyclopedia.ui.BackButton:setEnabled(false)
    end
    SelectWindow(previousTab, true)
end

function SelectWindow(type, isBackButtonPress)
    if previousType then
        local previousWindow = windowTypes[previousType]
        previousWindow.obj:enable()
        previousWindow.obj:setOn(false)
        if not isBackButtonPress then
            table.insert(tabStack, previousType)
            controllerCyclopedia.ui.BackButton:setEnabled(true)
        end
    end
    contentContainer:destroyChildren()

    local window = windowTypes[type]
    if window then
        window.obj:setOn(true)
        window.obj:disable()
        previousType = type
        if window.func then
            window.func(contentContainer)
        end
    end
    if CyclopediaButton then
        CyclopediaButton:setOn(type == "items" or type == "charms" or type == "map" or type == "houses" or type == "character" or type == "magicalArchives")
    end
    if ButtonBossSlot then
        ButtonBossSlot:setOn(type == "bossSlot")
    end
    if ButtonBestiary then
        ButtonBestiary:setOn(type == "bosstiary" or type == "bestiary")
    end
end

function Cyclopedia.onResourcesBalanceChange()
    if not controllerCyclopedia.ui or not controllerCyclopedia.ui:isVisible() then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    controllerCyclopedia.ui.GoldBase.Value:setText(Cyclopedia.formatGold(player:getTotalMoney()))

    local formatResourceBalance = function(resourceType, maxResourceType)
        return string.format("%d/%d", player:getResourceBalance(resourceType),
            player:getResourceBalance(maxResourceType))
    end

    controllerCyclopedia.ui.CharmsBase.Value:setText(formatResourceBalance(ResourceTypes.CHARM,
        ResourceTypes.MAX_CHARM))

    if controllerCyclopedia.ui.CharmsBase1410:isVisible() then
        controllerCyclopedia.ui.CharmsBase1410.Value:setText(formatResourceBalance(
            ResourceTypes.MINOR_CHARM, ResourceTypes.MAX_MINOR_CHARM))
    end
end

function isVisible()
    return controllerCyclopedia and controllerCyclopedia.ui and controllerCyclopedia.ui:isVisible()
end
