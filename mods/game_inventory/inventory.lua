local barWindow = nil
local barPanel = nil
local barButton = nil
local pbs = {}
local PB_COUNT = 6
local POKE_BAG_SLOT = InventorySlotLeg
local KEY_ORDER = 'Ctrl+3'
local KEY_FISH = 'Ctrl+2'
local KEY_BIKE = 'Ctrl+1'

local HOTKEY_SLOTS = {
    [InventorySlotNeck] = KEY_FISH,
    [InventorySlotFinger] = KEY_BIKE,
    [InventorySlotExt2] = KEY_ORDER
}

local fightModeRadioGroup = nil
local fightOffensiveBox = nil
local fightBalancedBox = nil
local fightDefensiveBox = nil

local InventorySlotStyles = {
    [InventorySlotHead] = "HeadSlot",
    [InventorySlotNeck] = "NeckSlot",
    [InventorySlotBack] = "BackSlot",
    [InventorySlotRight] = "RightSlot",
    [InventorySlotLeft] = "LeftSlot",
    [InventorySlotLeg] = "LegSlot",
    [InventorySlotFeet] = "FeetSlot",
    [InventorySlotFinger] = "FingerSlot",
    [InventorySlotAmmo] = "AmmoSlot",
    [InventorySlotExt2] = "BodySlot"
}

function init()
    barWindow = g_ui.loadUI('inventory', modules.game_interface.getRightPanel())
    barWindow:disableResize()
    barPanel = barWindow:getChildById('contentsPanel')

    barButton = modules.client_topmenu.getButton('barButton')
    if barButton then
        barButton:setVisible(false)
    end

    fightOffensiveBox = barWindow:recursiveGetChildById('fightOffensiveBox')
    fightBalancedBox = barWindow:recursiveGetChildById('fightBalancedBox')
    fightDefensiveBox = barWindow:recursiveGetChildById('fightDefensiveBox')

    fightModeRadioGroup = UIRadioGroup.create()
    fightModeRadioGroup:addWidget(fightOffensiveBox)
    fightModeRadioGroup:addWidget(fightBalancedBox)
    fightModeRadioGroup:addWidget(fightDefensiveBox)

    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onStatesChange = onStatesChange
    })
    connect(Container, {
        onOpen = refreshPbsFromLegBag,
        onClose = refreshPbsFromLegBag,
        onUpdateItem = refreshPbsFromLegBag,
        onSizeChange = refreshPbsFromLegBag
    })
    connect(g_game, {
        onGameStart = refresh,
        onGameEnd = hide,
        onFightModeChange = update
    })
    connect(fightModeRadioGroup, {onSelectionChange = onSetFightMode})

    createPbs()
    registerInventoryHotkeys()
    barWindow:setup()
end

function terminate()
    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onStatesChange = onStatesChange
    })
    disconnect(Container, {
        onOpen = refreshPbsFromLegBag,
        onClose = refreshPbsFromLegBag,
        onUpdateItem = refreshPbsFromLegBag,
        onSizeChange = refreshPbsFromLegBag
    })
    disconnect(g_game, {
        onGameStart = refresh,
        onGameEnd = hide,
        onFightModeChange = update
    })
    if fightModeRadioGroup then
        disconnect(fightModeRadioGroup, {onSelectionChange = onSetFightMode})
    end

    unregisterInventoryHotkeys()

    if fightModeRadioGroup then
        fightModeRadioGroup:destroy()
        fightModeRadioGroup = nil
    end
    pbs = {}
    barPanel = nil
    if barWindow then
        barWindow:destroy()
        barWindow = nil
    end
end

local function useInventorySlot(slot)
    if not g_game.isOnline() then return end
    local player = g_game.getLocalPlayer()
    if not player then return end
    local item = player:getInventoryItem(slot)
    if not item then return end

    local gi = modules.game_interface
    local subType = item:getSubType() or -1

    if item:isContainer() then
        g_game.open(item)
        return
    end

    if item:isMultiUse() then
        if gi and gi.startUseWith then
            gi.startUseWith(item, subType)
        else
            g_game.use(item)
        end
        return
    end

    if g_game.getClientVersion() >= 780 and g_game.useInventoryItem then
        local id = item:getId()
        local ok = pcall(function() g_game.useInventoryItem(id) end)
        if ok then return end
    end

    if slot == InventorySlotFinger and g_game.getClientVersion() >= 780 and g_game.useInventoryItemWith then
        local ok = pcall(function()
            g_game.useInventoryItemWith(item:getId(), player, subType)
        end)
        if ok then return end
    end

    g_game.use(item)
end

function registerInventoryHotkeys()
    g_keyboard.bindKeyDown(KEY_ORDER, function() useInventorySlot(InventorySlotExt2) end)
    g_keyboard.bindKeyDown(KEY_FISH, function() useInventorySlot(InventorySlotNeck) end)
    g_keyboard.bindKeyDown(KEY_BIKE, function() useInventorySlot(InventorySlotFinger) end)
end

function unregisterInventoryHotkeys()
    g_keyboard.unbindKeyDown(KEY_ORDER)
    g_keyboard.unbindKeyDown(KEY_FISH)
    g_keyboard.unbindKeyDown(KEY_BIKE)
end

local function applySlotHotkeyTooltip(slot, itemWidget, item)
    local key = HOTKEY_SLOTS[slot]
    if not key or not itemWidget then return end
    local base = ''
    if item then
        local itt = item:getTooltip()
        if itt and itt:len() > 0 then base = itt .. '\n' end
    end
    itemWidget:setTooltip(base .. tr('Atalho: %s', key))
end

function getLegBagContainer()
    local player = g_game.getLocalPlayer()
    if not player then return nil end
    local slotItem = player:getInventoryItem(POKE_BAG_SLOT)
    if not slotItem or not slotItem:isContainer() then return nil end
    local pos = slotItem:getPosition()
    if not pos or pos.x ~= 65535 or pos.y ~= POKE_BAG_SLOT then return nil end
    for _, container in pairs(g_game.getContainers()) do
        local cItem = container:getContainerItem()
        if cItem then
            local p = cItem:getPosition()
            if p and p.x == 65535 and p.y == POKE_BAG_SLOT then return container end
        end
    end
    return nil
end

function countPokesInLegSlot()
    local player = g_game.getLocalPlayer()
    if not player then return 0 end
    local item = player:getInventoryItem(POKE_BAG_SLOT)
    if not item then return 0 end

    local container = getLegBagContainer()
    if container then
        local n = container:getItemsCount()
        if type(n) ~= 'number' then n = 0 end
        return math.min(n, PB_COUNT)
    end

    if item:isContainer() then return 0 end
    if item:isStackable() then return math.min(item:getCount(), PB_COUNT) end

    return 1
end

function countPokesForPbs()
    local leg = countPokesInLegSlot()
    local m = modules.game_pokebar
    if m and m.getFilledTeamSlotCount then
        local ok, n = pcall(function() return m.getFilledTeamSlotCount() end)
        if ok and type(n) == 'number' and n > 0 then return math.min(n, PB_COUNT) end
    end
    return leg
end

function refreshPbsFromLegBag()
    if not pbs[1] then return end
    local n = countPokesForPbs()
    for i = 1, PB_COUNT do
        pbs[i]:setImageSource(i > n and '/images/ui/pxg/pb_apagada' or '/images/ui/pxg/pb_acessa')
    end
end

function onInventoryChange(player, slot, item, oldItem)
    if slot >= InventorySlotPurse then return end
    local itemWidget = barPanel:getChildById('slot' .. slot)
    if itemWidget then
        if item then
            itemWidget:setStyle(InventorySlotStyles[slot])
            itemWidget:setItem(item)
        else
            itemWidget:setStyle(InventorySlotStyles[slot])
            itemWidget:setItem(nil)
        end
        if HOTKEY_SLOTS[slot] then applySlotHotkeyTooltip(slot, itemWidget, item) end
    end
    if slot == POKE_BAG_SLOT then refreshPbsFromLegBag() end
end

function onStatesChange(localPlayer, now, old)
    if now == old then return end

    local bitsChanged = bit32.bxor(now, old)
    for i = 1, 32 do
        local pow = math.pow(2, i - 1)
        if pow > bitsChanged then break end
        local bitChanged = bit32.band(bitsChanged, pow)
        if bitChanged ~= 0 then
            if bitChanged == 128 then toggleBattle() end
        end
    end
end

function onSetFightMode(self, selectedFightButton)
    if selectedFightButton == nil then return end
    local buttonId = selectedFightButton:getId()
    local fightMode
    if buttonId == 'fightOffensiveBox' then
        fightMode = FightOffensive
    elseif buttonId == 'fightBalancedBox' then
        fightMode = FightBalanced
    else
        fightMode = FightDefensive
    end
    g_game.setFightMode(fightMode)
end

function toggle()
  if barWindow:isVisible() then
    barWindow:close()
    if barButton then barButton:setOn(false) end
  else
    barWindow:open()
    if barButton then barButton:setOn(true) end
  end
end

function refresh()
    online()
    local player = g_game.getLocalPlayer()
    for i = InventorySlotFirst, InventorySlotLast do
        if g_game.isOnline() then
            onInventoryChange(player, i, player:getInventoryItem(i))
        else
            onInventoryChange(player, i, nil)
        end
    end
    if g_game.isOnline() then
        onInventoryChange(player, InventorySlotExt2, player:getInventoryItem(InventorySlotExt2))
    else
        onInventoryChange(player, InventorySlotExt2, nil)
    end
    refreshPbsFromLegBag()
    scheduleEvent(function() refreshPbsFromLegBag() end, 400)
end

function hide()
    if barButton then
        barButton:setVisible(false)
        barButton:setOn(false)
    end
end

function update()
    local fightMode = g_game.getFightMode()
    if fightMode == FightOffensive then
        fightModeRadioGroup:selectWidget(fightOffensiveBox)
    elseif fightMode == FightBalanced then
        fightModeRadioGroup:selectWidget(fightBalancedBox)
    else
        fightModeRadioGroup:selectWidget(fightDefensiveBox)
    end
end

function online()
    local player = g_game.getLocalPlayer()
    if player then
        local char = g_game.getCharacterName()

        local lastCombatControls = g_settings.getNode('LastCombatControls')

        if not table.empty(lastCombatControls) then
            if lastCombatControls[char] then
                g_game.setFightMode(lastCombatControls[char].fightMode)
            end
        end
    end
    if g_game.isOnline() and barButton then
        barButton:setVisible(true)
        barButton:setOn(barWindow:isVisible())
    end
    update()
end

function createPbs()
    local panelPbs = barWindow:recursiveGetChildById('panelPbs')
    local parent = panelPbs or barWindow
    for i = 1, PB_COUNT do
        pbs[i] = g_ui.createWidget(('pbInventory'), parent)
        pbs[i]:setId('pb' .. i)
    end
    refreshPbsFromLegBag()
end

function onMiniWindowClose() end
