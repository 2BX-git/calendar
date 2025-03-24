#!/bin/bash

# Função para esperar o .env ser criado
wait_for_env() {
  echo "Aguardando o arquivo .env ser criado..."
  while [ ! -f .env ]; do
    sleep 5
  done
  echo "Arquivo .env encontrado!"
  export $(cat .env | grep -v '^#' | xargs)
}

# Função para obter o code
get_auth_code() {
  echo "Iniciando o servidor temporariamente para obter o código de autorização..."
  npm start &
  SERVER_PID=$!

  # Espera o servidor iniciar
  sleep 5

  # Exibe o URL de autenticação para o usuário
  echo "Por favor, acesse o seguinte URL no seu navegador para autorizar o acesso:"
  echo "https://calendar.2bx.com.br/auth"

  # Espera o code ser salvo em /tmp/auth_code
  echo "Aguardando o código de autorização..."
  while [ ! -f /tmp/auth_code ]; do
    sleep 5
  done

  # Lê o code
  GOOGLE_AUTH_CODE=$(cat /tmp/auth_code)
  echo "Código de autorização obtido: $GOOGLE_AUTH_CODE"

  # Para o servidor temporário
  kill $SERVER_PID
  wait $SERVER_PID 2>/dev/null
}

# Função para obter o refresh_token
get_refresh_token() {
  echo "Trocando o código de autorização por um refresh_token..."
  RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
    -d "code=$GOOGLE_AUTH_CODE" \
    -d "client_id=$GOOGLE_CLIENT_ID" \
    -d "client_secret=$GOOGLE_CLIENT_SECRET" \
    -d "redirect_uri=$GOOGLE_REDIRECT_URI" \
    -d "grant_type=authorization_code")

  # Extrai o refresh_token da resposta JSON
  REFRESH_TOKEN=$(echo $RESPONSE | grep -o '"refresh_token":"[^"]*' | sed 's/"refresh_token":"//')

  if [ -z "$REFRESH_TOKEN" ]; then
    echo "Erro ao obter o refresh_token. Resposta do Google: $RESPONSE"
    exit 1
  fi

  echo "Refresh token obtido: $REFRESH_TOKEN"

  # Atualiza o .env com o refresh_token
  echo "GOOGLE_REFRESH_TOKEN=$REFRESH_TOKEN" >> .env
}

# Início do script
echo "Iniciando o processo de inicialização..."

# Espera o .env ser criado
wait_for_env

# Verifica se o GOOGLE_REFRESH_TOKEN já existe
if [ -n "$GOOGLE_REFRESH_TOKEN" ]; then
  echo "Refresh token já existe: $GOOGLE_REFRESH_TOKEN"
  npm start
  exit 0
fi

# Obtém o code
get_auth_code

# Obtém o refresh_token
get_refresh_token

# Inicia o servidor
npm start
