#!/bin/bash

################################################################################
# Script Completo para Atualizar Servidor DeBrief
# Atualiza código, reconstrói containers e verifica saúde
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configurações
SERVER_HOST="82.25.92.217"
SERVER_USER="root"
PROJECT_DIR="/root/debrief"
BRANCH="main"

echo "🚀 Atualização Completa do Servidor DeBrief"
echo "=============================================="
echo ""

# ==================== 1. CONECTAR AO SERVIDOR ====================
print_info "1️⃣  Conectando ao servidor ${SERVER_HOST}..."

# Verificar se já estamos no servidor
if [ "$(hostname)" != "${SERVER_HOST}" ] && [ "$(hostname -I | grep -o ${SERVER_HOST})" = "" ]; then
    print_info "Executando comandos via SSH..."
    SSH_CMD="ssh ${SERVER_USER}@${SERVER_HOST}"
else
    print_info "Já estamos no servidor."
    SSH_CMD=""
fi

# ==================== 2. NAVEGAR PARA O DIRETÓRIO ====================
print_info "2️⃣  Navegando para ${PROJECT_DIR}..."
${SSH_CMD} "cd ${PROJECT_DIR} || { echo 'Diretório não encontrado. Criando...'; mkdir -p ${PROJECT_DIR}; cd ${PROJECT_DIR}; git clone https://github.com/alexvseo/DEBRIEF.git . || true; }"

# ==================== 3. VERIFICAR STATUS GIT ====================
print_info "3️⃣  Verificando status do Git..."
${SSH_CMD} "cd ${PROJECT_DIR} && git status"

# ==================== 4. DESCARTAR MUDANÇAS LOCAIS (SE NECESSÁRIO) ====================
print_warning "4️⃣  Descartando mudanças locais (se houver)..."
${SSH_CMD} "cd ${PROJECT_DIR} && git checkout -- . 2>/dev/null || true"
${SSH_CMD} "cd ${PROJECT_DIR} && git reset --hard HEAD 2>/dev/null || true"

# ==================== 5. FAZER PULL ====================
print_info "5️⃣  Fazendo pull do repositório (branch: ${BRANCH})..."
${SSH_CMD} "cd ${PROJECT_DIR} && git fetch origin && git pull origin ${BRANCH} || git pull origin main"

# ==================== 6. VERIFICAR ARQUIVOS IMPORTANTES ====================
print_info "6️⃣  Verificando arquivos importantes..."
${SSH_CMD} "cd ${PROJECT_DIR} && ls -la docker-compose.yml Caddyfile backend/Dockerfile frontend/Dockerfile 2>/dev/null || { print_error 'Arquivos essenciais não encontrados!'; exit 1; }"

# ==================== 7. PARAR CONTAINERS ====================
print_info "7️⃣  Parando containers existentes..."
${SSH_CMD} "cd ${PROJECT_DIR} && docker-compose down 2>/dev/null || true"
sleep 3

# ==================== 8. LIMPAR IMAGENS ANTIGAS (OPCIONAL) ====================
read -p "Deseja limpar imagens antigas? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    print_info "8️⃣  Limpando imagens antigas..."
    ${SSH_CMD} "cd ${PROJECT_DIR} && docker system prune -f"
    ${SSH_CMD} "docker rmi debrief-backend:latest debrief-frontend:latest 2>/dev/null || true"
else
    print_info "8️⃣  Pulando limpeza de imagens..."
fi

# ==================== 9. RECONSTRUIR IMAGENS ====================
print_info "9️⃣  Reconstruindo imagens Docker (isso pode levar alguns minutos)..."
${SSH_CMD} "cd ${PROJECT_DIR} && docker-compose build --no-cache"

# ==================== 10. INICIAR CONTAINERS ====================
print_info "🔟 Iniciando containers..."
${SSH_CMD} "cd ${PROJECT_DIR} && docker-compose up -d"

# ==================== 11. AGUARDAR INICIALIZAÇÃO ====================
print_info "1️⃣1️⃣  Aguardando containers iniciarem (60 segundos)..."
sleep 60

# ==================== 12. VERIFICAR STATUS ====================
print_info "1️⃣2️⃣  Verificando status dos containers..."
${SSH_CMD} "cd ${PROJECT_DIR} && docker-compose ps"

# ==================== 13. VERIFICAR SAÚDE ====================
print_info "1️⃣3️⃣  Verificando saúde dos serviços..."

# Backend
print_info "  - Backend (http://localhost:8000/health)..."
BACKEND_HEALTH=$(${SSH_CMD} "curl -s http://localhost:8000/health 2>/dev/null || echo 'FAILED'")
if echo "$BACKEND_HEALTH" | grep -q "healthy"; then
    print_success "    Backend está saudável"
else
    print_warning "    Backend pode estar com problemas"
    print_info "    Resposta: $BACKEND_HEALTH"
fi

# Frontend via Caddy
print_info "  - Frontend (http://localhost:2022)..."
FRONTEND_HEALTH=$(${SSH_CMD} "curl -s -o /dev/null -w '%{http_code}' http://localhost:2022 2>/dev/null || echo '000'")
if [ "$FRONTEND_HEALTH" = "200" ]; then
    print_success "    Frontend está acessível"
else
    print_warning "    Frontend pode estar com problemas (HTTP $FRONTEND_HEALTH)"
fi

# ==================== 14. MOSTRAR LOGS RECENTES ====================
print_info "1️⃣4️⃣  Últimos logs do backend (últimas 20 linhas)..."
${SSH_CMD} "cd ${PROJECT_DIR} && docker-compose logs --tail=20 backend"

print_info "1️⃣5️⃣  Últimos logs do Caddy (últimas 10 linhas)..."
${SSH_CMD} "cd ${PROJECT_DIR} && docker-compose logs --tail=10 caddy"

# ==================== 15. RESUMO FINAL ====================
echo ""
echo "=============================================="
print_success "✅ Atualização concluída!"
echo "=============================================="
echo ""
print_info "🌐 Acesse a aplicação:"
echo "  - Frontend: http://${SERVER_HOST}:2022"
echo "  - Backend:  http://${SERVER_HOST}:2025"
echo "  - API Docs: http://${SERVER_HOST}:2025/api/docs"
echo ""
print_info "📊 Comandos úteis:"
echo "  - Ver logs: cd ${PROJECT_DIR} && docker-compose logs -f"
echo "  - Reiniciar: cd ${PROJECT_DIR} && docker-compose restart"
echo "  - Parar: cd ${PROJECT_DIR} && docker-compose down"
echo ""
print_warning "⚠️  Se houver problemas, verifique os logs:"
echo "  cd ${PROJECT_DIR} && docker-compose logs backend"
echo "  cd ${PROJECT_DIR} && docker-compose logs frontend"
echo "  cd ${PROJECT_DIR} && docker-compose logs caddy"
echo ""

