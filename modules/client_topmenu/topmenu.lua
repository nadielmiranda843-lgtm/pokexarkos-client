-- private variables
local topMenu
local leftButtonsPanel
local centerButtonsPanel
local rightButtonsPanel
local leftGameButtonsPanel
local rightGameButtonsPanel
local list = {}

dofile('/modules/client_topmenu/topbuttons.lua')

local function addButton(id, description, icon, callback, panel, toggle, front, visible)
  local class = 'TopButton'

  local button = panel:getChildById(id)
  if not button then
    button = g_ui.createWidget(class)
    if front then
      panel:insertChild(1, button)
    else
      panel:addChild(button)
    end
  end
  
  if not visible then
    button:setVisible(false)
    table.insert(list, id)
  end
  
  button:setId(id)
  button:setTooltip(description)
  button:setIcon(resolvepath(icon, 3))
  button:setIconWidth(32)
  button:setIconHeight(32)
  button:setIconOffsetX(0)
  button:setIconOffsetY(-2)

  button.onMouseRelease = function(widget, mousePos, mouseButton)
    if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
      callback()
      return true
    end
  end

  return button
end

function init()
  connect(g_game, { 
    onGameStart = online,
    onGameEnd = offline,
    onPingBack = updatePing 
  })

  connect(g_app, { onFps = updateFps })

  topMenu = g_ui.displayUI('topmenu')

  leftButtonsPanel = topMenu:getChildById('leftButtonsPanel')
  centerButtonsPanel = topMenu:getChildById('centerGameButtonsPanel')
  rightButtonsPanel = topMenu:getChildById('rightButtonsPanel')
  leftGameButtonsPanel = topMenu:getChildById('leftGameButtonsPanel')
  rightGameButtonsPanel = topMenu:getChildById('rightGameButtonsPanel')
  pingLabel = topMenu:getChildById('pingLabel')
  fpsLabel = topMenu:getChildById('fpsLabel')

  for _, btn in ipairs(TopButtons) do
    addLeftGameButton(
      btn.id,
      btn.tooltip,
      btn.icon,
      btn.callback
    )
  end

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  disconnect(g_game, { 
    onGameStart = online,
    onGameEnd = offline,
    onPingBack = updatePing 
  })

  disconnect(g_app, { onFps = updateFps })

  topMenu:destroy()
end

function online()
  showGameButtons()

  addEvent(function()
    if modules.client_options.getOption('showPing') and 
      (g_game.getFeature(GameClientPing) or g_game.getFeature(GameExtendedClientPing)) then
      pingLabel:show()
    else
      pingLabel:hide()
    end
  end)
end

function offline()
  hideGameButtons()
  pingLabel:hide()
end

function updateFps(fps)
  fpsLabel:setText('FPS: ' .. fps)
end

function updatePing(ping)
  local text = 'Ping: '
  local color

  if ping < 0 then
    text = text .. "??"
    color = 'yellow'
  else
    text = text .. ping .. ' ms'
    if ping >= 500 then
      color = 'red'
    elseif ping >= 250 then
      color = 'yellow'
    else
      color = 'green'
    end
  end

  pingLabel:setColor(color)
  pingLabel:setText(text)
end

function setPingVisible(enable)
  pingLabel:setVisible(enable)
end

function setFpsVisible(enable)
  fpsLabel:setVisible(enable)
end

function addLeftButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, false, front, true)
end

function addLeftToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, true, front, true)
end

function addRightButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, false, front, false)
end

function addRightToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, true, front, false)
end

function addLeftGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, false, front, true)
end

function addLeftGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, true, front, true)
end

function addRightGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, false, front, false)
end

function addRightGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, centerButtonsPanel, true, front, false)
end

function showGameButtons()
  leftGameButtonsPanel:show()
  rightGameButtonsPanel:show()

  for _, value in pairs(list) do
    local button = centerButtonsPanel:getChildById(value)
    if button then
      button:setVisible(true)
    end
  end
end

function hideGameButtons()
  leftGameButtonsPanel:hide()
  rightGameButtonsPanel:hide()

  for _, value in pairs(list) do
    local button = centerButtonsPanel:getChildById(value)
    if button then
      button:setVisible(false)
    end
  end
end

function getButton(id)
  return topMenu:recursiveGetChildById(id)
end

function getTopMenu()
  return topMenu
end

function hide()
  topMenu:hide()
end

function show()
  topMenu:show()
  topMenu:raise()
  topMenu:focus()
end

function toggle()
  local menu = getTopMenu()
  if not menu then return end

  if menu:isVisible() then
    menu:hide()
    modules.client_background.getBackground():addAnchor(AnchorTop, 'parent', AnchorTop)
    modules.client_hide.getHideBtn():setImageSource("/images/ui/hide")
    modules.client_hide.getHideBtn():setMarginTop(0)
  else
    modules.client_hide.getHideBtn():setMarginTop(40)
    menu:show()
    modules.client_hide.getHideBtn():setImageSource("/images/ui/show")
  end
end