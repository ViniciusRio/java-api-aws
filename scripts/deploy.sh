#!/usr/bin/env bash

# Define o diretório raiz do projeto e navega para ele
PROJECT_DIR="/app/java-api-aws" 
cd $PROJECT_DIR 

JAR_TARGET_DIR="$PROJECT_DIR/target"

# --- 1. INSTALAÇÃO DE DEPENDÊNCIAS (Amazon Linux 2023 usa dnf/yum) ---
echo "Verificando e instalando Docker, Java e ferramentas..."

# 1.1. Instalar Docker
if ! command -v docker &> /dev/null; then
  echo "Instalando Docker Engine..."
  sudo dnf install -y docker
  sudo systemctl start docker
  sudo systemctl enable docker
  # Adiciona o usuário atual ao grupo docker (necessita de nova sessão para efeito)
  sudo usermod -aG docker ec2-user 
fi

# 1.2. Instalar Docker Compose V2
if ! command -v docker compose &> /dev/null; then
  echo "Instalando Docker Compose Plugin (V2)..."
  sudo dnf install -y docker-compose-plugin
fi

# 1.3. Instalar JDK 17 (Necessário para o Maven compilar o JAR na EC2)
# Verifica se o compilador Java (javac) está disponível.
if ! command -v javac &> /dev/null || [[ "$(javac -version 2>&1)" != *"17."* ]]; then
  echo "Instalando JDK 17 Amazon Corretto..."
  sudo dnf install java-17-amazon-corretto -y
else
  echo "JDK (javac) já está instalado e configurado."
fi

# Aguarda um momento para garantir que o serviço Docker iniciou
sleep 5

# --- 2. PREPARAÇÃO DA APLICAÇÃO JAVA ---
echo "Compilando e empacotando a aplicação Java (Maven)..."
# O comando './mvnw' é executado no diretório $PROJECT_DIR

# Limpar e empacotar (isso cria o crud-v1.jar em target/)
./mvnw clean package -DskipTests

# Verifica se o JAR foi criado antes de prosseguir com o Docker
if [[ ! -f "$JAR_TARGET_DIR/crud-v1.jar" ]]; then
  echo "ERRO: O arquivo JAR não foi encontrado em $JAR_TARGET_DIR/crud-v1.jar. O build falhou."
  exit 1
fi

# --- 3. BUILD E DEPLOY DO DOCKER ---
echo "Executando o script de build e deploy..."
# Os scripts production-build.sh e production-up.sh devem estar no $PROJECT_DIR
./production-build.sh
./production-up.sh