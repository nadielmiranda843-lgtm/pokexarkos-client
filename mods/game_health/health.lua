healthInfoWindow = nil
healthInfoButton = nil

avatarCreature = nil
nickValue = nil
levelValue = nil
resetValue = nil
clanValue = nil
rankValue = nil
teamCountImage = nil
lifeBarBg = nil
lifeBarFill = nil
lifeBarText = nil

local SETTINGS_NODE = 'game_health'
local userVisible = false
local pendingPosSaveEvent = nil
local lastSavedPosStr = nil
local teamCountRefreshEvent = nil

local function shortenText(text, maxChars)
  text = tostring(text or '')
  maxChars = tonumber(maxChars) or 0

  if maxChars <= 0 or #text <= maxChars then
    return text
  end

  if maxChars <= 3 then
    return text:sub(1, maxChars)
  end

  return text:sub(1, maxChars - 3) .. '...'
end

local function getTeamSlotCount()
  local pokebarModule = nil
  if modules and modules.game_pokebar then
    pokebarModule = modules.game_pokebar
  elseif mods and mods.game_pokebar then
    pokebarModule = mods.game_pokebar
  end

  if pokebarModule and pokebarModule.getFilledTeamSlotCount then
    local ok, result = pcall(function() return pokebarModule.getFilledTeamSlotCount() end)
    if ok and type(result) == 'number' then
      return math.max(0, math.min(6, math.floor(result)))
    end
  end

  return 0
end

local function updateTeamCountImage()
  if not teamCountImage or not teamCountImage.setImageSource then
    return
  end

  local teamCount = getTeamSlotCount()
  teamCountImage:setImageSource('/mods/game_health/img/pokeball' .. teamCount .. '.png')
end

local function stopTeamCountAutoRefresh()
  if teamCountRefreshEvent then
    removeEvent(teamCountRefreshEvent)
    teamCountRefreshEvent = nil
  end
end

local function startTeamCountAutoRefresh()
  stopTeamCountAutoRefresh()

  local function refreshLoop()
    if not healthInfoWindow or not g_game.isOnline() then
      teamCountRefreshEvent = nil
      return
    end

    updateTeamCountImage()
    teamCountRefreshEvent = scheduleEvent(refreshLoop, 500)
  end

  refreshLoop()
end

local function getHealthBarColor(percent)
  if percent <= 15 then
    return '#c83c3c'
  elseif percent <= 40 then
    return '#d69a2d'
  end

  return '#22b14c'
end

local function updateLifeBar(localPlayer)
  if not (localPlayer and lifeBarBg and lifeBarFill and lifeBarText) then
    return
  end

  local health = tonumber(localPlayer:getHealth()) or 0
  local maxHealth = tonumber(localPlayer:getMaxHealth()) or 0
  local percent = 0

  if maxHealth > 0 then
    percent = math.max(0, math.min(100, math.floor((health / maxHealth) * 100 + 0.5)))
  elseif localPlayer.getHealthPercent then
    percent = tonumber(localPlayer:getHealthPercent()) or 0
    percent = math.max(0, math.min(100, percent))
  end

  local barWidth = lifeBarBg:getWidth() or 122
  lifeBarFill:setWidth(math.floor(barWidth * percent / 100))
  lifeBarFill:setBackgroundColor(getHealthBarColor(percent))
  lifeBarText:setText(string.format('%d%%', percent))
end

function init()
  connect(g_game, { onGameStart = online, onGameEnd = offline })
  connect(LocalPlayer, {
    onHealthChange = onHealthChange,
    onLevelChange = onLevelChange,
    onOutfitChange = onOutfitChange
  })

  healthInfoWindow = g_ui.displayUI('health.otui')
  if healthInfoWindow.disableResize then
    healthInfoWindow:disableResize()
  end

  healthInfoButton = modules.client_topmenu.addLeftGameToggleButton(
    'healthInfoButton',
    tr('Health Information'),
    '/images/topbuttons/healthinfo',
    toggle
  )

  local settings = g_settings.getNode(SETTINGS_NODE) or {}
  userVisible = settings.visible == true
  local posStr = settings.pos
  if posStr and posStr ~= '' then
    pcall(function()
      healthInfoWindow:breakAnchors()
      healthInfoWindow:setPosition(topoint(posStr))
      if healthInfoWindow.bindRectToParent then
        healthInfoWindow:bindRectToParent()
      end
    end)
    lastSavedPosStr = posStr
  end

  if userVisible then
    if g_game.isOnline() then
      healthInfoWindow:show()
    else
      healthInfoWindow:hide()
    end
    if healthInfoButton and healthInfoButton.setOn then
      pcall(function() healthInfoButton:setOn(true) end)
    end
  else
    healthInfoWindow:hide()
    if healthInfoButton and healthInfoButton.setOn then
      pcall(function() healthInfoButton:setOn(false) end)
    end
  end

  avatarCreature = healthInfoWindow:recursiveGetChildById('avatarCreature')
  nickValue = healthInfoWindow:recursiveGetChildById('nickValue')
  levelValue = healthInfoWindow:recursiveGetChildById('levelValue')
  clanValue = healthInfoWindow:recursiveGetChildById('clanValue')
  rankValue = healthInfoWindow:recursiveGetChildById('rankValue')
  teamCountImage = healthInfoWindow:recursiveGetChildById('teamCountImage')
  lifeBarBg = healthInfoWindow:recursiveGetChildById('lifeBarBg')
  lifeBarFill = healthInfoWindow:recursiveGetChildById('lifeBarFill')
  lifeBarText = healthInfoWindow:recursiveGetChildById('lifeBarText')

  refresh()

  connect(healthInfoWindow, { onGeometryChange = onHealthWindowGeometryChange })
end

function terminate()
  if healthInfoWindow then
    disconnect(healthInfoWindow, { onGeometryChange = onHealthWindowGeometryChange })
  end

  if pendingPosSaveEvent then
    removeEvent(pendingPosSaveEvent)
    pendingPosSaveEvent = nil
  end

  stopTeamCountAutoRefresh()

  disconnect(g_game, { onGameEnd = offline, onGameStart = online })
  disconnect(LocalPlayer, {
    onHealthChange = onHealthChange,
    onLevelChange = onLevelChange,
    onOutfitChange = onOutfitChange
  })

  if healthInfoWindow then
    healthInfoWindow:destroy()
    healthInfoWindow = nil
  end

  if healthInfoButton then
    healthInfoButton:destroy()
    healthInfoButton = nil
  end
end

function toggle()
  if not healthInfoWindow then return end

  if healthInfoWindow:isVisible() then
    userVisible = false
    healthInfoWindow:hide()
    stopTeamCountAutoRefresh()
    if healthInfoButton and healthInfoButton.setOn then
      pcall(function() healthInfoButton:setOn(false) end)
    end
  else
    userVisible = true
    if g_game.isOnline() then
      healthInfoWindow:show()
    else
      healthInfoWindow:hide()
    end
    if healthInfoButton and healthInfoButton.setOn then
      pcall(function() healthInfoButton:setOn(true) end)
    end
    refresh()
    startTeamCountAutoRefresh()
  end

  saveVisibility()
end

function offline()
  if not healthInfoWindow then return end
  healthInfoWindow:hide()
  stopTeamCountAutoRefresh()
  if healthInfoButton and healthInfoButton.setOn then
    pcall(function() healthInfoButton:setOn(false) end)
  end
end

function online()
  if not healthInfoWindow then return end

  if userVisible then
    healthInfoWindow:show()
    startTeamCountAutoRefresh()
    if healthInfoButton and healthInfoButton.setOn then
      pcall(function() healthInfoButton:setOn(true) end)
    end
  else
    healthInfoWindow:hide()
    stopTeamCountAutoRefresh()
    if healthInfoButton and healthInfoButton.setOn then
      pcall(function() healthInfoButton:setOn(false) end)
    end
  end

  refresh()
end

function refresh()
  if not (g_game.isOnline() and healthInfoWindow) then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then return end

  if nickValue then
    local rawName = localPlayer:getName() or ''
    nickValue:setText('Nick: ' .. shortenText(rawName, 14))
  end

  if levelValue then
    levelValue:setText('Level: ' .. tostring(localPlayer:getLevel()))
  end

  if clanValue then
    clanValue:setText('')
  end

  if rankValue then
    rankValue:setText('')
  end

  updateTeamCountImage()

  if avatarCreature and avatarCreature.setOutfit then
    avatarCreature:setOutfit(localPlayer:getOutfit())
    if avatarCreature.setOldScaling then
      avatarCreature:setOldScaling(true)
    end
    if avatarCreature.setDirection then
      avatarCreature:setDirection(Directions.South)
    end
    if avatarCreature.setAnimate then
      avatarCreature:setAnimate(true)
    end
  end

  updateLifeBar(localPlayer)
end

function onHealthChange(localPlayer, health, maxHealth)
  updateLifeBar(localPlayer)
end

function onLevelChange(localPlayer, value, percent)
  if levelValue then
    levelValue:setText('Level: ' .. tostring(value or 0))
  end
end

function onOutfitChange(localPlayer, outfit)
  if avatarCreature and avatarCreature.setOutfit then
    avatarCreature:setOutfit(outfit or localPlayer:getOutfit())
    if avatarCreature.setOldScaling then
      avatarCreature:setOldScaling(true)
    end
    if avatarCreature.setDirection then
      avatarCreature:setDirection(Directions.South)
    end
    if avatarCreature.setAnimate then
      avatarCreature:setAnimate(true)
    end
  end
end

function saveVisibility()
  local settings = g_settings.getNode(SETTINGS_NODE) or {}
  settings.visible = userVisible
  g_settings.setNode(SETTINGS_NODE, settings)
end

function savePosition()
  if not healthInfoWindow then return end
  local pos = healthInfoWindow:getPosition()
  if not pos then return end

  local posStr = pointtostring(pos)
  if posStr == lastSavedPosStr then return end
  lastSavedPosStr = posStr

  local settings = g_settings.getNode(SETTINGS_NODE) or {}
  settings.pos = posStr
  settings.visible = userVisible
  g_settings.setNode(SETTINGS_NODE, settings)
end

function onHealthWindowGeometryChange(widget, old, new)
  if pendingPosSaveEvent then
    removeEvent(pendingPosSaveEvent)
  end

  pendingPosSaveEvent = scheduleEvent(function()
    pendingPosSaveEvent = nil
    savePosition()
  end, 200)
end
