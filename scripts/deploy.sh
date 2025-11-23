#!/usr/bin/env bash

# Diretório base do projeto (Onde está o pom.xml e o docker-compose.yml)
PROJECT_DIR=$(pwd) # Obtém o diretório atual # Diretório onde o JAR compilado deve ser colocado
JAR_TARGET_DIR="$PROJECT_DIR/target"

# --- 1. INSTALAÇÃO DE DEPENDÊNCIAS (Amazon Linux 2023 usa dnf/yum) ---
echo "Verificando e instalando Docker e ferramentas..."

# Instalar Docker
if ! command -v docker &> /dev/null; then
  echo "Instalando Docker Engine..."
  sudo dnf install -y docker # Usando dnf, padrão no AL2023
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker ec2-user # Adiciona o usuário atual ao grupo docker
  # REINICIE A SESSÃO se o usermod for executado (pode ser necessário sair e entrar)
fi

# Instalar Docker Compose V2 (vem como plugin no AL2023)
if ! command -v docker compose &> /dev/null; then
  echo "Instalando Docker Compose Plugin (V2)..."
  sudo dnf install -y docker-compose-plugin
fi

# Aguarda um momento para garantir que o serviço Docker iniciou
sleep 5

# --- 2. PREPARAÇÃO DA APLICAÇÃO JAVA ---
echo "Compilando e empacotando a aplicação Java (Maven)..."
cd $PROJECT_DIR

# Limpar e empacotar (isso cria o crud-v1.jar em target/)
# Usando o wrapper do Maven
./mvnw clean package -DskipTests

# Verifica se o JAR foi criado antes de prosseguir com o Docker
if [[ ! -f "$JAR_TARGET_DIR/crud-v1.jar" ]]; then
  echo "ERRO: O arquivo JAR não foi encontrado em $JAR_TARGET_DIR/crud-v1.jar. O build falhou."
  exit 1
fi

# --- 3. BUILD E DEPLOY DO DOCKER ---
echo "Executando o script de build e deploy..."
# Adaptação dos scripts do Node para o Java
./production-build.sh
./production-up.sh