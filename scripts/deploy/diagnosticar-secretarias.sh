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

echo "2️⃣  Testando endpoint diretamente no backend (apenas_ativas=false)..."
echo ""
# Obter token (se disponível)
TOKEN=""
if [ -f "/tmp/debrief_token.txt" ]; then
    TOKEN=$(cat /tmp/debrief_token.txt)
fi

if [ -n "$TOKEN" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -H "Authorization: Bearer $TOKEN" "http://localhost:8000/api/secretarias/?apenas_ativas=false&limit=10000")
else
    echo "   ⚠️  Token não encontrado, testando sem autenticação (pode falhar)"
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

echo "3️⃣  Testando endpoint via Caddy (apenas_ativas=false)..."
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

echo "4️⃣  Verificando logs do backend (últimas 20 linhas com 'secretaria')..."
echo ""
docker-compose logs backend | grep -i "secretaria" | tail -20 || echo "   Nenhum log encontrado"
echo ""

echo "✅ Diagnóstico concluído"
echo ""
echo "💡 Se o endpoint retornar dados mas o frontend não mostrar:"
echo "   1. Verifique o console do navegador (F12)"
echo "   2. Verifique se há erros de CORS ou autenticação"
echo "   3. Verifique se o parâmetro apenas_ativas está sendo enviado corretamente"
