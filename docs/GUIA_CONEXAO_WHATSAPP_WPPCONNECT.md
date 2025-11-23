# 📱 Guia de Conexão WhatsApp - WPPConnect/Evolution API

**Data da Configuração:** 23 de Novembro de 2025  
**Status:** Infraestrutura 100% configurada - Aguardando conexão WhatsApp

---

## ✅ **O QUE JÁ ESTÁ CONFIGURADO**

### 🖥️ **No Servidor VPS (82.25.92.217)**

#### **1. Evolution API v2.1.1**
- ✅ Instalada e funcionando
- ✅ MySQL 8 como banco de dados
- ✅ Porta: 21465 (interna)
- ✅ SSL configurado via Caddy
- ✅ Acessível via: **https://wpp.interce.com.br**

#### **2. Caddy Reverse Proxy**
- ✅ SSL automático (Let's Encrypt)
- ✅ Domínio: `wpp.interce.com.br`
- ✅ Proxy para `localhost:21465`
- ✅ Configuração em: `/root/caddy/sites/wpp.caddy`

#### **3. Instância WhatsApp**
- ✅ Nome: `debrief`
- ✅ Tipo: WHATSAPP-BAILEYS
- ✅ Status: Disconnected (aguardando QR Code)
- ✅ Número configurado: `5585991042626`

#### **4. DeBrief Backend**
- ✅ Porta: 2023
- ✅ Frontend: 2022
- ✅ Variáveis configuradas em: `/var/www/debrief/backend/.env`

### 💾 **Banco de Dados**

#### **Tabelas Criadas:**
1. ✅ `users` - Campos `whatsapp` e `receber_notificacoes` adicionados
2. ✅ `configuracoes_whatsapp` - Configurações do remetente
3. ✅ `templates_mensagens` - Templates de notificações
4. ✅ `notification_logs` - Histórico de envios

---

## 🔑 **CREDENCIAIS E ACESSOS**

### **Evolution API Manager**
```
URL Manager: https://wpp.interce.com.br/manager
Server URL: https://wpp.interce.com.br
API Key Global: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
```

### **DeBrief - Configuração WhatsApp**
```
URL Frontend: https://debrief.interce.com.br
Área Admin: https://debrief.interce.com.br/admin/configuracao-whatsapp
Configurações:
  - WPP_URL: https://wpp.interce.com.br
  - WPP_INSTANCE: debrief
  - WPP_TOKEN: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
```

### **Número WhatsApp Remetente**
```
Número: 5585991042626
```

---

## 📋 **COMO CONECTAR O WHATSAPP (APÓS 1 HORA)**

### **Passo 1: Acessar o Manager**
1. Abra no navegador: **https://wpp.interce.com.br/manager**
2. Faça login com:
   - **Server URL**: `https://wpp.interce.com.br`
   - **API Key Global**: `debrief-wpp-58a2b7dda7da9474958e2a853062d5d5`

### **Passo 2: Gerar QR Code**
1. Na lista de instâncias, localize **"debrief"**
2. Clique no botão **"Get QR Code"** (laranja)
3. **AGUARDE 10-15 SEGUNDOS** com o modal aberto
4. O QR Code deve aparecer

### **Passo 3: Escanear com WhatsApp**
1. Abra o WhatsApp no celular (número `5585991042626`)
2. Vá em **Configurações** → **Aparelhos conectados**
3. Toque em **"Conectar um aparelho"**
4. Escaneie o QR Code que apareceu no Manager

### **Passo 4: Verificar Conexão**
1. No Manager, o status deve mudar para **"Connected"** (verde)
2. Aparecerão informações do número conectado
3. No DeBrief, acesse: `https://debrief.interce.com.br/admin/configuracao-whatsapp`
4. Clique em **"Testar Conexão"** para enviar mensagem de teste

---

## 🔧 **TROUBLESHOOTING**

### ⚠️ **Se o QR Code não aparecer:**

#### **Opção 1: Aguardar mais tempo**
- Deixe o modal aberto por 30-60 segundos
- O Baileys precisa inicializar completamente

#### **Opção 2: Reiniciar a instância**
1. Feche o modal (X verde)
2. Clique em **"RESTART"**
3. Aguarde 5 segundos
4. Clique novamente em **"Get QR Code"**

#### **Opção 3: Recriar a instância**
```bash
# Via SSH no servidor
ssh debrief
curl -X DELETE 'http://localhost:21465/instance/delete/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5'

curl -X POST http://localhost:21465/instance/create \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' \
  -H 'Content-Type: application/json' \
  -d '{"instanceName": "debrief", "integration": "WHATSAPP-BAILEYS"}'
```

#### **Opção 4: Verificar logs**
```bash
# Ver logs em tempo real
ssh debrief
docker logs wppconnect-server --tail 100 --follow
```

### ⚠️ **Se aparecer "Connection Failure" nos logs:**
- WhatsApp pode estar bloqueando temporariamente
- Aguarde 1-2 horas antes de tentar novamente
- Evite múltiplas tentativas seguidas

### ⚠️ **Se o status ficar "Disconnected":**
1. Clique em **"RESTART"** no Manager
2. Aguarde a instância reiniciar
3. Tente gerar novo QR Code

---

## 📂 **ARQUIVOS DE CONFIGURAÇÃO**

### **No Servidor (VPS)**

#### **Evolution API**
```bash
# Docker Compose
/root/wppconnect/docker-compose.yml

# Instâncias
/var/lib/docker/volumes/wppconnect-instances/_data/

# Logs
docker logs wppconnect-server
```

#### **Caddy**
```bash
# Configuração WPPConnect
/root/caddy/sites/wpp.caddy

# Configuração DeBrief
/root/caddy/sites/debrief.caddy

# Reload Caddy
docker exec caddy-global caddy reload --config /etc/caddy/Caddyfile
```

#### **DeBrief Backend**
```bash
# Variáveis de ambiente
/var/www/debrief/backend/.env

# Docker Compose
/var/www/debrief/docker-compose.yml

# Reiniciar backend
cd /var/www/debrief && docker-compose restart backend
```

### **No Projeto Local**

#### **Backend**
```bash
# .env local
backend/.env
  PORT=2023
  WPP_URL=https://wpp.interce.com.br
  WPP_INSTANCE=debrief
  WPP_TOKEN=debrief-wpp-58a2b7dda7da9474958e2a853062d5d5

# Serviços
backend/app/services/whatsapp.py
backend/app/services/notification_whatsapp.py

# Endpoints
backend/app/api/endpoints/whatsapp.py
```

#### **Frontend**
```bash
# Páginas de configuração
frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx
frontend/src/pages/admin/TemplatesWhatsApp.jsx
frontend/src/pages/admin/HistoricoNotificacoes.jsx

# Rotas
frontend/src/App.jsx
```

---

## 🔍 **COMANDOS ÚTEIS**

### **Verificar Status Evolution API**
```bash
# Testar API
curl -s https://wpp.interce.com.br/ | jq .

# Listar instâncias
curl -s 'http://localhost:21465/instance/fetchInstances' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' | jq .

# Status da instância debrief
curl -s 'http://localhost:21465/instance/fetchInstances?instanceName=debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' | jq .
```

### **Gerenciar Containers**
```bash
# Status dos containers
ssh debrief "docker ps | grep -E 'wppconnect|debrief'"

# Logs Evolution API
ssh debrief "docker logs wppconnect-server --tail 50"

# Reiniciar Evolution API
ssh debrief "cd /root/wppconnect && docker-compose restart evolution-api"

# Reiniciar DeBrief
ssh debrief "cd /var/www/debrief && docker-compose restart backend frontend"
```

### **Verificar Portas**
```bash
# Verificar portas em uso
ssh debrief "lsof -i :2022 -i :2023 -i :21465 2>&1 | head -10"

# Testar conexões
curl -I https://debrief.interce.com.br
curl -I https://wpp.interce.com.br
```

---

## 🌐 **CONFIGURAÇÃO DNS (Cloudflare)**

### **Registros Configurados:**
```
Tipo: A
Nome: wpp
Conteúdo: 82.25.92.217
Proxy: Desativado (nuvem CINZA ☁️)
TTL: Auto

Tipo: A
Nome: debrief
Conteúdo: 82.25.92.217
Proxy: Ativo (nuvem LARANJA 🟠)
TTL: Auto
```

**IMPORTANTE:** O registro `wpp` deve estar com **proxy DESATIVADO** (nuvem cinza) para evitar erro 525 SSL.

---

## 📊 **STATUS ATUAL**

### ✅ **Funcionando:**
- Evolution API v2.1.1 ativa e respondendo
- MySQL 8 rodando com banco `evolution`
- Caddy com SSL válido para `wpp.interce.com.br`
- Manager acessível via HTTPS
- Instância `debrief` criada
- Backend DeBrief configurado com variáveis WPPConnect
- Frontend com interfaces de configuração
- Banco de dados PostgreSQL com tabelas de notificações

### ⏳ **Pendente:**
- Conexão WhatsApp via QR Code (aguardando liberação do WhatsApp)
- Primeiro teste de envio de mensagem

### ⚠️ **Bloqueio Temporário:**
- WhatsApp está bloqueando tentativas de conexão (Connection Failure)
- Recomendado aguardar 1-2 horas antes de nova tentativa
- Evitar múltiplas tentativas seguidas

---

## 📝 **NOTAS IMPORTANTES**

### **Sobre o Baileys:**
- É uma biblioteca não oficial para WhatsApp Web
- Pode ter instabilidades temporárias
- WhatsApp pode bloquear tentativas excessivas
- Aguardar intervalo entre tentativas é recomendado

### **Sobre os Logs DEBUG:**
- Logs estão configurados em nível DEBUG
- Úteis para troubleshooting
- Geram muito volume (podem ser reduzidos para ERROR depois)

### **Sobre o Redis:**
- Erros de Redis nos logs podem ser ignorados
- Redis é opcional na Evolution API
- Não afeta funcionamento do WhatsApp

---

## 🚀 **PRÓXIMOS PASSOS (APÓS CONEXÃO)**

1. **Configurar no DeBrief:**
   - Acessar `https://debrief.interce.com.br/admin/configuracao-whatsapp`
   - Preencher dados do remetente
   - Salvar configuração

2. **Criar Templates:**
   - Acessar `https://debrief.interce.com.br/admin/templates-whatsapp`
   - Criar templates para:
     - Nova demanda
     - Demanda atualizada
     - Demanda concluída
     - Demanda cancelada

3. **Testar Envio:**
   - Na página de configuração, clicar "Testar Conexão"
   - Enviar mensagem de teste
   - Verificar recebimento no WhatsApp

4. **Configurar Usuários:**
   - Adicionar números WhatsApp aos usuários
   - Ativar "Receber Notificações" por usuário
   - Testar notificação individual

---

## 📞 **SUPORTE E DOCUMENTAÇÃO**

### **Documentação Evolution API:**
- Site oficial: https://doc.evolution-api.com
- Repositório: https://github.com/EvolutionAPI/evolution-api

### **Documentação Baileys:**
- Repositório: https://github.com/WhiskeySockets/Baileys

### **Logs e Monitoramento:**
```bash
# Ver logs em tempo real
ssh debrief "docker logs wppconnect-server --follow"

# Verificar saúde dos containers
ssh debrief "docker ps --format 'table {{.Names}}\t{{.Status}}'"

# Espaço em disco
ssh debrief "df -h"
```

---

## ⏰ **LEMBRETE**

**AGUARDAR 1 HORA** antes de tentar conectar novamente!

Quando retornar:
1. Leia esta documentação
2. Siga os passos da seção "COMO CONECTAR O WHATSAPP"
3. Se encontrar problemas, consulte a seção "TROUBLESHOOTING"

---

**Documentação criada em:** 23/11/2025  
**Última atualização:** 23/11/2025 às 18:55 (horário do servidor)  
**Versão Evolution API:** 2.1.1  
**Versão Baileys:** Incluída no Evolution API  

---

✅ **Sistema 100% pronto para conexão WhatsApp!**

