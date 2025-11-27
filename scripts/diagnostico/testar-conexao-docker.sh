#!/bin/bash

# Script para Testar Conexão do Container Docker com Banco
# Execute no servidor: ./testar-conexao-docker.sh

echo "=========================================="
echo "🐳 TESTE DE CONEXÃO DO CONTAINER DOCKER"
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

# Configurações
DB_HOST="82.25.92.217"
DB_PORT="5432"
DB_NAME="dbrief"
DB_USER="root"
DB_PASS="<redacted-db-password>"

echo "Configurações:"
echo "  Host: $DB_HOST"
echo "  Porta: $DB_PORT"
echo "  Banco: $DB_NAME"
echo "  Usuário: $DB_USER"
echo ""

# 1. Verificar IP do host
print_info "1️⃣  Verificando IP do host..."
HOST_IP=$(hostname -I | awk '{print $1}')
print_info "IP do host: $HOST_IP"
echo ""

# 2. Verificar gateway Docker
print_info "2️⃣  Verificando gateway Docker..."
if docker network inspect debrief_debrief-network 2>/dev/null | grep -q Gateway; then
    DOCKER_GATEWAY=$(docker network inspect debrief_debrief-network | grep Gateway | head -1 | awk '{print $2}' | tr -d '"' | tr -d ',')
    print_info "Gateway Docker: $DOCKER_GATEWAY"
else
    print_warning "Rede Docker não encontrada"
fi
echo ""

# 3. Testar conexão do host (fora do Docker)
print_info "3️⃣  Testando conexão do HOST (fora do Docker)..."
if timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    print_success "Host consegue acessar $DB_HOST:$DB_PORT"
else
    print_error "Host NÃO consegue acessar $DB_HOST:$DB_PORT"
    print_warning "Isso é estranho se outros sistemas conseguem..."
fi
echo ""

# 4. Testar conexão do container Docker
print_info "4️⃣  Testando conexão do CONTAINER DOCKER..."
if docker ps --filter "name=debrief-backend" --format "{{.Names}}" | grep -q debrief-backend; then
    print_info "Container backend encontrado"
    
    # Testar se container consegue acessar o IP externo
    if docker exec debrief-backend timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
        print_success "Container consegue acessar $DB_HOST:$DB_PORT"
    else
        print_error "Container NÃO consegue acessar $DB_HOST:$DB_PORT"
        print_warning "Problema de rede Docker identificado!"
    fi
    
    # Testar com host.docker.internal
    print_info "   Testando host.docker.internal..."
    if docker exec debrief-backend timeout 5 bash -c "echo > /dev/tcp/host.docker.internal/$DB_PORT" 2>/dev/null; then
        print_success "Container consegue acessar host.docker.internal:$DB_PORT"
        print_info "   Solução: Usar host.docker.internal em vez de $DB_HOST"
    else
        print_warning "host.docker.internal não funciona"
    fi
    
    # Testar com IP do host
    if [ -n "$HOST_IP" ]; then
        print_info "   Testando IP do host ($HOST_IP)..."
        if docker exec debrief-backend timeout 5 bash -c "echo > /dev/tcp/$HOST_IP/$DB_PORT" 2>/dev/null; then
            print_success "Container consegue acessar $HOST_IP:$DB_PORT"
            print_info "   Solução: Usar $HOST_IP em vez de $DB_HOST"
        else
            print_warning "IP do host ($HOST_IP) não funciona"
        fi
    fi
else
    print_warning "Container backend não está rodando"
    print_info "Iniciando teste com container temporário..."
    
    # Criar container temporário para teste
    docker run --rm --network debrief_debrief-network debrief-backend:latest timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null && \
        print_success "Container consegue acessar $DB_HOST:$DB_PORT" || \
        print_error "Container NÃO consegue acessar $DB_HOST:$DB_PORT"
fi
echo ""

# 5. Testar conexão Python do container
print_info "5️⃣  Testando conexão Python do container..."
if docker ps --filter "name=debrief-backend" --format "{{.Names}}" | grep -q debrief-backend; then
    docker exec debrief-backend python3 << EOF 2>&1 | head -20
import sys
try:
    import psycopg2
    print("✅ psycopg2 instalado")
    
    # Testar com IP externo
    try:
        conn = psycopg2.connect(
            host="$DB_HOST",
            port=$DB_PORT,
            database="$DB_NAME",
            user="$DB_USER",
            password="$DB_PASS",
            connect_timeout=5
        )
        print("✅ Conexão com $DB_HOST funcionou!")
        conn.close()
        sys.exit(0)
    except Exception as e:
        print(f"❌ Erro com $DB_HOST: {str(e)[:100]}")
        
        # Testar com host.docker.internal
        try:
            conn = psycopg2.connect(
                host="host.docker.internal",
                port=$DB_PORT,
                database="$DB_NAME",
                user="$DB_USER",
                password="$DB_PASS",
                connect_timeout=5
            )
            print("✅ Conexão com host.docker.internal funcionou!")
            conn.close()
            sys.exit(0)
        except Exception as e2:
            print(f"❌ Erro com host.docker.internal: {str(e2)[:100]}")
            sys.exit(1)
except ImportError:
    print("⚠️  psycopg2 não instalado")
    sys.exit(1)
EOF
    PYTHON_EXIT=$?
    if [ $PYTHON_EXIT -eq 0 ]; then
        print_success "Conexão Python funcionou!"
    else
        print_error "Conexão Python falhou"
    fi
else
    print_warning "Container não está rodando (pulando teste Python)"
fi
echo ""

# 6. Resumo e recomendações
echo "=========================================="
echo "📊 RESUMO E RECOMENDAÇÕES"
echo "=========================================="
echo ""

if docker exec debrief-backend timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    print_success "Container consegue acessar o banco!"
    print_info "O problema pode ser na configuração do DATABASE_URL"
else
    print_error "Container NÃO consegue acessar o banco pelo IP externo"
    echo ""
    print_info "Soluções possíveis:"
    echo ""
    echo "1️⃣  Usar host.docker.internal (recomendado):"
    echo "   DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@host.docker.internal:5432/dbrief"
    echo ""
    echo "2️⃣  Usar IP do host ($HOST_IP):"
    echo "   DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@$HOST_IP:5432/dbrief"
    echo ""
    echo "3️⃣  Usar network_mode: host no docker-compose.yml"
    echo "   (permite container acessar rede do host diretamente)"
    echo ""
    echo "4️⃣  Configurar extra_hosts no docker-compose.yml:"
    echo "   extra_hosts:"
    echo "     - \"host.docker.internal:host-gateway\""
    echo ""
fi
echo ""

