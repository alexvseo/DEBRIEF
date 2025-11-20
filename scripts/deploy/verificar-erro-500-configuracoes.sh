#!/bin/bash

# Script para verificar erro 500 no endpoint de configurações

echo "🔍 Verificando erro 500 no endpoint /api/configuracoes/agrupadas"
echo ""

echo "1️⃣  Verificando logs do backend (últimas 50 linhas com erro)..."
echo ""
docker-compose logs backend --tail 100 | grep -iE "(error|exception|traceback|500|configuracao)" | tail -50
echo ""

echo "2️⃣  Testando endpoint diretamente..."
echo ""
# Obter token
TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || echo "")

if [ -z "$TOKEN" ]; then
    echo "   ⚠️  Não foi possível obter token. Tentando com usuário do banco..."
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
        TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
          -H "Content-Type: application/json" \
          -d "{\"username\":\"$USERNAME\",\"password\":\"admin123\"}" | \
          python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || echo "")
    fi
fi

if [ -n "$TOKEN" ]; then
    echo "   ✅ Token obtido"
    echo ""
    echo "   Testando endpoint /api/configuracoes/agrupadas..."
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
      -H "Authorization: Bearer $TOKEN" \
      "http://localhost:8000/api/configuracoes/agrupadas")
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')
    
    echo "   Status: $HTTP_CODE"
    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ✅ Endpoint funcionou!"
        COUNT=$(echo "$BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
        echo "   Retornou $COUNT grupo(s) de configurações"
    else
        echo "   ❌ Endpoint retornou erro $HTTP_CODE"
        echo "   Resposta:"
        echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY" | head -20
    fi
else
    echo "   ❌ Não foi possível obter token"
fi
echo ""

echo "3️⃣  Verificando configurações no banco de dados..."
echo ""
docker-compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models import Configuracao, TipoConfiguracao
from sqlalchemy import text

db = SessionLocal()
try:
    # Usar query SQL direta para evitar problemas com enum
    total = db.execute(text('SELECT COUNT(*) FROM configuracoes')).scalar()
    print(f'   Total de configurações: {total}')
    
    # Contar por tipo usando SQL direto
    print()
    print('   Configurações por tipo (via SQL):')
    result = db.execute(text('SELECT tipo, COUNT(*) as total FROM configuracoes GROUP BY tipo ORDER BY tipo'))
    for row in result:
        print(f'     {row[0]}: {row[1]}')
    
    # Listar algumas configurações usando SQL direto
    print()
    print('   Primeiras 5 configurações:')
    result = db.execute(text('SELECT chave, tipo, is_sensivel FROM configuracoes LIMIT 5'))
    for row in result:
        print(f'     - {row[0]} (tipo: {row[1]}, sensível: {row[2]})')
    
    # Tentar carregar via ORM (pode falhar se enum estiver quebrado)
    print()
    print('   Tentando carregar via ORM...')
    try:
        configs = db.query(Configuracao).limit(3).all()
        for c in configs:
            print(f'     ✅ {c.chave} carregada via ORM')
            try:
                valor = c.get_valor()
                print(f'       Valor: {valor[:30] if valor else \"(vazio)\"}...')
            except Exception as e:
                print(f'       ⚠️  Erro ao obter valor: {e}')
    except Exception as e:
        print(f'     ❌ Erro ao carregar via ORM: {e}')
        print(f'     Isso indica que o enum precisa ser convertido para VARCHAR')
finally:
    db.close()
" 2>&1
echo ""

echo "4️⃣  Verificando variável de ambiente ENCRYPTION_KEY..."
echo ""
docker-compose exec -T backend python -c "
import os
key = os.getenv('ENCRYPTION_KEY')
if key:
    print(f'   ✅ ENCRYPTION_KEY está configurada (tamanho: {len(key)})')
else:
    print('   ⚠️  ENCRYPTION_KEY não está configurada')
    print('   Isso pode causar problemas ao descriptografar valores sensíveis')
" 2>&1
echo ""

echo "✅ Verificação concluída"
echo ""
echo "💡 Se o erro persistir:"
echo "   1. Verifique os logs completos: docker-compose logs backend --tail 200"
echo "   2. Verifique se ENCRYPTION_KEY está configurada no docker-compose.yml"
echo "   3. Verifique se há configurações com valores criptografados corrompidos"

