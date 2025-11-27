#!/bin/bash
set -euo pipefail

# Script para Deploy Final com Configurações Corretas
# Execute no servidor: ./deploy-final.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SECRETS_LIB="${SCRIPT_DIR}/lib/secrets.sh"
if [ -f "${SECRETS_LIB}" ]; then
    # shellcheck source=../../scripts/deploy/lib/secrets.sh
    source "${SECRETS_LIB}"
    debrief_load_secrets "${PROJECT_ROOT}"
fi

cd "${PROJECT_ROOT}"

echo "=========================================="
echo "🚀 DEPLOY FINAL - DeBrief"
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

# 1. Verificar conexão com banco
print_info "1️⃣  Verificando conexão com banco de dados..."
if [ -f "./testar-usuario-postgres.sh" ]; then
    if ./testar-usuario-postgres.sh 2>&1 | grep -q "✅ Conexão com usuário 'postgres' funcionou!"; then
        print_success "Conexão com banco verificada"
    else
        print_warning "Teste de conexão não passou, mas continuando..."
    fi
else
    print_warning "Script de teste não encontrado, pulando verificação"
fi
echo ""

# 2. Parar containers atuais
print_info "2️⃣  Parando containers atuais..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose.host-network.yml down 2>/dev/null || true
print_success "Containers parados"
echo ""

# 3. Rebuild do backend
print_info "3️⃣  Fazendo rebuild do backend..."
print_warning "   Isso pode levar alguns minutos..."
docker-compose -f docker-compose.host-network.yml build --no-cache backend
if [ $? -eq 0 ]; then
    print_success "Backend rebuild concluído"
else
    print_error "Erro no rebuild do backend"
    exit 1
fi
echo ""

# 4. Rebuild do frontend
print_info "4️⃣  Fazendo rebuild do frontend..."
print_warning "   Isso pode levar alguns minutos..."
docker-compose -f docker-compose.host-network.yml build --no-cache frontend
if [ $? -eq 0 ]; then
    print_success "Frontend rebuild concluído"
else
    print_error "Erro no rebuild do frontend"
    exit 1
fi
echo ""

# 5. Iniciar containers
print_info "5️⃣  Iniciando containers..."
docker-compose -f docker-compose.host-network.yml up -d
if [ $? -eq 0 ]; then
    print_success "Containers iniciados"
else
    print_error "Erro ao iniciar containers"
    exit 1
fi
echo ""

# 6. Aguardar backend iniciar
print_info "6️⃣  Aguardando backend iniciar (120 segundos)..."
print_warning "   Backend precisa de tempo para conectar ao banco..."
for i in {1..24}; do
    sleep 5
    if docker-compose -f docker-compose.host-network.yml ps backend | grep -q "healthy\|Up"; then
        print_success "Backend está iniciando..."
        break
    fi
    echo -n "."
done
echo ""
echo ""

# 7. Verificar status dos containers
print_info "7️⃣  Verificando status dos containers..."
docker-compose -f docker-compose.host-network.yml ps
echo ""

# 8. Verificar logs do backend
print_info "8️⃣  Verificando logs do backend (últimas 30 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=30 backend
echo ""

# 9. Testar health check
print_info "9️⃣  Testando health check do backend..."
sleep 5
HEALTH_STATUS=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null || echo "no_healthcheck")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    print_success "Backend está healthy!"
elif [ "$HEALTH_STATUS" = "starting" ]; then
    print_warning "Backend ainda está iniciando..."
elif [ "$HEALTH_STATUS" = "unhealthy" ]; then
    print_error "Backend está unhealthy - verifique os logs"
else
    print_warning "Health status: $HEALTH_STATUS"
fi
echo ""

# 10. Testar conexão do backend com banco
print_info "🔟 Testando conexão do backend com banco..."
docker exec debrief-backend python3 << EOF 2>&1 | head -10
import psycopg2
import os
try:
    db_url = os.getenv('DATABASE_URL', '')
    if 'postgresql://' in db_url:
        # Extrair informações da URL
        import urllib.parse
        parsed = urllib.parse.urlparse(db_url)
        conn = psycopg2.connect(
            host=parsed.hostname or 'localhost',
            port=parsed.port or 5432,
            database=parsed.path[1:] if parsed.path else 'dbrief',
            user=parsed.username or 'postgres',
            password=urllib.parse.unquote(parsed.password or ''),
            connect_timeout=5
        )
        print("✅ Backend consegue conectar ao banco!")
        cur = conn.cursor()
        cur.execute("SELECT current_database(), current_user;")
        result = cur.fetchone()
        print(f"✅ Banco: {result[0]}")
        print(f"✅ Usuário: {result[1]}")
        cur.close()
        conn.close()
    else:
        print("⚠️  DATABASE_URL não configurado corretamente")
except Exception as e:
    print(f"❌ Erro: {str(e)[:100]}")
EOF

echo ""

# 11. Resumo final
echo "=========================================="
echo "📊 RESUMO DO DEPLOY"
echo "=========================================="
echo ""

# Verificar status final
BACKEND_STATUS=$(docker-compose -f docker-compose.host-network.yml ps backend --format "{{.Status}}" 2>/dev/null || echo "unknown")
FRONTEND_STATUS=$(docker-compose -f docker-compose.host-network.yml ps frontend --format "{{.Status}}" 2>/dev/null || echo "unknown")
CADDY_STATUS=$(docker-compose -f docker-compose.host-network.yml ps caddy --format "{{.Status}}" 2>/dev/null || echo "unknown")

print_info "Status dos containers:"
echo "  Backend:  $BACKEND_STATUS"
echo "  Frontend: $FRONTEND_STATUS"
echo "  Caddy:    $CADDY_STATUS"
echo ""

if echo "$BACKEND_STATUS" | grep -q "Up.*healthy"; then
    print_success "✅ Deploy concluído com sucesso!"
    echo ""
    print_info "Acesse a aplicação em:"
    echo "  🌐 http://82.25.92.217:2022"
    echo ""
    print_info "Documentação da API:"
    echo "  📝 http://82.25.92.217:2025/api/docs"
    echo ""
else
    print_warning "⚠️  Deploy concluído, mas backend pode estar ainda iniciando"
    echo ""
    print_info "Verifique os logs:"
    echo "  docker-compose -f docker-compose.host-network.yml logs backend"
    echo ""
    print_info "Aguarde alguns minutos e verifique novamente:"
    echo "  docker-compose -f docker-compose.host-network.yml ps"
    echo ""
fi

echo ""

