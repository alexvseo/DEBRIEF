#!/bin/bash

# Script para Verificar Erro do Backend
# Execute no servidor: ./verificar-erro-backend.sh

echo "=========================================="
echo "🔍 VERIFICANDO ERRO DO BACKEND"
echo "=========================================="
echo ""

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

# 1. Status do container
print_info "1️⃣  Status do container backend..."
docker-compose ps backend
echo ""

# 2. Verificar se container existe
CONTAINER_EXISTS=$(docker ps -a --filter "name=debrief-backend" --format "{{.Names}}" | grep -c "debrief-backend" || echo "0")
if [ "$CONTAINER_EXISTS" = "0" ]; then
    print_error "Container debrief-backend não existe!"
    print_info "Tentando criar..."
    docker-compose up -d backend
    sleep 5
fi
echo ""

# 3. Logs completos do backend
print_info "2️⃣  Logs completos do backend (últimas 100 linhas)..."
echo "----------------------------------------"
docker-compose logs --tail=100 backend 2>&1
echo ""

# 4. Procurar erros específicos
print_info "3️⃣  Procurando erros específicos..."
echo "----------------------------------------"
ERRORS=$(docker-compose logs backend 2>&1 | grep -i "error\|exception\|traceback\|failed\|fatal\|unhealthy" | tail -30)
if [ -n "$ERRORS" ]; then
    print_error "Erros encontrados:"
    echo "$ERRORS"
else
    print_warning "Nenhum erro explícito encontrado nos logs"
fi
echo ""

# 5. Verificar se container está rodando
print_info "4️⃣  Verificando se container está rodando..."
CONTAINER_STATUS=$(docker inspect debrief-backend --format='{{.State.Status}}' 2>/dev/null || echo "not_found")
if [ "$CONTAINER_STATUS" = "running" ]; then
    print_success "Container está rodando"
elif [ "$CONTAINER_STATUS" = "exited" ]; then
    print_error "Container está parado (exited)"
    EXIT_CODE=$(docker inspect debrief-backend --format='{{.State.ExitCode}}' 2>/dev/null)
    print_info "Código de saída: $EXIT_CODE"
elif [ "$CONTAINER_STATUS" = "not_found" ]; then
    print_error "Container não encontrado"
else
    print_warning "Status do container: $CONTAINER_STATUS"
fi
echo ""

# 6. Verificar health status
print_info "5️⃣  Verificando health status..."
HEALTH_STATUS=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null || echo "no_healthcheck")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    print_success "Backend está healthy"
elif [ "$HEALTH_STATUS" = "unhealthy" ]; then
    print_error "Backend está unhealthy"
    print_info "Últimas tentativas de health check:"
    docker inspect debrief-backend --format='{{range .State.Health.Log}}{{.Output}}{{end}}' 2>/dev/null | tail -5
elif [ "$HEALTH_STATUS" = "starting" ]; then
    print_warning "Backend ainda está iniciando..."
else
    print_warning "Health status: $HEALTH_STATUS"
fi
echo ""

# 7. Tentar executar comando dentro do container
print_info "6️⃣  Testando se container responde..."
if docker exec debrief-backend echo "OK" 2>/dev/null; then
    print_success "Container responde a comandos"
    
    # Verificar processos
    print_info "   Processos dentro do container:"
    docker exec debrief-backend ps aux 2>/dev/null | grep -E "uvicorn|python" || print_warning "Nenhum processo uvicorn encontrado"
else
    print_error "Container não responde (pode estar parado ou com erro)"
fi
echo ""

# 8. Testar health check manualmente
print_info "7️⃣  Testando health check manualmente..."
HEALTH_TEST=$(docker exec debrief-backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$HEALTH_TEST" = "200" ]; then
    print_success "Health check retorna 200 OK"
    docker exec debrief-backend curl -s http://localhost:8000/health | head -3
elif [ "$HEALTH_TEST" = "000" ]; then
    print_error "Health check falhou (não conseguiu conectar)"
    print_info "Possíveis causas:"
    echo "   - Backend não está rodando"
    echo "   - Erro ao iniciar a aplicação"
    echo "   - Erro de configuração"
else
    print_warning "Health check retornou HTTP $HEALTH_TEST"
fi
echo ""

# 9. Verificar variáveis de ambiente críticas
print_info "8️⃣  Verificando variáveis de ambiente..."
if docker exec debrief-backend env 2>/dev/null | grep -E "DATABASE_URL|ALLOWED_EXTENSIONS" > /dev/null; then
    print_success "Variáveis de ambiente encontradas"
    docker exec debrief-backend env 2>/dev/null | grep -E "DATABASE_URL|ALLOWED_EXTENSIONS|SECRET_KEY" | head -3
else
    print_error "Não foi possível verificar variáveis (container não responde)"
fi
echo ""

# 10. Tentar iniciar backend isoladamente
print_info "9️⃣  Tentando iniciar backend isoladamente para ver erro..."
docker-compose up backend 2>&1 | head -50
echo ""

# 11. Resumo e recomendações
echo "=========================================="
echo "✅ Verificação concluída!"
echo "=========================================="
echo ""
print_info "📝 Próximos passos baseados no diagnóstico:"
echo ""

if [ "$HEALTH_STATUS" = "unhealthy" ] || [ "$CONTAINER_STATUS" = "exited" ]; then
    print_error "Backend não está funcionando"
    echo ""
    echo "   1. Verifique os logs acima para identificar o erro específico"
    echo "   2. Erros comuns:"
    echo "      - Erro de conexão com banco de dados"
    echo "      - Erro de configuração (ALLOWED_EXTENSIONS, etc)"
    echo "      - Erro de importação de módulos"
    echo "      - Código com erro de sintaxe"
    echo ""
    echo "   3. Soluções sugeridas:"
    echo "      - docker-compose logs backend | tail -100"
    echo "      - docker-compose build --no-cache backend"
    echo "      - docker-compose up backend (sem -d para ver erro)"
    echo "      - Verificar se código está correto: git status"
fi
echo ""

