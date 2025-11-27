#!/bin/bash

# Script para verificar status do Caddy Global no servidor

echo "=========================================="
echo "🔍 VERIFICANDO CADDY GLOBAL"
echo "=========================================="
echo ""

SERVER="root@82.25.92.217"

ssh $SERVER << 'ENDSSH'
    echo "1️⃣  VERIFICANDO CONTAINER CADDY GLOBAL"
    echo "=========================================="
    docker ps -a | grep caddy || echo "⚠️  Nenhum container Caddy encontrado"
    echo ""
    
    echo "2️⃣  VERIFICANDO PROCESSO CADDY"
    echo "=========================================="
    ps aux | grep caddy | grep -v grep || echo "⚠️  Nenhum processo Caddy encontrado"
    echo ""
    
    echo "3️⃣  VERIFICANDO PORTAS 80 E 443"
    echo "=========================================="
    echo "Porta 80:"
    netstat -tlnp 2>/dev/null | grep ":80 " || ss -tlnp 2>/dev/null | grep ":80 " || echo "❌ Porta 80 não está aberta"
    echo ""
    echo "Porta 443:"
    netstat -tlnp 2>/dev/null | grep ":443" || ss -tlnp 2>/dev/null | grep ":443" || echo "❌ Porta 443 não está aberta"
    echo ""
    
    echo "4️⃣  VERIFICANDO DIRETÓRIO /root/caddy"
    echo "=========================================="
    if [ -d "/root/caddy" ]; then
        echo "✅ Diretório existe"
        ls -la /root/caddy/ | head -10
        echo ""
        
        echo "5️⃣  VERIFICANDO DOCKER COMPOSE DO CADDY"
        echo "=========================================="
        if [ -f "/root/caddy/docker-compose.yml" ]; then
            echo "✅ docker-compose.yml encontrado"
            cd /root/caddy
            docker-compose ps 2>/dev/null || docker compose ps 2>/dev/null || echo "⚠️  Erro ao verificar status"
        else
            echo "❌ docker-compose.yml não encontrado"
        fi
        echo ""
        
        echo "6️⃣  LOGS DO CADDY GLOBAL (últimas 30 linhas)"
        echo "=========================================="
        docker logs caddy-global --tail 30 2>&1 || echo "⚠️  Container caddy-global não encontrado ou sem logs"
        echo ""
    else
        echo "❌ Diretório /root/caddy não existe"
    fi
    
    echo "7️⃣  TESTANDO CONECTIVIDADE HTTPS"
    echo "=========================================="
    echo "Testando https://debrief.interce.com.br:"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" --max-time 5 https://debrief.interce.com.br || echo "❌ Falha ao conectar HTTPS"
    echo ""
    
ENDSSH


