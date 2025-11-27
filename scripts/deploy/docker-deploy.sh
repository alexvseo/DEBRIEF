#!/bin/bash

# ==================== Script de Deploy Docker - DeBrief ====================
# Este script facilita o deploy da aplicação usando Docker

set -euo pipefail  # Parar em caso de erro

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SECRETS_LIB="${SCRIPT_DIR}/lib/secrets.sh"
if [ -f "${SECRETS_LIB}" ]; then
    # shellcheck source=../../scripts/deploy/lib/secrets.sh
    source "${SECRETS_LIB}"
    debrief_load_secrets "${PROJECT_ROOT}"
fi

cd "${PROJECT_ROOT}"

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

# Garantir arquivo .env (docker-compose)
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
    print_warning "Arquivo .env não encontrado!"
    if [ -f "${PROJECT_ROOT}/env.example" ]; then
        print_info "Copiando env.example -> .env..."
        cp "${PROJECT_ROOT}/env.example" "${PROJECT_ROOT}/.env"
        print_success ".env criado a partir do template"
        print_warning "Edite .env e configure POSTGRES_PASSWORD, SECRET_KEY, etc."
        read -rp "Pressione ENTER para continuar ou Ctrl+C para cancelar..." _
    else
        print_error "env.example não encontrado. Aborte o deploy."
        exit 1
    fi
fi

# Verificar se o arquivo .env existe no backend
if [ ! -f "${PROJECT_ROOT}/backend/.env" ]; then
    print_warning "Arquivo backend/.env não encontrado!"
    if [ -f "${PROJECT_ROOT}/backend/env.example" ]; then
        print_info "Copiando backend/env.example -> backend/.env..."
        cp "${PROJECT_ROOT}/backend/env.example" "${PROJECT_ROOT}/backend/.env"
        print_success "Arquivo backend/.env criado"
        print_warning "IMPORTANTE: Edite backend/.env e configure as variáveis sensíveis!"
        echo ""
        read -rp "Pressione ENTER para continuar ou Ctrl+C para cancelar..." _
    else
        print_error "Template backend/env.example não encontrado!"
        exit 1
    fi
fi

print_success "Arquivos de ambiente encontrados"

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
        print_info "Frontend: http://82.25.92.217:2022"
        print_info "Backend: http://82.25.92.217:2025"
        print_info "API Docs: http://82.25.92.217:2025/docs"
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
        print_info "Frontend: http://82.25.92.217:2022"
        print_info "Backend: http://82.25.92.217:2025"
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
        print_info "Frontend: http://82.25.92.217:2022"
        print_info "Backend: http://82.25.92.217:2025"
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

