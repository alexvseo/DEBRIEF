# 🚀 Workflow de Desenvolvimento - DeBrief

## 📋 Novo Fluxo de Trabalho

A partir de agora, **TODO o desenvolvimento** será feito seguindo este fluxo:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  1️⃣  EDITAR CÓDIGO NO CURSOR                           │
│      ↓                                                  │
│  2️⃣  COMMIT + PUSH PARA GITHUB                         │
│      ↓                                                  │
│  3️⃣  DEPLOY AUTOMÁTICO NO VPS                          │
│      ↓                                                  │
│  4️⃣  TESTAR EM https://debrief.interce.com.br          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## ⚠️ **NÃO USAR MAIS**

- ❌ Docker local (`docker-compose.dev.yml`)
- ❌ Túnel SSH para banco de dados
- ❌ Testes em `localhost:3000` ou `localhost:8000`

**Motivo:** Conflitos com Caddy e sincronização entre ambientes.

---

## 🎯 **Workflow Passo a Passo**

### **Opção 1: Deploy Completo** (com rebuild)

Use quando adicionar/remover dependências (npm, pip) ou mudar Dockerfiles.

```bash
cd "/Users/alexsantos/Documents/PROJETOS DEV COM IA/DEBRIEF"
./scripts/deploy.sh
```

**O que faz:**
1. ✅ Verifica mudanças não comitadas
2. ✅ Solicita mensagem de commit (se necessário)
3. ✅ Faz commit e push para GitHub
4. ✅ Conecta ao VPS
5. ✅ Atualiza código (`git pull`)
6. ✅ Reconstrói containers (`docker-compose build`)
7. ✅ Reinicia serviços
8. ✅ Mostra logs e status

**Tempo:** ~3-5 minutos

---

### **Opção 2: Deploy Rápido** (sem rebuild)

Use para mudanças simples em código (Python, JavaScript, configurações).

```bash
cd "/Users/alexsantos/Documents/PROJETOS DEV COM IA/DEBRIEF"
./scripts/deploy-rapido.sh
```

**O que faz:**
1. ✅ Faz `git add .`
2. ✅ Solicita mensagem de commit
3. ✅ Faz push para GitHub
4. ✅ Atualiza código no VPS
5. ✅ Reinicia containers (sem rebuild)
6. ✅ Mostra status

**Tempo:** ~30-60 segundos

---

### **Opção 3: Deploy Manual**

Se preferir controle total:

```bash
# 1. Commit local
git add .
git commit -m "Sua mensagem aqui"
git push origin main

# 2. Deploy no servidor
ssh debrief
cd /var/www/debrief
git pull origin main

# 3. Rebuild (se necessário)
docker-compose build backend frontend

# 4. Restart
docker-compose up -d --force-recreate backend frontend

# 5. Verificar
docker-compose ps
docker-compose logs -f backend
```

---

## 📝 **Boas Práticas**

### **Commits**

✅ **Bom:**
```
git commit -m "feat: adiciona campo links_referencia em demandas"
git commit -m "fix: corrige validação de email no login"
git commit -m "docs: atualiza README com novas instruções"
```

❌ **Evitar:**
```
git commit -m "update"
git commit -m "fix"
git commit -m "changes"
```

### **Tipos de Commit**
- `feat:` nova funcionalidade
- `fix:` correção de bug
- `docs:` documentação
- `style:` formatação, espaços
- `refactor:` refatoração de código
- `test:` testes
- `chore:` tarefas de manutenção

---

## 🔍 **Comandos Úteis**

### **Ver logs em tempo real**
```bash
ssh debrief "cd /var/www/debrief && docker-compose logs -f backend"
```

### **Ver status dos containers**
```bash
ssh debrief "cd /var/www/debrief && docker-compose ps"
```

### **Restart rápido (sem deploy)**
```bash
ssh debrief "cd /var/www/debrief && docker-compose restart backend frontend"
```

### **Ver últimos commits**
```bash
git log --oneline -10
```

### **Desfazer último commit (antes do push)**
```bash
git reset --soft HEAD~1
```

---

## 🐛 **Troubleshooting**

### **Erro: "Your local changes would be overwritten"**

```bash
ssh debrief
cd /var/www/debrief
git stash
git pull origin main
```

### **Container unhealthy**

```bash
ssh debrief
cd /var/www/debrief
docker-compose logs backend
docker-compose restart backend
```

### **Erro de porta em uso**

```bash
ssh debrief
docker ps | grep -E ':8000|:3000'
# Se houver conflito, parar containers duplicados
docker stop <container_id>
```

### **Rollback para versão anterior**

```bash
# Localmente
git log --oneline -10  # Ver últimos commits
git reset --hard <commit_hash>
git push origin main --force

# No servidor
ssh debrief "cd /var/www/debrief && git pull origin main --force && docker-compose up -d --force-recreate"
```

---

## 📊 **URLs do Sistema**

| Ambiente | URL | Uso |
|----------|-----|-----|
| **Produção** | https://debrief.interce.com.br | Sistema principal |
| **API Docs** | https://debrief.interce.com.br/api/docs | Documentação Swagger |
| **WPP Connect** | https://wpp.interce.com.br | Evolution API |
| **WPP Manager** | https://wpp.interce.com.br/manager | Interface WhatsApp |

---

## ✅ **Checklist de Deploy**

Antes de cada deploy, verifique:

- [ ] Código testado no Cursor (syntax check)
- [ ] Sem erros de lint visíveis
- [ ] Imports e dependências corretos
- [ ] Mensagem de commit descritiva
- [ ] Verificar logs após deploy
- [ ] Testar funcionalidade alterada no site

---

## 🎯 **Resumo**

### **Para mudanças simples (90% dos casos):**
```bash
./scripts/deploy-rapido.sh
```

### **Para mudanças com dependências:**
```bash
./scripts/deploy.sh
```

### **Para ver o resultado:**
```
https://debrief.interce.com.br
```

---

## 📞 **Suporte**

Em caso de problemas:
1. Verificar logs: `ssh debrief "cd /var/www/debrief && docker-compose logs -f"`
2. Verificar status: `ssh debrief "cd /var/www/debrief && docker-compose ps"`
3. Reiniciar serviços: `ssh debrief "cd /var/www/debrief && docker-compose restart"`
4. Se persistir, fazer rollback para versão estável

---

**Data de implementação:** 23/11/2025  
**Última atualização:** 23/11/2025

