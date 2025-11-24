#!/bin/bash

################################################################################
# Script para diagnosticar problemas de rede do container Docker
# Verifica se o container consegue acessar localhost:5432
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

echo "🔍 Diagnosticando rede do container backend..."
echo ""

# 1. Verificar se o container existe
print_info "1️⃣  Verificando container backend..."
if ! docker ps | grep -q debrief-backend; then
    print_error "Container backend não está rodando!"
    exit 1
fi
print_success "Container backend encontrado"
echo ""

# 2. Verificar network_mode
print_info "2️⃣  Verificando modo de rede do container..."
NETWORK_MODE=$(docker inspect debrief-backend --format='{{.HostConfig.NetworkMode}}')
print_info "Network mode: $NETWORK_MODE"

if [ "$NETWORK_MODE" = "host" ]; then
    print_success "Container está em network_mode: host (correto)"
else
    print_warning "Container NÃO está em network_mode: host"
    print_info "Isso pode causar problemas de conexão com localhost"
fi
echo ""

# 3. Verificar se consegue resolver localhost
print_info "3️⃣  Testando resolução de localhost no container..."
if docker exec debrief-backend getent hosts localhost > /dev/null 2>&1; then
    print_success "Container consegue resolver localhost"
    docker exec debrief-backend getent hosts localhost
else
    print_error "Container NÃO consegue resolver localhost"
fi
echo ""

# 4. Verificar se consegue fazer ping em localhost
print_info "4️⃣  Testando conectividade com localhost..."
if docker exec debrief-backend ping -c 1 127.0.0.1 > /dev/null 2>&1; then
    print_success "Container consegue fazer ping em 127.0.0.1"
else
    print_error "Container NÃO consegue fazer ping em 127.0.0.1"
fi
echo ""

# 5. Verificar se a porta 5432 está acessível
print_info "5️⃣  Testando acesso à porta 5432 do host..."
if docker exec debrief-backend timeout 2 bash -c 'cat < /dev/null > /dev/tcp/localhost/5432' 2>/dev/null; then
    print_success "Porta 5432 está acessível do container"
else
    print_error "Porta 5432 NÃO está acessível do container"
    print_info "Verificando se PostgreSQL está escutando..."
    if netstat -tlnp 2>/dev/null | grep -q ":5432" || ss -tlnp 2>/dev/null | grep -q ":5432"; then
        print_info "PostgreSQL está escutando na porta 5432 no host"
        netstat -tlnp 2>/dev/null | grep ":5432" || ss -tlnp 2>/dev/null | grep ":5432"
    else
        print_error "PostgreSQL NÃO está escutando na porta 5432"
    fi
fi
echo ""

# 6. Testar conexão Python/psycopg2
print_info "6️⃣  Testando conexão Python/psycopg2 do container..."
docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
import psycopg2
import sys

try:
    print("Tentando conectar em localhost:5432...")
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='postgres',
        password='Mslestra@2025',
        database='dbrief',
        connect_timeout=5
    )
    print("✅ Conexão bem-sucedida!")
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()
    print(f"PostgreSQL version: {version[0][:50]}...")
    cursor.close()
    conn.close()
    sys.exit(0)
except psycopg2.OperationalError as e:
    print(f"❌ Erro de conexão: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Erro inesperado: {e}")
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    print_success "Conexão Python funcionou!"
else
    print_error "Conexão Python falhou!"
fi
echo ""

# 7. Verificar variáveis de ambiente do container
print_info "7️⃣  Verificando DATABASE_URL no container..."
DATABASE_URL=$(docker exec debrief-backend env | grep DATABASE_URL | cut -d'=' -f2-)
if [ -n "$DATABASE_URL" ]; then
    print_info "DATABASE_URL: ${DATABASE_URL:0:50}..."
    if echo "$DATABASE_URL" | grep -q "localhost"; then
        print_success "DATABASE_URL está usando localhost (correto)"
    else
        print_warning "DATABASE_URL NÃO está usando localhost"
    fi
else
    print_error "DATABASE_URL não encontrado no container"
fi
echo ""

# 8. Verificar logs do backend
print_info "8️⃣  Últimas linhas dos logs do backend (erros de conexão)..."
docker logs debrief-backend --tail=20 2>&1 | grep -i -E "error|connection|postgres|database" || print_info "Nenhum erro recente encontrado"
echo ""

# 9. Recomendações
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "📋 RECOMENDAÇÕES:"
echo ""

if [ "$NETWORK_MODE" != "host" ]; then
    print_warning "Container não está em network_mode: host"
    echo "  Solução: Use docker-compose.host-network.yml ou adicione network_mode: host"
fi

if ! docker exec debrief-backend timeout 2 bash -c 'cat < /dev/null > /dev/tcp/localhost/5432' 2>/dev/null; then
    print_warning "Container não consegue acessar localhost:5432"
    echo "  Possíveis soluções:"
    echo "  1. Verificar se está usando docker-compose.host-network.yml"
    echo "  2. Reiniciar o container: docker-compose restart backend"
    echo "  3. Reconstruir: docker-compose down && docker-compose up -d"
fi

echo ""
print_info "Se o problema persistir, tente:"
echo "  1. docker-compose down"
echo "  2. docker-compose -f docker-compose.host-network.yml up -d"
echo "  3. docker-compose logs backend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

