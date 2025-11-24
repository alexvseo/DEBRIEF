#!/bin/bash

# Script para diagnosticar problema de carregamento de secretarias

echo "🔍 Diagnosticando carregamento de secretarias"
echo ""

echo "1️⃣  Verificando secretarias no banco de dados..."
echo ""
docker-compose exec backend python -c "
from app.core.database import SessionLocal
from app.models import Secretaria

db = SessionLocal()
try:
    # Contar todas as secretarias
    total = db.query(Secretaria).count()
    print(f'   Total de secretarias no banco: {total}')
    
    # Contar ativas e inativas
    ativas = db.query(Secretaria).filter(Secretaria.ativo == True).count()
    inativas = db.query(Secretaria).filter(Secretaria.ativo == False).count()
    print(f'   Secretarias ativas: {ativas}')
    print(f'   Secretarias inativas: {inativas}')
    
    # Listar algumas secretarias
    print()
    print('   Primeiras 5 secretarias:')
    secretarias = db.query(Secretaria).limit(5).all()
    for s in secretarias:
        print(f'     - ID: {s.id[:8]}... | Nome: {s.nome} | Ativo: {s.ativo}')
finally:
    db.close()
" 2>&1
echo ""

echo "2️⃣  Obtendo token de autenticação..."
echo ""
# Tentar fazer login para obter token
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' 2>&1)

TOKEN=""
if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || echo "")
fi

if [ -z "$TOKEN" ]; then
    echo "   ⚠️  Não foi possível obter token. Tentando com usuário do banco..."
    # Tentar obter usuário master do banco
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
        echo "   📝 Tentando login com usuário: $USERNAME"
        LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
          -H "Content-Type: application/json" \
          -d "{\"username\":\"$USERNAME\",\"password\":\"admin123\"}" 2>&1)
        TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || echo "")
    fi
fi

if [ -n "$TOKEN" ]; then
    echo "   ✅ Token obtido com sucesso"
else
    echo "   ❌ Não foi possível obter token. Testes sem autenticação falharão."
fi
echo ""

echo "3️⃣  Testando endpoint diretamente no backend (apenas_ativas=false)..."
echo ""
if [ -n "$TOKEN" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -H "Authorization: Bearer $TOKEN" "http://localhost:8000/api/secretarias/?apenas_ativas=false&limit=10000")
else
    echo "   ⚠️  Testando sem autenticação (esperado: 401)"
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "http://localhost:8000/api/secretarias/?apenas_ativas=false&limit=10000")
fi

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

echo "   Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    COUNT=$(echo "$BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data) if isinstance(data, list) else 0)" 2>/dev/null || echo "0")
    echo "   ✅ Endpoint funcionou! Retornou $COUNT secretaria(s)"
    echo "   Primeiras 3 secretarias:"
    echo "$BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); [print(f'     - {s.get(\"nome\", \"N/A\")} (Ativo: {s.get(\"ativo\", \"N/A\")})') for s in (data[:3] if isinstance(data, list) else [])]" 2>/dev/null || echo "     (Erro ao parsear JSON)"
else
    echo "   ❌ Endpoint retornou erro"
    echo "   Resposta: $BODY" | head -5
fi
echo ""

echo "4️⃣  Testando endpoint via Caddy (apenas_ativas=false)..."
echo ""
if [ -n "$TOKEN" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -H "Authorization: Bearer $TOKEN" "http://localhost:2022/api/secretarias/?apenas_ativas=false&limit=10000")
else
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "http://localhost:2022/api/secretarias/?apenas_ativas=false&limit=10000")
fi

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

echo "   Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    COUNT=$(echo "$BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data) if isinstance(data, list) else 0)" 2>/dev/null || echo "0")
    echo "   ✅ Endpoint via Caddy funcionou! Retornou $COUNT secretaria(s)"
else
    echo "   ❌ Endpoint via Caddy retornou erro"
    echo "   Resposta: $BODY" | head -5
fi
echo ""

echo "5️⃣  Verificando logs do backend (últimas 30 linhas com 'secretaria' ou '401')..."
echo ""
docker-compose logs backend | grep -iE "(secretaria|401|unauthorized)" | tail -30 || echo "   Nenhum log encontrado"
echo ""

echo "6️⃣  Verificando se o frontend está enviando token corretamente..."
echo ""
echo "   💡 Para verificar no navegador:"
echo "      1. Abra o DevTools (F12)"
echo "      2. Vá para a aba 'Network'"
echo "      3. Recarregue a página de Configurações"
echo "      4. Procure por requisições para '/api/secretarias/'"
echo "      5. Verifique se o header 'Authorization: Bearer ...' está presente"
echo "      6. Verifique o status code da resposta"
echo ""

echo "✅ Diagnóstico concluído"
echo ""
echo "💡 Se o endpoint retornar dados mas o frontend não mostrar:"
echo "   1. Verifique o console do navegador (F12)"
echo "   2. Verifique se há erros de CORS ou autenticação"
echo "   3. Verifique se o parâmetro apenas_ativas está sendo enviado corretamente"
echo "   4. Verifique se o token está sendo enviado no header Authorization"
