#!/bin/bash

################################################################################
# Script para corrigir problemas de rede do container Docker
# Garante que o container está em network_mode: host
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

echo "🔧 Corrigindo rede do container backend..."
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

# 2. Verificar qual arquivo usar
print_info "2️⃣  Verificando configuração..."
if grep -q "network_mode: host" docker-compose.host-network.yml; then
    print_success "docker-compose.host-network.yml está configurado corretamente"
    USE_FILE="docker-compose.host-network.yml"
else
    print_warning "docker-compose.host-network.yml não tem network_mode: host"
    USE_FILE="docker-compose.yml"
fi
echo ""

# 3. Usar docker-compose.host-network.yml
print_info "3️⃣  Usando docker-compose.host-network.yml para garantir network_mode: host..."
docker-compose -f docker-compose.host-network.yml down 2>/dev/null || true
print_success "Configuração verificada"
echo ""

# 4. Reconstruir e iniciar
print_info "4️⃣  Reconstruindo e iniciando containers..."
docker-compose -f docker-compose.host-network.yml build --no-cache backend 2>&1 | tail -n 5
docker-compose -f docker-compose.host-network.yml up -d
print_success "Containers iniciados"
echo ""

# 5. Aguardar inicialização
print_info "5️⃣  Aguardando inicialização dos containers..."
sleep 5
echo ""

# 6. Verificar network_mode
print_info "6️⃣  Verificando network_mode do container..."
NETWORK_MODE=$(docker inspect debrief-backend --format='{{.HostConfig.NetworkMode}}' 2>/dev/null || echo "unknown")
if [ "$NETWORK_MODE" = "host" ]; then
    print_success "✅ Container está em network_mode: host"
else
    print_error "❌ Container NÃO está em network_mode: host (atual: $NETWORK_MODE)"
    print_warning "Pode ser necessário usar docker-compose.host-network.yml explicitamente"
fi
echo ""

# 7. Testar conexão
print_info "7️⃣  Testando conexão com PostgreSQL..."
sleep 3
if docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
import psycopg2
import sys
try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='postgres',
        password='Mslestrategia.2025@',
        database='dbrief',
        connect_timeout=5
    )
    print("✅ Conexão bem-sucedida!")
    conn.close()
    sys.exit(0)
except Exception as e:
    print(f"❌ Erro: {e}")
    sys.exit(1)
PYTHON_SCRIPT
2>&1 | grep -q "✅"; then
    print_success "Conexão com PostgreSQL funcionou!"
else
    print_warning "Conexão ainda com problemas"
    print_info "Verifique os logs: docker-compose logs backend"
fi
echo ""

# 8. Verificar status
print_info "8️⃣  Status dos containers:"
docker-compose -f docker-compose.host-network.yml ps
echo ""

print_success "🎉 Correção concluída!"
print_info "Se ainda houver problemas, verifique:"
echo "  - docker-compose logs backend"
echo "  - ./scripts/diagnostico/diagnosticar-rede-container.sh"
echo ""

