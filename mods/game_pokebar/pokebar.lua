local OPCODE_POKEBAR = 108
local OPCODE_POKEBAR_LEGACY = 53
local TOTAL_SLOTS = 6
local SETTINGS_POKEBAR_WINDOW = 'pokebar-window'

local pokeBarWindow = nil
local pokeBarButton = nil
local slotData = {}
local registeredOpcodes = {}
local slotWidgets = {}
local terminating = false
local positionSaveEnabled = false
local savePositionEvent = nil
local syncEvent = nil
local POKEBAR_ICON_BASE = '/images/game/bar_icon/'
local LIFE_BAR_IMAGE_COLOR_BY_STATE = {
  high = '#22c55e',
  mid = '#eab308',
  low = '#ef4444'
}
local transportMode = 'unknown'

local function flushSavePokebarPosition()
  if savePositionEvent then
    removeEvent(savePositionEvent)
    savePositionEvent = nil
  end
  if not pokeBarWindow or terminating then return end
  local pos = pokeBarWindow:getPosition()
  if not pos then return end
  g_settings.setNode(SETTINGS_POKEBAR_WINDOW, { x = pos.x, y = pos.y })
end

local function scheduleSavePokebarPosition()
  if not positionSaveEnabled or terminating or not pokeBarWindow then return end
  if savePositionEvent then
    removeEvent(savePositionEvent)
  end
  savePositionEvent = scheduleEvent(function()
    savePositionEvent = nil
    flushSavePokebarPosition()
  end, 150)
end

local function applySavedPokebarPosition()
  if not pokeBarWindow then return end
  local node = g_settings.getNode(SETTINGS_POKEBAR_WINDOW)
  local x = node and tonumber(node.x)
  local y = node and tonumber(node.y)
  if x and y then
    if pokeBarWindow.breakAnchors then
      pokeBarWindow:breakAnchors()
    end
    pokeBarWindow:setPosition({ x = x, y = y })
  elseif pokeBarWindow.move then
    pokeBarWindow:move(30, 170)
  end
end

local function updateWindowSizeBySlots(slotCount)
  if not pokeBarWindow then return end
  local count = tonumber(slotCount) or 0
  if count < 0 then count = 0 end
  if count > TOTAL_SLOTS then count = TOTAL_SLOTS end

  local height = 120
  if count > 0 then
    height = 90 + ((count - 1) * 53)
  end

  pokeBarWindow:setHeight(height)
end

local function getSlotWidget(slot, key)
  local widgets = slotWidgets[slot]
  if not widgets then return nil end
  return widgets[key]
end

local function createSlotWidgets()
  if not pokeBarWindow then return end
  slotWidgets = {}

  for i = 1, TOTAL_SLOTS do
    local topMargin = 30 + ((i - 1) * 53)
    local bar = g_ui.createWidget('PokeBarRow', pokeBarWindow)
    bar:setId('bar' .. i)
    bar:addAnchor(AnchorTop, 'parent', AnchorTop)
    bar:setMarginTop(topMargin)

    local life = bar:recursiveGetChildById('life')
    local gender = bar:recursiveGetChildById('pokemonGender')
    local name = bar:recursiveGetChildById('pokeName')
    local percent = bar:recursiveGetChildById('percent')
    local portrait = bar:recursiveGetChildById('portrait')
    local portraitIcon = bar:recursiveGetChildById('portraitIcon')

    slotWidgets[i] = {
      bar = bar,
      life = life,
      portrait = portrait,
      portraitIcon = portraitIcon,
      name = name,
      percent = percent,
      gender = gender
    }
  end
end

local function buildIconCandidates(pokeName)
  local raw = tostring(pokeName or ''):match('^%s*(.-)%s*$')
  if raw == '' then return {} end

  local lower = raw:lower()
  local compact = lower:gsub('[%s%-]+', '')
  local underscore = lower:gsub('[%s%-]+', '_')
  local alnum = lower:gsub('[^%w]', '')
  local candidates = { raw, lower, compact, underscore, alnum }
  local unique = {}
  local out = {}

  for i = 1, #candidates do
    local c = candidates[i]
    if c ~= '' and not unique[c] then
      unique[c] = true
      out[#out + 1] = c
    end
  end

  return out
end

local function resolvePortraitIconPath(pokeName)
  local names = buildIconCandidates(pokeName)
  local extensions = { '.png', '.jpg', '.jpeg', '.webp' }

  for i = 1, #names do
    local base = POKEBAR_ICON_BASE .. names[i]
    for j = 1, #extensions do
      local filePath = base .. extensions[j]
      if g_resources.fileExists(filePath) then
        return filePath
      end
    end
  end

  return nil
end

local function getLifeStateByHp(hp)
  if hp <= 30 then
    return 'low'
  elseif hp <= 70 then
    return 'mid'
  end
  return 'high'
end

local function applyLifeBarVisualByHp(life, hp)
  if not life then return end
  local state = getLifeStateByHp(hp)
  if life.setImageColor then
    life:setImageColor(LIFE_BAR_IMAGE_COLOR_BY_STATE[state] or LIFE_BAR_IMAGE_COLOR_BY_STATE.low)
  end
end

local function resetSlot(slot)
  local bar = getSlotWidget(slot, 'bar')
  local life = getSlotWidget(slot, 'life')
  local portrait = getSlotWidget(slot, 'portrait')
  local portraitIcon = getSlotWidget(slot, 'portraitIcon')
  local name = getSlotWidget(slot, 'name')
  local percent = getSlotWidget(slot, 'percent')
  local gender = getSlotWidget(slot, 'gender')

  if bar then
    bar:hide()
  end
  if life then
    life:setPercent(0)
    life:hide()
  end
  if portrait then
    portrait:setOutfit({type = 0})
    portrait:hide()
  end
  if portraitIcon then
    portraitIcon:setImageSource('')
    portraitIcon:hide()
  end
  if name then
    name:setText('')
    name:hide()
  end
  if percent then
    percent:setText('0%')
    percent:hide()
  end
  if gender then
    gender:hide()
  end
end

local function resetAllSlots()
  for i = 1, TOTAL_SLOTS do
    resetSlot(i)
  end
  slotData = {}
  updateWindowSizeBySlots(0)
end

local function renderSlot(slot, data)
  local bar = getSlotWidget(slot, 'bar')
  local life = getSlotWidget(slot, 'life')
  local portrait = getSlotWidget(slot, 'portrait')
  local portraitIcon = getSlotWidget(slot, 'portraitIcon')
  local name = getSlotWidget(slot, 'name')
  local percent = getSlotWidget(slot, 'percent')
  local gender = getSlotWidget(slot, 'gender')
  if not bar or not life or not portrait or not name or not percent then
    return
  end

  local hp = math.max(0, math.min(100, tonumber(data.healthPercent) or 0))
  local level = tonumber(data.level) or 1
  local pokeName = tostring(data.name or '')
  local looktype = tonumber(data.looktype) or 0
  local usable = data.usable ~= false

  bar:show()
  life:show()
  name:show()
  percent:show()
  if gender then
    gender:hide()
  end

  applyLifeBarVisualByHp(life, hp)
  life:setPercent(hp)
  percent:setText(hp .. '%')

  local iconPath = resolvePortraitIconPath(pokeName)
  if portraitIcon and iconPath then
    portraitIcon:setImageSource(iconPath)
    portraitIcon:show()
    portrait:hide()
  else
    if portraitIcon then
      portraitIcon:setImageSource('')
      portraitIcon:hide()
    end
    portrait:show()
    if looktype > 0 then
      portrait:setOutfit({type = looktype, head = 0, body = 0, legs = 0, feet = 0})
    else
      portrait:setOutfit({type = 0})
    end
  end

  local label = '[' .. level .. '] ' .. pokeName
  if not usable then
    label = label .. ' (Lv req)'
  end
  name:setText(label)
end

local function normalizeName(str)
  local s = tostring(str or ''):lower()
  s = s:gsub('%b[]', '')
  s = s:gsub('[^%w%s%-_]', ' ')
  s = s:gsub('%s+', ' ')
  s = s:match('^%s*(.-)%s*$') or ''
  return s
end

local function findBallSlotContainer()
  local containers = g_game.getContainers()
  if not containers then return nil end

  for _, container in pairs(containers) do
    local rawName = normalizeName(container:getName())
    if rawName == 'ball slot' or rawName == 'ballslot' then
      return container
    end
  end

  return nil
end

local function getBallItemForSlot(slot)
  local container = findBallSlotContainer()
  if not container then
    return nil
  end

  local items = nil
  if container.getItems then
    items = container:getItems()
  end

  if not items or #items <= 0 then
    return nil
  end

  local data = slotData[slot]
  local realSlot = tonumber(data and data.slot) or tonumber(slot) or 1
  local reversedIndex = (#items - realSlot) + 1
  return items[reversedIndex]
end

local function getActiveSlot()
  for i = 1, TOTAL_SLOTS do
    local data = slotData[i]
    if data and data.active then
      return i
    end
  end
  return nil
end

local function tryUseOpenBallSlot(slot)
  local data = slotData[slot]
  if not data then return false end

  local targetItem = getBallItemForSlot(slot)
  if not targetItem then
    return false
  end

  local activeSlot = getActiveSlot()

  if activeSlot and activeSlot ~= slot then
    local activeItem = getBallItemForSlot(activeSlot)
    if activeItem then
      local okReturn = pcall(function()
        g_game.use(activeItem)
      end)

      if okReturn then
        scheduleEvent(function()
          if not g_game.isOnline() then return end
          local refreshedTarget = getBallItemForSlot(slot) or targetItem
          pcall(function()
            g_game.use(refreshedTarget)
          end)
        end, 250)
        return true, 420
      end
    end
  end

  local ok = pcall(function()
    g_game.use(targetItem)
  end)
  return ok, 120
end

local function tryUseClosedBallSlot(slot)
  if findBallSlotContainer() then
    return false
  end

  local sameActiveSlot = getActiveSlot() == slot
  local player = g_game.getLocalPlayer()
  if not player then return false end

  local legItem = player:getInventoryItem(InventorySlotLeg)
  if not legItem or not legItem.isContainer or not legItem:isContainer() then
    return false
  end

  if modules and modules.game_containers and modules.game_containers.suppressContainerWindowOnce then
    pcall(function()
      modules.game_containers.suppressContainerWindowOnce('ball slot')
    end)
  end

  local opened = pcall(function()
    g_game.open(legItem)
  end)
  if not opened then
    return false
  end

  local attempts = 0
  local function tryAfterOpen()
    if not g_game.isOnline() then return end

    local container = findBallSlotContainer()
    if not container then
      attempts = attempts + 1
      local maxAttempts = sameActiveSlot and 10 or 8
      local retryDelay = sameActiveSlot and 100 or 80
      if attempts < maxAttempts then
        scheduleEvent(tryAfterOpen, retryDelay)
      end
      return
    end

    local used, closeDelay = tryUseOpenBallSlot(slot)
    if not used then
      attempts = attempts + 1
      local maxUseAttempts = sameActiveSlot and 5 or 3
      local retryDelay = sameActiveSlot and 120 or 100
      if attempts < maxUseAttempts then
        scheduleEvent(tryAfterOpen, retryDelay)
        return
      end

      scheduleEvent(function()
        if g_game.isOnline() then
          pcall(function()
            g_game.close(container)
          end)
        end
      end, 50)
      return
    end

    scheduleEvent(function()
      if g_game.isOnline() then
        pcall(function()
          g_game.close(container)
        end)
      end
    end, closeDelay or 120)
  end

  scheduleEvent(tryAfterOpen, sameActiveSlot and 120 or 80)
  return true
end

local function trySendOpcode(slot)
  if not g_game.isOnline() then return false end
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return false end

  local realSlot = tonumber(slotData[slot] and slotData[slot].slot) or slot
  local payload = { action = 'useSlot', slot = realSlot }

  local opcodesToTry = { OPCODE_POKEBAR }
  if OPCODE_POKEBAR_LEGACY ~= OPCODE_POKEBAR then
    opcodesToTry[#opcodesToTry + 1] = OPCODE_POKEBAR_LEGACY
  end

  for i = 1, #opcodesToTry do
    local opcodeToUse = opcodesToTry[i]

    if protocolGame.sendExtendedJSONOpcode then
      local ok = pcall(function()
        protocolGame:sendExtendedJSONOpcode(opcodeToUse, payload)
      end)
      if ok then return true end
    end

    if protocolGame.sendExtendedOpcode then
      local ok = pcall(function()
        protocolGame:sendExtendedOpcode(opcodeToUse, json.encode(payload))
      end)
      if ok then return true end
    end
  end

  return false
end

local function trySendLegacyTalk(slot)
  if not g_game.isOnline() then return false end

  local realSlot = tonumber(slotData[slot] and slotData[slot].slot) or tonumber(slot) or 1
  local ok = pcall(function()
    g_game.talk('!p ' .. realSlot)
  end)
  return ok
end

local function onUseSlot(slot)
  local data = slotData[slot]
  if not data or not data.name or data.name == '' then
    return
  end

  if not g_game.isOnline() then
    return
  end

  local activeSlot = getActiveSlot()
  local ballSlotOpen = findBallSlotContainer() ~= nil
  if not activeSlot and not ballSlotOpen then
    if trySendOpcode(slot) then
      return
    end
  end

  if tryUseOpenBallSlot(slot) then
    return
  end

  if tryUseClosedBallSlot(slot) then
    return
  end

  if trySendLegacyTalk(slot) then
    return
  end

  trySendOpcode(slot)
end

local function bindSlotClicks()
  for i = 1, TOTAL_SLOTS do
    local bar = getSlotWidget(i, 'bar')
    if bar then
      local index = i
      bar.onMouseRelease = function(widget, mousePos, mouseButton)
        if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
          onUseSlot(index)
          return true
        end
        return false
      end
    end
  end
end

local function parseLegacyPayload(buffer)
  local slots = {}
  for name in tostring(buffer):gmatch('([^,]+),%s*') do
    if name and name ~= '' then
      slots[#slots + 1] = {
        slot = #slots + 1,
        name = name,
        level = 1,
        looktype = 0,
        healthPercent = 100,
        active = false,
        usable = true
      }
      if #slots >= TOTAL_SLOTS then break end
    end
  end
  return slots
end

local function onPokebarOpcode(protocol, opcode, buffer)
  if not pokeBarWindow then return end

  local slots = nil
  local ok, payload = pcall(function() return json.decode(buffer) end)
  if ok and type(payload) == 'table' and type(payload.slots) == 'table' then
    transportMode = 'json'
    slots = payload.slots
  else
    transportMode = 'legacy'
    slots = parseLegacyPayload(buffer)
  end

  resetAllSlots()
  local visibleSlots = math.min(#slots, TOTAL_SLOTS)
  for i = 1, visibleSlots do
    slotData[i] = slots[i]
    renderSlot(i, slots[i])
  end
  updateWindowSizeBySlots(visibleSlots)

  pokeBarWindow:show()
  pokeBarWindow:raise()
  if pokeBarButton then
    pokeBarButton:setOn(true)
  end

  local inv = modules.game_inventory
  if inv and type(inv.refreshPbsFromLegBag) == 'function' then
    pcall(function() inv.refreshPbsFromLegBag() end)
  end
end

local function requestSync()
  if not g_game.isOnline() then return end
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end

  local payload = { action = 'requestSync' }
  local sent = false
  if protocolGame.sendExtendedJSONOpcode then
    local ok = pcall(function()
      protocolGame:sendExtendedJSONOpcode(OPCODE_POKEBAR, payload)
    end)
    if ok then
      sent = true
    end
  end

  if not sent and protocolGame.sendExtendedOpcode then
    pcall(function()
      protocolGame:sendExtendedOpcode(OPCODE_POKEBAR, json.encode(payload))
    end)
  end
end

local function stopAutoSync()
  if syncEvent then
    removeEvent(syncEvent)
    syncEvent = nil
  end
end

local function startAutoSync()
  stopAutoSync()

  local function loop()
    if terminating or not pokeBarWindow or not g_game.isOnline() then
      syncEvent = nil
      return
    end

    requestSync()

    syncEvent = scheduleEvent(function()
      loop()
    end, 1000)
  end

  loop()
end

local function showWindow()
  if not pokeBarWindow then return end
  pokeBarWindow:show()
  pokeBarWindow:raise()
  if pokeBarButton then
    pokeBarButton:setOn(true)
  end
  requestSync()
  startAutoSync()
end

local function hideWindow()
  if not pokeBarWindow then return end
  pokeBarWindow:hide()
  if pokeBarButton then
    pokeBarButton:setOn(false)
  end
  stopAutoSync()
end

function toggle()
  if not pokeBarWindow or not pokeBarButton then return end
  if pokeBarWindow:isVisible() then
    hideWindow()
  else
    showWindow()
  end
end

function init()
  pokeBarWindow = g_ui.displayUI('pokebar')
  if not pokeBarWindow then return end
  positionSaveEnabled = false
  applySavedPokebarPosition()
  pokeBarWindow:hide()
  createSlotWidgets()
  resetAllSlots()
  bindSlotClicks()

  pokeBarWindow.onGeometryChange = function()
    scheduleSavePokebarPosition()
  end
  positionSaveEnabled = true

  pokeBarButton = modules.client_topmenu.addLeftToggleButton('pbarButton', tr('Poke Bar'), '/images/topbuttons/pokebar', toggle)
  pokeBarButton:setWidth(34)
  pokeBarButton:setOn(false)

  connect(g_game, {
    onGameStart = showWindow,
    onGameEnd = hideWindow
  })

  if ProtocolGame and ProtocolGame.registerExtendedOpcode then
    local okMain = pcall(function()
      ProtocolGame.registerExtendedOpcode(OPCODE_POKEBAR, onPokebarOpcode)
    end)
    if okMain then
      registeredOpcodes[OPCODE_POKEBAR] = true
    end

    if OPCODE_POKEBAR_LEGACY ~= OPCODE_POKEBAR then
      local okLegacy = pcall(function()
        ProtocolGame.registerExtendedOpcode(OPCODE_POKEBAR_LEGACY, onPokebarOpcode)
      end)
      if okLegacy then
        registeredOpcodes[OPCODE_POKEBAR_LEGACY] = true
      end
    end
  end

  if g_game.isOnline() then
    showWindow()
    requestSync()
    startAutoSync()
  end
end

function getFilledTeamSlotCount()
  local n = 0
  for i = 1, TOTAL_SLOTS do
    local d = slotData[i]
    if d and tostring(d.name or '') ~= '' then n = n + 1 end
  end
  return n
end

function terminate()
  if terminating then return end
  terminating = true
  positionSaveEnabled = false
  stopAutoSync()
  flushSavePokebarPosition()

  if ProtocolGame and ProtocolGame.unregisterExtendedOpcode then
    for opcode, _ in pairs(registeredOpcodes) do
      pcall(function()
        ProtocolGame.unregisterExtendedOpcode(opcode)
      end)
    end
  end
  registeredOpcodes = {}

  disconnect(g_game, {
    onGameStart = showWindow,
    onGameEnd = hideWindow
  })

  local button = pokeBarButton
  pokeBarButton = nil
  if button then
    pcall(function()
      button:destroy()
    end)
  end

  local window = pokeBarWindow
  pokeBarWindow = nil
  if window then
    pcall(function()
      window:destroy()
    end)
  end
  slotWidgets = {}
  slotData = {}
  terminating = false
end
