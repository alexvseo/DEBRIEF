#!/bin/bash

################################################################################
# Script para migrar para docker-compose.host-network.yml
# Resolve problemas de conexão com PostgreSQL
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

echo "🔧 Migrando para docker-compose.host-network.yml..."
echo ""

# Verificar se está no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    print_error "Este script deve ser executado na raiz do projeto"
    exit 1
fi

# Verificar se docker-compose.host-network.yml existe
if [ ! -f "docker-compose.host-network.yml" ]; then
    print_error "docker-compose.host-network.yml não encontrado!"
    exit 1
fi

# 1. Parar containers atuais
print_info "1️⃣  Parando containers atuais..."
docker-compose down 2>/dev/null || true
print_success "Containers parados"
echo ""

# 2. Usar docker-compose.host-network.yml
print_info "2️⃣  Usando docker-compose.host-network.yml..."
print_info "Isso garante network_mode: host para acesso ao PostgreSQL"
echo ""

# 3. Reconstruir e iniciar
print_info "3️⃣  Reconstruindo e iniciando containers..."
docker-compose -f docker-compose.host-network.yml build --no-cache 2>&1 | tail -n 10
docker-compose -f docker-compose.host-network.yml up -d
print_success "Containers iniciados"
echo ""

# 4. Aguardar inicialização
print_info "4️⃣  Aguardando inicialização dos containers..."
sleep 10
echo ""

# 5. Verificar network_mode
print_info "5️⃣  Verificando network_mode do backend..."
NETWORK_MODE=$(docker inspect debrief-backend --format='{{.HostConfig.NetworkMode}}' 2>/dev/null || echo "unknown")
if [ "$NETWORK_MODE" = "host" ]; then
    print_success "✅ Backend está em network_mode: host"
else
    print_error "❌ Backend NÃO está em network_mode: host (atual: $NETWORK_MODE)"
fi
echo ""

# 6. Testar conexão com PostgreSQL
print_info "6️⃣  Testando conexão com PostgreSQL..."
sleep 5
if docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
import psycopg2
import sys
try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='postgres',
        password='<redacted-db-password>',
        database='dbrief',
        connect_timeout=5
    )
    print('✅ Conexão com PostgreSQL funcionou!')
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()
    print(f'PostgreSQL: {version[0][:50]}...')
    cursor.close()
    conn.close()
    sys.exit(0)
except Exception as e:
    print(f'❌ Erro: {e}')
    sys.exit(1)
PYTHON_SCRIPT
2>&1 | grep -q "✅"; then
    print_success "Conexão com PostgreSQL funcionou!"
else
    print_warning "Conexão com PostgreSQL ainda com problemas"
    print_info "Execute: ./scripts/correcao/corrigir-postgresql-servidor.sh"
fi
echo ""

# 7. Verificar status dos containers
print_info "7️⃣  Status dos containers:"
docker-compose -f docker-compose.host-network.yml ps
echo ""

# 8. Verificar logs do backend
print_info "8️⃣  Últimas linhas dos logs do backend:"
docker-compose -f docker-compose.host-network.yml logs --tail=10 backend | grep -i -E "banco|database|postgres|error|startup" || print_info "Nenhum erro relacionado encontrado"
echo ""

print_success "🎉 Migração concluída!"
print_info "Agora o backend deve conseguir acessar PostgreSQL em localhost:5432"
print_info "Se ainda houver problemas, verifique:"
echo "  - ./scripts/diagnostico/verificar-postgresql-servidor.sh"
echo "  - ./scripts/correcao/corrigir-postgresql-servidor.sh"
echo ""

