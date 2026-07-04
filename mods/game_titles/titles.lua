local playerTitles = {
["Carluccio"] = {title = "ADM", titleFont = "verdana-11px-rounded", color = "#8831eb"},
["Morduk"] = {title = "ADMIN", titleFont = "verdana-11px-rounded", color = "#8831eb"}
}

local dynamicPlayerTitles = {}

function init()

  connect(Creature, {
    onAppear = updateTitle,
  })  
end

function terminate()

disconnect(Creature, {
    onAppear = updateTitle,
  })  
end

function setDynamicTitles(titles)
  dynamicPlayerTitles = titles or {}

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  local creatures = g_map.getSpectators(localPlayer:getPosition(), false)
  if not creatures then
    return
  end

  for _, creature in ipairs(creatures) do
    updateTitle(creature)
  end
end

function updateTitle(creature)
    local name = creature:getName()
	if creature:isNpc() then
	creature:setTitle("NPC", "verdana-11px-rounded", "blue")
    end
	if creature:getSkull() == SkullYellow then 
	creature:setTitle("Shiny", "verdana-11px-rounded", "orange")
	end
    if creature:getSkull() == SkullRed then 
	creature:setTitle("Mega", "verdana-11px-rounded", "red")
	end
	-- if creature:getSkull() == SkullYellow then 
	-- creature:setTitle("Shiny Mega", "verdana-11px-rounded", "#500e9c")
	-- end
    if creature:isPlayer() then
        local dynamicTitle = dynamicPlayerTitles[name]
        if dynamicTitle and dynamicTitle.title then
            local titleText = dynamicTitle.title
            if dynamicTitle.cityVip then
                titleText = '[ VIP ]\n' .. titleText
            end
            creature:setTitle(titleText, "verdana-11px-rounded", dynamicTitle.color or "#f1f1f1")
        elseif playerTitles[name] then
            creature:setTitle(playerTitles[name].title, playerTitles[name].titleFont, playerTitles[name].color)
        end
    end
end
