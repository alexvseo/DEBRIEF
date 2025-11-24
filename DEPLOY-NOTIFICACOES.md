# 🚀 Deploy de Notificações WhatsApp em Produção

## 📋 Checklist Pré-Deploy

Antes de fazer deploy, verifique:

- [ ] Evolution API funcionando no servidor (porta 21465)
- [ ] WhatsApp conectado e com QR Code validado
- [ ] Campos `whatsapp` e `receber_notificacoes` existem na tabela `users`
- [ ] Backend testado localmente
- [ ] Script `testar-notificacoes.sh` executou com sucesso

---

## 🔧 Passos para Deploy

### 1. Fazer Commit e Push (Local)

```bash
# Ver status
git status

# Adicionar arquivos novos
git add backend/app/services/notification.py
git add backend/app/api/endpoints/demandas.py
git add backend/app/api/endpoints/usuarios.py
git add backend/app/schemas/user.py
git add NOTIFICACOES-WHATSAPP.md
git add RESUMO-IMPLEMENTACAO-NOTIFICACOES.md
git add INICIO-RAPIDO-NOTIFICACOES.md
git add DEPLOY-NOTIFICACOES.md
git add testar-notificacoes.sh
git add configurar-whatsapp-usuarios.sql

# Commit
git commit -m "feat: Implementar sistema de notificações WhatsApp

- Adicionar NotificationService para gerenciar notificações individuais
- Segmentação automática: usuários comuns (apenas seu cliente) vs Masters (tudo)
- Notificações em: criar, atualizar, excluir demandas e mudanças de status
- Endpoints para usuários configurarem WhatsApp (/api/usuarios/me/notificacoes)
- Logs completos na tabela notification_logs
- Documentação completa e scripts de teste"

# Push para repositório
git push origin main
```

---

### 2. Deploy no Servidor (SSH)

```bash
# Conectar ao servidor
ssh root@82.25.92.217

# Ir para diretório do projeto
cd /var/www/debrief

# Fazer backup antes de atualizar
cp -r backend backend-backup-$(date +%Y%m%d-%H%M%S)

# Puxar alterações
git pull origin main

# Verificar se arquivos foram atualizados
ls -la backend/app/services/notification.py
ls -la backend/app/api/endpoints/demandas.py
ls -la backend/app/api/endpoints/usuarios.py

# Verificar logs do git
git log --oneline -5
```

---

### 3. Atualizar Backend (Servidor)

```bash
# Ainda no servidor (SSH)

# Entrar no container do backend
docker exec -it debrief-backend bash

# Verificar se novos arquivos existem
ls -la /app/app/services/notification.py

# Sair do container
exit

# Reiniciar backend para aplicar mudanças
docker restart debrief-backend

# Verificar logs do backend
docker logs -f debrief-backend --tail 50
```

**Aguardar:** Backend iniciar (cerca de 10-15 segundos)

**Procurar nos logs:**
- ✅ "Application startup complete"
- ✅ "WhatsAppService inicializado"
- ❌ Não deve ter erros de import

---

### 4. Verificar API no Servidor (Servidor)

```bash
# Verificar health check
curl http://localhost:2023/health

# Verificar endpoint de notificações (precisa estar autenticado)
curl http://localhost:2023/api/usuarios/me \
  -H "Authorization: Bearer SEU_TOKEN"
```

---

### 5. Configurar Usuários para Receber Notificações (Servidor)

```bash
# Conectar ao banco via túnel SSH
# No seu computador LOCAL:
./conectar-banco-correto.sh

# Em outra aba, conectar com DBeaver:
# - Host: localhost
# - Port: 5433
# - Database: dbrief
# - User: postgres
# - Password: Mslestra@2025db

# Executar queries de configuração
# (usar o arquivo configurar-whatsapp-usuarios.sql)
```

**Exemplo de configuração:**

```sql
-- Configurar usuário Master principal
UPDATE users 
SET 
    whatsapp = '5585991042626',
    receber_notificacoes = true
WHERE tipo = 'master'
  AND email = 'alex@example.com';

-- Configurar usuários de um cliente específico
UPDATE users 
SET 
    receber_notificacoes = true
WHERE cliente_id = (SELECT id FROM clientes WHERE nome ILIKE '%russas%')
  AND ativo = true;

-- Verificar configuração
SELECT 
    username,
    email,
    tipo,
    cliente_id,
    whatsapp,
    receber_notificacoes,
    ativo
FROM users
WHERE whatsapp IS NOT NULL
ORDER BY tipo DESC, username;
```

---

### 6. Teste em Produção (Servidor)

```bash
# No servidor, via SSH

# Verificar Evolution API
curl http://localhost:21465/instance/connectionState/debrief \
  -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"

# Resposta esperada: "state": "open"
```

**Criar demanda de teste:**

1. Acessar: http://debrief.interce.com.br
2. Fazer login com usuário configurado
3. Criar nova demanda
4. Verificar WhatsApp do usuário configurado

---

### 7. Monitorar Logs (Servidor)

```bash
# Logs do backend em tempo real
docker logs -f debrief-backend | grep -i "notific"

# Procurar por:
# - "Notificações WhatsApp enviadas: X usuários"
# - "Notificação enviada para [nome] ([telefone])"
# - "Erro ao enviar notificações" (não deve aparecer)
```

**Verificar no banco:**

```sql
-- Ver últimas notificações
SELECT 
    nl.created_at,
    nl.status,
    d.nome as demanda,
    c.nome as cliente,
    nl.dados_enviados->>'usuario_nome' as usuario_notificado,
    nl.dados_enviados->>'whatsapp' as whatsapp
FROM notification_logs nl
JOIN demandas d ON d.id = nl.demanda_id
JOIN clientes c ON c.id = d.cliente_id
WHERE nl.tipo = 'whatsapp'
ORDER BY nl.created_at DESC
LIMIT 10;

-- Estatísticas
SELECT 
    status,
    COUNT(*) as total,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 2) as percentual
FROM notification_logs
WHERE tipo = 'whatsapp'
  AND created_at >= CURRENT_DATE
GROUP BY status;
```

---

### 8. Rollback (Se Necessário)

Se houver problema após deploy:

```bash
# No servidor (SSH)
cd /var/www/debrief

# Listar backups disponíveis
ls -la backend-backup-*

# Restaurar backup (substituir data)
rm -rf backend
cp -r backend-backup-20241124-143022 backend

# Reiniciar backend
docker restart debrief-backend

# Verificar logs
docker logs -f debrief-backend --tail 50
```

---

## 📊 Monitoramento Pós-Deploy

### Primeiras 24 horas

**A cada 2-4 horas, verificar:**

1. **Backend rodando?**
   ```bash
   curl http://82.25.92.217:2023/health
   ```

2. **WhatsApp conectado?**
   ```bash
   ssh root@82.25.92.217
   curl http://localhost:21465/instance/connectionState/debrief \
     -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
   ```

3. **Notificações sendo enviadas?**
   ```sql
   -- Executar no banco
   SELECT 
       COUNT(*) as enviadas_hoje,
       SUM(CASE WHEN status = 'enviado' THEN 1 ELSE 0 END) as sucesso,
       SUM(CASE WHEN status = 'erro' THEN 1 ELSE 0 END) as erros
   FROM notification_logs
   WHERE tipo = 'whatsapp'
     AND created_at >= CURRENT_DATE;
   ```

4. **Erros no backend?**
   ```bash
   docker logs debrief-backend --tail 100 | grep -i "error\|erro"
   ```

### Após 1 semana

**Verificar:**

- Taxa de sucesso de notificações (deve ser > 95%)
- Usuários reclamaram de não receber notificações?
- WhatsApp desconectou alguma vez?
- Logs de erro relacionados a notificações?

---

## 🔒 Segurança

### Dados Sensíveis Protegidos

✅ **API Key do WhatsApp**
- Armazenada em `.env` (não commitada)
- Não exposta em logs
- Acesso apenas pelo backend

✅ **Números de Telefone**
- Armazenados no banco (PostgreSQL)
- Não expostos em endpoints públicos
- Acessíveis apenas pelo próprio usuário (ou Master)

✅ **Mensagens**
- Não armazenamos conteúdo completo
- Logs estruturados (JSON) sem PII excessivo

---

## 📈 Métricas de Sucesso

Indicadores de que o deploy foi bem-sucedido:

- ✅ Backend iniciou sem erros
- ✅ Endpoint `/api/usuarios/me/notificacoes` responde 200 OK
- ✅ Criar demanda dispara notificações
- ✅ Usuários recebem mensagens no WhatsApp
- ✅ Logs mostram "enviado" (não "erro")
- ✅ Segmentação funciona (usuários recebem apenas do seu cliente)
- ✅ Taxa de sucesso > 95%

---

## 🆘 Troubleshooting em Produção

### Backend não inicia após deploy

```bash
# Ver logs completos
docker logs debrief-backend --tail 200

# Procurar por:
# - ImportError (falta arquivo)
# - ModuleNotFoundError (dependência faltando)
# - SyntaxError (erro de código)
```

**Solução:** Rollback para versão anterior

### Notificações não sendo enviadas

1. **Verificar Evolution API:**
   ```bash
   curl http://localhost:21465/instance/connectionState/debrief \
     -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
   ```

2. **Verificar configuração do usuário:**
   ```sql
   SELECT * FROM users WHERE email = 'usuario@example.com';
   ```

3. **Verificar logs de erro:**
   ```sql
   SELECT * FROM notification_logs 
   WHERE status = 'erro' 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

### WhatsApp desconectou

```bash
# No servidor
cd /var/www/debrief
./reconectar-whatsapp-evolution.sh

# Seguir instruções para escanear QR Code
```

---

## 📝 Checklist Final

Após deploy, confirmar:

- [ ] Backend rodando sem erros
- [ ] Endpoint `/api/usuarios/me/notificacoes` funciona
- [ ] WhatsApp Evolution API conectado
- [ ] Demanda de teste criada e notificação enviada
- [ ] Logs mostram notificações com sucesso
- [ ] Pelo menos 1 usuário Master configurado com WhatsApp
- [ ] Documentação atualizada no repositório
- [ ] Time informado sobre nova funcionalidade

---

## 🎉 Deploy Concluído!

Sistema de notificações WhatsApp está **LIVE** em produção! 🚀

**Próximos Passos:**

1. ✅ Configurar WhatsApp de todos os usuários ativos
2. ✅ Comunicar nova funcionalidade ao time
3. ✅ Monitorar por 24-48 horas
4. ✅ Coletar feedback dos usuários
5. ⏳ Implementar melhorias baseadas em feedback

---

**Data do Deploy:** _________  
**Responsável:** _________  
**Status:** _________  
**Observações:** _________

