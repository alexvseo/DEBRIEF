#!/bin/bash

# Script de Rebuild Completo - DeBrief
# Limpa tudo e reconstrói do zero
# Execute no servidor: ./rebuild-completo.sh

set -e  # Parar em caso de erro

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "🔧 REBUILD COMPLETO - DeBrief"
echo "=========================================="
echo ""

# Verificar se há mudanças locais no Git
if [ -d ".git" ]; then
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        print_warning "Há mudanças locais no Git!"
        print_info "Descartando mudanças locais antes de continuar..."
        git checkout -- . 2>/dev/null || true
        git reset --hard HEAD 2>/dev/null || true
        print_success "Mudanças locais descartadas"
        echo ""
    fi
    
    # Fazer pull
    print_info "Fazendo pull do repositório..."
    git pull 2>/dev/null || print_warning "Erro ao fazer pull (continuando mesmo assim...)"
    echo ""
fi

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

# 1. Parar todos os containers
print_info "1️⃣  Parando todos os containers..."
docker-compose down 2>/dev/null || true
print_success "Containers parados"
echo ""

# 2. Remover containers órfãos
print_info "2️⃣  Removendo containers órfãos..."
docker-compose down --remove-orphans 2>/dev/null || true
print_success "Containers órfãos removidos"
echo ""

# 3. Remover imagens antigas do projeto
print_info "3️⃣  Removendo imagens antigas do DeBrief..."
docker rmi debrief-backend:latest 2>/dev/null || print_warning "Imagem backend não encontrada"
docker rmi debrief-frontend:latest 2>/dev/null || print_warning "Imagem frontend não encontrada"
print_success "Imagens antigas removidas"
echo ""

# 4. Limpar volumes não usados (CUIDADO: pode remover dados)
print_warning "4️⃣  Limpando volumes não usados..."
read -p "   Remover volumes não usados? (s/N): " confirm_volumes
if [ "$confirm_volumes" = "s" ] || [ "$confirm_volumes" = "S" ]; then
    docker volume prune -f
    print_success "Volumes não usados removidos"
else
    print_info "Volumes mantidos"
fi
echo ""

# 5. Limpar cache do Docker (opcional)
print_warning "5️⃣  Limpar cache do Docker?"
read -p "   Limpar cache do build? (s/N): " confirm_cache
if [ "$confirm_cache" = "s" ] || [ "$confirm_cache" = "S" ]; then
    docker builder prune -f
    print_success "Cache do Docker limpo"
else
    print_info "Cache mantido"
fi
echo ""

# 6. Verificar espaço em disco
print_info "6️⃣  Verificando espaço em disco..."
df -h / | tail -1
echo ""

# 7. Rebuild completo
print_info "7️⃣  Fazendo rebuild completo (sem cache)..."
print_warning "   Isso pode levar vários minutos..."
docker-compose build --no-cache
print_success "Build concluído"
echo ""

# 8. Iniciar containers
print_info "8️⃣  Iniciando containers..."
docker-compose up -d
print_success "Containers iniciados"
echo ""

# 9. Aguardar backend ficar healthy
print_info "9️⃣  Aguardando backend ficar healthy (2 minutos)..."
print_warning "   Por favor, aguarde..."
for i in {1..24}; do
    sleep 5
    STATUS=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    if [ "$STATUS" = "healthy" ]; then
        print_success "Backend está healthy!"
        break
    fi
    if [ $i -eq 24 ]; then
        print_warning "Backend ainda não está healthy após 2 minutos"
    fi
    echo -n "."
done
echo ""
echo ""

# 10. Verificar status
print_info "🔟 Verificando status dos containers..."
docker-compose ps
echo ""

# 11. Verificar logs
print_info "1️⃣1️⃣  Últimas linhas dos logs do backend..."
docker-compose logs --tail=20 backend
echo ""

# 12. Testar endpoints
print_info "1️⃣2️⃣  Testando endpoints..."

# Backend direto
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2025/health 2>/dev/null || echo "000")
if [ "$BACKEND_HEALTH" = "200" ]; then
    print_success "Backend direto (porta 2025): OK"
else
    print_error "Backend direto (porta 2025): HTTP $BACKEND_HEALTH"
fi

# Frontend via Caddy
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    print_success "Frontend via Caddy (porta 2022): OK"
else
    print_error "Frontend via Caddy (porta 2022): HTTP $FRONTEND_STATUS"
fi

# API via Caddy
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    print_success "API via Caddy (/api): OK"
else
    print_error "API via Caddy (/api): HTTP $API_STATUS"
fi

echo ""

# 13. Resumo final
echo "=========================================="
echo "✅ REBUILD COMPLETO CONCLUÍDO!"
echo "=========================================="
echo ""
print_info "📊 Status:"
docker-compose ps
echo ""
print_info "🌐 URLs de Acesso:"
echo "   - Frontend: http://82.25.92.217:2022"
echo "   - Backend:  http://82.25.92.217:2025"
echo "   - API Docs: http://82.25.92.217:2025/docs"
echo ""
print_info "📝 Comandos úteis:"
echo "   - Ver logs: docker-compose logs -f"
echo "   - Ver status: docker-compose ps"
echo "   - Parar: docker-compose down"
echo ""

