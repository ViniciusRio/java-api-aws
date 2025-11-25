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
fi

# 1.2. Instalar Docker Compose V2
if ! command -v docker compose &> /dev/null; then
  echo "Instalando Docker Compose Plugin (V2)..."
  sudo dnf install -y docker-compose-plugin
fi

# Verifica se o comando 'docker-compose' V1 (que o sudo costuma reconhecer) existe
if ! sudo command -v docker-compose &> /dev/null; then
    echo "AVISO: Plugin Docker Compose V2 não encontrado no PATH. Instalando binário V2 manualmente..."
    
    # Define o caminho de instalação universal
    COMPOSE_DESTINATION="/usr/local/bin/docker-compose"
    
    # Baixa a última versão estável do Compose V2
    sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o $COMPOSE_DESTINATION
    
    # Garante permissão de execução
    sudo chmod +x $COMPOSE_DESTINATION
    
    # Cria um link simbólico para a sintaxe V1, caso o V2 não seja reconhecido
    sudo ln -s $COMPOSE_DESTINATION /usr/bin/docker-compose
    
    echo "Docker Compose V2 instalado manualmente em /usr/local/bin."
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

# 2.1. CORREÇÃO AUTOMÁTICA DO MAVEN WRAPPER 
# Usaremos '|| true' para garantir que o script continue se o 'if' falhar.

echo "Verificando e corrigindo estrutura do Maven Wrapper..."

# 1. Cria o diretório (se não existir)
mkdir -p .mvn/wrapper || true
  
# 2. Baixa o JAR do Wrapper (se não existir)
WRAPPER_JAR=".mvn/wrapper/maven-wrapper.jar"
if [[ ! -f "$WRAPPER_JAR" ]]; then
  echo "AVISO: Baixando maven-wrapper.jar..."
  WRAPPER_URL="https://repo.maven.apache.org/maven2/io/takari/maven-wrapper/0.5.6/maven-wrapper-0.5.6.jar"
  curl -L $WRAPPER_URL -o "$WRAPPER_JAR"
fi

# 3. CRIA O ARQUIVO DE PROPRIEDADES FALTANTE (Chave para a solução)
PROPERTIES_FILE=".mvn/wrapper/maven-wrapper.properties"
if [[ ! -f "$PROPERTIES_FILE" ]]; then
  echo "AVISO: Criando arquivo de propriedades faltante ($PROPERTIES_FILE)..."
  
  # Cria o arquivo com a URL de download do Maven 3.8.7
  echo "distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.8.7/apache-maven-3.8.7-bin.zip" > $PROPERTIES_FILE
fi
  
# 4. Garante permissão de execução (Caso o deploy remova)
chmod +x ./mvnw

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
chmod +x ./scripts/*.sh
# --- 3. BUILD E DEPLOY DO DOCKER ---
echo "Executando o script de build e deploy..."
# Adaptação dos scripts do Node para o Java
./scripts/production-build.sh  # <-- CORREÇÃO: ADICIONAR './scripts/'
./scripts/production-up.sh     # <-- CORREÇÃO: ADICIONAR './scripts/'