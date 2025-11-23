#!/usr/bin/env bash

# Start up Docker em modo Production
echo "Iniciando contêineres Docker..."

# O comando 'up' irá:
# 1. Puxar a imagem do MySQL.
# 2. Subir o MySQL (aguardando o healthcheck, graças ao depends_on).
# 3. Subir a aplicação Java.
# Certifique-se de que seu docker-compose.yml esteja correto e no diretório raiz.
sudo docker compose up -d