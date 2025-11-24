# 🚀 DeBrief - Guia Rápido de Desenvolvimento

## ⚡ Início Rápido

### **Fazer Deploy de Mudanças**

```bash
# Mudanças simples (código Python/JS)
./scripts/deploy-rapido.sh

# Mudanças com dependências
./scripts/deploy.sh
```

### **Testar o Sistema**

👉 **https://debrief.interce.com.br**

---

## 📁 Estrutura do Projeto

```
debrief/
├── backend/           # API FastAPI
│   ├── app/
│   │   ├── api/      # Endpoints
│   │   ├── models/   # SQLAlchemy models
│   │   ├── schemas/  # Pydantic schemas
│   │   └── services/ # Lógica de negócio
│   └── alembic/      # Migrations
│
├── frontend/         # React + Vite
│   └── src/
│       ├── pages/    # Páginas
│       ├── components/ # Componentes
│       └── services/   # API calls
│
├── scripts/          # Scripts de deploy
│   ├── deploy.sh
│   └── deploy-rapido.sh
│
└── docs/            # Documentação
    ├── WORKFLOW_DESENVOLVIMENTO.md    # Workflow completo
    ├── CADDY_CLOUDFLARE_SSL.md       # Configuração SSL
    └── GUIA_CONEXAO_WHATSAPP_WPPCONNECT.md
```

---

## 🔄 Workflow

```
1. Editar código no Cursor
2. Executar ./scripts/deploy-rapido.sh
3. Testar em https://debrief.interce.com.br
```

---

## 📚 Documentação Importante

| Documento | Descrição |
|-----------|-----------|
| `WORKFLOW_DESENVOLVIMENTO.md` | Workflow completo de desenvolvimento |
| `CADDY_CLOUDFLARE_SSL.md` | Configuração SSL e certificados |
| `GUIA_CONEXAO_WHATSAPP_WPPCONNECT.md` | Conexão WhatsApp |
| `ARQUITETURA_WHATSAPP_WPPCONNECT.md` | Arquitetura WhatsApp |
| `CONCLUSAO_MODULO_TRELLO.md` | Integração Trello |

---

## 🌐 URLs do Sistema

| Serviço | URL |
|---------|-----|
| **App Principal** | https://debrief.interce.com.br |
| **API Docs** | https://debrief.interce.com.br/api/docs |
| **WPP Connect** | https://wpp.interce.com.br |
| **WPP Manager** | https://wpp.interce.com.br/manager |

---

## 🔑 Credenciais

### **Servidor VPS**
```
Host: 82.25.92.217
User: root
SSH: ssh debrief
```

### **Banco de Dados**
```
Host: localhost (via container debrief_db)
Port: 5432
User: postgres
Pass: Mslestrategia.2025@
DB: dbrief
```

### **WPPConnect / Evolution API**
```
Server: https://wpp.interce.com.br
API Key: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
Instance: debrief
```

---

## 🛠️ Comandos Úteis

### **Ver logs em tempo real**
```bash
ssh debrief "cd /var/www/debrief && docker-compose logs -f backend"
```

### **Status dos containers**
```bash
ssh debrief "cd /var/www/debrief && docker-compose ps"
```

### **Restart rápido**
```bash
ssh debrief "cd /var/www/debrief && docker-compose restart backend frontend"
```

### **Executar migrations**
```bash
ssh debrief "cd /var/www/debrief && docker-compose exec backend alembic upgrade head"
```

---

## 🐛 Problemas Comuns

### **Erro de autenticação Git**
```bash
git remote set-url origin https://TOKEN@github.com/alexvseo/DEBRIEF.git
```

### **Container unhealthy**
```bash
ssh debrief "cd /var/www/debrief && docker-compose restart backend"
```

### **Mudanças não aparecendo**
```bash
# No servidor
ssh debrief "cd /var/www/debrief && git status"
ssh debrief "cd /var/www/debrief && docker-compose build backend frontend"
ssh debrief "cd /var/www/debrief && docker-compose up -d --force-recreate"
```

---

## ✅ Status Atual

- ✅ **Backend:** FastAPI em Python 3.12
- ✅ **Frontend:** React + Vite
- ✅ **Banco:** PostgreSQL 16
- ✅ **SSL:** Let's Encrypt (DNS Challenge)
- ✅ **Proxy:** Caddy com Cloudflare
- ✅ **WhatsApp:** Evolution API v2.1.1
- ✅ **Integração:** Trello configurado
- ✅ **Deploy:** Scripts automatizados

---

## 🎯 Próximos Passos

1. ✅ Workflow de deploy automatizado (CONCLUÍDO)
2. ⏳ Conectar WhatsApp via QR Code
3. ⏳ Testar envio de notificações
4. ⏳ Testar criação de cards no Trello
5. ⏳ Ajustes finos na UI

---

**Última atualização:** 23/11/2025  
**Versão:** 2.0  
**Status:** ✅ Operacional

