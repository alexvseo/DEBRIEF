# ⚡ GUIA RÁPIDO - Sincronização Bidirecional Trello

**Início rápido para configurar e usar a sincronização bidirecional**

---

## 🚀 **CONFIGURAÇÃO EM 3 PASSOS**

### **1️⃣ Deploy do Código**

```bash
cd /Users/alexsantos/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
git add .
git commit -m "feat: Sincronização bidirecional Trello ↔️ DeBrief"
git push origin main
./scripts/deploy.sh
```

### **2️⃣ Registrar Webhook no Trello**

```bash
# SSH no VPS
ssh root@82.25.92.217

# Ir para o projeto
cd /var/www/debrief
source venv/bin/activate

# Registrar webhook
python scripts/registrar_webhook_trello.py
```

**Resultado esperado:**
```
✅ Webhook registrado com sucesso!
   Webhook ID: abc123def456
   URL: https://debrief.interce.com.br/api/trello/webhook
   Ativo: ✅ Sim
```

### **3️⃣ Testar**

1. Criar uma demanda no DeBrief
2. Verificar que o card foi criado no Trello
3. Mover o card entre listas no Trello
4. ✅ Status atualizado automaticamente no DeBrief!
5. ✅ Notificação WhatsApp enviada!

---

## 🔄 **COMO FUNCIONA**

### **DeBrief → Trello**
```
Editar demanda no DeBrief
   ↓
Card atualizado no Trello automaticamente
```

### **Trello → DeBrief**
```
Mover card no Trello
   ↓
Status atualizado no DeBrief automaticamente
   ↓
Notificação WhatsApp enviada
```

---

## 🗺️ **MAPEAMENTO DE LISTAS**

### **Listas do Seu Board**

| Lista no Trello | Status no DeBrief | ID |
|----------------|-------------------|----|
| **ENVIOS DOS CLIENTES VIA DEBRIEF** | Aberta | 6810f40131d456a240f184ba |
| **EM DESENVOLVIMENTO** | Em Andamento | 68b82f29253b5480f0c06f3d |
| **EM ESPERA** | Concluída | 5ea097406d864d89b0017aa3 |

**Notas importantes**:
- ✅ Demandas canceladas **não têm lista no Trello** (cards serão arquivados)
- ✅ Lista "EM ESPERA" = Demandas CONCLUÍDAS no DeBrief
- ✅ Status "aguardando_cliente" mantém card em "EM DESENVOLVIMENTO"

---

## 🛠️ **COMANDOS ÚTEIS**

### **Listar webhooks ativos**
```bash
python scripts/registrar_webhook_trello.py --list
```

### **Deletar webhook**
```bash
python scripts/registrar_webhook_trello.py --delete <webhook_id>
```

### **Ver logs do backend**
```bash
docker compose logs backend | grep -i webhook
docker compose logs backend | grep -i trello
```

### **Testar endpoint webhook**
```bash
curl -I https://debrief.interce.com.br/api/trello/webhook
# Deve retornar: 200 OK
```

---

## 🔍 **TROUBLESHOOTING RÁPIDO**

### **Webhook não funciona?**
```bash
# 1. Verificar se está registrado
python scripts/registrar_webhook_trello.py --list

# 2. Testar endpoint
curl -I https://debrief.interce.com.br/api/trello/webhook

# 3. Ver logs
docker compose logs backend | tail -50
```

### **Status não atualiza?**
```bash
# Verificar nome da lista no Trello
# Editar mapeamento em:
# backend/app/api/endpoints/trello_webhook.py (linha 62)
```

### **Notificação não chega?**
```sql
-- Verificar configuração do usuário
SELECT whatsapp, receber_notificacoes 
FROM users 
WHERE id = 'ID_DO_USUARIO';

-- Ativar notificações
UPDATE users 
SET receber_notificacoes = true 
WHERE id = 'ID_DO_USUARIO';
```

---

## 📖 **DOCUMENTAÇÃO COMPLETA**

Para informações detalhadas, consulte:
- `docs/SINCRONIZACAO_BIDIRECIONAL_TRELLO.md` (documentação completa)

---

## ✅ **CHECKLIST DE VERIFICAÇÃO**

- [ ] Código deployado no VPS
- [ ] Endpoint `/api/trello/webhook` acessível (200 OK)
- [ ] Webhook registrado no Trello
- [ ] Demanda de teste criada
- [ ] Card criado no Trello
- [ ] Card movido entre listas
- [ ] Status atualizado no DeBrief
- [ ] Notificação WhatsApp recebida

---

**🎉 Pronto! Sua sincronização bidirecional está funcionando!**

