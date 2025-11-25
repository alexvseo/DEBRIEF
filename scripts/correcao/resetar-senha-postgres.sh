#!/bin/bash

# Script para Resetar Senha do PostgreSQL

echo "=================================================="
echo "🔐 RESETANDO SENHA DO POSTGRESQL"
echo "=================================================="
echo ""

SERVER="root@82.25.92.217"

echo "📡 Conectando ao servidor..."

ssh $SERVER << 'ENDSSH'

echo "1️⃣ Verificando senha atual nas variáveis de ambiente"
echo "=================================================="
docker exec debrief_db env | grep POSTGRES_PASSWORD
echo ""

echo "2️⃣ Resetando senha do usuário postgres para: Mslestra@2025db"
echo "=================================================="
docker exec debrief_db psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'Mslestra@2025db';"
echo ""

echo "3️⃣ Verificando se a senha foi alterada (testando conexão)"
echo "=================================================="
docker exec debrief_db sh -c "PGPASSWORD='Mslestra@2025db' psql -U postgres -d dbrief -c 'SELECT COUNT(*) FROM demandas;'"
echo ""

echo "4️⃣ Atualizando .env do backend com a senha correta"
echo "=================================================="
cd /var/www/debrief/backend
sed -i 's|postgresql://postgres:[^@]*@|postgresql://postgres:Mslestra%402025db@|g' .env
grep DATABASE_URL .env | sed 's/:[^@]*@/:***@/g'
echo ""

echo "5️⃣ Reiniciando backend"
echo "=================================================="
cd /var/www/debrief
docker-compose restart backend
echo ""

echo "6️⃣ Aguardando 10 segundos..."
sleep 10
echo ""

echo "7️⃣ Verificando logs do backend"
echo "=================================================="
docker logs debrief-backend --tail 20
echo ""

echo "8️⃣ Testando endpoint de health"
echo "=================================================="
curl -s http://localhost:2023/health
echo ""
echo ""

echo "=================================================="
echo "✅ SENHA RESETADA COM SUCESSO!"
echo "=================================================="
echo ""
echo "Nova senha: Mslestra@2025db"

ENDSSH

echo ""
echo "💡 Teste no navegador: http://debrief.interce.com.br"



