#!/bin/bash
# Script para aplicar network_mode: host no servidor
# Resolve conflitos de git e aplica configuração correta

set -e

echo "🔧 Aplicando network_mode: host para backend..."
echo ""

cd /root/debrief || exit 1

# 1. Fazer stash das mudanças locais
echo "1️⃣  Fazendo stash das mudanças locais..."
git stash push -m "Stash antes de aplicar network_mode: host" || true

# 2. Atualizar código
echo ""
echo "2️⃣  Atualizando código do GitHub..."
git pull

# 3. Verificar se network_mode está presente
echo ""
echo "3️⃣  Verificando configuração..."
if grep -q "network_mode: host" docker-compose.yml; then
    echo "✅ network_mode: host encontrado no docker-compose.yml"
else
    echo "❌ network_mode: host NÃO encontrado!"
    echo "   Aplicando manualmente..."
    
    # Aplicar network_mode: host manualmente
    sed -i '/^  backend:/a\    network_mode: host' docker-compose.yml
    
    # Remover ports (não funciona com network_mode: host)
    sed -i '/^    ports:/,/^    # Permitir container/d' docker-compose.yml
    
    # Remover extra_hosts
    sed -i '/^    extra_hosts:/,/^    environment:/d' docker-compose.yml
    
    # Atualizar DATABASE_URL para localhost
    sed -i 's|DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@.*:5432/dbrief|DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief|g' docker-compose.yml
    
    # Remover networks do backend
    sed -i '/^    networks:/d' docker-compose.yml
    
    echo "✅ Configuração aplicada manualmente"
fi

# 4. Verificar DATABASE_URL
echo ""
echo "4️⃣  Verificando DATABASE_URL..."
grep "DATABASE_URL" docker-compose.yml | head -1

# 5. Parar e remover backend
echo ""
echo "5️⃣  Parando e removendo backend..."
docker-compose stop backend 2>/dev/null || true
docker-compose rm -f backend 2>/dev/null || true

# 6. Recriar backend
echo ""
echo "6️⃣  Recriando backend com network_mode: host..."
docker-compose up -d backend

# 7. Aguardar inicialização
echo ""
echo "7️⃣  Aguardando inicialização (20s)..."
sleep 20

# 8. Verificar se container está rodando
echo ""
echo "8️⃣  Verificando status do container..."
docker-compose ps backend

# 9. Testar conexão com banco
echo ""
echo "9️⃣  Testando conexão com banco de dados..."
timeout 15 docker exec debrief-backend python3 -c "
import os
from sqlalchemy import create_engine, text
import sys

db_url = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {db_url[:70]}...')
print()

try:
    engine = create_engine(db_url, connect_args={'connect_timeout': 10})
    print('✅ Engine criado com sucesso')
    
    with engine.connect() as conn:
        print('✅ Conectado ao banco de dados')
        result = conn.execute(text('SELECT current_database()'))
        db_name = result.fetchone()[0]
        print(f'   Banco atual: {db_name}')
        
        result = conn.execute(text('SELECT COUNT(*) FROM users'))
        user_count = result.fetchone()[0]
        print(f'   Usuários na tabela users: {user_count}')
        
        print()
        print('✅ ✅ Teste de conexão concluído com sucesso!')
except Exception as e:
    print(f'❌ Erro ao conectar: {e}', file=sys.stderr)
    sys.exit(1)
" || {
    echo ""
    echo "❌ Erro ao testar conexão"
    echo ""
    echo "📋 Verificando logs do backend..."
    docker-compose logs --tail=30 backend
    exit 1
}

# 10. Reiniciar Caddy
echo ""
echo "🔟 Reiniciando Caddy..."
docker-compose restart caddy
sleep 5

# 11. Testar login diretamente no backend (porta 8000)
echo ""
echo "1️⃣1️⃣  Testando login diretamente no backend (porta 8000)..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" \
  -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$LOGIN_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Login funcionou! HTTP $HTTP_CODE"
    echo "$BODY" | head -3
else
    echo "❌ Login falhou! HTTP $HTTP_CODE"
    echo "Resposta: $BODY"
fi

# 12. Testar login via Caddy (porta 2022)
echo ""
echo "1️⃣2️⃣  Testando login via Caddy (porta 2022)..."
CADDY_RESPONSE=$(curl -s -X POST http://localhost:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" \
  -w "\nHTTP_CODE:%{http_code}")

CADDY_HTTP_CODE=$(echo "$CADDY_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
CADDY_BODY=$(echo "$CADDY_RESPONSE" | grep -v "HTTP_CODE")

if [ "$CADDY_HTTP_CODE" = "200" ]; then
    echo "✅ Login via Caddy funcionou! HTTP $CADDY_HTTP_CODE"
    echo "$CADDY_BODY" | head -3
else
    echo "⚠️  Login via Caddy falhou! HTTP $CADDY_HTTP_CODE"
    echo "Resposta: $CADDY_BODY"
    echo ""
    echo "📋 Verificando logs do Caddy..."
    docker-compose logs --tail=10 caddy
fi

echo ""
echo "✅ ✅ Processo concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Acesse: http://82.25.92.217:2022"
echo "   2. Faça login com: admin / admin123"
echo ""

