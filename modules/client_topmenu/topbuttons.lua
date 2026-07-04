TopButtons = {

  {
    id = 'barButton',
    tooltip = 'Inventory',
    icon = '/images/topbuttons/inventory',
    callback = function()
      modules.game_inventory.toggle()
    end
  },

  {
    id = 'cityTeleportButton',
    tooltip = 'Teleporte',
    icon = '/images/topbuttons/cityteleport',
    callback = function()
      if modules and modules.game_cityteleport and modules.game_cityteleport.toggle then
        modules.game_cityteleport.toggle()
      elseif mods and mods.game_cityteleport and mods.game_cityteleport.toggle then
        mods.game_cityteleport.toggle()
      else
        displayInfoBox('Teleporte', 'Modulo de teleporte nao esta carregado.')
      end
    end
  },

  {
    id = 'bugButton',
    tooltip = 'Teleport Bug',
    icon = '/images/topbuttons/bug',
    callback = function()
      g_game.talk('!bug')
    end
  },

  {
    id = 'skillsButton',
    tooltip = 'Skills',
    icon = '/modules/game_skills/img/perfil_icon',
    callback = function()
      modules.game_skills.toggle()
    end
  },

  {
    id = 'battleButton',
    tooltip = 'Battle',
    icon = '/images/topbuttons/battle',
    callback = function()
      modules.game_battle.toggle()
    end
  },

  {
    id = 'minimapButton',
    tooltip = 'Minimap',
    icon = '/images/topbuttons/minimap',
    callback = function()
      modules.game_minimap.toggle()
    end
  },

  {
    id = 'vipListButton',
    tooltip = 'VIP List',
    icon = '/images/topbuttons/viplist',
    callback = function()
      modules.game_viplist.toggle()
    end
  },

  {
    id = 'shopButton',
    tooltip = 'Shop',
    icon = '/images/topbuttons/shop',
    callback = function()
      if modules and modules.game_shop and modules.game_shop.toggle then
        modules.game_shop.toggle()
      elseif mods and mods.game_shop and mods.game_shop.toggle then
        mods.game_shop.toggle()
      else
        displayInfoBox('Shop Arkos', 'Modulo de shop nao esta carregado.')
      end
    end
  },

  {
    id = 'pubCommunityButton',
    tooltip = 'Central de Rank',
    icon = '/layouts/retro/images/topbuttons/pubcommunity',
    callback = function()
      if modules and modules.game_pubcommunity and modules.game_pubcommunity.toggle then
        modules.game_pubcommunity.toggle()
      elseif mods and mods.game_pubcommunity and mods.game_pubcommunity.toggle then
        mods.game_pubcommunity.toggle()
      else
        displayInfoBox('Central de Rank', 'Modulo da Central de Rank nao esta carregado.')
      end
    end
  },
  
  {
    id = 'elitePassButton',
    tooltip = 'Passe de Elite',
    icon = '/images/topbuttons/elitepass',
    callback = function()
      displayInfoBox('Passe de Elite', 'Passe de elite em desenvolvimento')
    end
  },

  {
    id = 'statsButton',
    tooltip = 'Debug Info',
    icon = '/images/topbuttons/debug',
    callback = function()
      modules.client_stats.toggle()
    end
  },

  {
    id = 'perfilButton',
    tooltip = 'Perfil',
    icon = '/images/topbuttons/menuperfil',
    callback = function()
      if modules and modules.game_profile and modules.game_profile.toggle then
        modules.game_profile.toggle()
      elseif mods and mods.game_profile and mods.game_profile.toggle then
        mods.game_profile.toggle()
      else
        displayInfoBox('Perfil', 'Modulo de perfil nao esta carregado.')
      end
    end
  },

  {
    id = 'optionsButton',
    tooltip = 'Options',
    icon = '/images/topbuttons/options',
    callback = function()
      modules.client_options.toggle()
    end
  },

  {
    id = 'audioButton',
    tooltip = 'Audio',
    icon = '/images/topbuttons/audio',
    callback = function()
      modules.client_options.toggleOption('enableAudio')
    end
  },

  {
    id = 'hotkeysButton',
    tooltip = 'Hotkeys',
    icon = '/images/topbuttons/hotkeys',
    callback = function()
      modules.game_hotkeys.toggle()
    end
  },

  {
    id = 'questLogButton',
    tooltip = 'Quest Log',
    icon = '/images/topbuttons/questlog',
    callback = function()
      g_game.requestQuestLog()
    end
  },

  {
    id = 'pbarButton',
    tooltip = 'Poke Bar',
    icon = '/images/topbuttons/pokebar',
    callback = function()
      modules.game_pokebar.toggle()
    end
  },

  {
    id = 'healthInfoButton',
    tooltip = 'Health Info',
    icon = '/images/topbuttons/healthinfo',
    callback = function()
      modules.game_healthinfo.toggle()
    end
  },

  {
    id = 'logoutButton',
    tooltip = 'Exit',
    icon = '/images/topbuttons/logout',
    callback = function()
      modules.game_interface.tryLogout()
    end
  }

}




