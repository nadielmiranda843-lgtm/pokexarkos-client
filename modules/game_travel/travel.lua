travelWindow = nil
travelButton = nil
searchEvent = nil

local selectedRegion = 'Kanto'
local selectedDestination = nil

local travelData = {
  Kanto = {
    { name = 'Pallet Town', subtitle = 'Inicio classico e hub inicial', method = 'Teleport Pad', command = 'pallet', note = 'Ideal para reset rapido e organizacao de inventario.', description = 'Centro inicial com acesso rapido aos primeiros NPCs, heal e organizacao basica do personagem.' },
    { name = 'Viridian City', subtitle = 'Rota de progresso inicial', method = 'Ground Warp', command = 'viridian', note = 'Boa para treino e preparacao de progresso.', description = 'Cidade de conexao com rotas de nivel inicial, suporte e movimentacao rapida entre areas seguras.' },
    { name = 'Pewter City', subtitle = 'Hub de pedra e desafio', method = 'Train Gate', command = 'pewter', note = 'Recomendada para players em evolucao.', description = 'Cidade focada em combate, quests e acesso a zonas mais densas de grind e desenvolvimento.' },
    { name = 'Cerulean City', subtitle = 'Acesso aquatico e suporte', method = 'Water Route', command = 'cerulean', note = 'Boa para rotas de agua e mapa mid game.', description = 'Ponto equilibrado para quests e farm, com rotas fluidas para jogadores em fase intermediaria.' },
    { name = 'Vermilion City', subtitle = 'Porto e deslocamento rapido', method = 'Port Warp', command = 'vermilion', note = 'Cidade forte para fluxo logistico.', description = 'Hub portuario com clima urbano, excelente para conectar viagem, mercado e movimento geral.' }
  },
  Johto = {
    { name = 'New Bark', subtitle = 'Base leve e nostalgica', method = 'Sky Rail', command = 'newbark', note = 'Boa opcao para rotas tranquilas.', description = 'Cidade limpa e compacta, util para comecar cadeias de viagem sem poluicao visual.' },
    { name = 'Violet', subtitle = 'Conexao vertical com progresso', method = 'Aerial Link', command = 'violet', note = 'Regiao classica com fluxo rapido.', description = 'Ponto de transicao entre rotas classicas, com boa leitura e progresso natural do jogador.' },
    { name = 'Goldenrod', subtitle = 'Capital comercial', method = 'Metro Warp', command = 'goldenrod', note = 'Excelente para economizar tempo de deslocamento.', description = 'Cidade grande e central para comercio, quests, organizacao e movimentacao entre regioes.' },
    { name = 'Ecruteak', subtitle = 'Hub mistico e elegante', method = 'Temple Gate', command = 'ecruteak', note = 'Otima para eventos tematicos.', description = 'Regiao com identidade forte e acesso a conteudos mistos de progressao, lore e batalhas.' }
  },
  Hoenn = {
    { name = 'Littleroot', subtitle = 'Entrada limpa e moderna', method = 'Energy Warp', command = 'littleroot', note = 'Boa para fluxo rapido de retorno.', description = 'Cidade inicial com leitura muito limpa, indicada para centralizar retorno e rotas simples.' },
    { name = 'Slateport', subtitle = 'Cidade portuaria premium', method = 'Port Travel', command = 'slateport', note = 'Boa para transicao entre continentes e ilhas.', description = 'Ambiente costeiro com acesso otimizado para troca de mapa, eventos e continuidade de quest.' },
    { name = 'Mauville', subtitle = 'Centro eletrico do mapa', method = 'Junction Warp', command = 'mauville', note = 'Excelente para mobilidade geral.', description = 'Nucleo forte de mobilidade e redistribuicao de rotas, ideal para diminuir tempo perdido.' },
    { name = 'Lilycove', subtitle = 'Hub visual premium', method = 'Aero Dock', command = 'lilycove', note = 'Boa para jogadores ja estabilizados.', description = 'Cidade de alto valor logistico, com rotas refinadas e clima de conteudo mais avancado.' }
  },
  Special = {
    { name = 'Elite Pass Arena', subtitle = 'Acesso especial e competitivo', method = 'Elite Warp', command = 'elitearena', note = 'Pode depender de missao ou passe.', description = 'Destino premium pensado para eventos, lutas fortes e conteudos diferenciados do servidor.' },
    { name = 'Battle Frontier', subtitle = 'Conteudo hardcore e rotativo', method = 'Frontier Gate', command = 'frontier', note = 'Indicado para jogadores mais avancados.', description = 'Area especial para desafios mais densos, escalada de dificuldade e ritmo mais agressivo.' },
    { name = 'Event Island', subtitle = 'Mapa sazonal e exclusivo', method = 'Event Ferry', command = 'eventisland', note = 'Pode abrir so em eventos especificos.', description = 'Destino flexivel para eventos, campanhas e conteudo sazonal sem poluir a rota padrao do jogo.' }
  }
}

local function getAllTabButtons()
  return {
    Kanto = travelWindow.tabKanto,
    Johto = travelWindow.tabJohto,
    Hoenn = travelWindow.tabHoenn,
    Special = travelWindow.tabSpecial
  }
end

local function normalized(value)
  return value:lower():gsub('%s+', '')
end

local function filterDestinations()
  if not travelWindow then
    return {}
  end

  local text = travelWindow.searchText:getText() or ''
  text = text:trim():lower()

  local entries = travelData[selectedRegion] or {}
  if text:len() == 0 then
    return entries
  end

  local result = {}
  for _, entry in ipairs(entries) do
    local haystack = table.concat({
      entry.name or '',
      entry.subtitle or '',
      entry.method or '',
      entry.command or '',
      entry.description or ''
    }, ' '):lower()

    if haystack:find(text, 1, true) then
      table.insert(result, entry)
    end
  end

  return result
end

local function setDetails(entry)
  selectedDestination = entry
  if not travelWindow then return end

  if not entry then
    travelWindow.detailsTitle:setText('Selecione um destino')
    travelWindow.detailsRegion:setText(selectedRegion)
    travelWindow.detailsDescription:setText('Selecione uma rota para ver a descricao, o tipo de acesso e o comando que sera enviado.')
    travelWindow.detailsMethod:setText('-')
    travelWindow.detailsCommand:setText('-')
    travelWindow.detailsNote:setText('-')
    travelWindow.confirmButton:setEnabled(false)
    return
  end

  travelWindow.detailsTitle:setText(entry.name)
  travelWindow.detailsRegion:setText(selectedRegion .. '  |  ' .. (entry.subtitle or ''))
  travelWindow.detailsDescription:setText(entry.description or '')
  travelWindow.detailsMethod:setText(entry.method or '-')
  travelWindow.detailsCommand:setText('!travel ' .. (entry.command or normalized(entry.name)))
  travelWindow.detailsNote:setText(entry.note or '-')
  travelWindow.confirmButton:setEnabled(true)
end

local function rebuildList()
  if not travelWindow then return end

  local tabs = getAllTabButtons()
  for region, button in pairs(tabs) do
    button:setOn(region == selectedRegion)
  end

  travelWindow.destinationList:destroyChildren()
  local entries = filterDestinations()

  for _, entry in ipairs(entries) do
    local card = g_ui.createWidget('TravelDestinationCard', travelWindow.destinationList)
    card.title:setText(entry.name)
    card.subtitle:setText(entry.subtitle or '')
    card.onClick = function(widget)
      for _, child in ipairs(travelWindow.destinationList:getChildren()) do
        child:setOn(false)
      end
      widget:setOn(true)
      setDetails(entry)
    end
    if selectedDestination and selectedDestination.name == entry.name then
      card:setOn(true)
    end
  end

  if #entries > 0 then
    setDetails(entries[1])
    local first = travelWindow.destinationList:getChildByIndex(1)
    if first then
      first:setOn(true)
    end
  else
    setDetails(nil)
    travelWindow.detailsDescription:setText('Nenhum destino encontrado para o filtro atual.')
  end
end

function selectRegion(region)
  selectedRegion = region
  selectedDestination = nil
  rebuildList()
end

local function onSearchChange()
  if searchEvent then
    removeEvent(searchEvent)
  end

  searchEvent = scheduleEvent(function()
    rebuildList()
    searchEvent = nil
  end, 60)
end

function confirmTravel()
  if not selectedDestination then
    return
  end

  local command = selectedDestination.command or normalized(selectedDestination.name)
  g_game.talk('!travel ' .. command)
end

function toggle()
  if not travelWindow then
    return
  end

  if travelWindow:isVisible() then
    hide()
  else
    show()
  end
end

function show()
  if not travelWindow then return end
  travelWindow:show()
  travelWindow:raise()
  travelWindow:focus()
  rebuildList()
end

function hide()
  if not travelWindow then return end
  travelWindow:hide()
end

function init()
  travelWindow = g_ui.displayUI('travel')
  travelWindow:hide()
  travelWindow.searchText.onTextChange = onSearchChange
  travelWindow.confirmButton:setEnabled(false)

  connect(g_game, {
    onGameEnd = hide
  })

  local gameRootPanel = modules.game_interface.getRootPanel() or g_ui.getRootWidget()
  g_keyboard.bindKeyDown('Ctrl+J', toggle, gameRootPanel)
end

function terminate()
  disconnect(g_game, {
    onGameEnd = hide
  })

  local gameRootPanel = modules.game_interface.getRootPanel() or g_ui.getRootWidget()
  g_keyboard.unbindKeyDown('Ctrl+J', gameRootPanel)

  if searchEvent then
    removeEvent(searchEvent)
    searchEvent = nil
  end

  if travelButton then
    travelButton:destroy()
    travelButton = nil
  end

  if travelWindow then
    travelWindow:destroy()
    travelWindow = nil
  end
end
