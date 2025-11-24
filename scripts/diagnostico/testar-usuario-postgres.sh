#!/bin/bash

# Script para Testar Conexão com Usuário postgres
# Execute no servidor: ./testar-usuario-postgres.sh

echo "=========================================="
echo "🔍 TESTAR CONEXÃO COM USUÁRIO POSTGRES"
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
DB_NAME="dbrief"
DB_USER="postgres"
DB_PASS="Mslestra@2025"

echo "Configurações:"
echo "  Usuário: $DB_USER"
echo "  Senha: $DB_PASS"
echo "  Banco: $DB_NAME"
echo "  Host: localhost:5432"
echo ""

# 1. Verificar se PostgreSQL está rodando
print_info "1️⃣  Verificando se PostgreSQL está rodando..."
if systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL está rodando"
else
    print_error "PostgreSQL não está rodando"
    print_info "Iniciando PostgreSQL..."
    sudo systemctl start postgresql
    sleep 2
    if systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL iniciado"
    else
        print_error "Erro ao iniciar PostgreSQL"
        exit 1
    fi
fi
echo ""

# 2. Verificar se usuário postgres existe
print_info "2️⃣  Verificando se usuário 'postgres' existe..."
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='postgres'" | grep -q 1; then
    print_success "Usuário 'postgres' existe"
else
    print_error "Usuário 'postgres' não existe (isso é estranho!)"
    exit 1
fi
echo ""

# 3. Verificar/atualizar senha do usuário postgres
print_info "3️⃣  Verificando/atualizando senha do usuário 'postgres'..."
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$DB_PASS';" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "Senha do usuário 'postgres' atualizada"
else
    print_warning "Erro ao atualizar senha (pode já estar correta)"
fi
echo ""

# 4. Verificar se banco dbrief existe
print_info "4️⃣  Verificando se banco '$DB_NAME' existe..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    print_success "Banco '$DB_NAME' existe"
else
    print_warning "Banco '$DB_NAME' não existe"
    print_info "Criando banco '$DB_NAME'..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER postgres;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Banco '$DB_NAME' criado"
    else
        print_error "Erro ao criar banco"
    fi
fi
echo ""

# 5. Testar conexão local com psql
print_info "5️⃣  Testando conexão local com psql..."
export PGPASSWORD="$DB_PASS"
if psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" 2>&1 | grep -q "PostgreSQL"; then
    print_success "✅ Conexão local com psql funcionou!"
    echo ""
    print_info "Informações da conexão:"
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT current_database(), current_user, version();" 2>&1 | head -5
else
    ERROR=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" 2>&1 | tail -1)
    print_error "Conexão local falhou: $ERROR"
fi
unset PGPASSWORD
echo ""

# 6. Testar conexão com Python (simulando backend)
print_info "6️⃣  Testando conexão com Python (simulando backend)..."
python3 << EOF
import sys
try:
    import psycopg2
    print("✅ psycopg2 instalado")
    
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="$DB_NAME",
            user="$DB_USER",
            password="$DB_PASS",
            connect_timeout=5
        )
        print("✅ Conexão Python funcionou!")
        
        cur = conn.cursor()
        cur.execute("SELECT current_database(), current_user, version();")
        result = cur.fetchone()
        print(f"✅ Banco: {result[0]}")
        print(f"✅ Usuário: {result[1]}")
        print(f"✅ PostgreSQL: {result[2][:50]}...")
        
        cur.close()
        conn.close()
        sys.exit(0)
    except psycopg2.OperationalError as e:
        print(f"❌ Erro de conexão: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")
        sys.exit(1)
except ImportError:
    print("⚠️  psycopg2 não está instalado")
    print("   Instale com: pip install psycopg2-binary")
    sys.exit(1)
EOF

PYTHON_EXIT=$?
echo ""

# 7. Testar conexão do container Docker (se estiver rodando)
print_info "7️⃣  Testando conexão do container Docker..."
if docker ps --filter "name=debrief-backend" --format "{{.Names}}" | grep -q debrief-backend; then
    print_info "Container backend encontrado"
    
    # Testar com localhost (se usar network_mode: host)
    docker exec debrief-backend python3 << EOF 2>&1 | head -20
import sys
try:
    import psycopg2
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="$DB_NAME",
            user="$DB_USER",
            password="$DB_PASS",
            connect_timeout=5
        )
        print("✅ Conexão do container funcionou!")
        conn.close()
        sys.exit(0)
    except Exception as e:
        print(f"❌ Erro: {str(e)[:100]}")
        sys.exit(1)
except ImportError:
    print("⚠️  psycopg2 não instalado no container")
    sys.exit(1)
EOF
    
    CONTAINER_EXIT=$?
    if [ $CONTAINER_EXIT -eq 0 ]; then
        print_success "✅ Container consegue conectar!"
    else
        print_warning "⚠️  Container não consegue conectar (pode precisar network_mode: host)"
    fi
else
    print_warning "Container backend não está rodando"
fi
echo ""

# 8. Resumo e recomendações
echo "=========================================="
echo "📊 RESUMO E RECOMENDAÇÕES"
echo "=========================================="
echo ""

if [ $PYTHON_EXIT -eq 0 ]; then
    print_success "✅ Conexão com usuário 'postgres' funcionou!"
    echo ""
    print_info "Próximos passos:"
    echo ""
    echo "1️⃣  Atualizar DATABASE_URL no docker-compose.yml:"
    echo "   DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief"
    echo ""
    echo "2️⃣  Usar network_mode: host para o backend:"
    echo "   docker-compose -f docker-compose.host-network.yml up -d"
    echo ""
    echo "3️⃣  Ou atualizar docker-compose.yml com:"
    echo "   - DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief"
    echo "   - network_mode: host no backend"
    echo ""
else
    print_error "❌ Conexão com usuário 'postgres' falhou"
    echo ""
    print_info "Verifique:"
    echo "  1. PostgreSQL está rodando: sudo systemctl status postgresql"
    echo "  2. Senha está correta"
    echo "  3. Banco dbrief existe: sudo -u postgres psql -l | grep dbrief"
fi
echo ""

