-- spell bar by Pota based on draky's
local spells = {}
local spellsNumber = 12
local OPCODE_SKILLBAR = 52
local side = 'vertical'
local sbw
local spellBarWindow
local movesVerticalPanel
local movesHorizontalPanel
local hideLevel = false
local SETTINGS_SKILLBAR = 'pokemonmoves-window'
local SPELL_SLOT_SIZE = 32
local SPELL_SLOT_SPACING = 5
local MIN_CAST_INTERVAL_MS = 120
local cooldownEvents = {}
local spellHotkeys = {}
local boundSpellHotkeys = {}
local bindAllSpellHotkeys
local rebindRetryEvents = {}
local lastHotkeyCastAt = 0
local function onGameEndHideMoves()
  if sbw then
    sbw:hide()
  end
end

local function onGameStartRebindHotkeys()
  if bindAllSpellHotkeys then
    bindAllSpellHotkeys()
  end

  for _, delay in ipairs({150, 400, 900}) do
    rebindRetryEvents[#rebindRetryEvents + 1] = scheduleEvent(function()
      if bindAllSpellHotkeys then
        bindAllSpellHotkeys()
      end
    end, delay)
  end
end

local function normalizeCooldownMs(value)
  local n = tonumber(value) or 0
  if n <= 0 then return 0 end
  -- Compatibilidade: algumas bases enviam speed em segundos (1, 2, 5...),
  -- outras já em milissegundos (1000, 2000...).
  if n <= 60 then
    return math.floor(n * 1000)
  end
  return math.floor(n)
end

local function formatCooldownText(remainingMs)
  local ms = math.max(0, tonumber(remainingMs) or 0)
  return string.format('%.1f', ms / 1000)
end

local function loadWindowSettings()
  local node = g_settings.getNode(SETTINGS_SKILLBAR)
  if type(node) ~= 'table' then return end

  if node.side == 'horizontal' or node.side == 'vertical' then
    side = node.side
  end

  if sbw and node.pos and tonumber(node.pos.x) and tonumber(node.pos.y) then
    if sbw.breakAnchors then
      sbw:breakAnchors()
    end
    sbw:setPosition({ x = tonumber(node.pos.x), y = tonumber(node.pos.y) })
  end

  if type(node.hotkeys) == 'table' then
    spellHotkeys = node.hotkeys
  end
end

local function saveWindowSettings()
  if not sbw then return end
  local pos = sbw:getPosition()
  if not pos then return end

  g_settings.setNode(SETTINGS_SKILLBAR, {
    side = side,
    pos = { x = pos.x, y = pos.y },
    hotkeys = spellHotkeys
  })
end

local function updateSpellTooltip(icon, slot)
  local hotkey = spellHotkeys[tostring(slot)]
  if hotkey and hotkey ~= '' then
    icon:setTooltip(icon.words .. ' [' .. hotkey .. ']')
  else
    icon:setTooltip(icon.words)
  end
end

local function getHotkeyIconText(slot)
  local hotkey = spellHotkeys[tostring(slot)]
  if not hotkey or hotkey == '' then
    return ''
  end
  return hotkey
end

local function unbindAllSpellHotkeys()
  for combo, bindData in pairs(boundSpellHotkeys) do
    for _, entry in ipairs(bindData) do
      g_keyboard.unbindKeyDown(combo, entry.callback, entry.widget)
    end
  end
  boundSpellHotkeys = {}
end

local function tryUseSpellBySlot(slot)
  if not g_game.isOnline() then return end
  local now = g_clock.millis()
  if now < (lastHotkeyCastAt + MIN_CAST_INTERVAL_MS) then return end
  local progress = sbw and sbw:recursiveGetChildById('progress' .. slot)
  if progress and progress:getPercent() < 100 then return end
  lastHotkeyCastAt = now
  g_game.talk('m' .. slot)
end

bindAllSpellHotkeys = function()
  unbindAllSpellHotkeys()

  for key, combo in pairs(spellHotkeys) do
    local slot = tonumber(key) or tonumber(tostring(key):match('%d+'))
    local keyCombo = (type(combo) == 'string' and combo) or tostring(combo or '')
    if slot and keyCombo ~= '' then
      keyCombo = keyCombo:match('^%s*(.-)%s*$')
      local callback = function()
        tryUseSpellBySlot(slot)
      end
      boundSpellHotkeys[keyCombo] = boundSpellHotkeys[keyCombo] or {}
      g_keyboard.bindKeyDown(keyCombo, callback)
      table.insert(boundSpellHotkeys[keyCombo], { callback = callback, widget = nil })
    end
  end
end

local function clearSlotHotkey(slot)
  spellHotkeys[tostring(slot)] = nil
  saveWindowSettings()
  bindAllSpellHotkeys()
  getSpells(spells)
end

local function setSlotHotkey(slot, combo)
  if not combo or combo == '' then return end
  for k, v in pairs(spellHotkeys) do
    if v == combo then
      spellHotkeys[k] = nil
    end
  end
  spellHotkeys[tostring(slot)] = combo
  saveWindowSettings()
  bindAllSpellHotkeys()
  getSpells(spells)
end

local function openHotkeyAssignWindow(slot)
  local assignWindow = g_ui.createWidget('MoveHotkeyAssignWindow', rootWidget)
  assignWindow:grabKeyboard()
  local comboPreview = assignWindow:getChildById('comboPreview')
  local addButton = assignWindow:getChildById('addButton')
  local selectedCombo = nil

  assignWindow.onKeyDown = function(widget, keyCode, keyboardModifiers)
    local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
    selectedCombo = keyCombo
    comboPreview:setText('Tecla atual: ' .. keyCombo)
    addButton:enable()
    return true
  end

  addButton.onClick = function()
    if selectedCombo and selectedCombo ~= '' then
      setSlotHotkey(slot, selectedCombo)
    end
    assignWindow:destroy()
  end
end

local function openSpellContextMenu(slot)
  local menu = g_ui.createWidget('PopupMenu')
  menu:addOption('Set Hotkey', function() openHotkeyAssignWindow(slot) end)
  if spellHotkeys[tostring(slot)] then
    menu:addOption('Clear Hotkey', function() clearSlotHotkey(slot) end)
  end
  menu:display()
end

local function getSpellSlotByMousePosition(mousePos)
  if not sbw or not mousePos then return nil end
  for i = 1, spellsNumber do
    local icon = sbw:recursiveGetChildById('spell' .. i)
    if icon and icon:isVisible() and icon:containsPoint(mousePos) then
      return i
    end
  end
  return nil
end

function msgcontains(message, keyword)
  local message, keyword = message:lower(), keyword:lower()
  if message == keyword then
    return true
  end
  return message:find(keyword) and not message:find('(%w+)' .. keyword)
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function getOpCode(protocol, opcode, buffer)
  local moves = {}
  local cooldowns = {}
  local cooldownRemaining = {}
  spells = {}
  for match in string.gmatch(buffer, "([^,]+),%s*") do
    if tonumber(match) == nil then
      moves[#moves + 1] = match
    else
      if #cooldowns < #moves then
        cooldowns[#cooldowns + 1] = tonumber(match)
      else
        cooldownRemaining[#cooldownRemaining + 1] = tonumber(match)        
      end
    end
  end
  for i = 1, #moves do
     local inside = {id = i, words = moves[i], lvl = 1, exhaustion = cooldowns[i], cooldownRemaining = cooldownRemaining[i]}
     table.insert(spells, inside)
  end
  getSpells(spells)
  level = g_game.getLocalPlayer():getLevel()
  sbw:show()
end

local function getActiveMovesPanel()
  if side == 'horizontal' then
    return movesHorizontalPanel
  end
  return movesVerticalPanel
end

local function applySideLayout()
  if not movesVerticalPanel or not movesHorizontalPanel then return end
  local isHorizontal = side == 'horizontal'
  movesHorizontalPanel:setVisible(isHorizontal)
  movesVerticalPanel:setVisible(not isHorizontal)
end

function init()
  sbw = g_ui.displayUI('pokemonmoves')
  sbw:move(500,200)
  loadWindowSettings()
  sbw.onGeometryChange = function()
    saveWindowSettings()
  end
  g_mouse.bindPress(sbw, function(mousePos, mouseButton)
    if mouseButton ~= MouseRightButton then return false end
    local slot = getSpellSlotByMousePosition(mousePos)
    createMenu(slot)
    return true
  end, MouseRightButton)
  movesVerticalPanel = sbw:recursiveGetChildById('movesVertical')
  movesHorizontalPanel = sbw:recursiveGetChildById('movesHorizontal')
  applySideLayout()
  sbw:hide()
  connect(g_game, 'onTalk', messageSentCallback)
  connect(g_game, {
    onGameEnd = onGameEndHideMoves,
    onGameStart = onGameStartRebindHotkeys
  })
  connect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
  ProtocolGame.registerExtendedOpcode(OPCODE_SKILLBAR, getOpCode)
  addEvent(function()
    bindAllSpellHotkeys()
  end)
  onGameStartRebindHotkeys()
end

function onLevelChange(localPlayer, value, percent)
  getSpells(spells)
end

function messageSentCallback(name, level, mode, text, channelId, pos)
  if not g_game.isOnline() then return end
  if g_game.getLocalPlayer():getName() ~= name then return end
  if mode ~= 34 then return end
  if msgcontains(text, "use") then
    text = string.gsub(text, "use ", "")
    text = string.gsub(text, "!", "")
    text = text:split(", ")[2]
    for i = 1, #spells do
      if spells[i].words:lower() == text:lower() then 
        startDownDelay(i)
        break
      end
    end
  elseif msgcontains(text, "thanks") then
    sbw:hide()
  end
end

function terminate()
  for _, event in ipairs(rebindRetryEvents) do
    if event then
      removeEvent(event)
    end
  end
  rebindRetryEvents = {}
  for _, event in pairs(cooldownEvents) do
    if event then
      removeEvent(event)
    end
  end
  cooldownEvents = {}
  unbindAllSpellHotkeys()
  saveWindowSettings()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_SKILLBAR)
  sbw:destroy()
  disconnect(g_game, {
    onGameEnd = onGameEndHideMoves,
    onGameStart = onGameStartRebindHotkeys
  })
  disconnect(g_game, 'onTalk', messageSentCallback)
  disconnect(LocalPlayer, {
    onLevelChange = onLevelChange
  })
end

function createMenu(slot)
  local menu = g_ui.createWidget('PopupMenu')
  if slot then
    menu:addOption('Set Hotkey', function() openHotkeyAssignWindow(slot) end)
    if spellHotkeys[tostring(slot)] then
      menu:addOption('Clear Hotkey', function() clearSlotHotkey(slot) end)
    end
    menu:addSeparator()
  end
  if side == 'horizontal' then
    menu:addOption('Set Vertical', function() side = 'vertical' saveWindowSettings() getSpells(spells) end)
  else
    menu:addOption('Set Horizontal',function() side = 'horizontal' saveWindowSettings() getSpells(spells) end)
  end
  menu:display()
end



function destroySpells()
  for i = 1, spellsNumber do
    if cooldownEvents[i] then
      removeEvent(cooldownEvents[i])
      cooldownEvents[i] = nil
    end
  end
  if movesVerticalPanel then
    movesVerticalPanel:destroyChildren()
  end
  if movesHorizontalPanel then
    movesHorizontalPanel:destroyChildren()
  end
end

function getSpells(table)
  destroySpells()
  applySideLayout()
  spellBarWindow = getActiveMovesPanel()
  local player = g_game.getLocalPlayer()
  local value = #table
  if not player or not spellBarWindow then return end
  for i = 1, #table do
    if (table[i].lvl > player:getLevel()) and hideLevel == true then
      value = i - 1
      break
    end
    if i == #table then value = i end
    local slotWidget = g_ui.createWidget('SpellSlot', spellBarWindow)
    local icon = slotWidget:recursiveGetChildById('spellIcon')
    local progress = slotWidget:recursiveGetChildById('spellProgress')
    local hotkeyLabel = slotWidget:recursiveGetChildById('hotkeyText')
    if not icon or not progress then
      slotWidget:destroy()
      break
    end
    icon:setId('spell'..i)
    local pathOn = "moves_icon/"..table[i].words.."_on.png"
    icon:setImageSource(pathOn)
    icon:setVisible(true) 
    icon.words = table[i].words
    icon.lvl = table[i].lvl
    icon.exhaustion = normalizeCooldownMs(table[i].exhaustion)
    local remaining = normalizeCooldownMs(table[i].cooldownRemaining)
    if icon.exhaustion > 0 and remaining > icon.exhaustion then
      remaining = icon.exhaustion
    end
    icon.exhaustionNeeded = math.max(0, icon.exhaustion - remaining)
    updateSpellTooltip(icon, i)
    progress:setId('progress'..i)
    progress:setVisible(true)
    progress:setPercent(100)
    if player:getLevel() < icon.lvl then
      progress:setText('L'..icon.lvl)
      progress:setColor('red')
      progress:setPercent(0)
    elseif icon.exhaustion > 0 and remaining > 0 then
      progress:setPercent(math.floor((icon.exhaustionNeeded * 100) / icon.exhaustion))
      progress:setText(formatCooldownText(remaining))
      progress:setColor('red')
      cooldownEvents[i] = scheduleEvent(function() spellTimeleft(i) end, 100)
    else
      progress:setText('')
    end
    progress:setPhantom(true)
    if hotkeyLabel then
      hotkeyLabel:setText(getHotkeyIconText(i))
    end

    icon.onClick = function() useSpell(i) end
    icon.onMouseRelease = function(self, mousePos, mouseButton)
      if mouseButton == MouseRightButton then
        openSpellContextMenu(i)
        return true
      end
      return false
    end
  end
  local slots = math.max(0, tonumber(value) or 0)
  local contentSize = (slots * SPELL_SLOT_SIZE) + (math.max(0, slots - 1) * SPELL_SLOT_SPACING)
  if side == 'horizontal' then
    sbw:setHeight(83)
    sbw:setWidth(math.max(64, contentSize + 32))
  else
    sbw:setWidth(64)
    sbw:setHeight(math.max(51, contentSize + 19))
  end
end

function useSpell(i)
  local progress = sbw:recursiveGetChildById('progress'..i)
  local player = g_game.getLocalPlayer()
  if not player then return end
  if progress:getPercent() < 100 then return modules.game_textmessage.displayFailureMessage('Sorry, not possible.') end
  g_game.talk('m'..i)
end

function startDownDelay(i)
  local spell = sbw:recursiveGetChildById('spell'..i)
  if not spell then return end
  local progress = sbw:recursiveGetChildById('progress'..i)
  if cooldownEvents[i] then
    removeEvent(cooldownEvents[i])
    cooldownEvents[i] = nil
  end
  progress:setPercent(0)
  progress:setText(formatCooldownText(spell.exhaustion))
  progress:setColor('red')
  spell.exhaustionNeeded = 0
  cooldownEvents[i] = scheduleEvent(function() spellTimeleft(i) end, 100)
end

function spellTimeleft(i)
  local spell = sbw:recursiveGetChildById('spell'..i)
  if not spell then return end
  local progress = sbw:recursiveGetChildById('progress'..i)
  spell.exhaustionNeeded = spell.exhaustionNeeded + 100
  if spell.exhaustionNeeded < spell.exhaustion then
    progress:setPercent(math.floor(((spell.exhaustionNeeded) * 100)/spell.exhaustion))
    progress:setText(formatCooldownText(spell.exhaustion - spell.exhaustionNeeded))
    progress:setColor('red')
  else
    progress:setPercent(100)
    progress:setText('')
    spell.exhaustionNeeded = 0    
    cooldownEvents[i] = nil
    return true
  end
  cooldownEvents[i] = scheduleEvent(function() spellTimeleft(i) end, 100)
end