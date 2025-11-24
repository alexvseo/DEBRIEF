#!/bin/bash

# Script para testar o endpoint de configurações com autenticação

echo "🧪 Testando endpoint /api/configuracoes/agrupadas"
echo ""

echo "1️⃣  Obtendo token de autenticação..."
echo ""

# Tentar diferentes combinações de usuário/senha
TOKEN=""
USERNAME=""
PASSWORD=""

# Tentar com admin/admin123
echo "   Tentando login com admin/admin123..."
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' 2>&1)

if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || echo "")
    if [ -n "$TOKEN" ]; then
        USERNAME="admin"
        PASSWORD="admin123"
        echo "   ✅ Token obtido com admin/admin123"
    fi
fi

# Se não funcionou, tentar obter usuário master do banco
if [ -z "$TOKEN" ]; then
    echo "   Tentando obter usuário master do banco..."
    USERNAME=$(docker-compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models import User

db = SessionLocal()
try:
    user = db.query(User).filter(User.tipo == 'master').first()
    if user:
        print(user.username)
finally:
    db.close()
" 2>/dev/null | head -1)
    
    if [ -n "$USERNAME" ]; then
        echo "   📝 Usuário encontrado: $USERNAME"
        echo "   Tentando login com $USERNAME/admin123..."
        LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
          -H "Content-Type: application/json" \
          -d "{\"username\":\"$USERNAME\",\"password\":\"admin123\"}" 2>&1)
        
        if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
            TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || echo "")
            if [ -n "$TOKEN" ]; then
                PASSWORD="admin123"
                echo "   ✅ Token obtido com $USERNAME/admin123"
            fi
        fi
    fi
fi

if [ -z "$TOKEN" ]; then
    echo "   ❌ Não foi possível obter token"
    echo "   Verifique se há um usuário master no banco e se a senha está correta"
    exit 1
fi

echo ""
echo "2️⃣  Testando endpoint /api/configuracoes/agrupadas..."
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/configuracoes/agrupadas" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

echo "   Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Endpoint funcionou!"
    echo ""
    
    # Contar grupos
    COUNT=$(echo "$BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
    echo "   Grupos retornados: $COUNT"
    echo ""
    
    # Mostrar estrutura
    echo "   Estrutura da resposta:"
    echo "$BODY" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for grupo in data:
        print(f'     - Tipo: {grupo.get(\"tipo\", \"N/A\")}')
        print(f'       Configurações: {len(grupo.get(\"configuracoes\", []))}')
        for config in grupo.get('configuracoes', [])[:2]:
            print(f'         • {config.get(\"chave\", \"N/A\")}: {config.get(\"valor\", \"N/A\")[:30]}...')
        if len(grupo.get('configuracoes', [])) > 2:
            print(f'         ... e mais {len(grupo.get(\"configuracoes\", [])) - 2} configurações')
        print()
except Exception as e:
    print(f'     Erro ao parsear JSON: {e}')
" 2>/dev/null || echo "     (Erro ao processar resposta)"
    
    echo ""
    echo "3️⃣  Testando endpoint via Caddy..."
    echo ""
    
    RESPONSE_CADDY=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
      -H "Authorization: Bearer $TOKEN" \
      "http://localhost:2022/api/configuracoes/agrupadas" 2>&1)
    
    HTTP_CODE_CADDY=$(echo "$RESPONSE_CADDY" | grep "HTTP_CODE" | cut -d: -f2)
    
    echo "   Status via Caddy: $HTTP_CODE_CADDY"
    if [ "$HTTP_CODE_CADDY" = "200" ]; then
        echo "   ✅ Endpoint via Caddy funcionou!"
    else
        echo "   ❌ Endpoint via Caddy retornou erro"
        BODY_CADDY=$(echo "$RESPONSE_CADDY" | sed '/HTTP_CODE/d')
        echo "   Resposta: $BODY_CADDY" | head -5
    fi
    
else
    echo "   ❌ Endpoint retornou erro $HTTP_CODE"
    echo ""
    echo "   Resposta:"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY" | head -20
    echo ""
    
    echo "4️⃣  Verificando logs do backend..."
    echo ""
    docker-compose logs backend --tail 30 | grep -iE "(error|exception|traceback|configuracao)" | tail -10
fi

echo ""
echo "✅ Teste concluído"

