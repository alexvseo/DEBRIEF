#!/bin/bash

################################################################################
# Script para testar criação de cliente via API
# Diagnostica problemas ao criar clientes
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

echo "🔍 Testando criação de cliente via API..."
echo ""

# Configurações
API_URL="${API_URL:-http://localhost:8000/api}"
USERNAME="${USERNAME:-admin}"
PASSWORD="${PASSWORD:-admin123}"

# 1. Fazer login
print_info "1️⃣  Fazendo login..."
TOKEN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${USERNAME}&password=${PASSWORD}")

TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    print_error "Falha ao fazer login"
    echo "Resposta: $TOKEN_RESPONSE"
    exit 1
fi

print_success "Login realizado. Token obtido."
echo ""

# 2. Testar criação de cliente válido
print_info "2️⃣  Testando criação de cliente válido..."
CLIENTE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Cliente Teste '$(date +%s)'",
    "whatsapp_group_id": "99999999-1234567890@g.us",
    "trello_member_id": "3def456",
    "ativo": true
  }')

HTTP_CODE=$(echo "$CLIENTE_RESPONSE" | tail -n1)
BODY=$(echo "$CLIENTE_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ]; then
    print_success "Cliente criado com sucesso!"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
    print_error "Falha ao criar cliente (HTTP $HTTP_CODE)"
    echo "Resposta: $BODY"
fi
echo ""

# 3. Testar validação de nome vazio
print_info "3️⃣  Testando validação de nome vazio..."
VALIDACAO_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "",
    "ativo": true
  }')

HTTP_CODE=$(echo "$VALIDACAO_RESPONSE" | tail -n1)
BODY=$(echo "$VALIDACAO_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "422" ] || [ "$HTTP_CODE" = "400" ]; then
    print_success "Validação funcionando (esperado HTTP $HTTP_CODE)"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
    print_warning "Validação pode não estar funcionando (HTTP $HTTP_CODE)"
fi
echo ""

# 4. Testar validação de WhatsApp ID inválido
print_info "4️⃣  Testando validação de WhatsApp ID inválido..."
WHATSAPP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Cliente Teste WhatsApp",
    "whatsapp_group_id": "99999999-1234567890",
    "ativo": true
  }')

HTTP_CODE=$(echo "$WHATSAPP_RESPONSE" | tail -n1)
BODY=$(echo "$WHATSAPP_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "422" ] || [ "$HTTP_CODE" = "400" ]; then
    print_success "Validação de WhatsApp funcionando (esperado HTTP $HTTP_CODE)"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
    print_warning "Validação de WhatsApp pode não estar funcionando (HTTP $HTTP_CODE)"
fi
echo ""

# 5. Testar cliente duplicado
print_info "5️⃣  Testando criação de cliente duplicado..."
DUPLICADO_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Cliente Duplicado",
    "ativo": true
  }')

HTTP_CODE1=$(echo "$DUPLICADO_RESPONSE" | tail -n1)

# Tentar criar novamente
DUPLICADO_RESPONSE2=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Cliente Duplicado",
    "ativo": true
  }')

HTTP_CODE2=$(echo "$DUPLICADO_RESPONSE2" | tail -n1)
BODY2=$(echo "$DUPLICADO_RESPONSE2" | head -n-1)

if [ "$HTTP_CODE1" = "201" ] && [ "$HTTP_CODE2" = "400" ]; then
    print_success "Validação de duplicado funcionando"
    echo "$BODY2" | python3 -m json.tool 2>/dev/null || echo "$BODY2"
else
    print_warning "Validação de duplicado pode não estar funcionando"
fi
echo ""

# 6. Verificar logs do backend
print_info "6️⃣  Verificando logs do backend (últimas 20 linhas)..."
if command -v docker &> /dev/null; then
    if docker ps | grep -q debrief-backend; then
        docker logs debrief-backend --tail=20 2>&1 | grep -i -E "cliente|error|exception" || print_info "Nenhum erro relacionado encontrado"
    else
        print_warning "Container backend não encontrado"
    fi
else
    print_warning "Docker não encontrado, pulando verificação de logs"
fi
echo ""

print_success "🎉 Testes concluídos!"
echo ""
print_info "Para usar com servidor remoto:"
echo "  API_URL=http://82.25.92.217:2022/api ./scripts/diagnostico/testar-criar-cliente.sh"
echo ""

