# 🎯 DeBrief - Configuração Cursor AI

Este diretório contém configurações e scripts para facilitar o desenvolvimento e gestão do projeto DeBrief com acesso automático ao VPS da Hostinger.

---

## 🚀 Script de Gestão Automática

### Como Usar

```bash
# Executar o script de gestão
./.cursor/debrief-config.sh
```

### Funcionalidades Disponíveis

O script oferece um menu interativo com as seguintes opções:

#### 🔌 Gestão de Túnel SSH (Banco de Dados)
1. **Iniciar Túnel SSH** - Conecta o banco PostgreSQL remoto em localhost:5433
2. **Parar Túnel SSH** - Encerra o túnel ativo
3. **Status do Túnel** - Verifica se o túnel está ativo

#### 🖥️ Gestão do Servidor
4. **Conectar ao Servidor** - Abre sessão SSH interativa
5. **Listar Arquivos** - Mostra conteúdo do diretório do projeto
6. **Ver Containers Docker** - Status dos containers no servidor
7. **Logs Backend** - Últimas 50 linhas de log do backend
8. **Logs Frontend** - Últimas 50 linhas de log do frontend

#### 🔄 Deploy e Atualizações
9. **Git Pull** - Atualiza código no servidor
10. **Deploy Completo** - Pull + Build + Restart + Migrations
11. **Backup Banco** - Cria backup do PostgreSQL com opção de download
12. **Comando Customizado** - Executa qualquer comando no servidor
13. **Aplicar Migrations** - Roda alembic upgrade head no servidor

#### 🏠 Ambiente Local
14. **Iniciar Ambiente Local** - Sobe Docker local + túnel SSH
15. **Parar Ambiente Local** - Derruba containers locais
16. **Status Ambiente Local** - Verifica status dos containers e túnel

---

## ⚡ Atalhos Rápidos

### Desenvolvimento Local
```bash
# Iniciar tudo (túnel + Docker)
./.cursor/debrief-config.sh
# Escolher opção 14

# Parar tudo
./.cursor/debrief-config.sh
# Escolher opção 15
```

### Deploy no Servidor
```bash
# Deploy automático completo
./.cursor/debrief-config.sh
# Escolher opção 10
```

### Acessos Diretos
```bash
# SSH direto (usa configuração ~/.ssh/config)
ssh debrief

# Túnel SSH manual
ssh -f -N -L 5433:127.0.0.1:5432 debrief
```

---

## 📋 Configurações Importantes

### SSH Host Alias
O arquivo `~/.ssh/config` contém:
```
Host debrief
  HostName 82.25.92.217
  User root
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 60
  ServerAliveCountMax 3
  ControlMaster auto
  ControlPath ~/.ssh/cm-%r@%h:%p
  ControlPersist 4h
```

### Túnel SSH
- **Porta Local:** 5433
- **Servidor:** 127.0.0.1:5432
- **Banco:** dbrief
- **Usuário:** postgres
- **Senha:** <redacted-legacy-password>

### Diretórios
- **Local:** `/Users/alexsantos/Documents/PROJETOS DEV COM IA/DEBRIEF`
- **Servidor:** `/var/www/debrief`
- **Backups:** `./backups/`

---

## 🔐 Acesso Automático

O sistema está configurado para acesso automático via:
1. **Chave SSH:** `~/.ssh/id_ed25519`
2. **Passphrase:** `<redacted-passphrase>` (configurada no ssh-agent)
3. **Conexão Persistente:** Mantém conexão por 4 horas
4. **Túnel Automático:** Script gerencia túnel SSH para banco

---

## 🐳 Docker - Desenvolvimento Local

### URLs de Acesso
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs
- **Health Check:** http://localhost:8000/api/health

### Comandos Manuais
```bash
# Iniciar
docker-compose -f docker-compose.dev.yml up -d

# Parar
docker-compose -f docker-compose.dev.yml down

# Logs
docker logs debrief-backend -f
docker logs debrief-frontend -f

# Migrations
docker exec debrief-backend alembic upgrade head
```

---

## 📚 Documentação Completa

Consulte o relatório completo em:
```
docs/RELATORIO_MEMORIA_PROJETO_DEBRIEF.md
```

Este documento contém:
- ✅ Todas as configurações SSH e túnel
- ✅ Guia completo de desenvolvimento
- ✅ Estrutura do projeto
- ✅ Sistema de notificações WhatsApp (status)
- ✅ Comandos de referência rápida
- ✅ Troubleshooting

---

## 🛠️ Troubleshooting Rápido

### Túnel não conecta
```bash
# Matar processos da porta
lsof -ti:5433 | xargs kill -9

# Reiniciar túnel
./.cursor/debrief-config.sh
# Opção 1
```

### Login não funciona
```bash
# Verificar backend
curl http://localhost:8000/api/health

# Ver logs
docker logs debrief-backend --tail 50

# Credenciais padrão
username: admin
password: admin123
```

### Containers não iniciam
```bash
# Rebuild completo
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d --build --force-recreate
```

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Consultar `docs/RELATORIO_MEMORIA_PROJETO_DEBRIEF.md`
2. Verificar logs dos containers
3. Testar conexão SSH: `ssh debrief "echo 'OK'"`
4. Verificar túnel: `lsof -i :5433`

---

**Última Atualização:** 23 de Novembro de 2025  
**Versão:** 1.0


