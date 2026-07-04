local clientUiDebug
local clientUiDebugLabel
local clientUiDebugLabelDown
local clientUiDebugHighlightWidget
local isClientUiDebugActive = false

function onClientUiDebuggerMouseMove(mouseBindWidget, mousePos, mouseMove)
  local widgets = rootWidget:recursiveGetChildrenByPos(mousePos)

  local smallestWidget
  for _, widget in pairs(widgets) do
    if (widget:getId() ~= 'highlightWidget' and widget:getId() ~= 'toolTip') then
      if (not smallestWidget or
        (widget:getSize().width <= smallestWidget:getSize().width and widget:getSize().height <= smallestWidget:getSize().height)
        ) then
        smallestWidget = widget
      end
    end
  end

  if smallestWidget then
    clientUiDebugHighlightWidget:setPosition(smallestWidget:getPosition())
    clientUiDebugHighlightWidget:setSize(smallestWidget:getSize())
    clientUiDebugHighlightWidget:raise()
  end

  local widgetNames = {}
  for wi = #widgets, 1, -1 do
    local widget = widgets[wi]
    if (widget:getId() ~= 'highlightWidget') then
      table.insert(widgetNames, widget:getClassName() .. ' -> ' .. widget:getId())
    end
  end

  local lastWidgetName = widgetNames[#widgetNames] or "No widget found"
  clientUiDebugLabelDown:setText(lastWidgetName)
  clientUiDebugHighlightWidget:setText(lastWidgetName)
  clientUiDebugLabel:setText(table.concat(widgetNames, " -> "))
end

function toggleClientUiDebugger()
  if isClientUiDebugActive then
    disconnect(rootWidget, {
      onMouseMove = onClientUiDebuggerMouseMove,
    })

    if clientUiDebug or clientUiDebugHighlightWidget or clientUiDebugLabelDown then
      clientUiDebug:hide()
      clientUiDebugHighlightWidget:hide()
      clientUiDebugLabelDown:hide()
    end

    if g_ui.isDrawingDebugBoxes() then
      g_ui.setDebugBoxesDrawing(false)
    end

    g_keyboard.unbindKeyDown('Shift+X')
    g_keyboard.unbindKeyDown('Shift+C')
  else
    connect(rootWidget, {
      onMouseMove = onClientUiDebuggerMouseMove,
    })
    if not clientUiDebug then
      clientUiDebug = g_ui.displayUI('client_uidebug')
      clientUiDebugLabel = clientUiDebug:getChildById('clientUiDebugLabel')
    end
    if not clientUiDebugLabelDown then
      clientUiDebugLabelDown = g_ui.createWidget('clientUiDebugLabelDown', rootWidget)
    end
    if not clientUiDebugHighlightWidget then
      clientUiDebugHighlightWidget = g_ui.createWidget('HighlightWidget', rootWidget)
    end
    
    clientUiDebug:show()
    clientUiDebugHighlightWidget:show()
    clientUiDebugLabelDown:show()

    g_keyboard.bindKeyDown('Shift+C', function()
      local text = clientUiDebugLabelDown:getText()
      local id = text:match("-> (.+)$") or text
      g_window.setClipboardText(id)
    end)
    g_keyboard.bindKeyDown('Shift+X', function()
      g_ui.setDebugBoxesDrawing(not g_ui.isDrawingDebugBoxes())
    end)
  end

  isClientUiDebugActive = not isClientUiDebugActive
end

function init()
  clientUiDebug = g_ui.displayUI('client_uidebug')
  clientUiDebugLabel = clientUiDebug:getChildById('clientUiDebugLabel')
  clientUiDebugLabelDown = g_ui.createWidget('clientUiDebugLabelDown', rootWidget)
  clientUiDebugHighlightWidget = g_ui.createWidget('HighlightWidget', rootWidget)

  clientUiDebug:hide()
  clientUiDebugHighlightWidget:hide()
  clientUiDebugLabelDown:hide()
  g_keyboard.bindKeyDown("Ctrl+Shift+]", toggleClientUiDebugger)
end


function terminate()
  if isClientUiDebugActive then
    disconnect(rootWidget, {
      onMouseMove = onClientUiDebuggerMouseMove,
    })
  end
  if clientUiDebug or clientUiDebugHighlightWidget or clientUiDebugLabelDown then
    clientUiDebug:destroy()
    clientUiDebugHighlightWidget:destroy()
    clientUiDebugLabelDown:destroy()
  end
end
