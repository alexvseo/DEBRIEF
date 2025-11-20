#!/bin/bash

################################################################################
# Script para iniciar ambiente de desenvolvimento local
# Conecta ao banco de dados remoto e inicia containers Docker
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

echo "🚀 Iniciando ambiente de desenvolvimento local..."
echo ""

# Verificar se está no diretório correto
if [ ! -f "docker-compose.dev.yml" ]; then
    print_error "docker-compose.dev.yml não encontrado!"
    print_info "Execute este script na raiz do projeto"
    exit 1
fi

# Criar arquivos .env.dev se não existirem
if [ ! -f "backend/.env.dev" ]; then
    print_info "Criando backend/.env.dev a partir do exemplo..."
    if [ -f "backend/.env.dev.example" ]; then
        cp backend/.env.dev.example backend/.env.dev
        print_success "backend/.env.dev criado"
    else
        print_warning "backend/.env.dev.example não encontrado. Criando arquivo básico..."
        cat > backend/.env.dev << 'EOF'
DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@82.25.92.217:5432/dbrief
SECRET_KEY=dev-secret-key-local-change-me
FRONTEND_URL=http://localhost:5173
ENVIRONMENT=development
DEBUG=True
EOF
        print_success "backend/.env.dev criado com configurações básicas"
    fi
fi

if [ ! -f "frontend/.env.dev" ]; then
    print_info "Criando frontend/.env.dev a partir do exemplo..."
    if [ -f "frontend/.env.dev.example" ]; then
        cp frontend/.env.dev.example frontend/.env.dev
        print_success "frontend/.env.dev criado"
    else
        print_warning "frontend/.env.dev.example não encontrado. Criando arquivo básico..."
        cat > frontend/.env.dev << 'EOF'
VITE_API_URL=http://localhost:8000/api
VITE_ENV=development
VITE_DEBUG_MODE=true
EOF
        print_success "frontend/.env.dev criado com configurações básicas"
    fi
fi
echo ""

# 1. Verificar conexão com banco remoto
print_info "1️⃣  Verificando conexão com banco de dados remoto..."
if [ -f "scripts/dev/testar-conexao-banco-remoto.sh" ]; then
    if ./scripts/dev/testar-conexao-banco-remoto.sh; then
        print_success "Conexão com banco remoto OK"
    else
        print_warning "Problemas na conexão com banco remoto"
        print_info "Deseja continuar mesmo assim? (s/N)"
        read -r resposta
        if [ "$resposta" != "s" ] && [ "$resposta" != "S" ]; then
            print_info "Abortando..."
            exit 1
        fi
    fi
else
    print_warning "Script de teste não encontrado. Pulando verificação."
fi
echo ""

# 2. Parar containers existentes (se houver)
print_info "2️⃣  Parando containers de desenvolvimento existentes..."
docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
print_success "Containers parados"
echo ""

# 3. Verificar se portas estão livres
print_info "3️⃣  Verificando se portas estão livres..."
check_port() {
    local port=$1
    local service=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || nc -z localhost $port 2>/dev/null; then
        print_warning "Porta $port está em uso ($service)"
        print_info "Deseja parar o processo? (s/N)"
        read -r resposta
        if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
            if command -v lsof &> /dev/null; then
                PID=$(lsof -ti:$port)
                if [ -n "$PID" ]; then
                    kill -9 $PID 2>/dev/null || true
                    print_success "Processo na porta $port finalizado"
                fi
            fi
        fi
    else
        print_success "Porta $port está livre"
    fi
}

check_port 8000 "Backend"
check_port 5173 "Frontend"
echo ""

# 4. Construir imagens (se necessário)
print_info "4️⃣  Construindo imagens Docker (pode demorar na primeira vez)..."
docker-compose -f docker-compose.dev.yml build
print_success "Imagens construídas"
echo ""

# 5. Iniciar containers
print_info "5️⃣  Iniciando containers..."
docker-compose -f docker-compose.dev.yml up -d
print_success "Containers iniciados"
echo ""

# 6. Aguardar serviços ficarem prontos
print_info "6️⃣  Aguardando serviços ficarem prontos..."
sleep 5

# Verificar backend
print_info "Verificando backend..."
for i in {1..30}; do
    if curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
        print_success "Backend está respondendo"
        break
    fi
    if [ $i -eq 30 ]; then
        print_warning "Backend não respondeu após 30 tentativas"
        print_info "Verifique os logs: docker-compose -f docker-compose.dev.yml logs backend"
    else
        sleep 2
    fi
done

# Verificar frontend
print_info "Verificando frontend..."
for i in {1..15}; do
    if curl -s http://localhost:5173 > /dev/null 2>&1; then
        print_success "Frontend está respondendo"
        break
    fi
    if [ $i -eq 15 ]; then
        print_warning "Frontend não respondeu após 15 tentativas"
        print_info "Verifique os logs: docker-compose -f docker-compose.dev.yml logs frontend"
    else
        sleep 2
    fi
done
echo ""

# 7. Mostrar status
print_info "7️⃣  Status dos containers:"
docker-compose -f docker-compose.dev.yml ps
echo ""

# 8. Mostrar URLs de acesso
print_success "🎉 Ambiente de desenvolvimento iniciado!"
echo ""
print_info "📋 URLs de acesso:"
echo "  Frontend:  http://localhost:5173"
echo "  Backend:   http://localhost:8000"
echo "  API Docs:  http://localhost:8000/api/docs"
echo "  Health:    http://localhost:8000/api/health"
echo ""
print_info "📝 Comandos úteis:"
echo "  Ver logs:           docker-compose -f docker-compose.dev.yml logs -f"
echo "  Parar:             docker-compose -f docker-compose.dev.yml down"
echo "  Reiniciar:         docker-compose -f docker-compose.dev.yml restart"
echo "  Logs do backend:   docker-compose -f docker-compose.dev.yml logs -f backend"
echo "  Logs do frontend:  docker-compose -f docker-compose.dev.yml logs -f frontend"
echo ""
print_warning "⚠️  ATENÇÃO: Você está conectado ao banco de dados de PRODUÇÃO!"
print_warning "   Tenha cuidado ao fazer alterações que possam afetar dados reais."
echo ""

