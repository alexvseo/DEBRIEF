#!/bin/bash

# Script de Diagnóstico - Erro 502 Bad Gateway
# Execute no servidor para diagnosticar problemas de proxy

echo "=========================================="
echo "🔍 DIAGNÓSTICO 502 BAD GATEWAY - DeBrief"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar containers
echo "1️⃣  Verificando containers Docker..."
echo "----------------------------------------"
docker-compose ps
echo ""

# 2. Verificar se backend está rodando
echo "2️⃣  Verificando se backend está rodando..."
echo "----------------------------------------"
BACKEND_RUNNING=$(docker-compose ps backend | grep -c "Up")
if [ "$BACKEND_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✅ Container backend está rodando${NC}"
else
    echo -e "${RED}❌ Container backend NÃO está rodando${NC}"
    echo "   Execute: docker-compose up -d backend"
    exit 1
fi

# Verificar health do backend
BACKEND_HEALTH=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null)
if [ "$BACKEND_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✅ Backend está healthy${NC}"
elif [ "$BACKEND_HEALTH" = "unhealthy" ]; then
    echo -e "${RED}❌ Backend está unhealthy${NC}"
    echo "   Verifique os logs: docker-compose logs backend"
elif [ "$BACKEND_HEALTH" = "starting" ]; then
    echo -e "${YELLOW}⚠️  Backend ainda está iniciando...${NC}"
else
    echo -e "${YELLOW}⚠️  Status do backend: $BACKEND_HEALTH${NC}"
fi
echo ""

# 3. Verificar se backend responde diretamente
echo "3️⃣  Testando conexão direta com backend..."
echo "----------------------------------------"
BACKEND_IP=$(docker inspect debrief-backend --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
if [ -n "$BACKEND_IP" ]; then
    echo "   IP do backend: $BACKEND_IP"
    BACKEND_DIRECT=$(docker-compose exec -T backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
    if [ "$BACKEND_DIRECT" = "200" ]; then
        echo -e "${GREEN}✅ Backend responde diretamente (HTTP $BACKEND_DIRECT)${NC}"
    else
        echo -e "${RED}❌ Backend NÃO responde diretamente (HTTP $BACKEND_DIRECT)${NC}"
        echo "   Verifique os logs: docker-compose logs backend"
    fi
else
    echo -e "${RED}❌ Não foi possível obter IP do backend${NC}"
fi
echo ""

# 4. Verificar rede Docker
echo "4️⃣  Verificando rede Docker..."
echo "----------------------------------------"
NETWORK_EXISTS=$(docker network ls | grep -c "debrief-network")
if [ "$NETWORK_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✅ Rede debrief-network existe${NC}"
    
    # Verificar se ambos containers estão na mesma rede
    BACKEND_IN_NETWORK=$(docker inspect debrief-backend --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' | grep -c "debrief-network")
    FRONTEND_IN_NETWORK=$(docker inspect debrief-frontend --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' | grep -c "debrief-network")
    
    if [ "$BACKEND_IN_NETWORK" -gt 0 ] && [ "$FRONTEND_IN_NETWORK" -gt 0 ]; then
        echo -e "${GREEN}✅ Ambos containers estão na mesma rede${NC}"
    else
        echo -e "${RED}❌ Containers não estão na mesma rede${NC}"
        echo "   Backend na rede: $BACKEND_IN_NETWORK"
        echo "   Frontend na rede: $FRONTEND_IN_NETWORK"
    fi
else
    echo -e "${RED}❌ Rede debrief-network NÃO existe${NC}"
    echo "   Execute: docker-compose up -d"
fi
echo ""

# 5. Testar conexão do frontend para backend
echo "5️⃣  Testando conexão do frontend para backend..."
echo "----------------------------------------"
FRONTEND_TO_BACKEND=$(docker-compose exec -T frontend wget -qO- --timeout=5 http://backend:8000/health 2>/dev/null | grep -o "healthy" || echo "FAILED")
if [ "$FRONTEND_TO_BACKEND" = "healthy" ]; then
    echo -e "${GREEN}✅ Frontend consegue conectar ao backend${NC}"
else
    echo -e "${RED}❌ Frontend NÃO consegue conectar ao backend${NC}"
    echo "   Teste manual: docker-compose exec frontend wget -O- http://backend:8000/health"
fi
echo ""

# 6. Verificar logs do nginx
echo "6️⃣  Verificando logs do nginx (últimas 10 linhas)..."
echo "----------------------------------------"
docker-compose logs --tail=10 frontend | grep -i "error\|502\|upstream\|backend" || echo "   Nenhum erro recente encontrado"
echo ""

# 7. Verificar logs do backend
echo "7️⃣  Verificando logs do backend (últimas 10 linhas)..."
echo "----------------------------------------"
docker-compose logs --tail=10 backend | tail -10
echo ""

# 8. Testar proxy do nginx
echo "8️⃣  Testando proxy do nginx..."
echo "----------------------------------------"
PROXY_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null)
if [ "$PROXY_TEST" = "200" ]; then
    echo -e "${GREEN}✅ Proxy do nginx está funcionando (HTTP $PROXY_TEST)${NC}"
elif [ "$PROXY_TEST" = "502" ]; then
    echo -e "${RED}❌ Proxy retorna 502 Bad Gateway${NC}"
    echo "   Isso significa que o nginx não consegue conectar ao backend"
    echo "   Possíveis causas:"
    echo "   - Backend não está rodando"
    echo "   - Backend não está na mesma rede Docker"
    echo "   - Backend não está respondendo na porta 8000"
    echo "   - Nome do serviço 'backend' não está resolvendo"
else
    echo -e "${YELLOW}⚠️  Proxy retornou HTTP $PROXY_TEST${NC}"
fi
echo ""

# 9. Verificar resolução DNS do nome 'backend'
echo "9️⃣  Verificando resolução DNS do nome 'backend'..."
echo "----------------------------------------"
BACKEND_RESOLVE=$(docker-compose exec -T frontend nslookup backend 2>/dev/null | grep -o "Address: [0-9.]*" | head -1 || echo "FAILED")
if [ "$BACKEND_RESOLVE" != "FAILED" ]; then
    echo -e "${GREEN}✅ Nome 'backend' resolve para: $BACKEND_RESOLVE${NC}"
else
    echo -e "${RED}❌ Nome 'backend' NÃO resolve${NC}"
    echo "   Isso pode ser o problema! O nginx precisa resolver 'backend' para o IP do container"
fi
echo ""

# 10. Verificar configuração do nginx
echo "🔟 Verificando configuração do nginx..."
echo "----------------------------------------"
NGINX_TEST=$(docker-compose exec -T frontend nginx -t 2>&1)
if echo "$NGINX_TEST" | grep -q "successful"; then
    echo -e "${GREEN}✅ Configuração do nginx está válida${NC}"
else
    echo -e "${RED}❌ Configuração do nginx tem erros:${NC}"
    echo "$NGINX_TEST"
fi
echo ""

echo "=========================================="
echo "✅ Diagnóstico concluído!"
echo "=========================================="
echo ""
echo "📝 Próximos passos baseados no diagnóstico:"
echo ""
if [ "$BACKEND_HEALTH" != "healthy" ]; then
    echo "   1. 🔴 PRIORIDADE: Corrigir backend (está unhealthy)"
    echo "      - docker-compose logs backend"
    echo "      - Verificar se backend iniciou corretamente"
fi
if [ "$FRONTEND_TO_BACKEND" != "healthy" ]; then
    echo "   2. 🔴 PRIORIDADE: Corrigir conectividade entre containers"
    echo "      - docker-compose down"
    echo "      - docker-compose up -d"
fi
if [ "$PROXY_TEST" = "502" ]; then
    echo "   3. 🔴 PRIORIDADE: Proxy retorna 502"
    echo "      - Verificar se backend está rodando: docker-compose ps"
    echo "      - Verificar logs: docker-compose logs backend"
    echo "      - Reiniciar: docker-compose restart backend"
fi
echo ""

