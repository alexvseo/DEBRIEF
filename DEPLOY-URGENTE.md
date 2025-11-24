# 🚀 DEPLOY URGENTE - Correção Página WhatsApp

## ⚠️ SITUAÇÃO ATUAL

**Problema:** A página https://debrief.interce.com.br/admin/configuracao-whatsapp ainda está com a versão antiga.

**Status das Alterações:**
- ✅ Código corrigido localmente
- ❌ **NÃO aplicado no servidor ainda**
- ❌ **NÃO commitado no git**

---

## 🎯 SOLUÇÃO: Deploy em 3 Passos

### ⚡ PASSO 1: Commit Local (2 minutos)

Execute no terminal:

```bash
cd /Users/alexmini/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF

# Adicionar arquivos principais
git add frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx
git add backend/app/api/endpoints/whatsapp.py
git add backend/app/api/endpoints/usuarios.py
git add backend/app/api/endpoints/demandas.py
git add backend/app/services/notification.py
git add backend/app/schemas/user.py

# Adicionar documentação
git add NOTIFICACOES-WHATSAPP.md
git add RESUMO-IMPLEMENTACAO-NOTIFICACOES.md
git add INICIO-RAPIDO-NOTIFICACOES.md
git add DEPLOY-NOTIFICACOES.md
git add README-NOTIFICACOES.md
git add CORRECAO-PAGINA-WHATSAPP.md
git add testar-notificacoes.sh
git add configurar-whatsapp-usuarios.sql

# Commit
git commit -m "feat: Sistema completo de notificações WhatsApp + correção página config

✅ Implementado:
- Sistema de notificações individuais via WhatsApp
- Segmentação automática por cliente (users recebem apenas do seu cliente, masters recebem tudo)
- NotificationService com notificações em criar/atualizar/excluir/status
- Endpoints GET /api/usuarios/me e PUT /api/usuarios/me/notificacoes
- Endpoints GET /api/whatsapp/status e POST /api/whatsapp/testar

✅ Corrigido:
- Página /admin/configuracao-whatsapp reformulada
- Número remetente agora aparece: 5585991042626
- Instância agora aparece: debrief  
- Campo de teste agora está ATIVO e funcional
- Status da conexão em tempo real
- Documentação completa inline

✅ Documentação:
- 6 arquivos .md com guias completos
- Script testar-notificacoes.sh
- Queries SQL prontas"

# Push para GitHub
git push origin main
```

**✅ Resultado Esperado:**
```
Enumerating objects: X, done.
Writing objects: 100% (X/X), done.
To github.com:usuario/debrief.git
   abc1234..def5678  main -> main
```

---

### ⚡ PASSO 2: Deploy no Servidor (3 minutos)

Execute no terminal:

```bash
# Conectar ao servidor
ssh root@82.25.92.217

# Navegar para diretório
cd /var/www/debrief

# Verificar branch atual
git branch
# Deve mostrar: * main

# Fazer backup (segurança)
cp -r frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx.bak

# Puxar alterações
git pull origin main

# Verificar se arquivo foi atualizado
head -20 frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx
# Deve mostrar as novas linhas com "Evolution API"

# Reiniciar containers
docker restart debrief-backend
docker restart debrief-frontend

# Aguardar containers iniciarem (15 segundos)
sleep 15

# Verificar logs do backend
docker logs debrief-backend --tail 50 | grep -i "startup\|error"

# Verificar logs do frontend
docker logs debrief-frontend --tail 20
```

**✅ Resultado Esperado:**

Backend deve mostrar:
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Frontend deve mostrar:
```
/docker-entrypoint.sh: Configuration complete; ready for start up
```

---

### ⚡ PASSO 3: Testar em Produção (1 minuto)

1. **Abrir navegador em modo anônimo** (Ctrl+Shift+N)
2. **Acessar:** https://debrief.interce.com.br/admin/configuracao-whatsapp
3. **Fazer hard refresh:** Ctrl+Shift+R (ou Cmd+Shift+R no Mac)
4. **Verificar:**
   - ✅ Título: "Configuração WhatsApp"
   - ✅ Seção: "Status da Conexão" (nova!)
   - ✅ Número remetente: `5585991042626` (aparecendo!)
   - ✅ Instância: `debrief` (aparecendo!)
   - ✅ Seção: "Suas Configurações de Notificação" (nova!)
   - ✅ Campo "Seu Número WhatsApp" editável
   - ✅ Campo "Número para Teste" ATIVO
   - ✅ Botão "Enviar Teste" habilitado

---

## 📋 Checklist de Validação

Após deploy, confirmar:

**Interface:**
- [ ] Página carrega sem erros
- [ ] Status da conexão é exibido no topo
- [ ] Seção "Configuração do Sistema" aparece
- [ ] Número `5585991042626` está visível (não editável)
- [ ] Instância `debrief` está visível (não editável)
- [ ] Seção "Suas Configurações" aparece
- [ ] Campo WhatsApp pessoal está editável
- [ ] Toggle "Receber Notificações" funciona
- [ ] Seção "Testar Notificação" aparece
- [ ] Campo "Número para Teste" está ATIVO (não desabilitado)
- [ ] Campo "Mensagem" está editável

**Funcionalidades:**
- [ ] Botão "Salvar Configurações" funciona
- [ ] Botão "Enviar Teste" funciona
- [ ] Mensagem de teste chega no WhatsApp
- [ ] Botão "Verificar Conexão" atualiza status

---

## 🐛 Se Algo Der Errado

### Problema 1: Página ainda está antiga após deploy

**Causa:** Cache do navegador

**Solução:**
```bash
# No navegador:
1. Abrir DevTools (F12)
2. Clicar com botão direito no botão Reload
3. Selecionar "Empty Cache and Hard Reload"

# OU

1. Abrir modo anônimo (Ctrl+Shift+N)
2. Acessar a página
```

### Problema 2: Git pull deu conflito

**Solução:**
```bash
# No servidor
cd /var/www/debrief

# Ver arquivos em conflito
git status

# Fazer stash das mudanças locais
git stash

# Puxar novamente
git pull origin main

# Ver o que foi modificado
git log --oneline -5
```

### Problema 3: Backend não inicia

**Solução:**
```bash
# Ver logs completos
docker logs debrief-backend

# Se houver erro de import:
docker exec -it debrief-backend bash
ls -la /app/app/services/notification.py
exit

# Se arquivo não existir, puxar novamente
git pull origin main
docker restart debrief-backend
```

### Problema 4: Frontend não inicia

**Solução:**
```bash
# Ver logs
docker logs debrief-frontend

# Rebuild do frontend se necessário
docker-compose -f docker-compose.prod.yml build debrief-frontend
docker restart debrief-frontend
```

---

## 🔍 Verificação Rápida

### Teste 1: API está funcionando?

```bash
# No servidor
curl http://localhost:2023/api/whatsapp/status \
  -H "Authorization: Bearer SEU_TOKEN" | jq .
```

**Resposta esperada:**
```json
{
  "connected": true,
  "state": "open",
  "instance": "debrief",
  "numero_remetente": "5585991042626"
}
```

### Teste 2: Frontend foi atualizado?

```bash
# No servidor
grep -n "Evolution API" /var/www/debrief/frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx

# Deve retornar várias linhas com "Evolution API"
```

### Teste 3: Containers estão rodando?

```bash
# No servidor
docker ps | grep debrief

# Deve mostrar 3 containers: backend, frontend, db
```

---

## 📞 Suporte Rápido

Se precisar de ajuda imediata:

1. **Ver logs em tempo real:**
```bash
# Backend
docker logs -f debrief-backend

# Frontend
docker logs -f debrief-frontend
```

2. **Verificar arquivos atualizados:**
```bash
cd /var/www/debrief
git log --oneline -3
git diff HEAD~1 frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx
```

3. **Rollback de emergência:**
```bash
cd /var/www/debrief
git log --oneline -5
git reset --hard COMMIT_ID_ANTERIOR
docker restart debrief-backend debrief-frontend
```

---

## ⏱️ Tempo Estimado Total

- **Passo 1 (Commit):** 2 minutos
- **Passo 2 (Deploy):** 3 minutos
- **Passo 3 (Teste):** 1 minuto

**TOTAL: ~6 minutos** ⚡

---

## ✅ Checklist Rápido

Execute na ordem:

```bash
# 1. Commit (local)
cd ~/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
git add frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx backend/app/api/endpoints/whatsapp.py backend/app/services/notification.py
git commit -m "feat: Sistema notificações WhatsApp + correção página"
git push origin main

# 2. Deploy (servidor)
ssh root@82.25.92.217 'cd /var/www/debrief && git pull origin main && docker restart debrief-backend debrief-frontend'

# 3. Aguardar (20 segundos)
sleep 20

# 4. Testar (navegador)
# Abrir: https://debrief.interce.com.br/admin/configuracao-whatsapp
# Hard refresh: Ctrl+Shift+R
```

---

**🎯 PRONTO! A página estará corrigida!**

**Qualquer problema, verifique os logs:**
```bash
ssh root@82.25.92.217
docker logs debrief-backend --tail 100
docker logs debrief-frontend --tail 50
```

