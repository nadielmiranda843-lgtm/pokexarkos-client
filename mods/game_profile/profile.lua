Icons = {}
Icons[1] = { tooltip = tr('You are poisoned'), path = '/images/game/states/poisoned.png', id = 'condition_poisoned' }
Icons[2] = { tooltip = tr('You are burning'), path = '/images/game/states/burning.png', id = 'condition_burning' }
Icons[4] = { tooltip = tr('You are electrified'), path = '/images/game/states/electrified.png', id = 'condition_electrified' }
Icons[8] = { tooltip = tr('You are drunk'), path = '/images/game/states/drunk.png', id = 'condition_drunk' }
Icons[16] = { tooltip = tr('You are protected by a magic shield'), path = '/images/game/states/magic_shield.png', id = 'condition_magic_shield' }
Icons[32] = { tooltip = tr('You are paralysed'), path = '/images/game/states/slowed.png', id = 'condition_slowed' }
Icons[64] = { tooltip = tr('You are hasted'), path = '/images/game/states/haste.png', id = 'condition_haste' }
Icons[128] = { tooltip = tr('You may not logout during a fight'), path = '/images/game/states/logout_block.png', id = 'condition_logout_block' }
Icons[256] = { tooltip = tr('You are drowing'), path = '/images/game/states/drowning.png', id = 'condition_drowning' }
Icons[512] = { tooltip = tr('You are freezing'), path = '/images/game/states/freezing.png', id = 'condition_freezing' }
Icons[1024] = { tooltip = tr('You are dazzled'), path = '/images/game/states/dazzled.png', id = 'condition_dazzled' }
Icons[2048] = { tooltip = tr('You are cursed'), path = '/images/game/states/cursed.png', id = 'condition_cursed' }
Icons[4096] = { tooltip = tr('Voc?? est?? strengthened'), path = '/images/game/states/strengthened.png', id = 'condition_strengthened' }
Icons[8192] = { tooltip = tr('You may not logout or enter a protection zone'), path = '/images/game/states/protection_zone_block.png', id = 'condition_protection_zone_block' }
Icons[16384] = { tooltip = tr('You are within a protection zone'), path = '/images/game/states/protection_zone.png', id = 'condition_protection_zone' }
Icons[32768] = { tooltip = tr('You are bleeding'), path = '/images/game/states/bleeding.png', id = 'condition_bleeding' }
Icons[65536] = { tooltip = tr('You are hungry'), path = '/images/game/states/hungry.png', id = 'condition_hungry' }

local profileWindow
local nameLabel
local outfitBox
local levelLabel
local idValueBox
local levelValueBox
local vocationValueBox
local groupValueBox
local pokemonValueBox
local resetValueBox
local diamondsValueBox
local premiumValueBox
local stateSummaryValueBox
local healthSummaryValueBox
local bankValueBox
local capacityValueBox
local aboutAccountText
local redeemButton
local resetButton
local donateButton
local inspectWindow
local inspectNameLabel
local inspectOutfitBox
local inspectRankValueBox
local inspectHealthValueBox
local inspectHealthFill
local inspectLevelValueBox
local inspectResetValueBox
local inspectGroupValueBox
local inspectChatButton
local bottomPlayerName
local redeemWindow
local redeemCodeInput
local viewedCreature = nil
local viewedInspectCreature = nil

local RESET_REQUIRED_LEVEL = 10000
local OPCODE_PROFILE_INSPECT = 109
local inspectPlayerData = {}
local ownResetCount = '0'
local refreshInspectWindow

local function formatNumber(value)
  local number = tonumber(value)
  if not number then
    return '--'
  end

  number = math.floor(number)
  local formatted = tostring(number)
  while true do
    local replaced, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
    formatted = replaced
    if count == 0 then
      break
    end
  end
  return formatted
end

local function setBoxText(widget, text)
  if not widget then return end
  local label = widget:recursiveGetChildById('value')
  if label then
    label:setText(text or '--')
  end
end

local function setBoxTextColor(widget, color)
  if not widget then return end
  local label = widget:recursiveGetChildById('value')
  if label and label.setColor then
    label:setColor(color or '#f2fbff')
  end
end

local function resetInspectPlayerData(targetId)
  inspectPlayerData = {
    targetId = targetId,
    rank = '1',
    health = 0,
    maxHealth = 0,
    level = '--',
    reset = '0',
    donatePoints = '0',
    groupLabel = 'TREINADOR'
  }
end

local function getProfileGroupLabel(player)
  if not player or not player:isPlayer() then
    return 'CRIATURA'
  end

  local title = ''
  if player.getTitle then
    title = tostring(player:getTitle() or ''):lower()
  end

  local rawName = tostring(player:getName() or '')
  local bracketTitle = rawName:match('^%[([^%]]+)%]')
  bracketTitle = bracketTitle and bracketTitle:lower() or ''

  if title == 'dono' or bracketTitle == 'dono' then
    return 'DONO'
  elseif title == 'gm' or bracketTitle == 'gm' then
    return 'GM'
  elseif title == 'help' or bracketTitle == 'help' then
    return 'HELP'
  end

  if player.getId and inspectPlayerData.targetId == player:getId() and inspectPlayerData.groupLabel and inspectPlayerData.groupLabel ~= '' then
    return inspectPlayerData.groupLabel
  end

  return 'TREINADOR'
end

local function getProfileGroupColor(groupLabel)
  local value = tostring(groupLabel or ''):upper()
  if value == 'DONO' then
    return '#ff4d4d'
  elseif value == 'GM' then
    return '#c56eff'
  elseif value == 'HELP' then
    return '#ffb347'
  end
  return '#f2fbff'
end

local function getHealthBarColor(percent)
  if percent <= 15 then
    return '#cc3b3b'
  elseif percent <= 40 then
    return '#d68d2a'
  end

  return '#2fbf71'
end

local function updateInspectHealthBar(health, maxHealth)
  if not inspectHealthValueBox then
    return
  end

  health = tonumber(health) or 0
  maxHealth = tonumber(maxHealth) or 0

  local percent = 0
  if maxHealth > 0 then
    percent = math.max(0, math.min(100, math.floor((health / maxHealth) * 100 + 0.5)))
  end

  setBoxText(inspectHealthValueBox, string.format('%d%%', percent))

  if inspectHealthFill then
    local boxWidth = inspectHealthValueBox:getWidth() or 118
    inspectHealthFill:setWidth(math.max(0, math.floor(boxWidth * percent / 100)))
    inspectHealthFill:setBackgroundColor(getHealthBarColor(percent))
  end
end

local function requestInspectPlayerData(player)
  if not player or not player.getId then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local targetId = player:getId()
  resetInspectPlayerData(targetId)

  local payload = {
    action = 'requestPlayerInfo',
    targetId = targetId
  }

  if protocolGame.sendExtendedJSONOpcode then
    protocolGame:sendExtendedJSONOpcode(OPCODE_PROFILE_INSPECT, payload)
  elseif protocolGame.sendExtendedOpcode then
    protocolGame:sendExtendedOpcode(OPCODE_PROFILE_INSPECT, json.encode(payload))
  end
end

local function normalizePlayerName(name)
  local rawName = tostring(name or '')
  rawName = rawName:gsub('^%s+', ''):gsub('%s+$', '')
  rawName = rawName:gsub('^%[[^%]]+%]%s*', '')
  return rawName
end

local function onProfileInspectOpcode(protocol, opcode, buffer)
  local ok, data = pcall(function() return json.decode(buffer) end)
  if not ok or type(data) ~= 'table' then
    return
  end

  if data.action ~= 'playerInfo' then
    return
  end

  inspectPlayerData = {
    targetId = tonumber(data.targetId),
    rank = tostring(data.rank or '1'),
    health = tonumber(data.health) or 0,
    maxHealth = tonumber(data.maxHealth) or 0,
    level = tostring(data.level or '--'),
    reset = tostring(data.reset or '0'),
    donatePoints = tostring(data.donatePoints or '0'),
    groupLabel = tostring(data.groupLabel or 'TREINADOR'),
    name = tostring(data.name or ''),
    cleanName = tostring(data.plainName or normalizePlayerName(data.name))
  }

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer and inspectPlayerData.targetId == localPlayer:getId() then
    ownResetCount = tostring(inspectPlayerData.reset or '0')
    if resetValueBox then
      setBoxText(resetValueBox, ownResetCount)
    end
    if diamondsValueBox then
      setBoxText(diamondsValueBox, formatNumber(inspectPlayerData.donatePoints or 0))
    end
    if groupValueBox then
      setBoxText(groupValueBox, inspectPlayerData.groupLabel or 'TREINADOR')
      setBoxTextColor(groupValueBox, getProfileGroupColor(inspectPlayerData.groupLabel))
    end
    local healthModule = nil
    if modules and modules.game_health then
      healthModule = modules.game_health
    elseif mods and mods.game_health then
      healthModule = mods.game_health
    end
    if healthModule and healthModule.refresh then
      pcall(function() healthModule.refresh() end)
    end
  end

  if viewedInspectCreature and viewedInspectCreature.getId and inspectPlayerData.targetId == viewedInspectCreature:getId() then
    if inspectNameLabel and inspectPlayerData.name and inspectPlayerData.name ~= '' then
      inspectNameLabel:setText(inspectPlayerData.name)
    end
    setBoxText(inspectRankValueBox, tostring(inspectPlayerData.rank or '1'))
    updateInspectHealthBar(inspectPlayerData.health, inspectPlayerData.maxHealth)
    setBoxText(inspectLevelValueBox, tostring(inspectPlayerData.level or '--'))
    setBoxText(inspectResetValueBox, tostring(inspectPlayerData.reset or '0'))
    if refreshInspectWindow then
      refreshInspectWindow()
    end
  end
end

local function getVocationName(vocation)
  local map = {
    [0] = 'None',
    [1] = 'Warrior',
    [2] = 'Ranger',
    [3] = 'Mage',
    [4] = 'Support',
    [5] = 'Master Sorcerer',
    [6] = 'Elder Druid',
    [7] = 'Royal Paladin',
    [8] = 'Elite Knight',
    [11] = 'Elite Knight',
    [12] = 'Royal Paladin',
    [13] = 'Master Sorcerer',
    [14] = 'Elder Druid'
  }
  return map[vocation] or ('Classe ' .. tostring(vocation or 0))
end

local function getPokemonCount()
  local pokebarModule = nil
  if modules and modules.game_pokebar then
    pokebarModule = modules.game_pokebar
  elseif mods and mods.game_pokebar then
    pokebarModule = mods.game_pokebar
  end

  if pokebarModule and pokebarModule.getFilledTeamSlotCount then
    local ok, result = pcall(function() return pokebarModule.getFilledTeamSlotCount() end)
    if ok and result then
      return result
    end
  end
  return 0
end

local function getDiamondsBalance()
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer and inspectPlayerData.targetId == localPlayer:getId() then
    local value = tonumber(inspectPlayerData.donatePoints or '0')
    if value then
      return value
    end
  end

  if modules and modules.game_shop and modules.game_shop.getPointsBalance then
    local ok, value = pcall(modules.game_shop.getPointsBalance)
    if ok and type(value) == 'number' then
      return value
    end
  end

  return nil
end

local function getBankBalance()
  if Market and Market.getBalance then
    local ok, value = pcall(Market.getBalance)
    if ok and type(value) == 'number' then
      return value
    end
  end

  if modules and modules.game_market and modules.game_market.getBalance then
    local ok, value = pcall(modules.game_market.getBalance)
    if ok and type(value) == 'number' then
      return value
    end
  end

  return nil
end

local function buildDisplayName(player)
  if not player then
    return ''
  end

  local rawName = player:getName() or ''
  local title = ''
  if player.getTitle then
    title = player:getTitle() or ''
  end

  local baseName = rawName:gsub('^%[[^%]]+%]%s*', '')
  baseName = baseName:gsub('(%l)(%u)', '%1 %2')

  if rawName == '' then
    return baseName
  end

  if title ~= '' and not rawName:match('^%[') then
    return string.format('[%s] %s', title, baseName)
  end

  return rawName
end

local function getPlayerRank(player)
  if player and player.getId and inspectPlayerData.targetId == player:getId() then
    return tostring(inspectPlayerData.rank or '1')
  end
  return '1'
end

local function getPlayerLevel(player)
  if player and player.getId and inspectPlayerData.targetId == player:getId() then
    return tostring(inspectPlayerData.level or '--')
  end
  return '--'
end

local function getPlayerReset(player)
  if player and player.getId and inspectPlayerData.targetId == player:getId() then
    return tostring(inspectPlayerData.reset or '0')
  end
  return '0'
end

refreshInspectWindow = function()
  if not (inspectWindow and g_game.isOnline()) then return end

  local player = viewedInspectCreature
  if not player or (player.isRemoved and player:isRemoved()) or not player.isPlayer or not player:isPlayer() then
    inspectWindow:hide()
    viewedInspectCreature = nil
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  local isOwnPlayer = false
  if localPlayer and player.getId and localPlayer.getId and player:getId() == localPlayer:getId() then
    isOwnPlayer = true
  elseif player.isLocalPlayer and player:isLocalPlayer() then
    isOwnPlayer = true
  end

  if isOwnPlayer then
    inspectWindow:hide()
    viewedInspectCreature = nil
    openForCreature(localPlayer)
    return
  end

  local displayName = inspectPlayerData.name and inspectPlayerData.name ~= '' and inspectPlayerData.name or buildDisplayName(player)
  if inspectNameLabel then
    inspectNameLabel:setText(displayName)
  end

  if inspectOutfitBox then
    inspectOutfitBox:setOutfit(player:getOutfit())
    if inspectOutfitBox.setOldScaling then
      inspectOutfitBox:setOldScaling(true)
    end
  end

  setBoxText(inspectRankValueBox, getPlayerRank(player))
  updateInspectHealthBar(inspectPlayerData.health, inspectPlayerData.maxHealth)
  setBoxText(inspectLevelValueBox, getPlayerLevel(player))
  setBoxText(inspectResetValueBox, getPlayerReset(player))
  local inspectGroupLabel = getProfileGroupLabel(player)
  setBoxText(inspectGroupValueBox, inspectGroupLabel)
  setBoxTextColor(inspectGroupValueBox, getProfileGroupColor(inspectGroupLabel))

  local rawName = inspectPlayerData.cleanName or normalizePlayerName(player:getName())
  local localPlayer = g_game.getLocalPlayer()
  local isOwnPlayer = localPlayer and player.getId and localPlayer.getId and player:getId() == localPlayer:getId()
  local alreadyVip = localPlayer and localPlayer.hasVip and rawName ~= '' and localPlayer:hasVip(rawName)
  if inspectChatButton then
    inspectChatButton:setVisible(not isOwnPlayer)
  end
end

local function updateActionButtons(player)
  local isOwnProfile = player and player == g_game.getLocalPlayer()
  if redeemButton then
    redeemButton:setVisible(isOwnProfile)
  end
  if donateButton then
    donateButton:setVisible(isOwnProfile)
  end
  if resetButton then
    resetButton:setVisible(isOwnProfile)
    local canReset = isOwnProfile and (player:getLevel() or 0) >= RESET_REQUIRED_LEVEL
    resetButton:setEnabled(true)
    if canReset then
      resetButton:setTooltip('Reset disponivel a partir do level 10000.')
    else
      resetButton:setTooltip('O reset libera no level 10000.')
    end
  end
end

local function showRedeemWindow()
  if not redeemWindow then
    redeemWindow = g_ui.displayUI('redeem.otui')
    if not redeemWindow then
      displayInfoBox('Resgate', 'Nao foi possivel abrir a janela de resgate.')
      return
    end

    local closeButton = redeemWindow:recursiveGetChildById('closeButton')
    if closeButton then
      closeButton.onClick = function()
        redeemWindow:hide()
      end
    end

    redeemCodeInput = redeemWindow:recursiveGetChildById('redeemCodeInput')
    local redeemActionButton = redeemWindow:recursiveGetChildById('redeemActionButton')
    if redeemActionButton then
      redeemActionButton.onClick = function()
        local code = ''
        if redeemCodeInput and redeemCodeInput.getText then
          code = redeemCodeInput:getText() or ''
        end
        code = code:gsub('^%s+', ''):gsub('%s+$', '')
        if code == '' then
          displayInfoBox('Resgate', 'Digite um codigo para resgatar.')
          return
        end
        g_game.talk('!resgatar ' .. code)
        displayInfoBox('Resgate', 'Codigo enviado para resgate.')
        if redeemCodeInput and redeemCodeInput.setText then
          redeemCodeInput:setText('')
        end
        redeemWindow:hide()
      end
    end
  end

  redeemWindow:show()
  redeemWindow:raise()
  redeemWindow:focus()
  if redeemCodeInput and redeemCodeInput.setText then
    redeemCodeInput:setText('')
    redeemCodeInput:focus()
  end
end
local function refreshProfile()
  if not (profileWindow and g_game.isOnline()) then return end
  local player = viewedCreature
  if not player or (player.isRemoved and player:isRemoved()) then
    player = g_game.getLocalPlayer()
  end
  if not player then return end

  local rawName = player:getName() or ''
  local title = ''
  if player.getTitle then
    title = player:getTitle() or ''
  end

  local displayName = rawName
  local baseName = rawName:gsub('^%[[^%]]+%]%s*', '')
  baseName = baseName:gsub('(%l)(%u)', '%1 %2')

  if displayName == '' then
    displayName = baseName
  elseif title ~= '' and not rawName:match('^%[') then
    displayName = string.format('[%s] %s', title, baseName)
  else
    displayName = rawName
  end

  if nameLabel then
    nameLabel:setText('')
  end
  if bottomPlayerName then
    bottomPlayerName:setText(displayName)
  end
  if outfitBox then
    outfitBox:setOutfit(player:getOutfit())
    if outfitBox.setOldScaling then
      outfitBox:setOldScaling(true)
    end
  end
  levelLabel:setText('Lv' .. player:getLevel())

  local playerId = '--'
  if player.getId then
    local rawId = player:getId()
    if rawId and rawId > 0 then
      playerId = tostring(rawId)
    end
  end

  setBoxText(idValueBox, 'ID: ' .. playerId)
  setBoxText(levelValueBox, tostring(player:getLevel()))
  local vocation = 0
  if player.getVocation then
    vocation = player:getVocation()
  end
  setBoxText(vocationValueBox, getVocationName(vocation))
  local profileGroupLabel = getProfileGroupLabel(player)
  setBoxText(groupValueBox, profileGroupLabel)
  setBoxTextColor(groupValueBox, getProfileGroupColor(profileGroupLabel))
  setBoxText(resetValueBox, player == g_game.getLocalPlayer() and ownResetCount or '--')
  local pokemonCount = player == g_game.getLocalPlayer() and getPokemonCount() or '--'
  setBoxText(pokemonValueBox, tostring(pokemonCount))

  if profileWindow and profileWindow:isVisible() and player == g_game.getLocalPlayer() then
    requestInspectPlayerData(player)
  end

  local diamondsBalance = player == g_game.getLocalPlayer() and getDiamondsBalance() or nil
  setBoxText(diamondsValueBox, diamondsBalance ~= nil and formatNumber(diamondsBalance) or '--')

  local premiumText = 'Standard'
  if player.isPremium and player:isPremium() then
    premiumText = 'Premium'
  elseif player ~= g_game.getLocalPlayer() then
    premiumText = '--'
  end
  setBoxText(premiumValueBox, premiumText)

  local states = player:getStates() or 0
  setBoxText(stateSummaryValueBox, states == 0 and 'Nenhum estado' or 'Estados ativos')

  local maxHealth = player:getMaxHealth() or 0
  local health = player:getHealth() or 0
  local healthPercent = 0
  if maxHealth > 0 then
    healthPercent = math.floor((health / maxHealth) * 100 + 0.5)
  elseif player.getHealthPercent then
    healthPercent = player:getHealthPercent() or 0
  end
  local accountSummary = premiumText
  if healthPercent > 0 then
    accountSummary = string.format('%s | %d%% life', premiumText, healthPercent)
  end
  setBoxText(healthSummaryValueBox, accountSummary)

  local capacity = 0
  if player == g_game.getLocalPlayer() and player.getFreeCapacity then
    capacity = player:getFreeCapacity()
  end
  local bankBalance = player == g_game.getLocalPlayer() and getBankBalance() or nil
  setBoxText(bankValueBox, bankBalance and (formatNumber(bankBalance) .. ' gp') or '--')
  setBoxText(capacityValueBox, player == g_game.getLocalPlayer() and (formatNumber(capacity) .. ' oz') or '--')

  if aboutAccountText then
    if player == g_game.getLocalPlayer() then
      aboutAccountText:setText('Conta ativa para loja, beneficios e recursos especiais do personagem.')
    else
      aboutAccountText:setText('Beneficios visiveis do treinador e status publico da conta.')
    end
  end

  local content = profileWindow:recursiveGetChildById('panelCondition')
  if content then
    for bit, meta in pairs(Icons) do
      local shouldHave = bit32.band(states, bit) ~= 0
      local icon = content:getChildById(meta.id)
      if shouldHave then
        if not icon then
          icon = g_ui.createWidget('ConditionWidget', content)
          icon:setId(meta.id)
          icon:setImageSource(meta.path)
          icon:setTooltip(meta.tooltip)
        end
      elseif icon then
        icon:destroy()
      end
    end
  end

  updateActionButtons(player)
end

function toggle()
  if not profileWindow then return end
  if profileWindow:isVisible() then
    profileWindow:hide()
  else
    profileWindow:show()
    profileWindow:raise()
    profileWindow:focus()
    refreshProfile()
  end
end

function openForCreature(creature)
  viewedCreature = creature or g_game.getLocalPlayer()
  viewedInspectCreature = nil
  if inspectWindow then
    inspectWindow:hide()
  end
  if not profileWindow then return end
  profileWindow:show()
  profileWindow:raise()
  profileWindow:focus()
  refreshProfile()
end

function openInspectForPlayer(creature)
  if not creature or not creature.isPlayer or not creature:isPlayer() then
    return false
  end

  local localPlayer = g_game.getLocalPlayer()
  local isOwnPlayer = false
  if localPlayer and creature.getId and localPlayer.getId and creature:getId() == localPlayer:getId() then
    isOwnPlayer = true
  elseif creature.isLocalPlayer and creature:isLocalPlayer() then
    isOwnPlayer = true
  end

  if isOwnPlayer then
    openForCreature(localPlayer)
    return true
  end

  viewedInspectCreature = creature
  requestInspectPlayerData(creature)
  if profileWindow then
    profileWindow:hide()
  end
  if not inspectWindow then return false end
  inspectWindow:show()
  inspectWindow:raise()
  inspectWindow:focus()
  refreshInspectWindow()
  return true
end

local function hideProfile()
  if profileWindow then
    profileWindow:hide()
  end
  if inspectWindow then
    inspectWindow:hide()
  end
  viewedCreature = nil
  viewedInspectCreature = nil
end


local function onProfileGameStart()
  refreshProfile()
  requestOwnResetCount()
end

function init()
  if ProtocolGame and ProtocolGame.registerExtendedOpcode then
    ProtocolGame.registerExtendedOpcode(OPCODE_PROFILE_INSPECT, onProfileInspectOpcode)
  end

  profileWindow = g_ui.displayUI('profile.otui')
  if not profileWindow then
    print('[game_profile] profile.otui could not be loaded; module disabled.')
    return
  end
  profileWindow:hide()

  inspectWindow = g_ui.displayUI('playerpreview.otui')
  if inspectWindow then
    inspectWindow:hide()
    inspectNameLabel = inspectWindow:recursiveGetChildById('inspectNameLabel')
    inspectOutfitBox = inspectWindow:recursiveGetChildById('inspectOutfitBox')
    inspectRankValueBox = inspectWindow:recursiveGetChildById('inspectRankValueBox')
    inspectHealthValueBox = inspectWindow:recursiveGetChildById('inspectHealthValueBox')
    if inspectHealthValueBox then
      inspectHealthFill = inspectHealthValueBox:recursiveGetChildById('fill')
    end
    inspectLevelValueBox = inspectWindow:recursiveGetChildById('inspectLevelValueBox')
    inspectResetValueBox = inspectWindow:recursiveGetChildById('inspectResetValueBox')
    inspectGroupValueBox = inspectWindow:recursiveGetChildById('inspectGroupValueBox')
    inspectChatButton = inspectWindow:recursiveGetChildById('inspectChatButton')

    local inspectCloseButton = inspectWindow:recursiveGetChildById('inspectCloseButton')
    if inspectCloseButton then
      inspectCloseButton.onClick = function()
        inspectWindow:hide()
        viewedInspectCreature = nil
      end
    end


    if inspectChatButton then
      inspectChatButton.onClick = function()
        local player = viewedInspectCreature
        if not player then
          return
        end

        local rawName = player:getName() or ''
        if rawName == '' then
          return
        end

        g_game.openPrivateChannel(rawName)
      end
    end
  end

  nameLabel = profileWindow:recursiveGetChildById('nameLabel')
  outfitBox = profileWindow:recursiveGetChildById('outfitBox')
  levelLabel = profileWindow:recursiveGetChildById('levelLabel')
  idValueBox = profileWindow:recursiveGetChildById('idValueBox')
  levelValueBox = profileWindow:recursiveGetChildById('levelValueBox')
  vocationValueBox = profileWindow:recursiveGetChildById('vocationValueBox')
  groupValueBox = profileWindow:recursiveGetChildById('groupValueBox')
  pokemonValueBox = profileWindow:recursiveGetChildById('pokemonValueBox')
  resetValueBox = profileWindow:recursiveGetChildById('resetValueBox')
  diamondsValueBox = profileWindow:recursiveGetChildById('diamondsValueBox')
  premiumValueBox = profileWindow:recursiveGetChildById('premiumValueBox')
  stateSummaryValueBox = profileWindow:recursiveGetChildById('stateSummaryValueBox')
  healthSummaryValueBox = profileWindow:recursiveGetChildById('healthSummaryValueBox')
  bankValueBox = profileWindow:recursiveGetChildById('bankValueBox')
  capacityValueBox = profileWindow:recursiveGetChildById('capacityValueBox')
  aboutAccountText = profileWindow:recursiveGetChildById('aboutAccountText')
  redeemButton = profileWindow:recursiveGetChildById('redeemButton')
  resetButton = profileWindow:recursiveGetChildById('resetButton')
  donateButton = profileWindow:recursiveGetChildById('donateButton')
  bottomPlayerName = profileWindow:recursiveGetChildById('bottomPlayerName')

  if redeemButton then
    redeemButton.onClick = function()
      showRedeemWindow()
    end
  end

  if donateButton then
    donateButton.onClick = function()
      g_platform.openUrl('https://www.pokexarkos.com.br/#inicio')
    end
  end

  if resetButton then
    resetButton.onClick = function()
      local player = g_game.getLocalPlayer()
      if not player then
        return
      end

      if player:getLevel() < RESET_REQUIRED_LEVEL then
        displayInfoBox('Reset', 'O reset libera somente a partir do level 10000.')
        return
      end

      local confirmWindow
      local yesCallback = function()
        if profileWindow then
          profileWindow:hide()
        end
        g_game.talk('!reset')
        scheduleEvent(function()
          requestOwnResetCount()
          local healthModule = nil
          if modules and modules.game_health then
            healthModule = modules.game_health
          elseif mods and mods.game_health then
            healthModule = mods.game_health
          end
          if healthModule and healthModule.refresh then
            pcall(function() healthModule.refresh() end)
          end
        end, 300)
        if confirmWindow then
          confirmWindow:destroy()
          confirmWindow = nil
        end
      end

      local noCallback = function()
        if confirmWindow then
          confirmWindow:destroy()
          confirmWindow = nil
        end
      end

      confirmWindow = displayGeneralBox('Reset', 'Deseja resetar?', {
        { text='Sim', callback=yesCallback },
        { text='Nao', callback=noCallback },
        anchor=AnchorHorizontalCenter
      }, yesCallback, noCallback)
    end
  end

  connect(g_game, { onGameEnd = hideProfile, onGameStart = onProfileGameStart })
  connect(LocalPlayer, {
    onHealthChange = refreshProfile,
    onStatesChange = refreshProfile,
    onLevelChange = refreshProfile,
    onSkillChange = refreshProfile
  })

end

function forceRefresh()
  refreshProfile()
  refreshInspectWindow()
end

function terminate()
  disconnect(g_game, { onGameEnd = hideProfile, onGameStart = onProfileGameStart })
  disconnect(LocalPlayer, {
    onHealthChange = refreshProfile,
    onStatesChange = refreshProfile,
    onLevelChange = refreshProfile,
    onSkillChange = refreshProfile
  })

  if ProtocolGame and ProtocolGame.unregisterExtendedOpcode then
    ProtocolGame.unregisterExtendedOpcode(OPCODE_PROFILE_INSPECT)
  end

  if redeemWindow then
    redeemWindow:destroy()
    redeemWindow = nil
  end

  if inspectWindow then
    inspectWindow:destroy()
    inspectWindow = nil
  end

  if profileWindow then
    profileWindow:destroy()
    profileWindow = nil
  end
end










function getOwnResetCount()
  return tostring(ownResetCount or '0')
end

function requestOwnResetCount()
  local player = g_game.getLocalPlayer()
  if player then
    requestInspectPlayerData(player)
  end
end
