local SpelllistProfile = 'Default'
local SPELL_LIST_OPCODE = 0xF5
local learnedSpells = {}
local pendingSpellListRefresh = nil

spelllistWindow = nil
spelllistButton = nil
spellList = nil
nameValueLabel = nil
formulaValueLabel = nil
vocationValueLabel = nil
groupValueLabel = nil
typeValueLabel = nil
cooldownValueLabel = nil
levelValueLabel = nil
manaValueLabel = nil
premiumValueLabel = nil
descriptionValueLabel = nil

vocationBoxAny = nil
vocationBoxSorcerer = nil
vocationBoxDruid = nil
vocationBoxPaladin = nil
vocationBoxKnight = nil
vocationBoxMonk = nil

groupBoxAny = nil
groupBoxAttack = nil
groupBoxHealing = nil
groupBoxSupport = nil

premiumBoxAny = nil
premiumBoxNo = nil
premiumBoxYes = nil

vocationRadioGroup = nil
groupRadioGroup = nil
premiumRadioGroup = nil

-- consts
FILTER_PREMIUM_ANY = 0
FILTER_PREMIUM_NO = 1
FILTER_PREMIUM_YES = 2

FILTER_VOCATION_ANY = 0
FILTER_VOCATION_SORCERER = 1
FILTER_VOCATION_DRUID = 2
FILTER_VOCATION_PALADIN = 3
FILTER_VOCATION_KNIGHT = 4
FILTER_VOCATION_MONK = 5

FILTER_GROUP_ANY = 0
FILTER_GROUP_ATTACK = 1
FILTER_GROUP_HEALING = 2
FILTER_GROUP_SUPPORT = 3

-- Filter Settings
local filters = {
    level = false,
    vocation = false,

    vocationId = FILTER_VOCATION_ANY,
    premium = FILTER_PREMIUM_ANY,
    groupId = FILTER_GROUP_ANY
}

function getSpelllistProfile()
    return SpelllistProfile
end

function setSpelllistProfile(name)
    if SpelllistProfile == name then
        return
    end

    if SpelllistSettings[name] and SpellInfo[name] then
        local oldProfile = SpelllistProfile
        SpelllistProfile = name
        changeSpelllistProfile(oldProfile)
    else
        perror('Spelllist profile \'' .. name .. '\' could not be set.')
    end
end

function online()
    if not spelllistButton then
        spelllistButton = modules.game_mainpanel.addToggleButton('spelllistButton', tr('Jutsus'),
        '/images/options/button_spells', toggle, false, 9)
        spelllistButton:setOn(false)
    end

    -- Vocation is only send in newer clients
    if g_game.getClientVersion() >= 950 then
        spelllistWindow:getChildById('buttonFilterVocation'):setVisible(true)
    else
        spelllistWindow:getChildById('buttonFilterVocation'):setVisible(false)
    end
end

function offline()
	if pendingSpellListRefresh then
		removeEvent(pendingSpellListRefresh)
		pendingSpellListRefresh = nil
	end
    learnedSpells = {}
    if modules.game_actionbar and modules.game_actionbar.replaceBottomBarWithJutsus then
        modules.game_actionbar.replaceBottomBarWithJutsus(learnedSpells)
    end
    resetWindow()
end

function init()
	ProtocolGame.registerOpcode(SPELL_LIST_OPCODE, onLearnedSpellList)
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    spelllistWindow = g_ui.displayUI('spelllist', modules.game_interface.getRightPanel())
    spelllistWindow:hide()

    nameValueLabel = spelllistWindow:getChildById('labelNameValue')
    formulaValueLabel = spelllistWindow:getChildById('labelFormulaValue')
    vocationValueLabel = spelllistWindow:getChildById('labelVocationValue')
    groupValueLabel = spelllistWindow:getChildById('labelGroupValue')
    typeValueLabel = spelllistWindow:getChildById('labelTypeValue')
    cooldownValueLabel = spelllistWindow:getChildById('labelCooldownValue')
    levelValueLabel = spelllistWindow:getChildById('labelLevelValue')
    manaValueLabel = spelllistWindow:getChildById('labelManaValue')
    premiumValueLabel = spelllistWindow:getChildById('labelPremiumValue')
    descriptionValueLabel = spelllistWindow:getChildById('labelDescriptionValue')

    vocationBoxAny = spelllistWindow:getChildById('vocationBoxAny')
    vocationBoxSorcerer = spelllistWindow:getChildById('vocationBoxSorcerer')
    vocationBoxDruid = spelllistWindow:getChildById('vocationBoxDruid')
    vocationBoxPaladin = spelllistWindow:getChildById('vocationBoxPaladin')
    vocationBoxKnight = spelllistWindow:getChildById('vocationBoxKnight')
    vocationBoxMonk = spelllistWindow:getChildById('vocationBoxMonk')

    groupBoxAny = spelllistWindow:getChildById('groupBoxAny')
    groupBoxAttack = spelllistWindow:getChildById('groupBoxAttack')
    groupBoxHealing = spelllistWindow:getChildById('groupBoxHealing')
    groupBoxSupport = spelllistWindow:getChildById('groupBoxSupport')

    premiumBoxAny = spelllistWindow:getChildById('premiumBoxAny')
    premiumBoxYes = spelllistWindow:getChildById('premiumBoxYes')
    premiumBoxNo = spelllistWindow:getChildById('premiumBoxNo')

    vocationRadioGroup = UIRadioGroup.create()
    vocationRadioGroup:addWidget(vocationBoxAny)
    vocationRadioGroup:addWidget(vocationBoxSorcerer)
    vocationRadioGroup:addWidget(vocationBoxDruid)
    vocationRadioGroup:addWidget(vocationBoxPaladin)
    vocationRadioGroup:addWidget(vocationBoxKnight)
    vocationRadioGroup:addWidget(vocationBoxMonk)

    groupRadioGroup = UIRadioGroup.create()
    groupRadioGroup:addWidget(groupBoxAny)
    groupRadioGroup:addWidget(groupBoxAttack)
    groupRadioGroup:addWidget(groupBoxHealing)
    groupRadioGroup:addWidget(groupBoxSupport)

    premiumRadioGroup = UIRadioGroup.create()
    premiumRadioGroup:addWidget(premiumBoxAny)
    premiumRadioGroup:addWidget(premiumBoxYes)
    premiumRadioGroup:addWidget(premiumBoxNo)

    premiumRadioGroup:selectWidget(premiumBoxAny)
    vocationRadioGroup:selectWidget(vocationBoxAny)
    groupRadioGroup:selectWidget(groupBoxAny)

    vocationRadioGroup.onSelectionChange = toggleFilter
    groupRadioGroup.onSelectionChange = toggleFilter
    premiumRadioGroup.onSelectionChange = toggleFilter

    spellList = spelllistWindow:getChildById('spellList')

    g_keyboard.bindKeyPress('Down', function()
        spellList:focusNextChild(KeyboardFocusReason)
    end, spelllistWindow)
    g_keyboard.bindKeyPress('Up', function()
        spellList:focusPreviousChild(KeyboardFocusReason)
    end, spelllistWindow)

    initializeSpelllist()
    resizeWindow()

    if g_game.isOnline() then
        online()
    end
    Keybind.new("Windows", "Show/hide spell list", "Alt+L", "")
    Keybind.bind("Windows", "Show/hide spell list", {
      {
        type = KEY_DOWN,
        callback = toggle,
      }
    })
end

function terminate()
	if pendingSpellListRefresh then
		removeEvent(pendingSpellListRefresh)
		pendingSpellListRefresh = nil
	end
	ProtocolGame.unregisterOpcode(SPELL_LIST_OPCODE)
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    spelllistWindow:destroy()
    if spelllistButton then
        spelllistButton:destroy()
        spelllistButton = nil
    end
    vocationRadioGroup:destroy()
    groupRadioGroup:destroy()
    premiumRadioGroup:destroy()
    Keybind.delete("Windows", "Show/hide spell list")
end

function initializeSpelllist()
	spellList:destroyChildren()
	table.sort(learnedSpells, function(left, right)
		local leftLevel = tonumber(left.level) or 0
		local rightLevel = tonumber(right.level) or 0
		if leftLevel ~= rightLevel then
			return leftLevel < rightLevel
		end
		return left.name:lower() < right.name:lower()
	end)

	for _, info in ipairs(learnedSpells) do
		if info then
			local tmpLabel = g_ui.createWidget('SpellListLabel', spellList)
			tmpLabel:setId(info.words)
			tmpLabel:setText(info.name)
			tmpLabel:setPhantom(false)
			tmpLabel:setHeight(22)
			tmpLabel:setTextOffset(topoint('6 3'))
			tmpLabel.spellData = info
			tmpLabel.onClick = updateSpellInformation
		end
	end

	local scrollBar = spelllistWindow:getChildById('spellsScrollBar')
	if scrollBar then
		scrollBar:setValue(0)
	end

	spellList.onChildFocusChange = function(self, focusedChild)
		if focusedChild then
			updateSpellInformation(focusedChild)
		end
	end
end

function onLearnedSpellList(protocol, msg)
	learnedSpells = {}
	local count = msg:getU16()
	for i = 1, count do
		table.insert(learnedSpells, {
			name = msg:getString(),
			words = msg:getString(),
			level = msg:getU16(),
			mana = msg:getU16()
		})
	end

	table.sort(learnedSpells, function(left, right)
		if left.level ~= right.level then
			return left.level < right.level
		end
		return left.name < right.name
	end)

	-- NPCs antigos podem ensinar muitos jutsus em sequencia. Mantemos apenas a
	-- lista mais recente e reconstruimos a interface uma unica vez, evitando
	-- congelamentos causados por dezenas de atualizacoes no mesmo instante.
	if pendingSpellListRefresh then
		removeEvent(pendingSpellListRefresh)
	end
	pendingSpellListRefresh = scheduleEvent(function()
		pendingSpellListRefresh = nil
		if spellList then
			initializeSpelllist()
		end
		if modules.game_actionbar and modules.game_actionbar.replaceBottomBarWithJutsus then
			modules.game_actionbar.replaceBottomBarWithJutsus(learnedSpells)
		end
	end, 100)
end

function changeSpelllistProfile(oldProfile)
    -- Delete old labels
    for spellName, info in pairs(SpellInfo[oldProfile]) do
        local tmpLabel = spellList:getChildById(spellName)

        tmpLabel:destroy()
    end

    -- Create new spelllist and ajust window
    initializeSpelllist()
    resizeWindow()
    resetWindow()
end

local function vocationMatches(vocations, filterId)
    if filterId == FILTER_VOCATION_ANY then
        return true
    end
    if filterId == FILTER_VOCATION_MONK then
        return table.find(vocations, VocationsServer.Monk) or table.find(vocations, VocationsServer.ExaltedMonk)
    end
    return table.find(vocations, filterId) or table.find(vocations, filterId + 4)
end

function updateSpelllist()
	-- A lista recebida do servidor ja contem somente as magias aprendidas.
end

function updateSpellInformation(widget)
	local info = widget.spellData
	nameValueLabel:setText(info and info.name or '')
	levelValueLabel:setText(info and info.level or '')
	manaValueLabel:setText(info and info.mana or '')
end

function selectDefaultVocation()
    local player = g_game.getLocalPlayer()
    if not player then 
        return
    end
    local vocation = player:getVocation()
    local widget = vocationBoxAny
    if vocation == VocationsClient.Knight or vocation == VocationsClient.EliteKnight then
        widget = vocationBoxKnight
    elseif vocation == VocationsClient.Paladin or vocation == VocationsClient.RoyalPaladin then
        widget = vocationBoxPaladin
    elseif vocation == VocationsClient.Sorcerer or vocation == VocationsClient.MasterSorcerer then
        widget= vocationBoxSorcerer
    elseif vocation == VocationsClient.Druid or vocation == VocationsClient.ElderDruid then
        widget = vocationBoxDruid
    elseif vocation == VocationsClient.Monk or vocation == VocationsClient.ExaltedMonk then
        widget = vocationBoxMonk
    end
    vocationRadioGroup:selectWidget(widget)
end

function toggle()
    if spelllistButton:isOn() then
        spelllistButton:setOn(false)
        spelllistWindow:hide()
    else
        spelllistButton:setOn(true)
        selectDefaultVocation()
        spelllistWindow:show()
        spelllistWindow:raise()
        spelllistWindow:focus()
    end
end

function toggleFilter(widget, selectedWidget)
    if widget == vocationRadioGroup then
        local boxId = selectedWidget:getId()
        if boxId == 'vocationBoxAny' then
            filters.vocationId = FILTER_VOCATION_ANY
        elseif boxId == 'vocationBoxSorcerer' then
            filters.vocationId = FILTER_VOCATION_SORCERER
        elseif boxId == 'vocationBoxDruid' then
            filters.vocationId = FILTER_VOCATION_DRUID
        elseif boxId == 'vocationBoxPaladin' then
            filters.vocationId = FILTER_VOCATION_PALADIN
        elseif boxId == 'vocationBoxKnight' then
            filters.vocationId = FILTER_VOCATION_KNIGHT
        elseif boxId == 'vocationBoxMonk' then
            filters.vocationId = FILTER_VOCATION_MONK
        end
    elseif widget == groupRadioGroup then
        local boxId = selectedWidget:getId()
        if boxId == 'groupBoxAny' then
            filters.groupId = FILTER_GROUP_ANY
        elseif boxId == 'groupBoxAttack' then
            filters.groupId = FILTER_GROUP_ATTACK
        elseif boxId == 'groupBoxHealing' then
            filters.groupId = FILTER_GROUP_HEALING
        elseif boxId == 'groupBoxSupport' then
            filters.groupId = FILTER_GROUP_SUPPORT
        end
    elseif widget == premiumRadioGroup then
        local boxId = selectedWidget:getId()
        if boxId == 'premiumBoxAny' then
            filters.premium = FILTER_PREMIUM_ANY
        elseif boxId == 'premiumBoxNo' then
            filters.premium = FILTER_PREMIUM_NO
        elseif boxId == 'premiumBoxYes' then
            filters.premium = FILTER_PREMIUM_YES
        end
    else
        local id = widget:getId()
        if id == 'buttonFilterLevel' then
            filters.level = not (filters.level)
            widget:setOn(filters.level)
        elseif id == 'buttonFilterVocation' then
            filters.vocation = not (filters.vocation)
            widget:setOn(filters.vocation)
        end
    end

    updateSpelllist()
end

function resizeWindow()
    spelllistWindow:setWidth(SpelllistSettings['Default'].spellWindowWidth +
                                 SpelllistSettings[SpelllistProfile].iconSize.width - 32)
    spellList:setWidth(
        SpelllistSettings['Default'].spellListWidth + SpelllistSettings[SpelllistProfile].iconSize.width - 32)
end

function resetWindow()
    spelllistWindow:hide()
    if spelllistButton then
        spelllistButton:setOn(false)
    end

    -- Resetting filters
    filters.level = false
    filters.vocation = false

    local buttonFilterLevel = spelllistWindow:getChildById('buttonFilterLevel')
    buttonFilterLevel:setOn(filters.level)

    local buttonFilterVocation = spelllistWindow:getChildById('buttonFilterVocation')
    buttonFilterVocation:setOn(filters.vocation)

    vocationRadioGroup:selectWidget(vocationBoxAny)
    groupRadioGroup:selectWidget(groupBoxAny)
    premiumRadioGroup:selectWidget(premiumBoxAny)

    updateSpelllist()
end
