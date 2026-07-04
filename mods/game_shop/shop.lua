local OPCODE_SHOP = 110

local shopWindow
local pointsValueLabel
local itemListPanel
local itemFilterPanel
local itemBagFilterPanel
local mountListPanel
local mountFilterPanel
local outfitFilterPanel
local outfitListPanel
local vipFilterPanel
local vipListPanel
local pokeboxListPanel
local pokeboxFilterPanel
local itemListScrollBar
local mountListScrollBar
local outfitListScrollBar
local vipListScrollBar
local pokeboxListScrollBar
local categoryTitleLabel
local emptyStateLabel
local closeButton

local pointsBalance = 0
local currentCategory = 'montarias'
local currentItemFilter = 'item'
local currentBagFilter = 'common'
local currentMountFilter = 'all'
local currentOutfitFilter = 'common'
local currentVipFilter = 'premium'
local currentPokeboxFilter = 'all'
local itemVisibleOfferCount = 0
local mountVisibleOfferCount = 0
local outfitVisibleOfferCount = 0
local vipVisibleOfferCount = 0
local pokeboxVisibleOfferCount = 0
local closeButtonHovered = false
local closeButtonPressed = false
local purchaseConfirmWindow = nil
local buildItemOffers
local buildMountOffers
local buildOutfitOffers
local buildVipOffers
local buildPokeboxOffers
local getPreviewLookType
local refreshVisibleCategory

local shopCategories = {
  { id = 'roupa', label = 'Roupa' },
  { id = 'items', label = 'Items' },
  { id = 'vip', label = 'VIP' },
  { id = 'pokebox', label = 'PokeBox' },
  { id = 'montarias', label = 'Montarias' }
}

local pokeboxFilters = {
  { id = 'all', label = 'Todos' },
  { id = 'ark', label = 'Ark' },
  { id = 'lord', label = 'Lord' },
  { id = 'demon', label = 'Demon' },
  { id = 'angel', label = 'Angel' },
  { id = 'none', label = 'Comum' }
}

local mountFilters = {
  { id = 'all', label = 'Todos' },
  { id = 'common', label = 'Comum' },
  { id = 'special', label = 'Especial' },
  { id = 'legendary', label = 'Lendario' }
}

local outfitFilters = {
  { id = 'common', label = 'Comum' },
  { id = 'premium', label = 'Premium' },
  { id = 'legendary', label = 'Lendaria' },
  { id = 'epic', label = 'Epic' }
}

local vipFilters = {
  { id = 'premium', label = 'Premium' },
  { id = 'plus', label = 'Plus' }
}

local itemFilters = {
  { id = 'item', label = 'Item' },
  { id = 'pokeball', label = 'Pokeball' },
  { id = 'bags', label = 'Bags' }
}

local bagFilters = {
  { id = 'common', label = 'Bag Comum' },
  { id = 'legendary', label = 'Bag Lendarias' }
}

local itemOffers = {
  { key = 'bag alvo', itemId = 40181, previewImage = '/mods/game_shop/previews/items/bags/common/bag_alvo.png', name = 'Bag Alvo', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag ashe', itemId = 40175, previewImage = '/mods/game_shop/previews/items/bags/common/bag_ashe.png', name = 'Bag Ashe', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag ark', itemId = 40174, previewImage = '/mods/game_shop/previews/items/bags/common/bag_ark.png', name = 'Bag Ark', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag blue santa', itemId = 40163, previewImage = '/mods/game_shop/previews/items/bags/common/bag_blue_santa.png', name = 'Bag Blue Santa', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag red santa', itemId = 40162, previewImage = '/mods/game_shop/previews/items/bags/common/bag_red_santa.png', name = 'Bag Red Santa', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag pink twinkle', itemId = 40161, previewImage = '/mods/game_shop/previews/items/bags/common/bag_pink_twinkle.png', name = 'Bag Pink Twinkle', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag turquoise twinkle', itemId = 40160, previewImage = '/mods/game_shop/previews/items/bags/common/bag_turquoise_twinkle.png', name = 'Bag Turquoise Twinkle', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag purple twinkle', itemId = 40159, previewImage = '/mods/game_shop/previews/items/bags/common/bag_purple_twinkle.png', name = 'Bag Purple Twinkle', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag youtube', itemId = 40145, previewImage = '/mods/game_shop/previews/items/bags/common/bag_youtube.png', name = 'Bag Youtube', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag sweetheart', itemId = 40146, previewImage = '/mods/game_shop/previews/items/bags/common/bag_sweetheart.png', name = 'Bag Sweetheart', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag roseheart', itemId = 40147, previewImage = '/mods/game_shop/previews/items/bags/common/bag_roseheart.png', name = 'Bag Roseheart', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag soulmate', itemId = 40148, previewImage = '/mods/game_shop/previews/items/bags/common/bag_soulmate.png', name = 'Bag Soulmate', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag aurumheart', itemId = 40149, previewImage = '/mods/game_shop/previews/items/bags/common/bag_aurumheart.png', name = 'Bag Aurumheart', price = 10, category = 'bags', bagType = 'common' },
  { key = 'bag tempest', itemId = 40158, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_tempest.png', name = 'Bag Tempest', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag glacial', itemId = 40151, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_glacial.png', name = 'Bag Glacial', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag venom', itemId = 40157, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_venom.png', name = 'Bag Venom', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag infernal', itemId = 40156, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_infernal.png', name = 'Bag Infernal', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag sky fluffy', itemId = 40155, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_sky_fluffy.png', name = 'Bag Sky Fluffy', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag limon fluffy', itemId = 40154, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_limon_fluffy.png', name = 'Bag Limon Fluffy', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag cloudy fluffy', itemId = 40153, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_cloudy_fluffy.png', name = 'Bag Cloudy Fluffy', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag sunny fluffy', itemId = 40152, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_sunny_fluffy.png', name = 'Bag Sunny Fluffy', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag night', itemId = 39866, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_night.png', name = 'Bag Night', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag crimson', itemId = 39867, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_crimson.png', name = 'Bag Crimson', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag verdant', itemId = 39868, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_verdant.png', name = 'Bag Verdant', price = 10, category = 'bags', bagType = 'legendary' },
  { key = 'bag void', itemId = 39869, previewImage = '/mods/game_shop/previews/items/bags/legendary/bag_void.png', name = 'Bag Void', price = 10, category = 'bags', bagType = 'legendary' }
}

local mountOffers = {
  { itemId = 39220, name = 'Robo Basic Mecha', price = 15, race = 'special', maleLookType = 3424, femaleLookType = 3425 },
  { itemId = 39221, name = 'Robo Basic Blastoise', price = 15, race = 'special', maleLookType = 3428, femaleLookType = 3429 },
  { itemId = 39222, name = 'Robo Basic Magmar', price = 15, race = 'special', maleLookType = 3430, femaleLookType = 3431 },
  { itemId = 39223, name = 'Robo Basic Tropius', price = 15, race = 'special', maleLookType = 3426, femaleLookType = 3427 },
  { itemId = 39224, name = 'Robo Basic Gengar', price = 15, race = 'special', maleLookType = 3432, femaleLookType = 3433 },
  { itemId = 39073, name = 'Adventurer Bike', price = 10, race = 'common', maleLookType = 3379, femaleLookType = 3380 },
  { itemId = 39074, name = 'Hoverboard', price = 10, race = 'common', maleLookType = 3381, femaleLookType = 3382 },
  { itemId = 39075, name = 'Roller Skate', price = 10, race = 'common', maleLookType = 3389, femaleLookType = 3384 },
  { itemId = 39142, name = 'Normal Bike', price = 10, race = 'common', maleLookType = 3470, femaleLookType = 3469 },
  { itemId = 39141, name = 'Thunder Bike', price = 10, race = 'common', maleLookType = 3462, femaleLookType = 3461 },
  { itemId = 39140, name = 'Water Bike', price = 10, race = 'common', maleLookType = 3464, femaleLookType = 3463 },
  { itemId = 39138, name = 'Fire Bike', price = 10, race = 'common', maleLookType = 3468, femaleLookType = 3467 }
}

local outfitOffers = {
  { key = 'ethan', name = 'Ethan', price = 10, maleLookType = 3742, femaleLookType = 3742, category = 'common' },
  { key = 'coringa', name = 'Coringa', price = 10, maleLookType = 3752, femaleLookType = 3752, category = 'common' },
  { key = 'espectre 2', name = 'Espectre 2', price = 10, maleLookType = 3757, femaleLookType = 3757, category = 'common' },
  { key = 'aqua male', name = 'Aqua Male', price = 10, maleLookType = 3762, femaleLookType = 3762, category = 'common' },
  { key = 'aqua female', name = 'Aqua Female', price = 10, maleLookType = 3763, femaleLookType = 3763, category = 'common' },
  { key = 'magma male', name = 'Magma Male', price = 10, maleLookType = 3764, femaleLookType = 3764, category = 'common' },
  { key = 'magma female', name = 'Magma Female', price = 10, maleLookType = 3765, femaleLookType = 3765, category = 'common' },
  { key = 'green', name = 'Green', price = 10, maleLookType = 3799, femaleLookType = 3799, category = 'common' },
  { key = 'peppa pig', name = 'Peppa Pig', price = 10, maleLookType = 3626, femaleLookType = 3626, category = 'common' },
  { key = 'ranger branco', name = 'Ranger Branco', price = 10, maleLookType = 3627, femaleLookType = 3627, category = 'common' },
  { key = 'steve', name = 'Steve', price = 10, maleLookType = 3636, femaleLookType = 3636, category = 'common' },
  { key = 'harley', name = 'Harley', price = 10, maleLookType = 3692, femaleLookType = 3692, category = 'common' },
  { key = 'mercador re4', name = 'Mercador Re4', price = 10, maleLookType = 3597, femaleLookType = 3597, category = 'common' },
  { key = 'meduz', name = 'Meduz', price = 10, maleLookType = 845, femaleLookType = 845, category = 'common' },
  { key = 'wintress', name = 'Wintress', price = 10, maleLookType = 852, femaleLookType = 852, category = 'common' },
  { key = 'trem bala', name = 'Trem Bala', price = 20, maleLookType = 3724, femaleLookType = 3724, category = 'premium' },
  { key = 'cap patria', name = 'Cap Patria', price = 20, maleLookType = 3725, femaleLookType = 3725, category = 'premium' },
  { key = 'kaiju n8', name = 'Kaiju N8', price = 20, maleLookType = 3572, femaleLookType = 3572, category = 'premium' },
  { key = 'ainz ooal gown', name = 'Ainz Ooal Gown', price = 20, maleLookType = 3573, femaleLookType = 3573, category = 'premium' },
  { key = 'mago', name = 'Mago', price = 20, maleLookType = 844, femaleLookType = 844, category = 'premium' },
  { key = 'mago morto', name = 'Mago Morto', price = 20, maleLookType = 843, femaleLookType = 843, category = 'premium' },
  { key = 'kid boo', name = 'Kid Boo', price = 30, maleLookType = 3769, femaleLookType = 3769, category = 'legendary' },
  { key = 'sword trunks', name = 'Sword Trunks', price = 30, maleLookType = 3779, femaleLookType = 3779, category = 'legendary' },
  { key = 'fire domain', name = 'Fire Domain', price = 30, maleLookType = 3780, femaleLookType = 3780, category = 'legendary' },
  { key = 'goku god', name = 'Goku God', price = 30, maleLookType = 3507, femaleLookType = 3507, category = 'legendary' },
  { key = 'vegeta blue', name = 'Vegeta Blue', price = 30, maleLookType = 3522, femaleLookType = 3522, category = 'legendary' },
  { key = 'blue seraphim', name = 'Blue Seraphim', price = 40, maleLookType = 3809, femaleLookType = 3809, category = 'epic' },
  { key = 'silver angel', name = 'Silver Angel', price = 40, maleLookType = 3810, femaleLookType = 3810, category = 'epic' },
  { key = 'gold angel', name = 'Gold Angel', price = 40, maleLookType = 3811, femaleLookType = 3811, category = 'epic' }
}

local vipOffers = {
  { key = 'vip premium 7 dias', name = 'VIP Premium 7 Dias', price = 10, days = 7, category = 'premium' },
  { key = 'vip premium 15 dias', name = 'VIP Premium 15 Dias', price = 18, days = 15, category = 'premium' },
  { key = 'vip premium 30 dias', name = 'VIP Premium 30 Dias', price = 30, days = 30, category = 'premium' },
  { key = 'vip plus 7 dias', name = 'VIP Plus 7 Dias', price = 15, days = 7, category = 'plus' },
  { key = 'vip plus 15 dias', name = 'VIP Plus 15 Dias', price = 27, days = 15, category = 'plus' },
  { key = 'vip plus 30 dias', name = 'VIP Plus 30 Dias', price = 45, days = 30, category = 'plus' }
}

local pokeboxOffers = {
  { key = 'ark lunala', itemId = 40143, previewImage = '/mods/game_shop/boxsArk.png', name = 'Box Ark Lunala', price = 100 },
  { key = 'ark mega raichu', itemId = 40143, previewImage = '/mods/game_shop/boxsArk.png', name = 'Box Ark mega raichu', price = 100 },
  { key = 'ark rayquaza', itemId = 40143, previewImage = '/mods/game_shop/boxsArk.png', name = 'Box Ark Rayquaza', price = 100 },
  { key = 'ark regigigas', itemId = 40143, previewImage = '/mods/game_shop/boxsArk.png', name = 'Box Ark Regigigas', price = 100 },
  { key = 'ark yveltal', itemId = 40143, previewImage = '/mods/game_shop/boxsArk.png', name = 'Box Ark Yveltal', price = 100 },
  { key = 'ark zekrom', itemId = 40143, previewImage = '/mods/game_shop/boxsArk.png', name = 'Box Ark Zekrom', price = 100 },
  { key = 'lord ark heatran', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Ark Heatran', price = 100 },
  { key = 'lord ark zygarde', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Ark Zygarde', price = 100 },
  { key = 'lord dialga', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Dialga', price = 100 },
  { key = 'lord heatran', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Heatran', price = 100 },
  { key = 'lord ho-ho', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Ho-Ho', price = 100 },
  { key = 'lord jirachi', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Jirachi', price = 100 },
  { key = 'lord magmortar', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Magmortar', price = 100 },
  { key = 'lord meowscarada', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Meowscarada', price = 100 },
  { key = 'lord mew', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Mew', price = 100 },
  { key = 'lord mewtwo', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Mewtwo', price = 100 },
  { key = 'lord naganadel', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Naganadel', price = 100 },
  { key = 'lord rayquaza', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Rayquaza', price = 100 },
  { key = 'lord salamence', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Salamence', price = 100 },
  { key = 'lord zekrom', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Zekrom', price = 100 },
  { key = 'lord zygarde', itemId = 40164, previewImage = '/mods/game_shop/lord_box.png', name = 'Lord Box Zygarde', price = 100 },
  { key = 'diabolic arceus', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Arceus', price = 100 },
  { key = 'diabolic articuno', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Articuno', price = 100 },
  { key = 'diabolic cresselia', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Cresselia', price = 100 },
  { key = 'diabolic groudon', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Groudon', price = 100 },
  { key = 'diabolic heatran', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Heatran', price = 100 },
  { key = 'diabolic ho-oh', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Ho-oh', price = 100 },
  { key = 'diabolic latios', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Latios', price = 100 },
  { key = 'diabolic moltres', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Moltres', price = 100 },
  { key = 'diabolic rayquaza', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Rayquaza', price = 100 },
  { key = 'diabolic volcanion', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Volcanion', price = 100 },
  { key = 'diabolic zapdos', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Diabolic Zapdos', price = 100 },
  { key = 'shiny diabolic volcanion', itemId = 40144, previewImage = '/mods/game_shop/demon_box.png', name = 'Demon Box Shiny Diabolic Volcanion', price = 100 },
  { key = 'angel arceus', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Arceus', price = 100 },
  { key = 'angel celebi', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Celebi', price = 100 },
  { key = 'angel cresselia', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Cresselia', price = 100 },
  { key = 'angel dialga', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Dialga', price = 100 },
  { key = 'angel entei', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Entei', price = 100 },
  { key = 'angel heatran', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Heatran', price = 100 },
  { key = 'angel ho-ho', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Ho-Ho', price = 100 },
  { key = 'angel kyogre', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Kyogre', price = 100 },
  { key = 'angel latias', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Latias', price = 100 },
  { key = 'angel zekrom', itemId = 40150, previewImage = '/mods/game_shop/angel_box.png', name = 'Angel Box Zekrom', price = 100 }
}

local function formatNumber(value)
  local number = tonumber(value)
  if not number then
    return '0'
  end

  number = math.floor(number)
  local formatted = tostring(number)
  while true do
    local replaced, count = formatted:gsub('^(-?%d+)(%d%d%d)', '%1.%2')
    formatted = replaced
    if count == 0 then
      break
    end
  end
  return formatted
end

local function sendPayload(payload)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  if protocolGame.sendExtendedJSONOpcode then
    protocolGame:sendExtendedJSONOpcode(OPCODE_SHOP, payload)
    return true
  end

  if protocolGame.sendExtendedOpcode then
    protocolGame:sendExtendedOpcode(OPCODE_SHOP, json.encode(payload))
    return true
  end

  return false
end

local function updatePointsLabel()
  if not pointsValueLabel then
    return
  end
  pointsValueLabel:setText(formatNumber(pointsBalance))
end

local function setCloseButtonPressed(pressed)
  if not closeButton then
    return
  end

  closeButtonPressed = pressed

  if closeButton.setMarginTop then
    closeButton:setMarginTop(pressed and 8 or 7)
  end
  if closeButton.setMarginRight then
    closeButton:setMarginRight(pressed and 5 or 6)
  end
  if closeButton.setImageColor then
    if pressed then
      closeButton:setImageColor('#c8c8c8')
    elseif closeButtonHovered then
      closeButton:setImageColor('#ffffffcc')
    else
      closeButton:setImageColor('#ffffff')
    end
  end
end

local function setCloseButtonHovered(hovered)
  closeButtonHovered = hovered
  if closeButtonPressed then
    return
  end
  if closeButton and closeButton.setImageColor then
    closeButton:setImageColor(hovered and '#ffffffcc' or '#ffffff')
  end
end

local function getCategoryButton(categoryId)
  if not shopWindow then
    return nil
  end
  return shopWindow:recursiveGetChildById(categoryId .. 'Button')
end

local function updateCategoryButtons()
  for _, category in ipairs(shopCategories) do
    local button = getCategoryButton(category.id)
    if button then
      if button.setOn then
        button:setOn(category.id == currentCategory)
      end
      if button.setChecked then
        button:setChecked(category.id == currentCategory)
      end
    end
  end
end

local function getItemFilterButton(filterId)
  if not itemFilterPanel then
    return nil
  end
  return itemFilterPanel:recursiveGetChildById(filterId .. 'ItemFilterButton')
end

local function updateItemFilterButtons()
  for _, filter in ipairs(itemFilters) do
    local button = getItemFilterButton(filter.id)
    if button then
      if button.setOn then
        button:setOn(filter.id == currentItemFilter)
      end
      if button.setChecked then
        button:setChecked(filter.id == currentItemFilter)
      end
    end
  end
end

local function getBagFilterButton(filterId)
  if not itemBagFilterPanel then
    return nil
  end
  return itemBagFilterPanel:recursiveGetChildById(filterId .. 'BagFilterButton')
end

local function updateBagFilterButtons()
  for _, filter in ipairs(bagFilters) do
    local button = getBagFilterButton(filter.id)
    if button then
      if button.setOn then
        button:setOn(filter.id == currentBagFilter)
      end
      if button.setChecked then
        button:setChecked(filter.id == currentBagFilter)
      end
    end
  end
end

local function getMountFilterButton(filterId)
  if not mountFilterPanel then
    return nil
  end
  return mountFilterPanel:recursiveGetChildById(filterId .. 'MountFilterButton')
end

local function updateMountFilterButtons()
  for _, filter in ipairs(mountFilters) do
    local button = getMountFilterButton(filter.id)
    if button then
      if button.setOn then
        button:setOn(filter.id == currentMountFilter)
      end
      if button.setChecked then
        button:setChecked(filter.id == currentMountFilter)
      end
    end
  end
end

local function getOutfitFilterButton(filterId)
  if not outfitFilterPanel then
    return nil
  end
  return outfitFilterPanel:recursiveGetChildById(filterId .. 'OutfitFilterButton')
end

local function updateOutfitFilterButtons()
  for _, filter in ipairs(outfitFilters) do
    local button = getOutfitFilterButton(filter.id)
    if button then
      if button.setOn then
        button:setOn(filter.id == currentOutfitFilter)
      end
      if button.setChecked then
        button:setChecked(filter.id == currentOutfitFilter)
      end
    end
  end
end

local function getVipFilterButton(filterId)
  if not vipFilterPanel then
    return nil
  end
  return vipFilterPanel:recursiveGetChildById(filterId .. 'VipFilterButton')
end

local function updateVipFilterButtons()
  for _, filter in ipairs(vipFilters) do
    local button = getVipFilterButton(filter.id)
    if button then
      if button.setOn then
        button:setOn(filter.id == currentVipFilter)
      end
      if button.setChecked then
        button:setChecked(filter.id == currentVipFilter)
      end
    end
  end
end

local function getPokeboxFilterButton(filterId)
  if not pokeboxFilterPanel then
    return nil
  end
  return pokeboxFilterPanel:recursiveGetChildById(filterId .. 'FilterButton')
end

local function updatePokeboxFilterButtons()
  for _, filter in ipairs(pokeboxFilters) do
    local button = getPokeboxFilterButton(filter.id)
    if button then
      if button.setOn then
        button:setOn(filter.id == currentPokeboxFilter)
      end
      if button.setChecked then
        button:setChecked(filter.id == currentPokeboxFilter)
      end
    end
  end
end

local function clearConfirmWindow()
  if purchaseConfirmWindow then
    purchaseConfirmWindow:destroy()
    purchaseConfirmWindow = nil
  end
end

local function requestState()
  sendPayload({ action = 'requestState' })
end

local function shouldShowItemOffer(offer)
  if (offer.category or 'item') ~= currentItemFilter then
    return false
  end
  if currentItemFilter == 'bags' then
    return (offer.bagType or 'common') == currentBagFilter
  end
  return true
end

local function shouldShowMountOffer(offer)
  if currentMountFilter == 'all' then
    return true
  end
  return (offer.race or 'common') == currentMountFilter
end

local function shouldShowOutfitOffer(offer)
  return (offer.category or 'common') == currentOutfitFilter
end

local function shouldShowVipOffer(offer)
  return (offer.category or 'premium') == currentVipFilter
end

local function getPokeboxOfferRace(offer)
  local key = tostring(offer.key or offer.name or ''):lower()
  if key:find('^ark%s+') then
    return 'ark'
  end
  if key:find('^lord%s+') then
    return 'lord'
  end
  if key:find('diabolic') then
    return 'demon'
  end
  if key:find('^angel%s+') then
    return 'angel'
  end
  return 'none'
end

local function shouldShowPokeboxOffer(offer)
  if currentPokeboxFilter == 'all' then
    return true
  end
  return getPokeboxOfferRace(offer) == currentPokeboxFilter
end

local function selectPokeboxFilter(filterId)
  currentPokeboxFilter = filterId
  buildPokeboxOffers()
  refreshVisibleCategory()
end

local function selectItemFilter(filterId)
  currentItemFilter = filterId
  if currentItemFilter == 'bags' then
    currentBagFilter = 'common'
  end
  buildItemOffers()
  refreshVisibleCategory()
end

local function selectBagFilter(filterId)
  currentBagFilter = filterId
  buildItemOffers()
  refreshVisibleCategory()
end

local function selectOutfitFilter(filterId)
  currentOutfitFilter = filterId
  buildOutfitOffers()
  refreshVisibleCategory()
end

local function selectVipFilter(filterId)
  currentVipFilter = filterId
  buildVipOffers()
  refreshVisibleCategory()
end

local function confirmMountPurchase(offer)
  clearConfirmWindow()

  local function yesCallback()
    clearConfirmWindow()
    sendPayload({
      action = 'buyMount',
      itemId = offer.itemId
    })
  end

  local function noCallback()
    clearConfirmWindow()
  end

  purchaseConfirmWindow = displayGeneralBox('Shop Arkos', 'Deseja comprar ' .. offer.name .. ' por ' .. offer.price .. ' Ark Donate Points?', {
    { text='Comprar', callback=yesCallback },
    { text='Cancelar', callback=noCallback },
    anchor=AnchorHorizontalCenter
  }, yesCallback, noCallback)
end

local function onBuyMount(offer)
  if not g_game.isOnline() then
    return
  end

  if pointsBalance < offer.price then
    displayInfoBox('Shop Arkos', 'Voce nao tem Ark Donate Points suficientes para comprar ' .. offer.name .. '.')
    return
  end

  confirmMountPurchase(offer)
end

local function confirmOutfitPurchase(offer)
  clearConfirmWindow()

  local function yesCallback()
    clearConfirmWindow()
    sendPayload({
      action = 'buyOutfit',
      outfitKey = offer.key
    })
  end

  local function noCallback()
    clearConfirmWindow()
  end

  purchaseConfirmWindow = displayGeneralBox('Shop Arkos', 'Deseja comprar a roupa ' .. offer.name .. ' por ' .. offer.price .. ' Ark Donate Points?', {
    { text='Comprar', callback=yesCallback },
    { text='Cancelar', callback=noCallback },
    anchor=AnchorHorizontalCenter
  }, yesCallback, noCallback)
end

local function onBuyOutfit(offer)
  if not g_game.isOnline() then
    return
  end

  if pointsBalance < offer.price then
    displayInfoBox('Shop Arkos', 'Voce nao tem Ark Donate Points suficientes para comprar ' .. offer.name .. '.')
    return
  end

  confirmOutfitPurchase(offer)
end

local function confirmPokeboxPurchase(offer)
  clearConfirmWindow()

  local function yesCallback()
    clearConfirmWindow()
    sendPayload({
      action = 'buyPokebox',
      pokeboxKey = offer.key
    })
  end

  local function noCallback()
    clearConfirmWindow()
  end

  purchaseConfirmWindow = displayGeneralBox('Shop Arkos', 'Deseja comprar ' .. offer.name .. ' por ' .. offer.price .. ' Ark Donate Points?', {
    { text='Comprar', callback=yesCallback },
    { text='Cancelar', callback=noCallback },
    anchor=AnchorHorizontalCenter
  }, yesCallback, noCallback)
end

local function onBuyPokebox(offer)
  if not g_game.isOnline() then
    return
  end

  if pointsBalance < offer.price then
    displayInfoBox('Shop Arkos', 'Voce nao tem Ark Donate Points suficientes para comprar ' .. offer.name .. '.')
    return
  end

  confirmPokeboxPurchase(offer)
end

local function confirmItemPurchase(offer)
  clearConfirmWindow()

  local function yesCallback()
    clearConfirmWindow()
    sendPayload({
      action = 'buyItem',
      itemKey = offer.key
    })
  end

  local function noCallback()
    clearConfirmWindow()
  end

  purchaseConfirmWindow = displayGeneralBox('Shop Arkos', 'Deseja comprar ' .. offer.name .. ' por ' .. offer.price .. ' Ark Donate Points?', {
    { text='Comprar', callback=yesCallback },
    { text='Cancelar', callback=noCallback },
    anchor=AnchorHorizontalCenter
  }, yesCallback, noCallback)
end

local function onBuyItem(offer)
  if not g_game.isOnline() then
    return
  end

  if pointsBalance < offer.price then
    displayInfoBox('Shop Arkos', 'Voce nao tem Ark Donate Points suficientes para comprar ' .. offer.name .. '.')
    return
  end

  confirmItemPurchase(offer)
end

local function confirmVipPurchase(offer)
  clearConfirmWindow()

  local function yesCallback()
    clearConfirmWindow()
    sendPayload({
      action = 'buyVip',
      vipKey = offer.key,
      days = offer.days
    })
  end

  local function noCallback()
    clearConfirmWindow()
  end

  purchaseConfirmWindow = displayGeneralBox('Shop Arkos', 'Deseja comprar ' .. offer.name .. ' por ' .. offer.price .. ' Ark Donate Points?', {
    { text='Comprar', callback=yesCallback },
    { text='Cancelar', callback=noCallback },
    anchor=AnchorHorizontalCenter
  }, yesCallback, noCallback)
end

local function onBuyVip(offer)
  if not g_game.isOnline() then
    return
  end

  if pointsBalance < offer.price then
    displayInfoBox('Shop Arkos', 'Voce nao tem Ark Donate Points suficientes para comprar ' .. offer.name .. '.')
    return
  end

  confirmVipPurchase(offer)
end

buildItemOffers = function()
  if not itemListPanel then
    return
  end

  itemListPanel:destroyChildren()
  itemVisibleOfferCount = 0

  for _, offer in ipairs(itemOffers) do
    if shouldShowItemOffer(offer) then
      itemVisibleOfferCount = itemVisibleOfferCount + 1
      local row = g_ui.createWidget('ShopPokeboxRow', itemListPanel)
      row:setId('itemOffer' .. tostring(offer.key or offer.itemId))

      local preview = row:recursiveGetChildById('pokeboxImagePreview')
      local nameLabel = row:recursiveGetChildById('pokeboxNameLabel')
      local priceLabel = row:recursiveGetChildById('pokeboxPriceLabel')
      local buyButton = row:recursiveGetChildById('buyButton')

      if preview and offer.previewImage then
        preview:setVisible(true)
        preview:setImageSource(offer.previewImage)
      elseif preview then
        preview:setVisible(false)
      end

      if nameLabel then
        nameLabel:setText(offer.name)
      end

      if priceLabel then
        priceLabel:setText(offer.price .. ' ADP')
      end

      if buyButton then
        buyButton:setEnabled(true)
        buyButton.onClick = function()
          onBuyItem(offer)
        end
      end
    end
  end
end

buildVipOffers = function()
  if not vipListPanel then
    return
  end

  vipListPanel:destroyChildren()
  vipVisibleOfferCount = 0

  for _, offer in ipairs(vipOffers) do
    if shouldShowVipOffer(offer) then
      vipVisibleOfferCount = vipVisibleOfferCount + 1
      local row = g_ui.createWidget('ShopPokeboxRow', vipListPanel)
      row:setId('vipOffer' .. offer.key:gsub('%s+', ''))

      local preview = row:recursiveGetChildById('pokeboxImagePreview')
      local nameLabel = row:recursiveGetChildById('pokeboxNameLabel')
      local priceLabel = row:recursiveGetChildById('pokeboxPriceLabel')
      local buyButton = row:recursiveGetChildById('buyButton')

      if preview then
        preview:setVisible(true)
        preview:setImageSource('/mods/game_shop/assets/icon_vip_custom.png')
      end

      if nameLabel then
        nameLabel:setText(offer.name)
      end

      if priceLabel then
        priceLabel:setText(offer.price .. ' ADP')
      end

      if buyButton then
        buyButton.onClick = function()
          onBuyVip(offer)
        end
      end
    end
  end
end

local function buildMountOffers()
  if not mountListPanel then
    return
  end

  mountListPanel:destroyChildren()
  mountVisibleOfferCount = 0

  for _, offer in ipairs(mountOffers) do
    if shouldShowMountOffer(offer) then
      mountVisibleOfferCount = mountVisibleOfferCount + 1
      local row = g_ui.createWidget('ShopMountRow', mountListPanel)
      row:setId('mountOffer' .. offer.itemId)

      local preview = row:recursiveGetChildById('mountPreview')
      local nameLabel = row:recursiveGetChildById('mountNameLabel')
      local priceLabel = row:recursiveGetChildById('mountPriceLabel')
      local buyButton = row:recursiveGetChildById('buyButton')

      if preview then
        if preview.setAnimate then
          preview:setAnimate(true)
        end
        if preview.setCenter then
          preview:setCenter(true)
        end
        preview:setOutfit({ type = getPreviewLookType(offer) })
        if preview.setDirection then
          preview:setDirection(2)
        end
        preview:setVisible(true)
      end

      if nameLabel then
        nameLabel:setText(offer.name)
      end

      if priceLabel then
        priceLabel:setText(offer.price .. ' ADP')
      end

      if buyButton then
        buyButton.onClick = function()
          onBuyMount(offer)
        end
      end
    end
  end
end

local function selectMountFilter(filterId)
  currentMountFilter = filterId
  buildMountOffers()
  refreshVisibleCategory()
end

buildPokeboxOffers = function()
  if not pokeboxListPanel then
    return
  end

  pokeboxListPanel:destroyChildren()
  pokeboxVisibleOfferCount = 0

  for _, offer in ipairs(pokeboxOffers) do
    if shouldShowPokeboxOffer(offer) then
      pokeboxVisibleOfferCount = pokeboxVisibleOfferCount + 1
      local row = g_ui.createWidget('ShopPokeboxRow', pokeboxListPanel)
      row:setId('pokeboxOffer' .. offer.key:gsub('%s+', ''))

      local preview = row:recursiveGetChildById('pokeboxImagePreview')
      local nameLabel = row:recursiveGetChildById('pokeboxNameLabel')
      local priceLabel = row:recursiveGetChildById('pokeboxPriceLabel')
      local buyButton = row:recursiveGetChildById('buyButton')

      if preview and offer.previewImage then
        preview:setVisible(true)
        preview:setImageSource(offer.previewImage)
      elseif preview then
        preview:setVisible(false)
      end

      if nameLabel then
        nameLabel:setText(offer.name)
      end

      if priceLabel then
        priceLabel:setText(offer.price .. ' ADP')
      end

      if buyButton then
        buyButton.onClick = function()
          onBuyPokebox(offer)
        end
      end
    end
  end
end

getPreviewLookType = function(offer)
  local player = g_game.getLocalPlayer()
  if player and player.getSex and player:getSex() == 0 then
    return offer.femaleLookType or offer.maleLookType
  end
  return offer.maleLookType or offer.femaleLookType
end

buildOutfitOffers = function()
  if not outfitListPanel then
    return
  end

  outfitListPanel:destroyChildren()
  outfitVisibleOfferCount = 0

  for _, offer in ipairs(outfitOffers) do
    if shouldShowOutfitOffer(offer) then
      outfitVisibleOfferCount = outfitVisibleOfferCount + 1
      local row = g_ui.createWidget('ShopOutfitRow', outfitListPanel)
      row:setId('outfitOffer' .. offer.key:gsub('%s+', ''))

      local preview = row:recursiveGetChildById('outfitPreview')
      local nameLabel = row:recursiveGetChildById('outfitNameLabel')
      local priceLabel = row:recursiveGetChildById('outfitPriceLabel')
      local buyButton = row:recursiveGetChildById('buyButton')

      if preview then
        if preview.setAnimate then
          preview:setAnimate(true)
        end
        if preview.setCenter then
          preview:setCenter(true)
        end
        preview:setOutfit({ type = getPreviewLookType(offer) })
        if preview.setDirection then
          preview:setDirection(2)
        end
      end

      if nameLabel then
        nameLabel:setText(offer.name)
      end

      if priceLabel then
        priceLabel:setText(offer.price .. ' ADP')
      end

      if buyButton then
        buyButton.onClick = function()
          onBuyOutfit(offer)
        end
      end
    end
  end
end

refreshVisibleCategory = function()
  if not shopWindow then
    return
  end

  local isMounts = currentCategory == 'montarias'
  local isOutfits = currentCategory == 'roupa'
  local isItems = currentCategory == 'items'
  local isPokebox = currentCategory == 'pokebox'
  local isVip = currentCategory == 'vip'

  if categoryTitleLabel then
    if isMounts then
      categoryTitleLabel:setText('Montarias')
    elseif isOutfits then
      categoryTitleLabel:setText('Roupa')
    elseif isItems then
      categoryTitleLabel:setText('Items')
    elseif isPokebox then
      categoryTitleLabel:setText('PokeBox')
    elseif isVip then
      categoryTitleLabel:setText('VIP')
    else
      categoryTitleLabel:setText('Shop')
    end
  end

  if mountListPanel then
    mountListPanel:setVisible(isMounts)
  end

  if itemListPanel then
    itemListPanel:setVisible(isItems)
  end

  if itemFilterPanel then
    itemFilterPanel:setVisible(isItems)
  end

  if itemBagFilterPanel then
    itemBagFilterPanel:setVisible(isItems and currentItemFilter == 'bags')
  end

  if mountFilterPanel then
    mountFilterPanel:setVisible(isMounts)
  end

  if outfitFilterPanel then
    outfitFilterPanel:setVisible(isOutfits)
  end

  if vipFilterPanel then
    vipFilterPanel:setVisible(isVip)
  end

  if outfitListPanel then
    outfitListPanel:setVisible(isOutfits)
  end

  if pokeboxListPanel then
    pokeboxListPanel:setVisible(isPokebox)
  end

  if vipListPanel then
    vipListPanel:setVisible(isVip)
  end

  if pokeboxFilterPanel then
    pokeboxFilterPanel:setVisible(isPokebox)
  end

  if mountListScrollBar then
    mountListScrollBar:setVisible(isMounts)
  end

  if itemListScrollBar then
    itemListScrollBar:setVisible(isItems)
  end

  if outfitListScrollBar then
    outfitListScrollBar:setVisible(isOutfits)
  end

  if pokeboxListScrollBar then
    pokeboxListScrollBar:setVisible(isPokebox)
  end

  if vipListScrollBar then
    vipListScrollBar:setVisible(isVip)
  end

  if emptyStateLabel then
    local showEmptyItems = isItems and itemVisibleOfferCount == 0
    local showEmptyMounts = isMounts and mountVisibleOfferCount == 0
    local showEmptyOutfits = isOutfits and outfitVisibleOfferCount == 0
    local showEmptyVip = isVip and vipVisibleOfferCount == 0
    local showEmptyPokebox = isPokebox and pokeboxVisibleOfferCount == 0
    emptyStateLabel:setVisible((not isMounts and not isOutfits and not isItems and not isPokebox and not isVip) or showEmptyPokebox or showEmptyMounts or showEmptyOutfits or showEmptyItems or showEmptyVip)
    if showEmptyItems then
      emptyStateLabel:setText('Nenhum item nessa categoria.')
    elseif showEmptyMounts then
      emptyStateLabel:setText('Nenhuma montaria nessa categoria.')
    elseif showEmptyOutfits then
      emptyStateLabel:setText('Nenhuma roupa nessa categoria.')
    elseif showEmptyVip then
      emptyStateLabel:setText('Nenhum plano VIP disponivel.')
    elseif showEmptyPokebox then
      emptyStateLabel:setText('Nenhuma PokeBox nessa categoria.')
    elseif not isMounts and not isOutfits and not isItems and not isPokebox and not isVip then
      emptyStateLabel:setText('Categoria em desenvolvimento.\nEm breve novos produtos aqui.')
    end
  end

  updateCategoryButtons()
  updateItemFilterButtons()
  updateBagFilterButtons()
  updateMountFilterButtons()
  updateOutfitFilterButtons()
  updateVipFilterButtons()
  updatePokeboxFilterButtons()
end

local function selectCategory(categoryId)
  currentCategory = categoryId
  if categoryId == 'items' then
    currentItemFilter = 'item'
    buildItemOffers()
  elseif categoryId == 'montarias' then
    buildMountOffers()
  elseif categoryId == 'roupa' then
    buildOutfitOffers()
  elseif categoryId == 'vip' then
    buildVipOffers()
  elseif categoryId == 'pokebox' then
    buildPokeboxOffers()
  end
  refreshVisibleCategory()
end

local function onShopOpcode(protocol, opcode, buffer)
  local ok, data = pcall(function() return json.decode(buffer) end)
  if not ok or type(data) ~= 'table' then
    return
  end

  if data.pointsBalance ~= nil then
    pointsBalance = tonumber(data.pointsBalance) or 0
    updatePointsLabel()
  end

  if data.action == 'purchaseResult' and data.message then
    displayInfoBox('Shop Arkos', data.message)
  end
end

function toggle()
  if not shopWindow then
    return
  end

  if shopWindow:isVisible() then
    clearConfirmWindow()
    shopWindow:hide()
  else
    shopWindow:show()
    shopWindow:raise()
    shopWindow:focus()
    requestState()
    selectCategory(currentCategory)
  end
end

function hide()
  clearConfirmWindow()
  if shopWindow then
    shopWindow:hide()
  end
end

function getPointsBalance()
  return tonumber(pointsBalance) or 0
end

function init()
  if ProtocolGame and ProtocolGame.registerExtendedOpcode then
    ProtocolGame.registerExtendedOpcode(OPCODE_SHOP, onShopOpcode)
  end

  shopWindow = g_ui.displayUI('shop.otui')
  if not shopWindow then
    print('[game_shop] shop.otui could not be loaded; module disabled.')
    return
  end

  shopWindow:hide()

  pointsValueLabel = shopWindow:recursiveGetChildById('pointsValueLabel')
  itemListPanel = shopWindow:recursiveGetChildById('itemListPanel')
  itemFilterPanel = shopWindow:recursiveGetChildById('itemFilterPanel')
  itemBagFilterPanel = shopWindow:recursiveGetChildById('itemBagFilterPanel')
  mountListPanel = shopWindow:recursiveGetChildById('mountListPanel')
  mountFilterPanel = shopWindow:recursiveGetChildById('mountFilterPanel')
  outfitFilterPanel = shopWindow:recursiveGetChildById('outfitFilterPanel')
  outfitListPanel = shopWindow:recursiveGetChildById('outfitListPanel')
  vipFilterPanel = shopWindow:recursiveGetChildById('vipFilterPanel')
  vipListPanel = shopWindow:recursiveGetChildById('vipListPanel')
  pokeboxListPanel = shopWindow:recursiveGetChildById('pokeboxListPanel')
  pokeboxFilterPanel = shopWindow:recursiveGetChildById('pokeboxFilterPanel')
  itemListScrollBar = shopWindow:recursiveGetChildById('itemListScrollBar')
  mountListScrollBar = shopWindow:recursiveGetChildById('mountListScrollBar')
  outfitListScrollBar = shopWindow:recursiveGetChildById('outfitListScrollBar')
  vipListScrollBar = shopWindow:recursiveGetChildById('vipListScrollBar')
  pokeboxListScrollBar = shopWindow:recursiveGetChildById('pokeboxListScrollBar')
  categoryTitleLabel = shopWindow:recursiveGetChildById('categoryTitleLabel')
  emptyStateLabel = shopWindow:recursiveGetChildById('emptyStateLabel')
  closeButton = shopWindow:recursiveGetChildById('closeButton')

  if closeButton then
    closeButton.onMousePress = function()
      setCloseButtonPressed(true)
      return false
    end
    closeButton.onMouseRelease = function()
      setCloseButtonPressed(false)
      return false
    end
    closeButton.onHoverChange = function(_, hovered)
      setCloseButtonHovered(hovered)
      if not hovered then
        setCloseButtonPressed(false)
      end
    end
    closeButton.onClick = function()
      setCloseButtonPressed(false)
      toggle()
    end
  end

  for _, category in ipairs(shopCategories) do
    local button = getCategoryButton(category.id)
    if button then
      button.onClick = function()
        selectCategory(category.id)
      end
    end
  end

  for _, filter in ipairs(itemFilters) do
    local button = getItemFilterButton(filter.id)
    if button then
      button.onClick = function()
        selectItemFilter(filter.id)
      end
    end
  end

  for _, filter in ipairs(bagFilters) do
    local button = getBagFilterButton(filter.id)
    if button then
      button.onClick = function()
        selectBagFilter(filter.id)
      end
    end
  end

  for _, filter in ipairs(mountFilters) do
    local button = getMountFilterButton(filter.id)
    if button then
      button.onClick = function()
        selectMountFilter(filter.id)
      end
    end
  end

  for _, filter in ipairs(outfitFilters) do
    local button = getOutfitFilterButton(filter.id)
    if button then
      button.onClick = function()
        selectOutfitFilter(filter.id)
      end
    end
  end

  for _, filter in ipairs(vipFilters) do
    local button = getVipFilterButton(filter.id)
    if button then
      button.onClick = function()
        selectVipFilter(filter.id)
      end
    end
  end

  for _, filter in ipairs(pokeboxFilters) do
    local button = getPokeboxFilterButton(filter.id)
    if button then
      button.onClick = function()
        selectPokeboxFilter(filter.id)
      end
    end
  end

  buildItemOffers()
  buildMountOffers()
  buildOutfitOffers()
  buildVipOffers()
  buildPokeboxOffers()
  updatePointsLabel()
  refreshVisibleCategory()

  connect(g_game, {
    onGameEnd = hide,
    onGameStart = requestState
  })
end

function terminate()
  disconnect(g_game, {
    onGameEnd = hide,
    onGameStart = requestState
  })

  if ProtocolGame and ProtocolGame.unregisterExtendedOpcode then
    ProtocolGame.unregisterExtendedOpcode(OPCODE_SHOP)
  end

  clearConfirmWindow()

  if shopWindow then
    shopWindow:destroy()
    shopWindow = nil
  end
end
