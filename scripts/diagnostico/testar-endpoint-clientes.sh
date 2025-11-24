#!/bin/bash

################################################################################
# Script para testar endpoint de clientes
# Diagnostica problemas 404 ao criar clientes
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

echo "🔍 Testando endpoint de clientes..."
echo ""

# Configurações
API_URL="${API_URL:-http://localhost:8000/api}"
FRONTEND_URL="${FRONTEND_URL:-http://82.25.92.217:2022}"
USERNAME="${USERNAME:-admin}"
PASSWORD="${PASSWORD:-admin123}"

# 1. Verificar se backend está rodando
print_info "1️⃣  Verificando se backend está rodando..."
if curl -s -f "${API_URL}/health" > /dev/null 2>&1; then
    print_success "Backend está respondendo"
    curl -s "${API_URL}/health" | python3 -m json.tool 2>/dev/null || curl -s "${API_URL}/health"
else
    print_error "Backend NÃO está respondendo em ${API_URL}"
    print_info "Verificando containers Docker..."
    if command -v docker &> /dev/null; then
        docker ps | grep debrief-backend || print_error "Container backend não encontrado"
    fi
    exit 1
fi
echo ""

# 2. Verificar se endpoint existe (OpenAPI docs)
print_info "2️⃣  Verificando se endpoint /api/clientes está registrado..."
if curl -s -f "${API_URL}/openapi.json" > /dev/null 2>&1; then
    CLIENTES_ENDPOINT=$(curl -s "${API_URL}/openapi.json" | python3 -c "import sys, json; data=json.load(sys.stdin); paths=data.get('paths', {}); print('✅' if '/api/clientes' in str(paths) or '/clientes' in str(paths) else '❌')" 2>/dev/null || echo "?")
    if [ "$CLIENTES_ENDPOINT" = "✅" ]; then
        print_success "Endpoint /api/clientes encontrado no OpenAPI"
    else
        print_warning "Endpoint pode não estar registrado"
        print_info "Verificando rotas disponíveis..."
        curl -s "${API_URL}/openapi.json" | python3 -c "import sys, json; data=json.load(sys.stdin); paths=[p for p in data.get('paths', {}).keys() if 'cliente' in p.lower()]; print('\n'.join(paths) if paths else 'Nenhuma rota com cliente encontrada')" 2>/dev/null || echo "Erro ao verificar rotas"
    fi
else
    print_warning "Não foi possível verificar OpenAPI"
fi
echo ""

# 3. Fazer login
print_info "3️⃣  Fazendo login..."
TOKEN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${USERNAME}&password=${PASSWORD}")

TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('access_token', ''))" 2>/dev/null || echo "")

if [ -z "$TOKEN" ]; then
    print_error "Falha ao fazer login"
    echo "Resposta: $TOKEN_RESPONSE"
    exit 1
fi

print_success "Login realizado. Token obtido."
echo ""

# 4. Testar GET /api/clientes (listar)
print_info "4️⃣  Testando GET /api/clientes (listar clientes)..."
GET_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}/clientes/" \
  -H "Authorization: Bearer ${TOKEN}")

HTTP_CODE=$(echo "$GET_RESPONSE" | tail -n1)
BODY=$(echo "$GET_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    print_success "GET /api/clientes funcionou (HTTP $HTTP_CODE)"
    CLIENTES_COUNT=$(echo "$BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "?")
    print_info "Total de clientes: $CLIENTES_COUNT"
else
    print_error "GET /api/clientes falhou (HTTP $HTTP_CODE)"
    echo "Resposta: $BODY"
fi
echo ""

# 5. Testar POST /api/clientes (criar)
print_info "5️⃣  Testando POST /api/clientes (criar cliente)..."
NOME_CLIENTE="Cliente Teste $(date +%s)"
POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"nome\": \"${NOME_CLIENTE}\",
    \"whatsapp_group_id\": \"99999999-1234567890@g.us\",
    \"trello_member_id\": \"test123\",
    \"ativo\": true
  }")

HTTP_CODE=$(echo "$POST_RESPONSE" | tail -n1)
BODY=$(echo "$POST_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ]; then
    print_success "POST /api/clientes funcionou (HTTP $HTTP_CODE)"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    
    # Extrair ID do cliente criado
    CLIENTE_ID=$(echo "$BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('id', ''))" 2>/dev/null || echo "")
    
    if [ -n "$CLIENTE_ID" ]; then
        print_info "Cliente criado com ID: $CLIENTE_ID"
    fi
else
    print_error "POST /api/clientes falhou (HTTP $HTTP_CODE)"
    echo "Resposta: $BODY"
    
    # Diagnóstico adicional
    if [ "$HTTP_CODE" = "404" ]; then
        print_error "❌ ERRO 404: Endpoint não encontrado!"
        print_info "Possíveis causas:"
        echo "  1. Backend não tem a rota registrada"
        echo "  2. Caddy não está fazendo proxy corretamente"
        echo "  3. URL incorreta"
        echo ""
        print_info "Verificando rotas do backend..."
        if command -v docker &> /dev/null && docker ps | grep -q debrief-backend; then
            docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.main import app
routes = []
for route in app.routes:
    if hasattr(route, 'path'):
        routes.append(route.path)
for r in sorted(routes):
    if 'cliente' in r.lower():
        print(f"  ✅ {r}")
PYTHON_SCRIPT
        fi
    fi
fi
echo ""

# 6. Testar via Caddy (frontend URL)
print_info "6️⃣  Testando via Caddy (${FRONTEND_URL}/api/clientes)..."
CADDY_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${FRONTEND_URL}/api/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" 2>&1)

CADDY_HTTP_CODE=$(echo "$CADDY_RESPONSE" | tail -n1)
CADDY_BODY=$(echo "$CADDY_RESPONSE" | head -n-1)

if [ "$CADDY_HTTP_CODE" = "200" ]; then
    print_success "Caddy está fazendo proxy corretamente (HTTP $CADDY_HTTP_CODE)"
else
    print_error "Caddy pode ter problemas (HTTP $CADDY_HTTP_CODE)"
    if [ "$CADDY_HTTP_CODE" = "404" ]; then
        print_error "Caddy retornou 404 - verifique configuração do Caddyfile"
    fi
    echo "Resposta: $CADDY_BODY" | head -n 5
fi
echo ""

# 7. Verificar logs do backend
print_info "7️⃣  Verificando logs do backend (últimas 20 linhas relacionadas a clientes)..."
if command -v docker &> /dev/null && docker ps | grep -q debrief-backend; then
    docker logs debrief-backend --tail=50 2>&1 | grep -i -E "cliente|clientes|404|not found" | tail -10 || print_info "Nenhum log relacionado encontrado"
else
    print_warning "Container backend não encontrado"
fi
echo ""

# 8. Verificar logs do Caddy
print_info "8️⃣  Verificando logs do Caddy..."
if command -v docker &> /dev/null && docker ps | grep -q debrief-caddy; then
    docker logs debrief-caddy --tail=20 2>&1 | grep -i -E "clientes|404|error" | tail -10 || print_info "Nenhum log relacionado encontrado"
else
    print_warning "Container Caddy não encontrado"
fi
echo ""

print_success "🎉 Testes concluídos!"
echo ""
print_info "Se POST retornou 404, verifique:"
echo "  1. Backend tem a rota registrada em main.py"
echo "  2. Caddy está fazendo proxy para /api/*"
echo "  3. Backend está acessível em localhost:8000"
echo ""

