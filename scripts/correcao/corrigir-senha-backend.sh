#!/bin/bash

# Script para Corrigir Senha do Banco no Backend
# Corrige a DATABASE_URL com a senha correta

echo "=================================================="
echo "🔧 CORRIGINDO SENHA DO BANCO NO BACKEND"
echo "=================================================="
echo ""

SERVER="root@82.25.92.217"
APP_DIR="/var/www/debrief"

echo "📡 Conectando ao servidor..."

ssh $SERVER << 'ENDSSH'

cd /var/www/debrief/backend

echo "1️⃣ Backup do arquivo .env atual"
echo "=================================================="
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup criado"
echo ""

echo "2️⃣ Verificando senha atual"
echo "=================================================="
echo "Senha atual (mascarada):"
grep DATABASE_URL .env | sed 's/:[^@]*@/:***@/g'
echo ""

echo "3️⃣ Corrigindo senha no arquivo .env"
echo "=================================================="
# Corrige a senha: Mslestra@2025 -> Mslestra@2025db
sed -i 's|postgresql://postgres:Mslestra%402025@|postgresql://postgres:Mslestra%402025db@|g' .env

echo "Nova configuração (mascarada):"
grep DATABASE_URL .env | sed 's/:[^@]*@/:***@/g'
echo ""

echo "4️⃣ Reiniciando container do backend"
echo "=================================================="
cd /var/www/debrief
docker-compose restart backend
echo ""

echo "5️⃣ Aguardando 10 segundos para o backend iniciar..."
sleep 10
echo ""

echo "6️⃣ Verificando logs do backend"
echo "=================================================="
docker logs debrief-backend --tail 20
echo ""

echo "7️⃣ Testando conexão do backend"
echo "=================================================="
curl -s http://localhost:2023/health
echo ""
echo ""

echo "8️⃣ Tentando fazer login teste"
echo "=================================================="
curl -s -X POST http://localhost:2023/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' | head -c 500
echo ""
echo ""

echo "=================================================="
echo "✅ CORREÇÃO CONCLUÍDA!"
echo "=================================================="
echo ""
echo "🌐 Teste no navegador: http://debrief.interce.com.br"

ENDSSH

echo ""
echo "💡 Correção aplicada!"
echo ""
echo "Se ainda houver problemas, verifique:"
echo "  1. Firewall do servidor"
echo "  2. Configuração do Caddy/Nginx"
echo "  3. DNS do domínio debrief.interce.com.br"

