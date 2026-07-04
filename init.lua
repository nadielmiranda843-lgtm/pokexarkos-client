-- CONFIG
APP_NAME = "pokexarkos"  -- important, change it, it's name for config dir and files in appdata
APP_VERSION = 1341       -- client version for updater and login to identify outdated client
DEFAULT_LAYOUT = "default" -- on android it's forced to "mobile", check code bellow

-- If you don't use updater or other service, set it to updater = ""
Services = {
  -- website = "http://otclient.ovh", -- currently not used
  -- updater = "http://otclient.ovh/api/updater.php",
  -- stats = "",
  -- crash = "http://otclient.ovh/api/crash.php",
  -- feedback = "http://otclient.ovh/api/feedback.php",
  -- status = "http://otclient.ovh/api/status.php"
}

-- Servers accept http login url, websocket login url or ip:port:version
Servers = {
  OFFLINE = "26.183.177.197:7171:1098",
  --PokemonDivineLegacy = "127.0.0.1:7171:1098:30"
  -- PokemonDivineLegacy = "127.0.0.1:7171:1098:100"
}

--Server = "ws://otclient.ovh:3000/"
--Server = "ws://127.0.0.1:88/"
--USE_NEW_ENERGAME = true -- uses entergamev2 based on websockets instead of entergame
ALLOW_CUSTOM_SERVERS = false -- if true it shows option ANOTHER on server list

g_app.setName("Poke Xarkos")
-- CONFIG END

-- print first terminal message
g_logger.info(os.date("== application started at %b %d %Y %X"))
g_logger.info(g_app.getName() .. ' ' .. g_app.getVersion() .. ' rev ' .. g_app.getBuildRevision() .. ' (' .. g_app.getBuildCommit() .. ') made by ' .. g_app.getAuthor() .. ' built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch())

if not g_resources.directoryExists("/data") then
  g_logger.fatal("Data dir doesn't exist.")
end

if not g_resources.directoryExists("/modules") then
  g_logger.fatal("Modules dir doesn't exist.")
end

-- settings
g_configs.loadSettings("/config.otml")

-- set layout
local settings = g_configs.getSettings()
local layout = DEFAULT_LAYOUT
if g_app.isMobile() then
  layout = "mobile"
elseif settings:exists('layout') then
  layout = settings:getValue('layout')
end
g_resources.setLayout(layout)

-- load mods
g_modules.discoverModules()
g_modules.ensureModuleLoaded("corelib")

local DEBUG_DOUBLE_DESTROY = false
if DEBUG_DOUBLE_DESTROY and UIWidget and UIWidget.destroy then
  local oldDestroy = UIWidget.destroy
  local destroyedWidgets = setmetatable({}, { __mode = 'k' })

  UIWidget.destroy = function(self, ...)
    if destroyedWidgets[self] then
      local okId, widgetId = pcall(function() return self:getId() end)
      local okStyle, styleName = pcall(function() return self:getStyleName() end)
      local idText = (okId and widgetId and widgetId ~= '') and widgetId or '<sem-id>'
      local styleText = (okStyle and styleName and styleName ~= '') and styleName or '<sem-style>'
      g_logger.warning(string.format('[double-destroy] widget id=%s style=%s', idText, styleText))
      g_logger.warning(debug.traceback('[double-destroy] stack'))
    else
      destroyedWidgets[self] = true
    end
    return oldDestroy(self, ...)
  end
end
  
local function loadModules()
  -- libraries modules 0-99
  g_modules.autoLoadModules(99)
  g_modules.ensureModuleLoaded("gamelib")

  -- client modules 100-499
  g_modules.autoLoadModules(499)
  g_modules.ensureModuleLoaded("client")

  -- game modules 500-999
  g_modules.autoLoadModules(999)
  g_modules.ensureModuleLoaded("game_interface")
  -- g_modules.ensureModuleLoaded("game_inventory")

  -- mods 1000-9999
  g_modules.autoLoadModules(9999)
end

-- report crash
if type(Services.crash) == 'string' and Services.crash:len() > 4 and g_modules.getModule("crash_reporter") then
  g_modules.ensureModuleLoaded("crash_reporter")
end

-- run updater, must use data.zip
if type(Services.updater) == 'string' and Services.updater:len() > 4 
  and g_resources.isLoadedFromArchive() and g_modules.getModule("updater") then
  g_modules.ensureModuleLoaded("updater")
  return Updater.init(loadModules)
end
loadModules()
