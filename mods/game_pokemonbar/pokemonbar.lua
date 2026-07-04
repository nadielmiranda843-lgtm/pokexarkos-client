-- bar by Pota
local pokes = {}
local pokesNumber = 6
local OPCODE_POKEBAR = 53
local side = 'horizontal'
local pkb -- window widget
local pokeBarWindow -- UIWindow
local hideLevel = false -- hide pokes that can not be used due to level dependence

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
  -- Este módulo é legado; ignora payload JSON do pokebar novo.
  local ok, decoded = pcall(function() return json.decode(buffer) end)
  if ok and type(decoded) == 'table' then
    return
  end

  local names = {}
  pokes = {}
  for match in string.gmatch(buffer, "([^,]+),%s*") do
    if tonumber(match) == nil then
      names[#names + 1] = match
    end
  end
  for i = 1, #names do
     local inside = {id = i, words = names[i], lvl = 1}
     table.insert(pokes, inside)
  end
  getPortraits(pokes)
  level = g_game.getLocalPlayer():getLevel()
  pkb:show()
end

function init()
  pkb = g_ui.displayUI('pokemonbar')
  pkb:move(100,50)
  g_mouse.bindPress(pkb, function() createMenu() end, MouseRightButton)
  pkb:hide()
  connect(g_game, 'onTalk', messageSentCallback)
  connect(g_game, { onGameEnd = function() pkb:hide() end })
  connect(LocalPlayer, {
    onLevelChange = onLevelChange,
--    onFreeCapacityChange = onFreeCapacityChange
  })
  ProtocolGame.registerExtendedOpcode(OPCODE_POKEBAR, getOpCode)
end

function onLevelChange(localPlayer, value, percent)
  getPortraits(pokes)
end

--function onFreeCapacityChange(player, freeCapacity)
--  print(player, freeCapacity)
--end

function messageSentCallback(name, level, mode, text, channelId, pos)
  if not g_game.isOnline() then return end
  if g_game.getLocalPlayer():getName() ~= name then return end
  if mode ~= 34 then return end
  if msgcontains(text, "use") then
    text = string.gsub(text, "use ", "")
    text = string.gsub(text, "!", "")
    text = text:split(", ")[2]
    for i = 1, #pokes do
      if pokes[i].words:lower() == text:lower() then 
        startDownDelay(i)
        break
      end
    end
  elseif msgcontains(text, "thanks") then
--    pkb:hide()
  end
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(OPCODE_POKEBAR)
  pkb:destroy()
  disconnect(g_game, { onGameEnd = function() pkb:hide() end })
  disconnect(g_game, 'onTalk', messageSentCallback)
  disconnect(LocalPlayer, {
    onLevelChange = onLevelChange,
--    onFreeCapacityChange = onFreeCapacityChange
  })
end

function createMenu()
  local menu = g_ui.createWidget('PopupMenu')
  if side == 'horizontal' then
    menu:addOption('Set Vertical', function() side = 'vertical' getPortraits(pokes) end)
  else
    menu:addOption('Set Horizontal',function() side = 'horizontal' getPortraits(pokes) end)
  end
  menu:display()
end

function destroyPortraits()
  for i = 1, pokesNumber do
    if pkb:recursiveGetChildById('poke'..i) == nil then break end
    pkb:recursiveGetChildById('poke'..i):destroy()
    pkb:recursiveGetChildById('progress'..i):destroy()
  end
end

function getPortraits(table)
  destroyPortraits()
  pokeBarWindow = pkb:recursiveGetChildById('mainWindow')
  local player = g_game.getLocalPlayer()
  local value = #table
  local width = 38
  local height = 38
  if not player then return end
  for i = 1, #table do
    if (table[i].lvl > player:getLevel()) and hideLevel == true then
      value = i - 1
      break
    end
    if i == #table then value = i end
    icon = g_ui.createWidget('PokeButton',pokeBarWindow)
    --icon:
    icon:setId('poke'..i)
    local safeName = table[i].words:lower():gsub("[^%w%s%-_]", "")
    local pathOn = "/images/game/bar_icon/" .. safeName .. ".png"
    icon:setImageSource(pathOn)
    icon:setVisible(true) 
    icon.words = table[i].words
    icon.lvl = table[i].lvl
    icon:setTooltip(table[i].words)
    if side == 'horizontal' then
      icon:setMarginTop(3)
      height = 38
      width = (i) * 32 + 2*(i)
      icon:setMarginLeft((i) * 32 + 2*(i) - 32)
    else
      icon:setMarginLeft(3)
      icon:setMarginTop((i) * 32 + 2*(i) - 32)
      width = 38
      height = (i) * 32 + 2*(i)
    end
    --progress:
    progress = g_ui.createWidget('PokeProgress',pokeBarWindow)
    progress:setId('progress'..i)
    progress:setVisible(true)
    progress:setPercent(100)
    progress:setMarginLeft(icon:getMarginLeft())
    progress:setMarginTop(icon:getMarginTop())
    if player:getLevel() < icon.lvl then progress:setText('L'..icon.lvl) progress:setColor('red') progress:setPercent(0) end
    if progress:getPercent() == 100 then progress:setText('') elseif icon.lvl < player:getLevel() then progress:setText(progress:getPercent()) end
    progress:setPhantom(true)
    icon.onClick = function() usePoke(i) end
  end
  pkb:setHeight(height)
  pkb:setWidth(width)  
  pokeBarWindow:setSize(pkb:getSize())
end

function usePoke(i)
--  local progress = pkb:recursiveGetChildById('progress'..i)
  local player = g_game.getLocalPlayer()
  if not player then return end
  local icon = pkb:recursiveGetChildById('poke'..i)
--  if progress:getPercent() < 100 then return modules.game_textmessage.displayFailureMessage('Sorry, not possible.') end
  g_game.talk("!p "..i)
end
