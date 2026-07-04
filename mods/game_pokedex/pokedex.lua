local dexWindow = nil
local missionWindow = nil
local OPCODE_POKEDEX = 107
local pendingPackets = {}
local missionPendingPackets = {}
local currentMissionCategory = 'comuns'
local currentMissionState = nil
local currentMissionPayload = nil
local missionRefreshScheduled = false
local missionOpenPending = false
local DONATE_POINTS_REWARD_ITEM_ID = 39072
local REWARD_PREVIEW_PATHS = {
  angel_box = '/mods/game_shop/angel_box.png',
  demon_box = '/mods/game_shop/demon_box.png',
  lord_box = '/mods/game_shop/lord_box.png',
  ark_box = '/mods/game_shop/boxsArk.png',
  box_angel_entei = '/mods/game_pokedex/assets/preview_box_angel_entei.png',
  box_arceus = '/mods/game_pokedex/assets/preview_box_arceus.png',
  box_ark_mega_raichu = '/mods/game_pokedex/assets/preview_box_ark_mega_raichu.png',
  box_diabolic_zapdos = '/mods/game_pokedex/assets/preview_box_diabolic_zapdos.png',
  box_shiny_jirachi = '/mods/game_pokedex/assets/preview_box_shiny_jirachi.png',
  box_shiny_regice = '/mods/game_pokedex/assets/preview_box_shiny_regice.png',
  boost_stone = '/data/images/game/others_vitoredu/stones_32x32/boost stone.png',
  donate_points = '/mods/game_shop/assets/points_counter_custom.png'
}
local MISSION_TAB_IMAGE_PATHS = {
  comuns = {
    normal = '/mods/game_pokedex/assets/mission_tab_comuns.png'
  },
  angel = {
    normal = '/mods/game_pokedex/assets/mission_tab_angel.png'
  },
  diabolic = {
    normal = '/mods/game_pokedex/assets/mission_tab_diabolic.png'
  },
  lords = {
    normal = '/mods/game_pokedex/assets/mission_tab_lords.png'
  },
  ['lord ark'] = {
    normal = '/mods/game_pokedex/assets/mission_tab_lord_ark.png'
  },
  majestic = {
    normal = '/mods/game_pokedex/assets/mission_tab_majestic.png'
  },
  ark = {
    normal = '/mods/game_pokedex/assets/mission_tab_ark.png'
  },
  megas = {
    normal = '/mods/game_pokedex/assets/mission_tab_megas.png'
  },
  shiny = {
    normal = '/mods/game_pokedex/assets/mission_tab_shiny.png'
  },
  lendarios = {
    normal = '/mods/game_pokedex/assets/mission_tab_lendarios.png'
  }
}
local DEX_MISSION_BUTTON_SIZE = 108
local DEX_MISSION_ICON_SIZE = 98
local DEX_MISSION_ICON_HOVER_OFFSET = -2
local DEX_MISSION_ICON_PRESSED_OFFSET = 1
local ensureMissionWindow
local requestMissionState
local applyMissionCategory
local refreshMissionView
local buildMissionTabs
local buildMissionEntries
local buildMissionRewards
local preloadMissionState
local clearMissionCache
local missionButtonPressOpened = false
local buildMissionShop

local function onPokedexHotkey()
  if modules and modules.game_interface and modules.game_interface.startPokedexSelect then
    modules.game_interface.startPokedexSelect()
  end
end

local function sendPokedexPayload(payload)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  if protocolGame.sendExtendedJSONOpcode then
    protocolGame:sendExtendedJSONOpcode(OPCODE_POKEDEX, payload)
    return true
  end

  if protocolGame.sendExtendedOpcode then
    protocolGame:sendExtendedOpcode(OPCODE_POKEDEX, json.encode(payload))
    return true
  end

  return false
end

local function setIfExists(widget, id, value)
  if not widget then return end
  local child = widget:recursiveGetChildById(id)
  if child then
    child:setText(tostring(value or ''))
  end
end

local function setVisibleIfExists(widget, id, visible)
  if not widget then return end
  local child = widget:recursiveGetChildById(id)
  if child then
    child:setVisible(visible)
  end
end

local function getLocalPlayerLevel()
  local player = g_game.getLocalPlayer and g_game.getLocalPlayer()
  if not player or not player.getLevel then
    return 0
  end

  return tonumber(player:getLevel()) or 0
end

local function resolveRewardPreviewPath(itemId, label)
  local numericItemId = tonumber(itemId) or 0
  local text = string.lower(tostring(label or ''))

  if numericItemId == 40222 then
    return REWARD_PREVIEW_PATHS.box_angel_entei
  end

  if numericItemId == 40223 then
    return REWARD_PREVIEW_PATHS.box_diabolic_zapdos
  end

  if numericItemId == 39210 then
    return REWARD_PREVIEW_PATHS.box_arceus
  end

  if numericItemId == 39212 then
    return REWARD_PREVIEW_PATHS.box_shiny_jirachi
  end

  if numericItemId == 39213 then
    return REWARD_PREVIEW_PATHS.box_ark_mega_raichu
  end

  if numericItemId == 39219 then
    return REWARD_PREVIEW_PATHS.box_shiny_regice
  end

  if text == '' then
    return nil
  end

  if text:find('boost stone', 1, true) then
    return REWARD_PREVIEW_PATHS.boost_stone
  end

  if text:find('donate points', 1, true) or text:find('ark donate points', 1, true) then
    return REWARD_PREVIEW_PATHS.donate_points
  end

  return nil
end

local function normalizeRewardItemId(itemId, label)
  local text = string.lower(tostring(label or ''))
  if text:find('donate points', 1, true) or text:find('ark donate points', 1, true) then
    return DONATE_POINTS_REWARD_ITEM_ID
  end

  return tonumber(itemId) or 0
end

local function applyRewardPreview(widget, itemId, label, previewWidgetId, itemWidgetId)
  local preview = widget and widget:recursiveGetChildById(previewWidgetId)
  local itemWidget = widget and widget:recursiveGetChildById(itemWidgetId)
  local previewPath = resolveRewardPreviewPath(itemId, label)
  local normalizedItemId = normalizeRewardItemId(itemId, label)

  if preview and preview.setImageSource then
    if previewPath then
      preview:setImageSource(previewPath)
      preview:setVisible(true)
    else
      preview:setImageSource('')
      preview:setVisible(false)
    end
  end

  if itemWidget and itemWidget.setItemId then
    if normalizedItemId > 0 then
      itemWidget:setItemId(normalizedItemId)
      itemWidget:setVisible(not previewPath)
    else
      itemWidget:setItemId(0)
      itemWidget:setVisible(false)
    end
  end
end

local function openMissionDexWindow()
  local window = ensureMissionWindow()
  if not window then
    return
  end

  missionOpenPending = true
  window:show()
  window:raise()

  if currentMissionPayload then
    scheduleEvent(function()
      if not missionWindow or missionWindow ~= window or not currentMissionPayload then
        return
      end

      missionOpenPending = false
      applyMissionCategory(currentMissionCategory)
      refreshMissionView()
    end, 1)
  end

  if not missionRefreshScheduled then
    missionRefreshScheduled = true
    requestMissionState(currentMissionCategory)
  end
end

local function ensureWindow()
  if dexWindow then return dexWindow end

  dexWindow = g_ui.displayUI('pokedex.otui')
  if not dexWindow then
    return nil
  end

  dexWindow:hide()
  if dexWindow.move then
    dexWindow:move(220, 120)
  end

  dexWindow.onEscape = function()
    dexWindow:hide()
  end

  local missionButton = dexWindow:recursiveGetChildById('dexMissionButton')
  local missionClientButton = dexWindow:recursiveGetChildById('dexMissionClientButton')
  if missionButton then
    local missionIcon = missionButton:recursiveGetChildById('dexMissionIcon')
    missionButton:setTooltip('Central de Missoes Dex')
    missionButton:setSize({ width = DEX_MISSION_BUTTON_SIZE, height = DEX_MISSION_BUTTON_SIZE })
    if missionIcon then
      missionIcon:setTooltip('')
      missionIcon:setSize({ width = DEX_MISSION_ICON_SIZE, height = DEX_MISSION_ICON_SIZE })
      missionIcon:setOpacity(1)
      missionIcon:setMarginTop(0)
    end

    missionButton.onHoverChange = function(widget, hovered)
      if missionIcon then
        missionIcon:setMarginTop(hovered and DEX_MISSION_ICON_HOVER_OFFSET or 0)
      end
    end

    missionButton.onMousePress = function()
      missionButtonPressOpened = true
      openMissionDexWindow()
      if missionIcon then
        missionIcon:setMarginTop(DEX_MISSION_ICON_PRESSED_OFFSET)
      end
      return true
    end

    missionButton.onMouseRelease = function(_, _, mouseButton)
      if mouseButton ~= MouseLeftButton then
        return true
      end

      if missionIcon then
        missionIcon:setMarginTop(missionButton:isHovered() and DEX_MISSION_ICON_HOVER_OFFSET or 0)
      end
      if missionButton:isHovered() and not missionButtonPressOpened then
        openMissionDexWindow()
      end
      missionButtonPressOpened = false

      return true
    end

    missionButton.onClick = openMissionDexWindow
  end

  if missionClientButton then
    local missionClientLabel = missionClientButton:recursiveGetChildById('dexMissionClientButtonLabel')
    missionClientButton:setTooltip('Abrir a Central de Missoes Dex')
    if missionClientLabel then
      missionClientLabel:setTooltip('Abrir a Central de Missoes Dex')
    end

    missionClientButton.onHoverChange = function(widget, hovered)
      if hovered then
        widget:setOpacity(1.0)
        if missionClientLabel then
          missionClientLabel:setColor('#ffffff')
        end
      else
        widget:setOpacity(0.91)
        if missionClientLabel then
          missionClientLabel:setColor('#eff8ff')
          missionClientLabel:setMarginTop(0)
        end
      end
    end

    missionClientButton.onMousePress = function(widget, mousePos, mouseButton)
      if mouseButton ~= MouseLeftButton then
        return false
      end

      missionButtonPressOpened = true
      openMissionDexWindow()
      widget:setOpacity(0.88)
      if missionClientLabel then
        missionClientLabel:setMarginTop(1)
        missionClientLabel:setColor('#d7f6ff')
      end
      return true
    end

    missionClientButton.onMouseRelease = function(widget, mousePos, mouseButton)
      if mouseButton ~= MouseLeftButton then
        return false
      end

      if widget:isHovered() then
        widget:setOpacity(1.0)
        if missionClientLabel then
          missionClientLabel:setMarginTop(0)
          missionClientLabel:setColor('#ffffff')
        end
      else
        widget:setOpacity(0.91)
        if missionClientLabel then
          missionClientLabel:setMarginTop(0)
          missionClientLabel:setColor('#eff8ff')
        end
      end

      if widget:isHovered() and not missionButtonPressOpened then
        openMissionDexWindow()
      end
      missionButtonPressOpened = false

      return false
    end

    missionClientButton:setOpacity(0.91)
    missionClientButton.onClick = openMissionDexWindow
  end

  g_mouse.bindPressMove(dexWindow, function(mousePos, mouseMoved)
    if missionButton and missionButton:isHovered() then
      return
    end

    if missionClientButton and missionClientButton:isHovered() then
      return
    end

    local pos = dexWindow:getPosition()
    dexWindow:move(pos.x + mouseMoved.x, pos.y + mouseMoved.y)
  end)

  return dexWindow
end

ensureMissionWindow = function()
  if missionWindow then return missionWindow end

  missionWindow = g_ui.displayUI('dexmission.otui')
  if not missionWindow then
    print('[game_pokedex] dexmission.otui could not be loaded.')
    return nil
  end

  missionWindow:hide()
  if missionWindow.move then
    missionWindow:move(110, 60)
  end

  missionWindow.onEscape = function()
    missionOpenPending = false
    missionWindow:hide()
  end

  local closeButton = missionWindow:recursiveGetChildById('missionCloseButton')
  if closeButton then
    closeButton.onClick = function()
      missionWindow:hide()
    end
  end

  g_mouse.bindPressMove(missionWindow, function(mousePos, mouseMoved)
    local pos = missionWindow:getPosition()
    missionWindow:move(pos.x + mouseMoved.x, pos.y + mouseMoved.y)
  end)

  return missionWindow
end

local function setOutfitIfExists(widget, id, outfit)
  if not widget then return end
  local child = widget:recursiveGetChildById(id)
  if child and child.setOutfit then
    child:setOutfit(outfit)
  end
end

local function trim(s)
  if not s then return '' end
  return (tostring(s):gsub('\r', ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalizeInlineText(value)
  local text = trim(value)
  text = text:gsub('\n+', ' ')
  text = text:gsub('%s+', ' ')
  return text
end

local function displayOrDash(value)
  local text = normalizeInlineText(value)
  if text == '' then
    return '--'
  end
  return text
end

local function displayNumberOrDash(value)
  local number = tonumber(value)
  if not number or number <= 0 then
    return '--'
  end
  return tostring(math.floor(number))
end

local SECTION_MARKERS = {
  '[ABOUT]:',
  '[STATS]:',
  '[MOVES]:',
  '[EVOLUTIONS]:',
  '[HABILITIES]:'
}

local function extractSection(status, marker)
  if not status or status == '' then return '' end
  local startAt = status:find(marker, 1, true)
  if not startAt then return '' end

  local contentStart = startAt + #marker
  local nextAt = nil
  for i = 1, #SECTION_MARKERS do
    local current = SECTION_MARKERS[i]
    if current ~= marker then
      local idx = status:find(current, contentStart, true)
      if idx and (not nextAt or idx < nextAt) then
        nextAt = idx
      end
    end
  end

  local raw = nextAt and status:sub(contentStart, nextAt - 1) or status:sub(contentStart)
  return trim(raw)
end

local function extractField(section, label)
  if not section or section == '' then return '' end
  local pattern = label .. ':%s*([^|\n]+)'
  local value = section:match(pattern)
  return trim(value)
end

local function limitLines(text, maxLines)
  if not text or text == '' then return '' end
  local out = {}
  for line in text:gmatch('[^\n]+') do
    local clean = trim(line)
    if clean ~= '' then
      out[#out + 1] = clean
      if #out >= maxLines then break end
    end
  end
  return table.concat(out, '\n')
end

local function compactMoveLines(text)
  if not text or text == '' then return '' end
  local out = {}
  for line in text:gmatch('[^\n]+') do
    local compact = trim(line)
    compact = compact:gsub('^m%d+%s*%-%s*', '')
    compact = compact:gsub('%s*%-%s*Cooldown:%s*', '  ')
    compact = compact:gsub('%s*seconds?%.?', 's')
    compact = compact:gsub('%s+', ' ')
    if #compact > 28 then
      compact = compact:sub(1, 25) .. '...'
    end
    out[#out + 1] = compact
  end
  return table.concat(out, '\n')
end

local function parseAboutSection(aboutSection)
  local aboutType = extractField(aboutSection, 'Type')
  local aboutLevel = extractField(aboutSection, 'Level')
  local boost = extractField(aboutSection, 'Boost'):gsub('^%+', '')
  local love = extractField(aboutSection, 'Love')
  return aboutType, aboutLevel, boost, love
end

local function renderPokemonPortrait(widget, looktype)
  if not widget then return end
  setOutfitIfExists(widget, 'pokemonOutfit', { type = tonumber(looktype) or 0 })
end

local function renderDexFields(status)
  if not dexWindow then return end
  if not status or status == '' then return end

  local aboutSection = extractSection(status, '[ABOUT]:')
  local statsSection = extractSection(status, '[STATS]:')
  local movesSection = extractSection(status, '[MOVES]:')
  local evolutionsSection = extractSection(status, '[EVOLUTIONS]:')
  local abilitiesSection = extractSection(status, '[HABILITIES]:')

  local _, aboutLevel, boost, love = parseAboutSection(aboutSection)

  setIfExists(dexWindow, 'infoLevel', displayOrDash(aboutLevel))
  setIfExists(dexWindow, 'infoBoost', '+' .. displayOrDash(boost))
  setIfExists(dexWindow, 'infoLove', displayOrDash(love))
  setIfExists(dexWindow, 'statHealthLabel', displayOrDash(extractField(statsSection, 'Health')))
  setIfExists(dexWindow, 'statAttackLabel', displayOrDash(extractField(statsSection, 'Attack')))
  setIfExists(dexWindow, 'statMagicAttackLabel', displayOrDash(extractField(statsSection, 'Magic Attack')))
  setIfExists(dexWindow, 'statMagicDefenseLabel', displayOrDash(extractField(statsSection, 'Magic Defense')))
  setIfExists(dexWindow, 'statArmorLabel', displayOrDash(extractField(statsSection, 'Armor')))
  setIfExists(dexWindow, 'statSpeedLabel', displayOrDash(extractField(statsSection, 'Speed')))

  local movesBody = compactMoveLines(trim(movesSection))
  local evolutionsBody = limitLines(trim(evolutionsSection), 7)
  local abilitiesBody = limitLines(trim(abilitiesSection), 7)

  setIfExists(dexWindow, 'movesLabel', movesBody ~= '' and movesBody or 'Nenhum')
  setIfExists(dexWindow, 'evolutionsLabel', evolutionsBody ~= '' and evolutionsBody or 'Nenhuma')
  setIfExists(dexWindow, 'abilitiesLabel', abilitiesBody ~= '' and abilitiesBody or 'Nenhuma')
end

local function clearContainer(container)
  if not container then return end
  local children = container:getChildren()
  for i = #children, 1, -1 do
    children[i]:destroy()
  end
end

local function findCategoryData(categoryId)
  if not currentMissionPayload or not currentMissionPayload.categories then
    return nil
  end

  for _, category in ipairs(currentMissionPayload.categories) do
    if category.id == categoryId then
      return category
    end
  end
  return nil
end

refreshMissionView = function()
  local window = ensureMissionWindow()
  if not window or not currentMissionState then
    return
  end

  local categoryData = findCategoryData(currentMissionCategory)
  setIfExists(window, 'summaryTotal', string.format('Total descoberto: %d/%d', tonumber(currentMissionState.totalDiscovered) or 0, tonumber(currentMissionState.totalPokemon) or 0))
  setIfExists(window, 'summaryProgress', string.format('Progresso geral: %d%%', tonumber(currentMissionState.totalProgress) or 0))
  setIfExists(window, 'summaryPoints', string.format('Pontos Dex: %d', tonumber(currentMissionState.points) or 0))

  if categoryData then
    setIfExists(window, 'summaryCurrentCategory', string.format('Categoria: %s | %d/%d | %d%%', categoryData.label or '--', tonumber(categoryData.discovered) or 0, tonumber(categoryData.total) or 0, tonumber(categoryData.progress) or 0))
  else
    setIfExists(window, 'summaryCurrentCategory', 'Categoria: --')
  end

  buildMissionTabs()
  buildMissionEntries()
  buildMissionRewards()
  buildMissionShop()
end

applyMissionCategory = function(categoryId)
  if not currentMissionPayload then
    return
  end

  currentMissionCategory = categoryId or currentMissionCategory or 'comuns'
  currentMissionState = {
    selectedCategory = currentMissionCategory,
    points = currentMissionPayload.points,
    totalPokemon = currentMissionPayload.totalPokemon,
    totalDiscovered = currentMissionPayload.totalDiscovered,
    totalProgress = currentMissionPayload.totalProgress,
    categories = currentMissionPayload.categories or {},
    entries = (currentMissionPayload.entriesByCategory and currentMissionPayload.entriesByCategory[currentMissionCategory]) or currentMissionPayload.entries or {},
    rewards = (currentMissionPayload.rewardsByCategory and currentMissionPayload.rewardsByCategory[currentMissionCategory]) or currentMissionPayload.rewards or {},
    globalReward = currentMissionPayload.globalReward,
    shopOffers = currentMissionPayload.shopOffers or {}
  }
end

requestMissionState = function(categoryId)
  currentMissionCategory = categoryId or currentMissionCategory or 'comuns'
  sendPokedexPayload({
    action = 'requestMissionData',
    categoryId = currentMissionCategory
  })
end

preloadMissionState = function()
  if not g_game.isOnline or not g_game.isOnline() then
    return
  end

  if currentMissionPayload or missionRefreshScheduled then
    return
  end

  missionRefreshScheduled = true
  requestMissionState(currentMissionCategory)
end

clearMissionCache = function()
  currentMissionState = nil
  currentMissionPayload = nil
  missionPendingPackets = {}
  missionRefreshScheduled = false
  missionOpenPending = false
end

local function refreshMissionTabSkin(button, categoryId, hovered)
  local tabStyle = MISSION_TAB_IMAGE_PATHS[categoryId]
  if not button or not tabStyle then
    return
  end

  button:setImageSource(tabStyle.normal)
  button:setImageClip('0 0 104 26')
  button:setImageBorder(0)
  if categoryId == currentMissionCategory then
    button:setImageColor('#a0a0a0')
    button:setColor('#ffffff')
    button:setPaddingTop(0)
    return
  end

  button:setImageColor('white')
  button:setColor('#d9f6ff')
  button:setPaddingTop(0)
end

buildMissionTabs = function()
  if not missionWindow or not currentMissionState then return end
  local tabBar = missionWindow:recursiveGetChildById('missionTabBar')
  local row1 = missionWindow:recursiveGetChildById('missionTabRow1')
  local row2 = missionWindow:recursiveGetChildById('missionTabRow2')
  if not tabBar or not row1 or not row2 then return end

  clearContainer(row1)
  clearContainer(row2)
  local categories = currentMissionState.categories or {}
  local splitIndex = math.ceil(#categories / 2)
  local rows = { row1, row2 }

  for index, category in ipairs(categories) do
    local targetRow = index <= splitIndex and rows[1] or rows[2]
    local button = g_ui.createWidget('DexMissionTabButton', targetRow)
    button:setText(string.format('%s %d/%d', category.label, category.discovered, category.total))
    button:setWidth(104)
    local categoryId = category.id
    button:setBackgroundColor('#00000000')
    button:setBorderWidth(0)
    refreshMissionTabSkin(button, categoryId, false)

    button.onClick = function()
      if categoryId == currentMissionCategory then
        return
      end

      applyMissionCategory(categoryId)
      refreshMissionView()
    end
  end
end

buildMissionEntries = function()
  if not missionWindow or not currentMissionState then return end
  local list = missionWindow:recursiveGetChildById('missionPokemonList')
  if not list then return end

  clearContainer(list)

  for _, entry in ipairs(currentMissionState.entries or {}) do
    local row = g_ui.createWidget('DexMissionRowCard', list)
    local displayName = entry.name or 'Pokemon'
    setIfExists(row, 'pokeName', displayName)
    setIfExists(row, 'pokeInfo', string.format('Tipo: %s | Level: %s | Tier: %s', displayOrDash(entry.typeName), displayNumberOrDash(entry.level), displayNumberOrDash(entry.tier)))
    setIfExists(row, 'pokeDexNumber', '#' .. tostring(entry.dexNumber or 0))
    setIfExists(row, 'pokeStatus', entry.discovered and 'Descoberto' or 'Desconhecido')
    setOutfitIfExists(row, 'portraitCreature', { type = tonumber(entry.looktype) or 0 })

    local statusLabel = row:recursiveGetChildById('pokeStatus')
    if statusLabel then
      statusLabel:setColor(entry.discovered and '#61f38a' or '#ff6c6c')
    end

    row:setBackgroundColor(entry.discovered and '#173041dd' or '#251820dd')
  end
end

buildMissionRewards = function()
  return
end

buildMissionShop = function()
  if not missionWindow or not currentMissionState then return end
  local shopPanel = missionWindow:recursiveGetChildById('missionShopPanel')
  local shopList = missionWindow:recursiveGetChildById('missionShopList')
  if not shopPanel or not shopList then return end

  shopPanel:setVisible(true)
  clearContainer(shopList)

  for _, offer in ipairs(currentMissionState.shopOffers or {}) do
    local row = g_ui.createWidget('DexMissionShopRow', shopList)
    setIfExists(row, 'shopTitle', offer.name or 'Item')
    setIfExists(row, 'shopDescription', string.format('Custa %d Ponto Dex', tonumber(offer.price) or 0))
    applyRewardPreview(row, tonumber(offer.itemId) or 0, offer.name or '', 'shopPreview', 'shopItem')

    local previewFrame = row:recursiveGetChildById('shopPreviewFrame')
    local preview = row:recursiveGetChildById('shopPreview')
    if previewFrame then
      previewFrame.onMouseWheel = function()
        return true
      end
    end
    if preview then
      preview.onMouseWheel = function()
        return true
      end
    end

    local button = row:recursiveGetChildById('shopButton')
    if button then
      local canBuy = (tonumber(currentMissionState.points) or 0) >= (tonumber(offer.price) or 0)
      button:setText(canBuy and 'Comprar' or 'Sem pontos')
      button:setEnabled(canBuy)
      if canBuy then
        local offerId = offer.id
        local function handleBuyClick()
          button:setEnabled(false)
          sendPokedexPayload({
            action = 'buyMissionShop',
            offerId = offerId,
            categoryId = currentMissionCategory
          })
          return true
        end

        button.onClick = nil
        button.onMouseRelease = handleBuyClick
      else
        button.onClick = nil
        button.onMouseRelease = nil
      end
    end
  end
end

local function renderMissionState(payload)
  local window = ensureMissionWindow()
  if not window then
    return
  end

  currentMissionPayload = payload
  missionRefreshScheduled = false
  applyMissionCategory(payload.selectedCategory or currentMissionCategory or 'comuns')
  refreshMissionView()

  if window and missionOpenPending then
    missionOpenPending = false
    window:show()
    window:raise()
  end
end

local function handleMissionChunkPacket(data)
  local packetId = data.packetId or 'mission-single'
  local seq = tonumber(data.seq) or 1
  local total = tonumber(data.total) or 1
  local chunk = data.chunk or ''

  if not missionPendingPackets[packetId] then
    missionPendingPackets[packetId] = {
      total = total,
      received = 0,
      chunks = {}
    }
  end

  local packet = missionPendingPackets[packetId]
  if packet.chunks[seq] == nil then
    packet.chunks[seq] = chunk
    packet.received = packet.received + 1
  end

  if packet.received < packet.total then
    return
  end

  local joined = table.concat(packet.chunks)
  missionPendingPackets[packetId] = nil

  local ok, payload = pcall(function() return json.decode(joined) end)
  if ok and type(payload) == 'table' then
    renderMissionState(payload)
  end
end

local function onPokedexOpcode(protocol, opcode, buffer)
  local ok, data = pcall(function() return json.decode(buffer) end)
  if ok and type(data) == 'table' and data.action then
    if data.action == 'missionStateChunk' then
      handleMissionChunkPacket(data)
      return
    end

    if data.action == 'missionDirty' then
      if missionWindow and missionWindow:isVisible() then
        requestMissionState(currentMissionCategory)
      else
        currentMissionPayload = nil
        currentMissionState = nil
        missionRefreshScheduled = false
        missionOpenPending = false
      end
      return
    end
  end

  if not ensureWindow() then
    return
  end

  if not ok or type(data) ~= 'table' then
    return
  end

  local packetId = data.packetId or 'single'
  local seq = tonumber(data.seq) or 1
  local total = tonumber(data.total) or 1
  local statusChunk = data.statusChunk or data.status or ''

  if not pendingPackets[packetId] then
    pendingPackets[packetId] = {
      total = total,
      received = 0,
      chunks = {},
      meta = nil
    }
  end

  local packet = pendingPackets[packetId]
  if seq == 1 and data.monsterName then
    packet.meta = {
      monsterName = data.monsterName or '',
      raceName = data.raceName or '',
      tierStars = data.tierStars or '',
      isPriceless = data.isPriceless == true,
      priceNpc = data.priceNpc or 0,
      xpdoCatch = data.xpdoCatch or '',
      looktype = data.looktype or 0
    }
  end

  if packet.chunks[seq] == nil then
    packet.chunks[seq] = statusChunk
    packet.received = packet.received + 1
  end

  if seq == 1 then
    dexWindow:show()
    dexWindow:raise()

    local meta = packet.meta or {}
    setIfExists(dexWindow, 'pokemonName', displayOrDash(meta.monsterName))
    setIfExists(dexWindow, 'raceName', 'Tipo: ' .. displayOrDash(meta.raceName))
    setIfExists(dexWindow, 'tierStars', 'Tier: ' .. displayOrDash(meta.tierStars))
    setIfExists(dexWindow, 'infoPokemonName', displayOrDash(meta.monsterName))
    setIfExists(dexWindow, 'infoRaceName', 'Tipo: ' .. displayOrDash(meta.raceName))
    setIfExists(dexWindow, 'infoTierStars', 'Tier: ' .. displayOrDash(meta.tierStars))
    setIfExists(dexWindow, 'infoLevel', '--')
    setIfExists(dexWindow, 'infoBoost', '--')
    setIfExists(dexWindow, 'infoLove', '--')
    setIfExists(dexWindow, 'infoXp', displayOrDash(meta.xpdoCatch))
    setIfExists(dexWindow, 'priceInfo', meta.isPriceless and 'priceless' or ('$' .. tostring(meta.priceNpc)))
    renderPokemonPortrait(dexWindow, meta.looktype)
  end

  if packet.received < packet.total then
    return
  end

  local status = table.concat(packet.chunks)
  local meta = packet.meta or {}
  local aboutSection = extractSection(status, '[ABOUT]:')
  local _, aboutLevel, boost, love = parseAboutSection(aboutSection)

  dexWindow:show()
  dexWindow:raise()

  setIfExists(dexWindow, 'pokemonName', displayOrDash(meta.monsterName))
  setIfExists(dexWindow, 'raceName', 'Tipo: ' .. displayOrDash(meta.raceName))
  setIfExists(dexWindow, 'tierStars', 'Tier: ' .. displayOrDash(meta.tierStars))
  setIfExists(dexWindow, 'infoPokemonName', displayOrDash(meta.monsterName))
  setIfExists(dexWindow, 'infoRaceName', 'Tipo: ' .. displayOrDash(meta.raceName))
  setIfExists(dexWindow, 'infoTierStars', 'Tier: ' .. displayOrDash(meta.tierStars))
  setIfExists(dexWindow, 'infoLevel', displayOrDash(aboutLevel))
  setIfExists(dexWindow, 'infoBoost', '+' .. displayOrDash(boost))
  setIfExists(dexWindow, 'infoLove', displayOrDash(love))
  setIfExists(dexWindow, 'infoXp', displayOrDash(meta.xpdoCatch))
  setIfExists(dexWindow, 'priceInfo', meta.isPriceless and 'priceless' or ('$' .. tostring(meta.priceNpc)))
  renderPokemonPortrait(dexWindow, meta.looktype)
  renderDexFields(status)

  pendingPackets[packetId] = nil
end

function init()
  connect(g_game, {
    onGameStart = preloadMissionState,
    onGameEnd = clearMissionCache
  })

  if ProtocolGame and ProtocolGame.registerExtendedOpcode then
    ProtocolGame.registerExtendedOpcode(OPCODE_POKEDEX, onPokedexOpcode)
  end
  ensureMissionWindow()
  if missionWindow then
    missionWindow:hide()
  end
  g_keyboard.bindKeyDown('Ctrl+Tab', onPokedexHotkey)

  if g_game.isOnline and g_game.isOnline() then
    preloadMissionState()
  end
end

function terminate()
  disconnect(g_game, {
    onGameStart = preloadMissionState,
    onGameEnd = clearMissionCache
  })

  g_keyboard.unbindKeyDown('Ctrl+Tab')
  pendingPackets = {}
  missionPendingPackets = {}
  currentMissionState = nil
  currentMissionPayload = nil
  missionRefreshScheduled = false
  missionOpenPending = false

  if ProtocolGame and ProtocolGame.unregisterExtendedOpcode then
    ProtocolGame.unregisterExtendedOpcode(OPCODE_POKEDEX)
  end

  if missionWindow then
    missionWindow:destroy()
    missionWindow = nil
  end

  if dexWindow then
    dexWindow:destroy()
    dexWindow = nil
  end
end
