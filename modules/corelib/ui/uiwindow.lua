-- @docclass
UIWindow = extends(UIWidget, "UIWindow")

function UIWindow.create()
  local window = UIWindow.internalCreate()
  window:setTextAlign(AlignTopCenter)
  window:setDraggable(true)  
  window:setAutoFocusPolicy(AutoFocusFirst)
  return window
end

function UIWindow:onKeyDown(keyCode, keyboardModifiers)
  if keyboardModifiers == KeyboardNoModifier then
    if keyCode == KeyEnter then
      signalcall(self.onEnter, self)
    elseif keyCode == KeyEscape then
      signalcall(self.onEscape, self)
    end
  end
end

function UIWindow:onFocusChange(focused)
  if focused then self:raise() end
end

function UIWindow:onDragEnter(mousePos)
  if self.static then
    return false
  end
  self:breakAnchors()
  self.movingReference = { x = mousePos.x - self:getX(), y = mousePos.y - self:getY() }
  return true
end

function UIWindow:onDragLeave(droppedWidget, mousePos)
  -- TODO: auto detect and reconnect anchors
end

function UIWindow:onDragMove(mousePos, mouseMoved)
  if self.static then
    return
  end
  local pos = { x = mousePos.x - self.movingReference.x, y = mousePos.y - self.movingReference.y }
  self:setPosition(pos)
  self:bindRectToParent()
end

function closeWindow(self, MainWindow)
  if MainWindow then
    self:hide()
  else
    self:getParent():hide()
  end
  modules.game_interface.gameMapPanel:setShader(false)
end

function toggleWindow(widget, checked)
  if checked then
    widget:show()
    widget:raise()
    g_effects.fadeIn(widget, 350)
    modules.game_interface.gameMapPanel:setShader("blur")
    return
  else
    g_effects.fadeOut(widget, 250)
    scheduleEvent(function ()
      widget:hide()
      modules.game_interface.gameMapPanel:setShader("")
    end, 300)
  end
end
