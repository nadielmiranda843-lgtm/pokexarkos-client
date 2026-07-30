local OPCODE_PUB_COMMUNITY = 112
local CENTRAL_RANK_ENABLED = false -- Reative quando a Central de Rank estiver pronta.

local pubWindow
local tabelaProssomissaoWindow
local tabelaProssomissaoIcon
local messageLabel
local summaryLabel
local listPanel
local tabelaProssomissaoTitleLabel
local tabelaProssomissaoTextLabel
local tabelaProssomissaoAbandonButton
local tabelaProssomissaoCloseButton
local currentTab = 'rankings'
local currentState = nil
local currentTabelaProssomissaoState = nil
local tabelaProssomissaoIsMinimized = false
local tabelaProssomissaoAutoMinimizeUntil = 0
local tabelaProssomissaoIconCustomPosition = nil
local tabelaProssomissaoHadActiveMission = false
local tabelaProssomissaoRefreshEvent = nil

local function centerTabelaProssomissaoWindow()
  if not tabelaProssomissaoWindow or not rootWidget then return end
  local rootSize = rootWidget:getSize()
  local windowSize = tabelaProssomissaoWindow:getSize()
  local posX = math.floor((rootSize.width - windowSize.width) / 2)
  local posY = math.floor((rootSize.height - windowSize.height) / 2)
  tabelaProssomissaoWindow:setPosition({ x = math.max(posX, 0), y = math.max(posY, 0) })
  if tabelaProssomissaoIcon then
    if tabelaProssomissaoIconCustomPosition then
      tabelaProssomissaoIcon:setPosition(tabelaProssomissaoIconCustomPosition)
    else
      tabelaProssomissaoIcon:setPosition(tabelaProssomissaoWindow:getPosition())
    end
  end
end

local function onTabelaProssomissaoGameStart()
  tabelaProssomissaoIsMinimized = true
  tabelaProssomissaoAutoMinimizeUntil = g_clock.millis() + 7000
  if scheduleEvent then
    scheduleEvent(function()
      if tabelaProssomissaoHadActiveMission or (currentTabelaProssomissaoState and currentTabelaProssomissaoState.visible ~= false) then
        tabelaProssomissaoIsMinimized = true
        if tabelaProssomissaoWindow then
          tabelaProssomissaoWindow:hide()
        end
        if tabelaProssomissaoIcon then
          centerTabelaProssomissaoWindow()
          tabelaProssomissaoIcon:show()
          tabelaProssomissaoIcon:raise()
        end
      end
    end, 2200)
  end
end

local function onTabelaProssomissaoGameEnd()
  tabelaProssomissaoIsMinimized = false
  tabelaProssomissaoAutoMinimizeUntil = 0
  if tabelaProssomissaoWindow then
    tabelaProssomissaoWindow:hide()
  end
  if tabelaProssomissaoIcon then
    tabelaProssomissaoIcon:hide()
  end
end

local function buildTabelaProssomissaoUI()
  if not rootWidget then return end
  tabelaProssomissaoWindow = g_ui.createWidget('Panel', rootWidget)
  tabelaProssomissaoWindow:setId('tabelaProssomissaoWindow')
  tabelaProssomissaoWindow:setSize({ width = 340, height = 245 })
  tabelaProssomissaoWindow:setImageSource('/mods/game_pubcommunity/assets/mission_tracker_bg_v2.png')
  tabelaProssomissaoWindow:setImageBorder(18)
  tabelaProssomissaoWindow:setFocusable(true)
  tabelaProssomissaoWindow:setPhantom(false)
  tabelaProssomissaoWindow:hide()

  tabelaProssomissaoTitleLabel = g_ui.createWidget('Label', tabelaProssomissaoWindow)
  tabelaProssomissaoTitleLabel:setId('tabelaProssomissaoTitleLabel')
  tabelaProssomissaoTitleLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
  tabelaProssomissaoTitleLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  tabelaProssomissaoTitleLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
  tabelaProssomissaoTitleLabel:setMarginTop(45)
  tabelaProssomissaoTitleLabel:setMarginLeft(24)
  tabelaProssomissaoTitleLabel:setMarginRight(24)
  tabelaProssomissaoTitleLabel:setHeight(18)
  tabelaProssomissaoTitleLabel:setColor('#f7f3d2')
  tabelaProssomissaoTitleLabel:setFont('verdana-11px-rounded')
  tabelaProssomissaoTitleLabel:setTextAlign(AlignCenter)

  tabelaProssomissaoTextLabel = g_ui.createWidget('Label', tabelaProssomissaoWindow)
  tabelaProssomissaoTextLabel:setId('tabelaProssomissaoTextLabel')
  tabelaProssomissaoTextLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
  tabelaProssomissaoTextLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  tabelaProssomissaoTextLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
  tabelaProssomissaoTextLabel:setMarginTop(78)
  tabelaProssomissaoTextLabel:setMarginLeft(34)
  tabelaProssomissaoTextLabel:setMarginRight(34)
  tabelaProssomissaoTextLabel:setHeight(82)
  tabelaProssomissaoTextLabel:setColor('#d7e8ff')
  tabelaProssomissaoTextLabel:setFont('verdana-11px-antialised')
  tabelaProssomissaoTextLabel:setTextWrap(true)

  tabelaProssomissaoCloseButton = g_ui.createWidget('Button', tabelaProssomissaoWindow)
  tabelaProssomissaoCloseButton:setId('tabelaProssomissaoCloseButton')
  tabelaProssomissaoCloseButton:setText('Fechar')
  tabelaProssomissaoCloseButton:setSize({ width = 94, height = 22 })
  tabelaProssomissaoCloseButton:addAnchor(AnchorTop, 'tabelaProssomissaoTextLabel', AnchorBottom)
  tabelaProssomissaoCloseButton:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  tabelaProssomissaoCloseButton:setMarginTop(8)
  tabelaProssomissaoCloseButton:setMarginLeft(58)

  tabelaProssomissaoAbandonButton = g_ui.createWidget('Button', tabelaProssomissaoWindow)
  tabelaProssomissaoAbandonButton:setId('tabelaProssomissaoAbandonButton')
  tabelaProssomissaoAbandonButton:setText('Abandonar')
  tabelaProssomissaoAbandonButton:setSize({ width = 94, height = 22 })
  tabelaProssomissaoAbandonButton:addAnchor(AnchorTop, 'tabelaProssomissaoTextLabel', AnchorBottom)
  tabelaProssomissaoAbandonButton:addAnchor(AnchorLeft, 'tabelaProssomissaoCloseButton', AnchorRight)
  tabelaProssomissaoAbandonButton:setMarginTop(8)
  tabelaProssomissaoAbandonButton:setMarginLeft(10)

  tabelaProssomissaoIcon = g_ui.createWidget('UIButton', rootWidget)
  tabelaProssomissaoIcon:setId('tabelaProssomissaoIcon')
  tabelaProssomissaoIcon:setSize({ width = 54, height = 54 })
  tabelaProssomissaoIcon:setImageSource('/mods/game_pubcommunity/assets/mission_tracker_minimized.png')
  tabelaProssomissaoIcon:setImageBorder(0)
  tabelaProssomissaoIcon:setTooltip('Missao em andamento')
  tabelaProssomissaoIcon:setVisible(false)
  tabelaProssomissaoIcon:setFocusable(false)
  tabelaProssomissaoIcon:setPhantom(false)
  centerTabelaProssomissaoWindow()
end

local function clearList()
  if not listPanel then return end
  for _, child in ipairs(listPanel:getChildren()) do
    child:destroy()
  end
end

local function sendAction(payload)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end

  if protocolGame.sendExtendedJSONOpcode then
    protocolGame:sendExtendedJSONOpcode(OPCODE_PUB_COMMUNITY, payload)
  elseif protocolGame.sendExtendedOpcode then
    protocolGame:sendExtendedOpcode(OPCODE_PUB_COMMUNITY, json.encode(payload))
  end
end

local function refreshTabelaProssomissaoProgress()
  if not g_game.isOnline() then return end
  if tabelaProssomissaoHadActiveMission or (currentTabelaProssomissaoState and currentTabelaProssomissaoState.visible ~= false) then
    sendAction({ action = 'refresh_mission_tracker' })
  end
end

local function updateMessage(text)
  if messageLabel then
    messageLabel:setText(text ~= '' and text or ' ')
  end
end

local function countWrappedLines(text, charsPerLine)
  text = tostring(text or '')
  charsPerLine = math.max(charsPerLine or 1, 1)

  local lineCount = 0
  for line in (text .. '\n'):gmatch('(.-)\n') do
    lineCount = lineCount + math.max(1, math.ceil(#line / charsPerLine))
  end
  return math.max(lineCount, 1)
end

local function createInfoRow(title, description, rewardText, buttonText, callback, disabled)
  local panelWidth = listPanel and listPanel:getWidth() or 0
  local rowWidth = panelWidth > 100 and panelWidth - 2 or 620
  local hasReward = rewardText and rewardText ~= ''
  local hasButton = buttonText and buttonText ~= ''
  local hasSideColumn = hasReward or hasButton
  local sideColumnWidth = hasSideColumn and 138 or 0
  local textWidth = math.max(rowWidth - 24 - sideColumnWidth, 260)
  local charsPerLine = math.max(math.floor(textWidth / 7), 24)
  local descriptionLines = countWrappedLines(description, charsPerLine)
  local descriptionHeight = math.max(descriptionLines * 14, 28)
  local rowHeight = math.max(70, 38 + descriptionHeight)
  if hasReward and hasButton then
    rowHeight = math.max(rowHeight, 88)
  end

  local row = g_ui.createWidget('Panel', listPanel)
  row:setWidth(rowWidth)
  row:setHeight(rowHeight)
  row:setImageSource('/mods/game_shop/assets/product_row.png')
  row:setImageBorder(8)

  local nameLabel = g_ui.createWidget('Label', row)
  nameLabel:setFont('verdana-11px-rounded')
  nameLabel:setColor('#f2fbff')
  nameLabel:setText(title)
  nameLabel:setWidth(textWidth)
  nameLabel:setHeight(18)
  nameLabel:setTextWrap(false)
  nameLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
  nameLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  nameLabel:setMarginTop(10)
  nameLabel:setMarginLeft(12)

  local descLabel = g_ui.createWidget('Label', row)
  descLabel:setFont('verdana-11px-antialised')
  descLabel:setColor('#a8d7ef')
  descLabel:setText(description)
  descLabel:setWidth(textWidth)
  descLabel:setHeight(descriptionHeight)
  descLabel:setTextWrap(true)
  descLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
  descLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  descLabel:setMarginTop(32)
  descLabel:setMarginLeft(12)

  local rewardLabel = g_ui.createWidget('Label', row)
  rewardLabel:setFont('verdana-11px-antialised')
  rewardLabel:setColor('#ffd88f')
  rewardLabel:setText(rewardText or '')
  rewardLabel:setWidth(120)
  rewardLabel:setHeight(30)
  rewardLabel:setTextWrap(true)
  rewardLabel:setTextAlign(AlignRight)
  rewardLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
  rewardLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
  rewardLabel:setMarginTop(12)
  rewardLabel:setMarginRight(12)

  if buttonText then
    local button = g_ui.createWidget('Button', row)
    button:setText(buttonText)
    button:setSize({width = 92, height = 26})
    button:addAnchor(AnchorRight, 'parent', AnchorRight)
    button:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    button:setMarginRight(12)
    button:setMarginBottom(10)
    button:setEnabled(not disabled)
    button.onClick = callback
  end

  return row
end

local function updateTabelaProssomissaoText()
  if not tabelaProssomissaoTextLabel then return end

  if not currentTabelaProssomissaoState or currentTabelaProssomissaoState.visible == false then
    tabelaProssomissaoTextLabel:setText('')
    return
  end

  local lines = {}
  if currentTabelaProssomissaoState.summary and currentTabelaProssomissaoState.summary ~= '' then
    table.insert(lines, currentTabelaProssomissaoState.summary)
  end

  for _, objective in ipairs(currentTabelaProssomissaoState.objectives or {}) do
    local current = tonumber(objective.current) or 0
    local target = tonumber(objective.target) or 0
    table.insert(lines, string.format('%s: %d/%d', objective.label or 'Objetivo', current, target))
  end

  tabelaProssomissaoTextLabel:setText(table.concat(lines, '\n'))
end

local function showTabelaProssomissao()
  if not tabelaProssomissaoWindow then return end
  tabelaProssomissaoIsMinimized = false
  centerTabelaProssomissaoWindow()
  tabelaProssomissaoWindow:show()
  tabelaProssomissaoWindow:raise()
  tabelaProssomissaoWindow:focus()
  if tabelaProssomissaoIcon then
    tabelaProssomissaoIcon:hide()
  end
end

local function hideTabelaProssomissao()
  tabelaProssomissaoIsMinimized = false
  if tabelaProssomissaoWindow then tabelaProssomissaoWindow:hide() end
  if tabelaProssomissaoIcon then tabelaProssomissaoIcon:hide() end
end

local function minimizarTabelaProssomissao()
  if not tabelaProssomissaoWindow or not tabelaProssomissaoIcon then return end
  tabelaProssomissaoIsMinimized = true
  centerTabelaProssomissaoWindow()
  tabelaProssomissaoWindow:hide()
  tabelaProssomissaoIcon:show()
  tabelaProssomissaoIcon:raise()
end

local function renderTabelaProssomissao()
  if not tabelaProssomissaoWindow then return end

  if not currentTabelaProssomissaoState or currentTabelaProssomissaoState.visible == false then
    tabelaProssomissaoHadActiveMission = false
    currentTabelaProssomissaoState = nil
    hideTabelaProssomissao()
    return
  end

  tabelaProssomissaoHadActiveMission = true

  if tabelaProssomissaoTitleLabel then
    tabelaProssomissaoTitleLabel:setText(currentTabelaProssomissaoState.title or 'Missao ativa')
  end

  updateTabelaProssomissaoText()
  if currentTabelaProssomissaoState.startMinimized then
    tabelaProssomissaoIsMinimized = true
    tabelaProssomissaoAutoMinimizeUntil = 0
  end
  if tabelaProssomissaoAutoMinimizeUntil > 0 and g_clock.millis() <= tabelaProssomissaoAutoMinimizeUntil then
    tabelaProssomissaoIsMinimized = true
  else
    tabelaProssomissaoAutoMinimizeUntil = 0
  end

  if tabelaProssomissaoIsMinimized then
    if tabelaProssomissaoIcon then
      centerTabelaProssomissaoWindow()
      tabelaProssomissaoIcon:show()
      tabelaProssomissaoIcon:raise()
    end
    if tabelaProssomissaoWindow then
      tabelaProssomissaoWindow:hide()
    end
  else
    showTabelaProssomissao()
  end
end

local function renderShop()
  clearList()
  local shop = currentState and currentState.shop or {}

  for _, bag in ipairs(shop.bags or {}) do
    local description = string.format('%s\nComprado: %d/%d', bag.description or '', bag.purchased or 0, bag.limit or 0)
    createInfoRow(
      bag.name,
      description,
      string.format('%d Tokens', bag.price or 0),
      'Comprar',
      function() sendAction({ action = 'buy_offer', category = 'bags', offerKey = bag.key }) end,
      (bag.limit or 0) > 0 and (bag.purchased or 0) >= (bag.limit or 0)
    )
  end

  local categories = {
    { title = 'Pokebolas', rows = shop.pokebolas or {} },
    { title = 'Itens', rows = shop.itens or {} },
    { title = 'Tickets', rows = shop.tickets or {} }
  }

  for _, category in ipairs(categories) do
    for _, row in ipairs(category.rows) do
      createInfoRow(category.title, row.description or row.name or 'Itens em construcao', '', 'Em breve', nil, true)
    end
  end
end

local function renderRankings()
  clearList()
  createInfoRow('Ranking Global', 'Veja abaixo os principais rankings do servidor e acompanhe sua pontuacao geral.', '', nil, nil, true)

  local order = {
    { key = 'reputation', label = 'Top Reputacao' },
    { key = 'captures', label = 'Top Capturas' },
    { key = 'legendary', label = 'Top Lendarios' },
    { key = 'missions', label = 'Top Missoes' },
    { key = 'bosses', label = 'Top Bosses' }
  }

  for _, rankingGroup in ipairs(order) do
    createInfoRow(rankingGroup.label, 'Ranking mensal Top 10.', '', nil, nil, true)
    for position, row in ipairs((currentState and currentState.rankings and currentState.rankings[rankingGroup.key]) or {}) do
      createInfoRow(string.format('%d. %s', position, row.name or '---'), 'Pontuacao mensal acumulada.', tostring(row.value or 0), nil, nil, true)
    end
  end
end

local function renderTutorial()
  clearList()
  updateMessage('Entenda como funcionam as missoes e o ranking global do servidor.')
  createInfoRow('1. Encontre os NPCs de missao', 'Cada cidade tera seus proprios NPCs e desafios. Fale com o NPC, leia os objetivos e aceite apenas quando estiver pronto para comecar.', '', nil, nil, true)
  createInfoRow('2. Complete os objetivos', 'Acompanhe derrotas, capturas, entregas e outros objetivos pela pequena janela de progresso da missao.', '', nil, nil, true)
  createInfoRow('3. Receba as recompensas', 'Ao terminar todos os objetivos, volte ao NPC responsavel para entregar a missao e receber os itens, dinheiro ou outras recompensas definidas.', '', nil, nil, true)
  createInfoRow('4. Ganhe pontos de rank', 'As missoes concluidas entregam pontos para o ranking global. Esses pontos sao compartilhados entre os sistemas de missao de todas as cidades.', '', nil, nil, true)
  createInfoRow('5. Consulte a Central de Rank', 'Use a aba Rank para acompanhar as melhores colocacoes do servidor e a aba Loja para consultar recompensas liberadas pelo sistema.', '', nil, nil, true)
end

local function renderTab(tab)
  currentTab = tab or currentTab
  if currentTab == 'shop' then
    renderShop()
  elseif currentTab == 'rankings' then
    renderRankings()
  elseif currentTab == 'tutorial' then
    renderTutorial()
  end
end

local function updateSummary()
  if not summaryLabel or not currentState or not currentState.player then return end

  local player = currentState.player
  summaryLabel:setText(string.format(
    'Pontos: %s | Tokens: %s | Rank: %s',
    tostring(player.rankPoints or player.points or player.reputation or 0),
    tostring(player.tokens or 0),
    player.rank or 'Novato'
  ))
end

local function onPubCommunityOpcode(protocol, opcode, buffer)
  if opcode ~= OPCODE_PUB_COMMUNITY then return end

  local ok, data = pcall(function() return json.decode(buffer) end)
  if not ok or type(data) ~= 'table' then return end

  if data.action == 'titles' then
    if modules and modules.game_titles and modules.game_titles.setDynamicTitles then
      modules.game_titles.setDynamicTitles(data.titles or {})
    elseif mods and mods.game_titles and mods.game_titles.setDynamicTitles then
      mods.game_titles.setDynamicTitles(data.titles or {})
    end
    return
  end

  if data.action == 'guide' then
    if data.player then
      currentState = currentState or {}
      currentState.player = data.player
      updateSummary()
    end
    renderTab('tutorial')
    if pubWindow and not pubWindow:isVisible() then
      pubWindow:show()
      pubWindow:raise()
      pubWindow:focus()
    end
    return
  end

  if data.action == 'mission_tracker' then
    currentTabelaProssomissaoState = data
    renderTabelaProssomissao()
    return
  end

  if not CENTRAL_RANK_ENABLED then
    return
  end

  currentState = data
  updateSummary()
  updateMessage(data.message or '')

  if data.titles then
    if modules and modules.game_titles and modules.game_titles.setDynamicTitles then
      modules.game_titles.setDynamicTitles(data.titles)
    elseif mods and mods.game_titles and mods.game_titles.setDynamicTitles then
      mods.game_titles.setDynamicTitles(data.titles)
    end
  end

  local initialTab = data.initialTab
  if initialTab ~= 'rankings' and initialTab ~= 'shop' and initialTab ~= 'tutorial' then
    initialTab = currentTab
  end
  renderTab(initialTab)

  if pubWindow and not pubWindow:isVisible() then
    pubWindow:show()
    pubWindow:raise()
    pubWindow:focus()
  end
end

function toggle()
  if not CENTRAL_RANK_ENABLED then return end
  if not pubWindow then return end

  if pubWindow:isVisible() then
    pubWindow:hide()
    return
  end

  pubWindow:show()
  pubWindow:raise()
  pubWindow:focus()
  sendAction({ action = 'request_state', tab = currentTab })
end

function init()
  if connect then
    connect(g_game, {
      onGameStart = onTabelaProssomissaoGameStart,
      onGameEnd = onTabelaProssomissaoGameEnd
    })
  end

  if ProtocolGame and ProtocolGame.registerExtendedOpcode then
    ProtocolGame.registerExtendedOpcode(OPCODE_PUB_COMMUNITY, onPubCommunityOpcode)
  end

  buildTabelaProssomissaoUI()

  if tabelaProssomissaoWindow and not (tabelaProssomissaoTitleLabel and tabelaProssomissaoTextLabel and tabelaProssomissaoAbandonButton and tabelaProssomissaoCloseButton and tabelaProssomissaoIcon) then
    print('[game_pubcommunity] tabelaProssomissao widgets were not found; mission tracker disabled.')
    tabelaProssomissaoWindow:destroy()
    tabelaProssomissaoWindow = nil
    tabelaProssomissaoTitleLabel = nil
    tabelaProssomissaoTextLabel = nil
    tabelaProssomissaoAbandonButton = nil
    tabelaProssomissaoCloseButton = nil
    if tabelaProssomissaoIcon then
      tabelaProssomissaoIcon:destroy()
      tabelaProssomissaoIcon = nil
    end
  end

  if tabelaProssomissaoAbandonButton then
    tabelaProssomissaoAbandonButton.onClick = function()
      sendAction({ action = 'abandon_mission_tracker' })
    end
  end

  if tabelaProssomissaoCloseButton then
    tabelaProssomissaoCloseButton.onClick = function()
      minimizarTabelaProssomissao()
    end
  end

  if tabelaProssomissaoIcon then
    tabelaProssomissaoIcon.onClick = function()
      showTabelaProssomissao()
    end
    if g_mouse and g_mouse.bindPressMove then
      g_mouse.bindPressMove(tabelaProssomissaoIcon, function(mousePos, mouseMoved)
        local pos = tabelaProssomissaoIcon:getPosition()
        local newPos = { x = pos.x + mouseMoved.x, y = pos.y + mouseMoved.y }
        tabelaProssomissaoIcon:setPosition(newPos)
        tabelaProssomissaoIconCustomPosition = newPos
      end)
    end
  end

  if cycleEvent then
    tabelaProssomissaoRefreshEvent = cycleEvent(refreshTabelaProssomissaoProgress, 2000)
  end

  if not CENTRAL_RANK_ENABLED then
    return
  end

  pubWindow = g_ui.displayUI('pubcommunity.otui')
  if not pubWindow then
    print('[game_pubcommunity] pubcommunity.otui could not be loaded; module disabled.')
    return
  end
  pubWindow:hide()

  messageLabel = pubWindow:recursiveGetChildById('messageLabel')
  summaryLabel = pubWindow:recursiveGetChildById('summaryLabel')
  listPanel = pubWindow:recursiveGetChildById('listPanel')

  local closeButton = pubWindow:recursiveGetChildById('closeButton')
  local refreshButton = pubWindow:recursiveGetChildById('refreshButton')
  local rankTabButton = pubWindow:recursiveGetChildById('rankTabButton')
  local shopTabButton = pubWindow:recursiveGetChildById('shopTabButton')
  local tutorialTabButton = pubWindow:recursiveGetChildById('tutorialTabButton')

  if not (messageLabel and summaryLabel and listPanel and closeButton and refreshButton and rankTabButton and shopTabButton and tutorialTabButton) then
    print('[game_pubcommunity] required widgets were not found; module disabled.')
    pubWindow:destroy()
    pubWindow = nil
    return
  end

  closeButton.onClick = function() pubWindow:hide() end
  refreshButton.onClick = function()
    if currentTab == 'tutorial' then
      renderTutorial()
      return
    end

    sendAction({ action = 'request_state', tab = currentTab })
  end
  rankTabButton.onClick = function()
    updateMessage('Ranking global dos jogadores do servidor.')
    renderTab('rankings')
  end
  shopTabButton.onClick = function()
    updateMessage('Loja de recompensas e itens do sistema de rank.')
    renderTab('shop')
  end
  tutorialTabButton.onClick = function()
    renderTab('tutorial')
  end

end

function terminate()
  if tabelaProssomissaoRefreshEvent then
    removeEvent(tabelaProssomissaoRefreshEvent)
    tabelaProssomissaoRefreshEvent = nil
  end

  if disconnect then
    disconnect(g_game, {
      onGameStart = onTabelaProssomissaoGameStart,
      onGameEnd = onTabelaProssomissaoGameEnd
    })
  end

  if ProtocolGame and ProtocolGame.unregisterExtendedOpcode then
    ProtocolGame.unregisterExtendedOpcode(OPCODE_PUB_COMMUNITY)
  end

  if pubWindow then pubWindow:destroy() pubWindow = nil end
  if tabelaProssomissaoWindow then tabelaProssomissaoWindow:destroy() tabelaProssomissaoWindow = nil end
  if tabelaProssomissaoIcon then tabelaProssomissaoIcon:destroy() tabelaProssomissaoIcon = nil end
end
