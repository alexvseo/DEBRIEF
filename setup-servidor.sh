#!/bin/bash

# ==================== Setup Automático - Servidor DeBrief ====================
# Este script automatiza o setup inicial no servidor
# Execute no SERVIDOR: ./setup-servidor.sh

set -e  # Parar em caso de erro

echo "🚀 DeBrief - Setup Automático no Servidor"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Execute como root: sudo ./setup-servidor.sh"
    exit 1
fi

print_success "Executando como root"

# ==================== 1. ATUALIZAR SISTEMA ====================
print_info "Atualizando sistema..."
apt-get update -y
apt-get upgrade -y
print_success "Sistema atualizado"

# ==================== 2. INSTALAR DOCKER ====================
if ! command -v docker &> /dev/null; then
    print_info "Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    print_success "Docker instalado"
else
    print_success "Docker já instalado"
fi

# ==================== 3. INSTALAR DOCKER COMPOSE ====================
if ! command -v docker-compose &> /dev/null; then
    print_info "Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose instalado"
else
    print_success "Docker Compose já instalado"
fi

# Verificar versões
print_info "Docker: $(docker --version)"
print_info "Docker Compose: $(docker-compose --version)"

# ==================== 4. CRIAR DIRETÓRIOS ====================
print_info "Criando diretórios necessários..."
mkdir -p /var/www
mkdir -p /backups
print_success "Diretórios criados"

# ==================== 5. CLONAR REPOSITÓRIO ====================
print_warning "Configure o repositório Git manualmente:"
echo ""
echo "cd /var/www"
echo "git clone https://github.com/SEU-USUARIO/debrief.git"
echo "cd debrief"
echo ""
read -p "Pressione ENTER quando tiver clonado o repositório..."

# Verificar se o repositório foi clonado
if [ ! -d "/var/www/debrief" ]; then
    print_error "Repositório não encontrado em /var/www/debrief"
    print_info "Clone o repositório primeiro:"
    echo "cd /var/www"
    echo "git clone https://github.com/SEU-USUARIO/debrief.git"
    exit 1
fi

cd /var/www/debrief
print_success "Repositório encontrado"

# ==================== 6. CONFIGURAR VARIÁVEIS ====================
print_info "Configurando variáveis de ambiente..."

if [ ! -f "backend/.env" ]; then
    if [ -f "env.docker.example" ]; then
        cp env.docker.example backend/.env
        print_success "Arquivo .env criado"
    else
        print_error "Arquivo env.docker.example não encontrado"
        exit 1
    fi
fi

print_warning "IMPORTANTE: Configure as chaves de segurança!"
print_info "Gerando chaves..."

# Gerar SECRET_KEY
SECRET_KEY=$(openssl rand -hex 32)
print_info "SECRET_KEY gerada: $SECRET_KEY"

# Gerar ENCRYPTION_KEY (precisa de Python)
if command -v python3 &> /dev/null; then
    ENCRYPTION_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
    print_info "ENCRYPTION_KEY gerada: $ENCRYPTION_KEY"
else
    print_warning "Python3 não encontrado. Gere ENCRYPTION_KEY manualmente."
fi

print_warning "Edite o arquivo backend/.env e configure:"
echo "- SECRET_KEY=$SECRET_KEY"
if [ ! -z "$ENCRYPTION_KEY" ]; then
    echo "- ENCRYPTION_KEY=$ENCRYPTION_KEY"
fi
echo "- FRONTEND_URL=http://82.25.92.217:2022"
echo ""
read -p "Pressione ENTER quando tiver configurado o .env..."

# ==================== 7. CONFIGURAR FIREWALL ====================
print_info "Configurando firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 3000/tcp  # Frontend
ufw allow 8000/tcp  # Backend
print_success "Firewall configurado"

# ==================== 8. INICIAR APLICAÇÃO ====================
print_info "Iniciando aplicação com Docker..."
chmod +x docker-deploy.sh
docker-compose up -d --build
print_success "Aplicação iniciada"

# Aguardar containers iniciarem
print_info "Aguardando containers iniciarem..."
sleep 10

# ==================== 9. INICIALIZAR BANCO ====================
print_info "Inicializando banco de dados..."

# Executar migrations
docker-compose exec -T backend alembic upgrade head
print_success "Migrations executadas"

# Criar dados iniciais
docker-compose exec -T backend python init_db.py
print_success "Dados iniciais criados"

# ==================== 10. VERIFICAR STATUS ====================
print_info "Verificando status dos containers..."
docker-compose ps

echo ""
echo "=========================================="
print_success "Setup concluído com sucesso!"
echo "=========================================="
echo ""

# Obter IP do servidor
SERVER_IP=$(hostname -I | awk '{print $1}')

print_info "Acesse a aplicação em:"
echo "  - Frontend: http://$SERVER_IP:2022"
echo "  - Backend:  http://$SERVER_IP:8000"
echo "  - Docs:     http://$SERVER_IP:8000/docs"
echo ""
print_info "Login padrão:"
echo "  - Username: admin"
echo "  - Password: admin123"
echo ""
print_warning "IMPORTANTE:"
echo "  1. Altere a senha do usuário admin"
echo "  2. Configure um domínio"
echo "  3. Instale certificado SSL"
echo "  4. Configure backup automático"
echo ""
print_info "Ver logs: docker-compose logs -f"
print_info "Parar: docker-compose down"
print_info "Reiniciar: docker-compose restart"
echo ""
print_success "DeBrief está rodando! 🎉"

