# 🐳 Docker - DeBrief

Guia completo para deploy da aplicação DeBrief usando Docker.

---

## 📋 Pré-requisitos

- **Docker** instalado: [Download Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** instalado: [Download Docker Compose](https://docs.docker.com/compose/install/)
- Acesso ao servidor PostgreSQL remoto

---

## 🚀 Quick Start (Início Rápido)

### 1️⃣ Configurar Variáveis de Ambiente

```bash
# Copiar arquivo de exemplo para backend/.env
cp env.docker.example backend/.env

# Editar backend/.env e configurar as chaves de segurança
nano backend/.env  # ou use seu editor favorito
```

**Variáveis IMPORTANTES para configurar:**
- `SECRET_KEY` - Gere uma nova: `openssl rand -hex 32`
- `ENCRYPTION_KEY` - Gere com Python (ver instruções no arquivo)

### 2️⃣ Iniciar Aplicação

**Opção A: Usando o script automatizado** (Recomendado)
```bash
./docker-deploy.sh
```

**Opção B: Usando docker-compose diretamente**
```bash
docker-compose up -d
```

### 3️⃣ Acessar Aplicação

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **Docs API:** http://localhost:8000/docs

---

## 🗄️ Configuração do Banco de Dados

### Banco de Dados Remoto (Configurado)

A aplicação está configurada para conectar ao servidor PostgreSQL remoto:

```
Host: 82.25.92.217
Port: 5432
Database: dbrief
User: root
Password: Mslestrategia.2025@
```

**SSH Access:**
```
Host: 82.25.92.217
Port: 22
```

### Conexão via SSH Tunnel (Opcional)

Se preferir conectar via túnel SSH:

```bash
ssh -L 5432:localhost:5432 user@82.25.92.217
```

---

## 📦 Estrutura Docker

### Services (Serviços)

1. **backend** - FastAPI (porta 8000)
   - Python 3.11
   - Uvicorn
   - Conecta ao PostgreSQL remoto

2. **frontend** - React + Nginx (porta 3000)
   - Node.js 18 (build)
   - Nginx Alpine (produção)
   - Proxy reverso para backend

### Volumes

- `./backend/uploads` - Arquivos enviados (montado localmente)
- `./backend` - Código fonte (desenvolvimento)

### Networks

- `debrief-network` - Bridge network para comunicação entre containers

---

## 🛠️ Comandos Úteis

### Gerenciamento de Containers

```bash
# Iniciar aplicação
docker-compose up -d

# Parar aplicação
docker-compose down

# Reiniciar aplicação
docker-compose restart

# Ver status
docker-compose ps

# Ver logs (todos os serviços)
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f backend
docker-compose logs -f frontend

# Rebuild (após mudanças no código)
docker-compose build --no-cache
docker-compose up -d
```

### Acessar Containers

```bash
# Entrar no container do backend
docker-compose exec backend bash

# Entrar no container do frontend
docker-compose exec frontend sh

# Executar comandos no backend
docker-compose exec backend python manage.py
```

### Banco de Dados

```bash
# Conectar ao PostgreSQL remoto via container
docker-compose exec backend psql postgresql://root:Mslestrategia.2025%40@82.25.92.217:5432/dbrief

# Executar migrations
docker-compose exec backend alembic upgrade head

# Criar seed de dados
docker-compose exec backend python init_db.py
```

### Limpeza

```bash
# Parar e remover containers
docker-compose down

# Remover containers e volumes
docker-compose down -v

# Remover tudo (containers, volumes, networks)
docker-compose down -v --remove-orphans

# Limpar imagens não usadas
docker image prune -a
```

---

## 🔧 Configurações Avançadas

### Portas Customizadas

Edite o `docker-compose.yml`:

```yaml
services:
  backend:
    ports:
      - "8080:8000"  # Host:Container
  
  frontend:
    ports:
      - "80:80"      # Host:Container
```

### Variáveis de Ambiente

Adicione no `docker-compose.yml` ou crie um arquivo `.env`:

```yaml
environment:
  - SECRET_KEY=${SECRET_KEY}
  - DATABASE_URL=${DATABASE_URL}
```

### Volumes Persistentes

Para dados que devem persistir:

```yaml
volumes:
  uploads:
    driver: local
  
services:
  backend:
    volumes:
      - uploads:/app/uploads
```

---

## 🚢 Deploy em Produção

### 1️⃣ Preparar Ambiente

```bash
# Clonar repositório no servidor
git clone <seu-repo>
cd DEBRIEF

# Configurar variáveis de ambiente
cp env.docker.example backend/.env
nano backend/.env
```

### 2️⃣ Configurar Domínio

Edite `frontend/nginx.conf` e `backend/.env`:

```nginx
# nginx.conf
server_name seudominio.com;
```

```bash
# backend/.env
FRONTEND_URL=https://seudominio.com
```

### 3️⃣ SSL/HTTPS com Certbot (Opcional)

```bash
# Instalar Certbot
sudo apt-get install certbot python3-certbot-nginx

# Obter certificado
sudo certbot --nginx -d seudominio.com

# Renovação automática (cron)
sudo crontab -e
# Adicionar: 0 0 * * * certbot renew --quiet
```

### 4️⃣ Deploy

```bash
# Build e iniciar
docker-compose -f docker-compose.yml up -d --build

# Verificar logs
docker-compose logs -f
```

### 5️⃣ Manutenção

```bash
# Atualizar código
git pull
docker-compose down
docker-compose up -d --build

# Backup do banco (remoto)
pg_dump -h 82.25.92.217 -U root -d dbrief > backup_$(date +%Y%m%d).sql

# Restore
psql -h 82.25.92.217 -U root -d dbrief < backup.sql
```

---

## 🐛 Troubleshooting

### Problema: Container não inicia

```bash
# Ver logs detalhados
docker-compose logs backend
docker-compose logs frontend

# Verificar se as portas estão livres
lsof -i :8000
lsof -i :3000

# Rebuild forçado
docker-compose build --no-cache
docker-compose up -d
```

### Problema: Erro de conexão com banco

```bash
# Testar conexão do host
psql postgresql://root:Mslestrategia.2025%40@82.25.92.217:5432/dbrief

# Testar do container
docker-compose exec backend python -c "from app.core.database import engine; engine.connect()"

# Verificar variáveis de ambiente
docker-compose exec backend env | grep DATABASE
```

### Problema: Frontend não carrega

```bash
# Verificar se o build foi bem-sucedido
docker-compose logs frontend

# Rebuild do frontend
docker-compose build frontend --no-cache
docker-compose up -d frontend

# Testar nginx
docker-compose exec frontend nginx -t
```

### Problema: Permissões de arquivo

```bash
# Ajustar permissões da pasta uploads
chmod -R 777 backend/uploads

# Recriar container
docker-compose down
docker-compose up -d
```

---

## 📊 Monitoramento

### Health Checks

Os containers possuem health checks automáticos:

```bash
# Ver status de saúde
docker-compose ps

# Verificar logs de health check
docker inspect debrief-backend | grep -A 10 Health
```

### Recursos do Sistema

```bash
# Ver uso de recursos
docker stats

# Ver uso de disco
docker system df

# Limpar espaço
docker system prune -a
```

---

## 🔐 Segurança

### Checklist de Segurança

- [ ] Gerar nova `SECRET_KEY` para produção
- [ ] Gerar nova `ENCRYPTION_KEY` para produção
- [ ] Configurar CORS adequadamente
- [ ] Usar HTTPS em produção
- [ ] Firewall configurado (portas 80, 443, 22)
- [ ] Backup regular do banco de dados
- [ ] Senhas fortes para PostgreSQL
- [ ] SSH com chave pública (desabilitar senha)
- [ ] Atualizar dependências regularmente

### Gerar Chaves Seguras

```bash
# SECRET_KEY
openssl rand -hex 32

# ENCRYPTION_KEY
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

---

## 📝 Logs e Debugging

### Localização dos Logs

```bash
# Logs do Docker
docker-compose logs -f

# Logs dentro do container
docker-compose exec backend tail -f /app/logs/app.log

# Logs do sistema
journalctl -u docker.service -f
```

### Debug Mode

Para desenvolvimento, altere no `docker-compose.yml`:

```yaml
backend:
  environment:
    - ENVIRONMENT=development
    - DEBUG=True
  command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 🎯 Próximos Passos

1. ✅ Configurar variáveis de ambiente
2. ✅ Testar localmente com `docker-compose up`
3. ✅ Verificar conexão com banco remoto
4. ✅ Testar todas as funcionalidades
5. ⏳ Configurar SSL/HTTPS
6. ⏳ Deploy em servidor de produção
7. ⏳ Configurar backup automático
8. ⏳ Configurar monitoramento

---

## 📞 Suporte

Em caso de problemas:

1. Verificar logs: `docker-compose logs -f`
2. Verificar status: `docker-compose ps`
3. Verificar configurações: `backend/.env`
4. Consultar documentação do Docker

---

## 📚 Recursos Úteis

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [FastAPI Docker Guide](https://fastapi.tiangolo.com/deployment/docker/)
- [Nginx Docker Guide](https://hub.docker.com/_/nginx)

---

**✅ Configuração Docker pronta para uso!**

**🚀 Execute `./docker-deploy.sh` para começar!**

