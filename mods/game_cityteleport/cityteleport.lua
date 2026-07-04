local OPCODE_CITY_TELEPORT = 111

local teleportWindow
local cityGridPanel
local confirmWindow
local pageDescriptionLabel
local categoryPanel
local categoryToggleButton
local pageKantoButton
local pageJohtoButton
local pageExtrasButton
local pageVipButton
local pageEventsButton
local cityButtons = {}

local currentPage = 'kanto'
local isCategoryPanelVisible = false

-- Registre aqui as cidades que devem aparecer no menu do cliente.
local TELEPORT_CITIES = {
  { id = 'pallet', name = 'Pallet Town', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'viridian', name = 'Viridian City', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'pewter', name = 'Pewter City', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'cerulean', name = 'Cerulean City', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'vermilion', name = 'Vermilion City', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'lavender', name = 'Lavender Town', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'celadon', name = 'Celadon City', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'fuchsia', name = 'Fuchsia City', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'saffron', name = 'Saffron City', page = 'kanto', positionLabel = '1024, 1025, 7' },
  { id = 'cinnabar', name = 'Cinnabar Island', page = 'kanto', positionLabel = 'A configurar' },
  { id = 'newbark', name = 'New Bark Town', page = 'johto', positionLabel = 'A configurar' },
  { id = 'cherrygrove', name = 'Cherrygrove City', page = 'johto', positionLabel = 'A configurar' },
  { id = 'violet', name = 'Violet City', page = 'johto', positionLabel = 'A configurar' },
  { id = 'azalea', name = 'Azalea Town', page = 'johto', positionLabel = 'A configurar' },
  { id = 'goldenrod', name = 'Goldenrod City', page = 'johto', positionLabel = 'A configurar' },
  { id = 'ecruteak', name = 'Ecruteak City', page = 'johto', positionLabel = 'A configurar' },
  { id = 'olivine', name = 'Olivine City', page = 'johto', positionLabel = 'A configurar' },
  { id = 'cianwood', name = 'Cianwood City', page = 'johto', positionLabel = 'A configurar' },
  { id = 'mahogany', name = 'Mahogany Town', page = 'johto', positionLabel = 'A configurar' },
  { id = 'blackthorn', name = 'Blackthorn City', page = 'johto', positionLabel = 'A configurar' },
  { id = 'demoniccity', name = 'Cidade Demoniaca', page = 'extras', positionLabel = 'A configurar' },
  { id = 'angelcity', name = 'Cidade dos Anjos', page = 'extras', positionLabel = 'A configurar' }
}

local PAGE_LABELS = {
  kanto = 'Kanto',
  johto = 'Johto',
  extras = 'Extras',
  vip = 'Vip',
  events = 'Eventos'
}

local PAGE_DESCRIPTIONS = {
  vip = 'Cidades em construcao',
  events = 'Cidades em construcao'
}

local function sendPayload(payload)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  if protocolGame.sendExtendedJSONOpcode then
    protocolGame:sendExtendedJSONOpcode(OPCODE_CITY_TELEPORT, payload)
    return true
  end

  if protocolGame.sendExtendedOpcode then
    protocolGame:sendExtendedOpcode(OPCODE_CITY_TELEPORT, json.encode(payload))
    return true
  end

  return false
end

local function clearConfirmWindow()
  if confirmWindow then
    confirmWindow:destroy()
    confirmWindow = nil
  end
end

local function updatePageButtons()
  if categoryToggleButton then
    local label = categoryToggleButton:recursiveGetChildById('regionButtonLabel')
    if label then
      label:setText('Cidades')
    end
  end

  if pageKantoButton then
    local label = pageKantoButton:recursiveGetChildById('regionButtonLabel')
    if label then
      label:setText(PAGE_LABELS.kanto)
    end
    pageKantoButton:setOpacity(currentPage == 'kanto' and 1 or 0.8)
  end

  if pageJohtoButton then
    local label = pageJohtoButton:recursiveGetChildById('regionButtonLabel')
    if label then
      label:setText(PAGE_LABELS.johto)
    end
    pageJohtoButton:setOpacity(currentPage == 'johto' and 1 or 0.8)
  end

  if pageExtrasButton then
    local label = pageExtrasButton:recursiveGetChildById('regionButtonLabel')
    if label then
      label:setText(PAGE_LABELS.extras)
    end
    pageExtrasButton:setOpacity(currentPage == 'extras' and 1 or 0.8)
  end

  if pageVipButton then
    local label = pageVipButton:recursiveGetChildById('regionButtonLabel')
    if label then
      label:setText(PAGE_LABELS.vip)
    end
    pageVipButton:setOpacity(currentPage == 'vip' and 1 or 0.8)
  end

  if pageEventsButton then
    local label = pageEventsButton:recursiveGetChildById('regionButtonLabel')
    if label then
      label:setText(PAGE_LABELS.events)
    end
    pageEventsButton:setOpacity(currentPage == 'events' and 1 or 0.8)
  end

  if pageDescriptionLabel then
    pageDescriptionLabel:setText(PAGE_DESCRIPTIONS[currentPage] or '')
  end
end

local function setCategoryPanelVisible(visible)
  isCategoryPanelVisible = visible

  if categoryPanel then
    if visible then
      categoryPanel:show()
      categoryPanel:raise()
    else
      categoryPanel:hide()
    end
  end
end

local function requestTeleport(city)
  if not g_game.isOnline() then
    return
  end

  clearConfirmWindow()

  local function acceptTeleport()
    clearConfirmWindow()
    sendPayload({
      action = 'teleport',
      cityId = city.id
    })
  end

  local function refuseTeleport()
    clearConfirmWindow()
  end

  confirmWindow = displayGeneralBox(
    'Teleporte',
    'Deseja se teleportar para ' .. city.name .. '?',
    {
      { text = 'Sim', callback = acceptTeleport },
      { text = 'Nao', callback = refuseTeleport },
      anchor = AnchorHorizontalCenter
    },
    acceptTeleport,
    refuseTeleport
  )
end

local function buildCityButtons()
  if not cityGridPanel then
    return
  end

  local visibleCities = {}

  for _, city in ipairs(TELEPORT_CITIES) do
    if city.page == currentPage then
      table.insert(visibleCities, city)
    end
  end

  for index = 1, #cityButtons do
    local button = cityButtons[index]
    local city = visibleCities[index]
    if button then
      local label = button:recursiveGetChildById('cityButtonLabel')
      if city then
        button:show()
        if label then
          label:setText(city.name)
        end
        button:setTooltip(city.name .. ' - ' .. city.positionLabel)
        button.cityData = city
        button.onClick = function(widget)
          requestTeleport(widget.cityData)
        end
      else
        button:hide()
        if label then
          label:setText('')
        end
        button.cityData = nil
        button.onClick = nil
      end
    end
  end

  updatePageButtons()
end

local function cacheCityButtons()
  cityButtons = {}
  for index = 1, 10 do
    local button = cityGridPanel:recursiveGetChildById('cityButton' .. index)
    if button then
      table.insert(cityButtons, button)
    end
  end
end

local function selectPage(page)
  currentPage = page
  setCategoryPanelVisible(false)
  buildCityButtons()
end

function toggle()
  if not teleportWindow then
    return
  end

  if teleportWindow:isVisible() then
    hide()
  else
    setCategoryPanelVisible(false)
    teleportWindow:show()
    teleportWindow:raise()
    teleportWindow:focus()
  end
end

function hide()
  clearConfirmWindow()

  if teleportWindow then
    teleportWindow:hide()
  end
end

function init()
  teleportWindow = g_ui.displayUI('cityteleport.otui')
  if not teleportWindow then
    print('[game_cityteleport] cityteleport.otui could not be loaded; module disabled.')
    return
  end

  teleportWindow:hide()
  cityGridPanel = teleportWindow:recursiveGetChildById('cityGridPanel')
  pageDescriptionLabel = teleportWindow:recursiveGetChildById('pageDescriptionLabel')
  categoryPanel = teleportWindow:recursiveGetChildById('categoryPanel')
  categoryToggleButton = teleportWindow:recursiveGetChildById('categoryToggleButton')
  pageKantoButton = teleportWindow:recursiveGetChildById('pageKantoButton')
  pageJohtoButton = teleportWindow:recursiveGetChildById('pageJohtoButton')
  pageExtrasButton = teleportWindow:recursiveGetChildById('pageExtrasButton')
  pageVipButton = teleportWindow:recursiveGetChildById('pageVipButton')
  pageEventsButton = teleportWindow:recursiveGetChildById('pageEventsButton')

  cacheCityButtons()

  if categoryToggleButton then
    categoryToggleButton.onClick = function()
      setCategoryPanelVisible(not isCategoryPanelVisible)
    end
  end

  if pageKantoButton then
    pageKantoButton.onClick = function()
      selectPage('kanto')
    end
  end

  if pageJohtoButton then
    pageJohtoButton.onClick = function()
      selectPage('johto')
    end
  end

  if pageExtrasButton then
    pageExtrasButton.onClick = function()
      selectPage('extras')
    end
  end

  if pageVipButton then
    pageVipButton.onClick = function()
      selectPage('vip')
    end
  end

  if pageEventsButton then
    pageEventsButton.onClick = function()
      selectPage('events')
    end
  end

  buildCityButtons()

  connect(g_game, {
    onGameEnd = hide
  })
end

function terminate()
  disconnect(g_game, {
    onGameEnd = hide
  })

  clearConfirmWindow()

  if teleportWindow then
    teleportWindow:destroy()
    teleportWindow = nil
  end
end
