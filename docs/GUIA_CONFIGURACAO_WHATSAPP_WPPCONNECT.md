# 📱 Guia Completo: Configuração WhatsApp + WPPConnect

Este guia explica **passo a passo** como configurar o número remetente WhatsApp e integrar com WPPConnect no sistema DeBrief.

---

## 🎯 Visão Geral

Para enviar mensagens WhatsApp pelo DeBrief, você precisa:

1. ✅ Ter um **WhatsApp Business** ativo
2. ✅ Ter um servidor **WPPConnect** rodando
3. ✅ **Conectar** o WhatsApp ao WPPConnect (QR Code)
4. ✅ **Configurar** no DeBrief (interface web)
5. ✅ **Testar** o envio

---

## 📋 ETAPA 1: Preparar o WPPConnect Server

### Opção A: Usar WPPConnect Cloud (Recomendado) ☁️

#### Provedores Disponíveis:
- **Evolution API** (https://evolution-api.com)
- **WPPConnect Cloud** (https://wppconnect.io)
- **Outros provedores SaaS**

#### Passos:
1. Crie uma conta em um provedor
2. Crie uma nova **instância**
3. Anote as informações:
   ```
   URL: https://seu-servidor.wppconnect.io
   Instância: debrief-instance
   Token: ey...seu-token-aqui...
   ```

### Opção B: Instalar WPPConnect no Servidor Hostinger 🖥️

Se você quer instalar no seu próprio servidor (82.25.92.217):

#### Passo 1: Instalar Node.js no servidor
```bash
ssh root@82.25.92.217
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
node -v  # Verificar instalação
```

#### Passo 2: Instalar WPPConnect Server
```bash
cd /var/www
git clone https://github.com/wppconnect-team/wppconnect-server.git
cd wppconnect-server
npm install
```

#### Passo 3: Configurar
```bash
cp .env.example .env
nano .env
```

**Configuração mínima no .env:**
```env
# Porta do servidor
PORT=21465

# Secret para tokens (gere um aleatório)
SECRET_KEY=debrief-wpp-secret-key-2024

# Host
HOST=0.0.0.0

# Token de autenticação (crie um seguro)
TOKEN=seu-token-super-seguro-aqui
```

#### Passo 4: Iniciar servidor
```bash
# Instalar PM2 para manter rodando
npm install -g pm2

# Iniciar WPPConnect
pm2 start src/index.js --name wppconnect-server

# Salvar configuração
pm2 save
pm2 startup
```

#### Passo 5: Configurar Caddy (Proxy)
```bash
nano /etc/caddy/Caddyfile
```

Adicione:
```caddy
wpp.debrief.interce.com.br.com.br {
    reverse_proxy localhost:21465
}
```

Recarregue Caddy:
```bash
systemctl reload caddy
```

---

## 📱 ETAPA 2: Conectar WhatsApp ao WPPConnect

### Passo 1: Gerar QR Code

Acesse no navegador (substitua com seus dados):

```
https://wpp.debrief.interce.com.br.com.br/api/debrief-instance/start-session
```

Ou se estiver usando provedor cloud:
```
https://seu-servidor.wppconnect.io/api/debrief-instance/start-session
```

**Parâmetros da URL:**
- `debrief-instance` = nome da sua instância

### Passo 2: Escanear QR Code

1. Abra o **WhatsApp Business** no seu celular
2. Vá em: **⚙️ Configurações → Aparelhos conectados**
3. Toque em: **Conectar aparelho**
4. Escaneie o **QR Code** que apareceu no navegador

### Passo 3: Verificar Conexão

Acesse:
```
https://seu-servidor/api/debrief-instance/check-connection-session
```

**Resposta esperada:**
```json
{
  "status": "connected",
  "connected": true,
  "phone": "5585991042626",
  "battery": 100,
  "plugged": true
}
```

✅ Se mostrar `"connected": true`, está pronto!

---

## 🖥️ ETAPA 3: Configurar Variáveis de Ambiente (Backend)

### No Servidor (Produção)

```bash
ssh root@82.25.92.217
cd /var/www/debrief/backend
nano .env
```

Adicione ou edite estas linhas:

```env
# WhatsApp/WPPConnect Integration
WPP_URL=https://wpp.debrief.interce.com.br.com.br
WPP_INSTANCE=debrief-instance
WPP_TOKEN=seu-token-super-seguro-aqui
```

Reinicie o backend:
```bash
cd /var/www/debrief
docker-compose restart backend
```

### No Desenvolvimento Local

```bash
cd /Users/alexsantos/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF/backend
```

Crie ou edite o arquivo `.env`:

```env
# WhatsApp/WPPConnect Integration
WPP_URL=https://wpp.debrief.interce.com.br.com.br
WPP_INSTANCE=debrief-instance
WPP_TOKEN=seu-token-super-seguro-aqui
```

Reinicie o backend local:
```bash
cd ..
docker-compose -f docker-compose.dev.yml restart backend
```

---

## 🎨 ETAPA 4: Configurar na Interface Web do DeBrief

### Passo 1: Acessar Página de Configuração

**Local:**
```
http://localhost:3000/admin/configuracao-whatsapp
```

**Produção:**
```
https://debrief.interce.com.br.com.br/admin/configuracao-whatsapp
```

### Passo 2: Preencher Formulário

#### 📞 Campo 1: Número WhatsApp Business Remetente

```
5585991042626
```

**Regras:**
- ✅ Apenas números (sem espaços, + ou traços)
- ✅ Formato: código país + DDD + número
- ✅ Exemplo Brasil: `5585991042626`
- ✅ Exemplo SP: `5511999999999`
- ❌ NÃO: `+55 85 99104-2626`
- ❌ NÃO: `(85) 99104-2626`

**Esse deve ser o mesmo número conectado no WhatsApp!**

#### 🔧 Campo 2: Nome da Instância WPP Connect

```
debrief-instance
```

**Regras:**
- ✅ Nome exato criado no WPPConnect Server
- ✅ Case-sensitive (maiúsculas ≠ minúsculas)
- ✅ Sem espaços
- ✅ Exemplo: `debrief-instance`
- ❌ NÃO: `Debrief Instance`
- ❌ NÃO: `debrief instance`

#### 🔑 Campo 3: Token WPP Connect

```
seu-token-super-seguro-aqui
```

**Regras:**
- ✅ Token configurado no WPPConnect Server (arquivo .env)
- ✅ Ou token fornecido pelo provedor cloud
- ✅ Copie e cole exatamente como está
- ⚠️ Mantenha esse token seguro!

#### ✅ Campo 4: Configuração ativa

- [x] Marque o checkbox
- Apenas UMA configuração pode estar ativa por vez
- Se você criar uma nova e marcar como ativa, a anterior será desativada

### Passo 3: Salvar

Clique no botão **"Salvar Configuração"**

✅ Deve aparecer uma mensagem de sucesso!

---

## 🧪 ETAPA 5: Testar o Envio

### Teste 1: Testar Conexão (Interface)

Na mesma página de configuração:

1. Procure o botão **"Testar Conexão"**
2. Informe seu número de WhatsApp
3. Clique em **"Enviar Teste"**
4. Verifique se recebeu a mensagem no WhatsApp

### Teste 2: Via API (Postman/Insomnia)

```bash
POST http://localhost:8000/api/v1/whatsapp/config/test
Content-Type: application/json
Authorization: Bearer SEU_TOKEN_JWT

{
  "numero_teste": "5585991042626",
  "mensagem": "🎉 Teste de conexão DeBrief - Funcionando!"
}
```

**Resposta esperada:**
```json
{
  "sucesso": true,
  "mensagem": "Mensagem de teste enviada com sucesso!",
  "destinatario": "5585991042626"
}
```

### Teste 3: Criar Demanda de Teste

1. Crie um usuário de teste com WhatsApp cadastrado
2. Ative "Receber Notificações" para esse usuário
3. Crie uma demanda para o cliente desse usuário
4. Verifique se o usuário recebeu a notificação

---

## 📊 ETAPA 6: Verificar se Está Funcionando

### Verificar Logs de Notificações

```sql
-- Conectar ao banco via DBeaver ou terminal
psql -h localhost -p 5433 -U postgres -d dbrief

-- Ver últimas notificações
SELECT 
    nl.created_at as "Data/Hora",
    u.nome_completo as "Usuário",
    nl.destinatario as "WhatsApp",
    nl.status as "Status",
    nl.erro_mensagem as "Erro"
FROM notification_logs nl
JOIN users u ON nl.usuario_id = u.id
WHERE nl.tipo = 'whatsapp'
ORDER BY nl.created_at DESC
LIMIT 10;
```

### Verificar Status do WPPConnect

Acesse:
```
https://seu-servidor/api/debrief-instance/status
```

**Resposta esperada:**
```json
{
  "status": "online",
  "connected": true,
  "phone": "5585991042626"
}
```

---

## ⚙️ ETAPA 7: Configurar Templates de Mensagens

### Acessar Templates

**Local:**
```
http://localhost:3000/admin/templates-whatsapp
```

**Produção:**
```
https://debrief.interce.com.br.com.br/admin/templates-whatsapp
```

### Templates Padrão Já Criados

✅ **Nova Demanda Criada** (`demanda_criada`)
✅ **Demanda Atualizada** (`demanda_atualizada`)
✅ **Demanda Removida** (`demanda_deletada`)

### Criar Novo Template

1. Clique em **"Novo Template"**
2. Preencha:
   - **Nome:** "Demanda Aprovada"
   - **Tipo de Evento:** `demanda_aprovada`
   - **Mensagem:**
   ```
   ✅ *Demanda Aprovada*

   📋 *Demanda:* {{demanda_titulo}}
   🏢 *Cliente:* {{cliente_nome}}
   👤 *Aprovador:* {{usuario_responsavel}}
   📅 *Data:* {{data_atualizacao}}

   _Sistema DeBrief_
   ```
3. Marque **"Ativo"**
4. Clique em **"Salvar"**

### Variáveis Disponíveis

Use essas variáveis nos templates:

```
{{demanda_titulo}}         → Título da demanda
{{demanda_descricao}}      → Descrição completa
{{cliente_nome}}           → Nome do cliente
{{secretaria_nome}}        → Nome da secretaria
{{tipo_demanda}}           → Tipo da demanda
{{prioridade}}             → Nível de prioridade
{{prazo_final}}            → Data de prazo
{{usuario_responsavel}}    → Nome do responsável
{{usuario_nome}}           → Nome do usuário criador
{{usuario_email}}          → Email do usuário
{{data_criacao}}           → Data de criação
{{data_atualizacao}}       → Data da última atualização
{{status}}                 → Status atual
{{trello_card_url}}        → Link do Trello
```

---

## 🔧 Resolução de Problemas

### ❌ Problema: "Erro ao enviar mensagem"

**Possíveis causas:**

1. **WPPConnect não está rodando**
   ```bash
   # Verificar se está online
   curl https://seu-servidor/api/debrief-instance/status
   ```

2. **WhatsApp desconectado**
   - Gere novo QR Code e escaneie novamente
   - Acesse: `/api/debrief-instance/start-session`

3. **Token inválido**
   - Verifique se o token está correto no `.env` e na interface

4. **Instância com nome errado**
   - Verifique se o nome da instância está exatamente igual

### ❌ Problema: "Configuração não salva"

1. Verifique se o backend está rodando:
   ```bash
   docker ps | grep backend
   ```

2. Verifique logs do backend:
   ```bash
   docker logs debrief-backend --tail 50
   ```

3. Verifique se o banco está acessível:
   ```bash
   docker exec -it debrief_db psql -U postgres -d dbrief -c "SELECT * FROM configuracoes_whatsapp;"
   ```

### ❌ Problema: "Usuário não recebe notificação"

Verifique:

1. **Usuário tem WhatsApp cadastrado?**
   ```sql
   SELECT nome_completo, whatsapp, receber_notificacoes 
   FROM users 
   WHERE id = 'id-do-usuario';
   ```

2. **Campo "Receber Notificações" está ativo?**
   - Deve ser `true`

3. **Usuário pertence ao cliente da demanda?**
   - O sistema só notifica usuários do mesmo cliente

4. **Usuário está ativo?**
   - Campo `ativo` deve ser `true`

### ❌ Problema: "QR Code não aparece"

1. Verifique se WPPConnect está rodando:
   ```bash
   # No servidor
   pm2 status
   # Deve mostrar wppconnect-server como "online"
   ```

2. Verifique porta e firewall:
   ```bash
   netstat -tulpn | grep 21465
   ```

3. Verifique logs:
   ```bash
   pm2 logs wppconnect-server
   ```

---

## 📱 Fluxo Completo de Notificação

```
1. EVENTO OCORRE
   └─ Usuário cria demanda
   
2. SISTEMA BUSCA CONFIGURAÇÃO
   └─ ConfiguracaoWhatsApp.get_ativa(db)
   
3. SISTEMA BUSCA TEMPLATE
   └─ TemplateMensagem.get_by_tipo_evento(db, "demanda_criada")
   
4. SISTEMA BUSCA USUÁRIOS
   └─ Usuários do cliente com WhatsApp ativo
   
5. RENDERIZA MENSAGEM
   └─ Substitui variáveis {{}} pelos dados reais
   
6. ENVIA VIA WPPCONNECT
   └─ WhatsAppService.enviar_mensagem_individual()
   
7. REGISTRA LOG
   └─ NotificationLog.create(...)
   
8. RETORNA ESTATÍSTICAS
   └─ {enviados: 3, falhas: 0}
```

---

## ✅ Checklist Final

Antes de colocar em produção, verifique:

- [ ] WPPConnect Server rodando e acessível
- [ ] WhatsApp Business conectado (QR Code escaneado)
- [ ] Variáveis de ambiente configuradas (`.env`)
- [ ] Configuração salva na interface web
- [ ] Teste de envio funcionando
- [ ] Templates de mensagem criados e ativos
- [ ] Usuários com WhatsApp cadastrado
- [ ] Campo "Receber Notificações" ativado para usuários
- [ ] Logs de notificação sendo registrados
- [ ] Firewall liberado (se aplicável)

---

## 🆘 Suporte

Se precisar de ajuda:

1. **Verificar Documentação:**
   - `docs/ARQUITETURA_WHATSAPP_WPPCONNECT.md`

2. **Verificar Logs:**
   ```bash
   # Backend
   docker logs debrief-backend --tail 100
   
   # WPPConnect
   pm2 logs wppconnect-server
   ```

3. **Banco de Dados:**
   ```sql
   -- Ver configurações
   SELECT * FROM configuracoes_whatsapp;
   
   -- Ver templates
   SELECT nome, tipo_evento, ativo FROM templates_mensagens;
   
   -- Ver últimas notificações
   SELECT * FROM notification_logs ORDER BY created_at DESC LIMIT 10;
   ```

---

**Última atualização:** 23/11/2025  
**Versão:** 1.0  
**Autor:** DeBrief Team

