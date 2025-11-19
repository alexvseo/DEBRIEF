#!/bin/bash

# ==================== Script de Deploy Docker - DeBrief ====================
# Este script facilita o deploy da aplicação usando Docker

set -e  # Parar em caso de erro

echo "🐳 DeBrief - Deploy com Docker"
echo "================================"
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    print_info "Instale o Docker em: https://docs.docker.com/get-docker/"
    exit 1
fi

print_success "Docker está instalado"

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não está instalado!"
    print_info "Instale o Docker Compose em: https://docs.docker.com/compose/install/"
    exit 1
fi

print_success "Docker Compose está instalado"

# Verificar se o arquivo .env existe no backend
if [ ! -f "backend/.env" ]; then
    print_warning "Arquivo backend/.env não encontrado!"
    print_info "Copiando env.docker.example para backend/.env..."
    
    if [ -f "env.docker.example" ]; then
        cp env.docker.example backend/.env
        print_success "Arquivo backend/.env criado"
        print_warning "IMPORTANTE: Edite backend/.env e configure as variáveis necessárias!"
        print_info "Especialmente: SECRET_KEY, ENCRYPTION_KEY"
        echo ""
        read -p "Pressione ENTER para continuar ou Ctrl+C para cancelar..."
    else
        print_error "Arquivo env.docker.example não encontrado!"
        exit 1
    fi
fi

print_success "Arquivo backend/.env encontrado"

echo ""
print_info "Escolha uma opção:"
echo "1) 🚀 Iniciar aplicação (docker-compose up -d)"
echo "2) 🛑 Parar aplicação (docker-compose down)"
echo "3) 🔄 Reiniciar aplicação (down + up)"
echo "4) 📊 Ver logs (docker-compose logs -f)"
echo "5) 🗑️  Limpar tudo (down + volumes)"
echo "6) 🏗️  Rebuild (build + up)"
echo "7) ❌ Cancelar"
echo ""

read -p "Opção: " option

case $option in
    1)
        print_info "Iniciando aplicação..."
        docker-compose up -d
        print_success "Aplicação iniciada!"
        print_info "Frontend: http://localhost:3000"
        print_info "Backend: http://localhost:8000"
        print_info "API Docs: http://localhost:8000/docs"
        ;;
    2)
        print_info "Parando aplicação..."
        docker-compose down
        print_success "Aplicação parada!"
        ;;
    3)
        print_info "Reiniciando aplicação..."
        docker-compose down
        docker-compose up -d
        print_success "Aplicação reiniciada!"
        print_info "Frontend: http://localhost:3000"
        print_info "Backend: http://localhost:8000"
        ;;
    4)
        print_info "Mostrando logs (Ctrl+C para sair)..."
        docker-compose logs -f
        ;;
    5)
        print_warning "Esta operação irá remover todos os containers e volumes!"
        read -p "Tem certeza? (s/N): " confirm
        if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
            print_info "Limpando tudo..."
            docker-compose down -v
            print_success "Limpeza concluída!"
        else
            print_info "Operação cancelada"
        fi
        ;;
    6)
        print_info "Fazendo rebuild da aplicação..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        print_success "Rebuild concluído!"
        print_info "Frontend: http://localhost:3000"
        print_info "Backend: http://localhost:8000"
        ;;
    7)
        print_info "Operação cancelada"
        exit 0
        ;;
    *)
        print_error "Opção inválida!"
        exit 1
        ;;
esac

echo ""
print_success "Operação concluída!"
echo ""
print_info "Comandos úteis:"
echo "  - Ver status: docker-compose ps"
echo "  - Ver logs: docker-compose logs -f [service]"
echo "  - Entrar no container: docker-compose exec backend bash"
echo "  - Parar: docker-compose down"
echo ""

