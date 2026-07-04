function translateNetworkError(errcode, connecting, errdesc)
  local text
  if errcode == 111 then
    text = 'Conexao recusada. O servidor do PokeXarkos pode estar offline ou reiniciando.\nTente novamente em alguns instantes.'
  elseif errcode == 110 then
    text = 'Tempo de conexao esgotado. Verifique sua internet ou aguarde o servidor voltar.'
  elseif errcode == 1 then
    text = 'Falha na conexao. O endereco do servidor nao foi encontrado.'
  elseif connecting then
    text = 'Falha na conexao com o PokeXarkos.'
  else
    text = 'Sua conexao com o PokeXarkos foi perdida.\nSua internet pode ter caido ou o servidor pode ter reiniciado.'
  end
  text = text .. ' ' .. string.format('(ERRO %d)', errcode)
  return text
end
