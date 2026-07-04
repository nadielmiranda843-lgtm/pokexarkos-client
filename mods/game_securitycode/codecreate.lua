local creatingPasswordText = ""  -- Variável global para armazenar a senha da criação

-- Funcao pra limpar o texto da janela 1 da senha caso clique em cancel na janela 2
function clearJanela1()
  local creatingPassText = creatingPassWindow:getChildById('enterPasswordText')
  if creatingPassText then
    creatingPassText:setText('')
  end
end

-- Função para armazenar a senha da criação e abrir a otui creatingpassrepeat
function storePasswordAndOpenConfirm()
    local passwordText = creatingPassWindow:getChildById('enterPasswordText'):getText()
    if passwordText ~= "" then
        creatingPasswordText = passwordText
        creatingPassWindow:hide()  -- Oculta a otui creatingpass
        creatingPassRepeatWindow:show()   -- Exibe a otui creatingpassrepeat
        creatingPassRepeatWindow:raise()
    else
        -- Adicione aqui a lógica para exibir uma mensagem de erro ao usuário
        print("O campo de senha não pode estar vazio.")
    end
end

-- Função para enviar as senhas armazenadas
function sendPasswords()
    local confirmPasswordText = creatingPassRepeatWindow:getChildById('enterPasswordText'):getText()
    local passwordText = creatingPassWindow:getChildById('enterPasswordText'):getText()

    if confirmPasswordText ~= "" and passwordText ~= "" then
        local command = "!@%codecreate " .. creatingPasswordText .. "," .. confirmPasswordText
        g_game.talk(command)

        -- Limpa os campos de texto
        creatingPassRepeatWindow:getChildById('enterPasswordText'):setText('')
        creatingPassWindow:getChildById('enterPasswordText'):setText('')

        -- Oculta a janela de creatingpassrepeat
        creatingPassRepeatWindow:hide()
    else
        -- Adicione aqui a lógica para exibir uma mensagem de erro ao usuário
        print("Os campos de senha não podem estar vazios.")
    end
end

function creatingPassWindowHide()
  creatingPassRepeatWindow:getChildById('enterPasswordText'):setText('')
  creatingPassWindow:getChildById('enterPasswordText'):setText('')
  creatingPassWindow:hide()
end

function creatingPassRepeatWindowHide()
  creatingPassRepeatWindow:getChildById('enterPasswordText'):setText('')
  creatingPassWindow:getChildById('enterPasswordText'):setText('')
  creatingPassRepeatWindow:hide()
end

function init()
  connect(g_game, { onGameEnd = onGameEnd })
  connect(g_game, 'onTextMessage', onClick)
  creatingPassRepeatWindow = g_ui.displayUI('codecreaterepeat')
  creatingPassRepeatWindow:hide()

  creatingPassWindow = g_ui.displayUI('codecreate')
  creatingPassWindow:hide()

  confirmCodeWindow = g_ui.displayUI('codeloginconfirm')
  confirmCodeWindow:hide()

  codeLoginNotificationWindow = g_ui.displayUI('codeloginnotification')
  codeLoginNotificationWindow:hide()

  removeCodeWindow = g_ui.displayUI('coderemove')
  removeCodeWindow:hide()
end

function terminate()
  creatingPassRepeatWindow:hide()
  creatingPassWindow:hide()
  confirmCodeWindow:hide()
  codeLoginNotificationWindow:hide()
  creatingPassWindow:getChildById('enterPasswordText'):setText('')
  creatingPassRepeatWindow:getChildById('enterPasswordText'):setText('')
  disconnect(g_game, { onGameEnd = onGameEnd })
  disconnect(g_game, 'onTextMessage', onClick)
end

function onGameEnd()
  creatingPassWindow:getChildById('enterPasswordText'):setText('')
  creatingPassRepeatWindow:getChildById('enterPasswordText'):setText('')
  creatingPassRepeatWindow:hide()
  creatingPassWindow:hide()
  codeLoginNotificationWindow:hide()
end

function codeLoginConfirmWindowHide()
  confirmCodeWindow:getChildById('enterPasswordText'):setText('')
  confirmCodeWindow:hide()
end

function codeLoginNotificationWindowHide()
codeLoginNotificationWindow:hide()
  --addEvent(function() g_effects.fadeOut(lootWindow, 2500) end)
  --scheduleEvent(function() codeLoginNotificationWindow:hide() end, 2500)
end

function onClick(mode, text)
  if mode == MessageModes.Failure then
    if text:find('#@SecurityCodeCreateOpen') then
      creatingPassWindow:show()
      creatingPassWindow:raise()
    elseif text:find('#@SecurityCodeLoginConfirmOpen') then
      confirmCodeWindow:show()
      confirmCodeWindow:raise()
      creatingPassWindow:hide()
      creatingPassRepeatWindow:hide()
    elseif text:find('#@SecurityCodeLoginNotificationOpen') then
      g_effects.fadeIn(codeLoginNotificationWindow, 250)
      codeLoginNotificationWindow:show()
      codeLoginNotificationWindow:raise()
    elseif text:find('#@SecurityCodeLoginNotificationClose') then
      g_effects.fadeOut(codeLoginNotificationWindow, 250)
      codeLoginNotificationWindow:hide()
    elseif text:find('#@SecurityCodeRemoveOpen') then
      removeCodeWindow:show()
      removeCodeWindow:raise()
      creatingPassWindow:hide()
      creatingPassRepeatWindow:hide()
    end
  end
end