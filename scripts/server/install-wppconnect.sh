#!/bin/bash
#
# Script de Instalação do WPPConnect Server
# Arquitetura Multi-Aplicação
#
# Autor: DeBrief Team
# Data: 23/11/2025
#

set -e  # Parar em caso de erro

echo "🚀 Iniciando instalação do WPPConnect Server..."
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Criar estrutura de diretórios
echo -e "${YELLOW}📁 Criando estrutura de diretórios...${NC}"
mkdir -p /var/wppconnect/{data,tokens,logs}
cd /var/wppconnect

# 2. Gerar secrets e tokens
echo -e "${YELLOW}🔐 Gerando secrets e tokens seguros...${NC}"
SECRET_KEY="debrief-wpp-secret-$(openssl rand -hex 16)"
DEBRIEF_TOKEN="debrief-wpp-token-$(openssl rand -hex 16)"

# 3. Criar arquivo .env
echo -e "${YELLOW}⚙️  Criando arquivo .env...${NC}"
cat > .env << EOF
# WPPConnect Server Configuration
# Gerado automaticamente em $(date)

# Secret para criptografia
SECRET_KEY=${SECRET_KEY}

# Webhook para notificações (opcional)
WEBHOOK_URL=

# Ambiente
NODE_ENV=production

# Configurações de segurança
MAX_LISTENERS=15
AUTO_CLOSE=0
LOG_LEVEL=info
EOF

chmod 600 .env

# 4. Criar token do DeBrief
echo -e "${YELLOW}🎫 Criando token do DeBrief...${NC}"
echo "${DEBRIEF_TOKEN}" > tokens/debrief.token
chmod 600 tokens/debrief.token

# 5. Criar docker-compose.yml
echo -e "${YELLOW}🐳 Criando docker-compose.yml...${NC}"
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  wppconnect:
    image: wppconnect/wppconnect-server:latest
    container_name: wppconnect-server
    hostname: wppconnect
    restart: always
    ports:
      - "21465:21465"
    environment:
      # Configurações básicas
      - PORT=21465
      - HOST=0.0.0.0
      
      # Secret para criptografia
      - SECRET_KEY=${SECRET_KEY}
      
      # Habilitar múltiplas sessões
      - MAX_LISTENERS=15
      
      # Webhook (opcional)
      - WEBHOOK_URL=${WEBHOOK_URL:-}
      
      # Auto-close após inatividade (desabilitado)
      - AUTO_CLOSE=0
      
      # Logs
      - LOG_LEVEL=info
      
    volumes:
      # Persistência de dados das sessões
      - ./data:/usr/src/app/userDataDir
      
      # Tokens de autenticação
      - ./tokens:/usr/src/app/tokens
      
      # Logs
      - ./logs:/usr/src/app/logs
      
    networks:
      - wppconnect-network
      - debrief_default
      
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:21465/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    labels:
      - "com.wppconnect.description=WPPConnect Server - Multi App"
      - "com.wppconnect.version=latest"

networks:
  wppconnect-network:
    driver: bridge
  debrief_default:
    external: true
EOF

# 6. Baixar imagem Docker
echo -e "${YELLOW}📦 Baixando imagem Docker do WPPConnect...${NC}"
docker pull wppconnect/wppconnect-server:latest

# 7. Iniciar WPPConnect
echo -e "${YELLOW}🚀 Iniciando WPPConnect Server...${NC}"
docker-compose up -d

# 8. Aguardar inicialização
echo -e "${YELLOW}⏳ Aguardando inicialização (30s)...${NC}"
sleep 30

# 9. Verificar se está rodando
echo -e "${YELLOW}✅ Verificando status do container...${NC}"
if docker ps | grep -q wppconnect-server; then
    echo -e "${GREEN}✅ WPPConnect Server está rodando!${NC}"
else
    echo -e "${RED}❌ Erro: Container não está rodando${NC}"
    docker logs wppconnect-server --tail 50
    exit 1
fi

# 10. Testar health check
echo -e "${YELLOW}🏥 Testando health check...${NC}"
sleep 5
if curl -f http://localhost:21465/api/health 2>/dev/null; then
    echo -e "${GREEN}✅ Health check OK!${NC}"
else
    echo -e "${RED}❌ Health check falhou${NC}"
    exit 1
fi

# 11. Configurar Caddy
echo -e "${YELLOW}🌐 Configurando Caddy...${NC}"

# Backup do Caddyfile
cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)

# Adicionar configuração WPPConnect
cat >> /etc/caddy/Caddyfile << 'CADDY_EOF'

# WPPConnect Server - Multi Application
wpp.interce.com.br {
    reverse_proxy localhost:21465
    
    # Logs
    log {
        output file /var/log/caddy/wppconnect.log
        format json
    }
    
    # Headers de segurança e CORS
    header {
        # CORS para permitir acesso das aplicações
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization"
        
        # Segurança
        Strict-Transport-Security "max-age=31536000;"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
    }
    
    # Handle OPTIONS requests para CORS
    @options {
        method OPTIONS
    }
    handle @options {
        respond 200
    }
}
CADDY_EOF

# 12. Recarregar Caddy
echo -e "${YELLOW}🔄 Recarregando Caddy...${NC}"
systemctl reload caddy

if systemctl is-active --quiet caddy; then
    echo -e "${GREEN}✅ Caddy recarregado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao recarregar Caddy${NC}"
    exit 1
fi

# 13. Criar arquivo README
cat > README.md << 'README_EOF'
# WPPConnect Server - Multi Application

## 📍 Localização
```
/var/wppconnect/
```

## 🌐 Acesso
```
URL Externa: https://wpp.interce.com.br
URL Interna: http://localhost:21465
```

## 🔑 Credenciais

### Token DeBrief
Arquivo: `/var/wppconnect/tokens/debrief.token`

### Secret Key
Arquivo: `/var/wppconnect/.env`

## 📋 Comandos Úteis

### Gerenciamento do Container
```bash
# Ver status
docker ps | grep wppconnect

# Ver logs
docker logs wppconnect-server -f

# Reiniciar
cd /var/wppconnect && docker-compose restart

# Parar
cd /var/wppconnect && docker-compose stop

# Iniciar
cd /var/wppconnect && docker-compose up -d

# Ver uso de recursos
docker stats wppconnect-server
```

### Gerenciamento de Instâncias

```bash
# Listar todas as sessões
curl http://localhost:21465/api/sessions

# Verificar sessão específica
curl http://localhost:21465/api/debrief-instance/status

# Gerar QR Code para nova sessão
curl http://localhost:21465/api/debrief-instance/start-session
```

### Backup

```bash
# Backup completo
cd /var
tar -czf wppconnect-backup-$(date +%Y%m%d).tar.gz wppconnect/

# Backup apenas dados
cd /var/wppconnect
tar -czf data-backup-$(date +%Y%m%d).tar.gz data/
```

### Adicionar Nova Aplicação

```bash
# 1. Gerar novo token
TOKEN=$(openssl rand -hex 16)
echo "app2-wpp-token-${TOKEN}" > /var/wppconnect/tokens/app2.token
chmod 600 /var/wppconnect/tokens/app2.token

# 2. Mostrar token
cat /var/wppconnect/tokens/app2.token

# 3. Configurar na aplicação
# WPP_URL=https://wpp.interce.com.br
# WPP_INSTANCE=app2-instance
# WPP_TOKEN=(token gerado acima)
```

## 🔍 Monitoramento

### Logs
```bash
# Logs do WPPConnect
docker logs wppconnect-server --tail 100 -f

# Logs do Caddy
tail -f /var/log/caddy/wppconnect.log

# Logs das sessões
tail -f /var/wppconnect/logs/*.log
```

### Health Check
```bash
# Local
curl http://localhost:21465/api/health

# Externo
curl https://wpp.interce.com.br/api/health
```

## 🚨 Troubleshooting

### Container não inicia
```bash
docker logs wppconnect-server
docker-compose down
docker-compose up -d
```

### Sessão desconecta
```bash
# Reiniciar sessão
curl http://localhost:21465/api/debrief-instance/close-session
curl http://localhost:21465/api/debrief-instance/start-session
```

### Limpar sessões antigas
```bash
cd /var/wppconnect
docker-compose down
rm -rf data/*
docker-compose up -d
```

## 📊 Estrutura de Arquivos

```
/var/wppconnect/
├── docker-compose.yml          # Configuração do container
├── .env                         # Variáveis de ambiente
├── README.md                    # Esta documentação
├── tokens/                      # Tokens de autenticação
│   ├── debrief.token           # Token do DeBrief
│   ├── app2.token              # Token App 2 (futuro)
│   └── app3.token              # Token App 3 (futuro)
├── data/                        # Dados das sessões WhatsApp
│   ├── debrief-instance/
│   ├── app2-instance/
│   └── app3-instance/
└── logs/                        # Logs das aplicações
```

## 🔐 Segurança

- Tokens únicos por aplicação
- Comunicação HTTPS via Caddy
- Rede Docker isolada
- Volumes com permissões restritas
- CORS configurado
- Headers de segurança

## 📱 Instâncias Suportadas

Cada aplicação pode ter sua própria instância (número WhatsApp):

1. **debrief-instance** → DeBrief
2. **app2-instance** → Aplicação 2
3. **app3-instance** → Aplicação 3
4. ... e assim por diante

Cada instância é completamente isolada das outras.

---

**Instalado em:** $(date)
**Versão:** 1.0
README_EOF

# 14. Salvar informações de instalação
cat > INSTALACAO.txt << INFO_EOF
============================================
  INSTALAÇÃO WPPCONNECT - INFORMAÇÕES
============================================

Data: $(date)
Servidor: $(hostname)
IP: $(hostname -I | awk '{print $1}')

ACESSOS:
========
URL Externa: https://wpp.interce.com.br
URL Interna: http://localhost:21465

CREDENCIAIS DEBRIEF:
====================
Instância: debrief-instance
Token: ${DEBRIEF_TOKEN}

Secret Key: ${SECRET_KEY}

ARQUIVOS IMPORTANTES:
=====================
Token: /var/wppconnect/tokens/debrief.token
Env: /var/wppconnect/.env
Docker: /var/wppconnect/docker-compose.yml

COMANDOS ÚTEIS:
===============
Ver logs: docker logs wppconnect-server -f
Status: docker ps | grep wppconnect
Reiniciar: cd /var/wppconnect && docker-compose restart
Health: curl http://localhost:21465/api/health

PRÓXIMOS PASSOS:
================
1. Configurar DNS no Cloudflare: wpp.interce.com.br → 82.25.92.217
2. Aguardar propagação DNS (5-10 minutos)
3. Acessar: https://wpp.interce.com.br/api/health
4. Conectar WhatsApp: https://wpp.interce.com.br/api/debrief-instance/start-session
5. Configurar no DeBrief backend (.env):
   WPP_URL=https://wpp.interce.com.br
   WPP_INSTANCE=debrief-instance
   WPP_TOKEN=${DEBRIEF_TOKEN}

============================================
INFO_EOF

chmod 600 INSTALACAO.txt

# 15. Mostrar resumo
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   ✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}📍 INFORMAÇÕES IMPORTANTES:${NC}"
echo ""
echo "🌐 URL Externa: https://wpp.interce.com.br"
echo "🏠 URL Interna: http://localhost:21465"
echo ""
echo "🔑 Instância DeBrief: debrief-instance"
echo "🎫 Token DeBrief: ${DEBRIEF_TOKEN}"
echo ""
echo -e "${YELLOW}📝 PRÓXIMOS PASSOS:${NC}"
echo ""
echo "1. Configure no Cloudflare:"
echo "   Tipo: A"
echo "   Nome: wpp"
echo "   Conteúdo: 82.25.92.217"
echo "   Proxy: ❌ DESATIVADO"
echo ""
echo "2. Aguarde propagação DNS (5-10 minutos)"
echo ""
echo "3. Teste o acesso:"
echo "   curl https://wpp.interce.com.br/api/health"
echo ""
echo "4. Configure no DeBrief (.env):"
echo "   WPP_URL=https://wpp.interce.com.br"
echo "   WPP_INSTANCE=debrief-instance"
echo "   WPP_TOKEN=${DEBRIEF_TOKEN}"
echo ""
echo -e "${GREEN}✅ Todas as informações foram salvas em:${NC}"
echo "   /var/wppconnect/INSTALACAO.txt"
echo "   /var/wppconnect/README.md"
echo ""
echo -e "${YELLOW}📋 Ver logs:${NC} docker logs wppconnect-server -f"
echo ""

