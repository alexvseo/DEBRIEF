# 🚀 Deploy no Servidor - DeBrief

**Servidor:** 82.25.92.217  
**Status:** Pronto para Deploy

---

## 📋 Pré-requisitos no Servidor

O servidor precisa ter instalado:
- Docker
- Docker Compose
- Git
- Acesso SSH

---

## 🎯 Passo a Passo - Deploy Completo

### 1️⃣ Conectar ao Servidor via SSH

```bash
ssh root@82.25.92.217
```

### 2️⃣ Instalar Docker (se necessário)

```bash
# Atualizar sistema
apt-get update && apt-get upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker --version
docker-compose --version
```

### 3️⃣ Clonar Repositório do GitHub

```bash
# Criar diretório para projetos
mkdir -p /var/www
cd /var/www

# Clonar repositório (SUBSTITUA pela URL do seu repo)
git clone https://github.com/SEU-USUARIO/debrief.git
cd debrief
```

### 4️⃣ Configurar Variáveis de Ambiente

```bash
# Copiar template
cp env.docker.example backend/.env

# Editar arquivo
nano backend/.env
```

**Configure as seguintes variáveis:**

```bash
# ==================== BANCO DE DADOS ====================
DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief

# ==================== SEGURANÇA ====================
# GERAR NOVAS CHAVES!
SECRET_KEY=<GERAR-NOVA-CHAVE>
ENCRYPTION_KEY=<GERAR-NOVA-CHAVE>

# ==================== CORS ====================
# Ajustar para seu domínio ou IP
FRONTEND_URL=http://82.25.92.217:2022
```

**Gerar chaves de segurança:**

```bash
# SECRET_KEY
openssl rand -hex 32

# ENCRYPTION_KEY
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 5️⃣ Iniciar Aplicação com Docker

```bash
# Tornar script executável
chmod +x docker-deploy.sh

# Iniciar aplicação
./docker-deploy.sh
# Escolha opção 1 (Iniciar aplicação)

# OU diretamente:
docker-compose up -d --build
```

### 6️⃣ Verificar Status

```bash
# Ver containers rodando
docker-compose ps

# Ver logs
docker-compose logs -f

# Verificar saúde dos containers
docker ps
```

### 7️⃣ Inicializar Banco de Dados

```bash
# Executar migrations
docker-compose exec backend alembic upgrade head

# Criar seed de dados (usuários, tipos, prioridades)
docker-compose exec backend python init_db.py
```

### 8️⃣ Configurar Firewall

```bash
# Permitir portas necessárias
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 2022/tcp  # Frontend (temporário)
ufw allow 8000/tcp  # Backend (temporário)
ufw enable
```

### 9️⃣ Acessar Aplicação

- **Frontend:** http://82.25.92.217:2022
- **Backend API:** http://82.25.92.217:8000
- **Docs:** http://82.25.92.217:8000/docs

**Login padrão:**
- Username: `admin`
- Password: `admin123`

---

## 🔒 Configuração de Domínio e SSL (Opcional)

### Se você tem um domínio:

#### 1. Apontar Domínio para o Servidor

No seu provedor de DNS:
```
A Record: @ -> 82.25.92.217
A Record: www -> 82.25.92.217
```

#### 2. Instalar Certbot

```bash
apt-get install certbot python3-certbot-nginx -y
```

#### 3. Obter Certificado SSL

```bash
certbot --nginx -d seudominio.com -d www.seudominio.com
```

#### 4. Configurar Renovação Automática

```bash
certbot renew --dry-run
```

#### 5. Atualizar docker-compose.yml

```yaml
frontend:
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - /etc/letsencrypt:/etc/letsencrypt:ro
```

---

## 📊 Monitoramento

### Ver Logs em Tempo Real

```bash
# Todos os serviços
docker-compose logs -f

# Backend apenas
docker-compose logs -f backend

# Frontend apenas
docker-compose logs -f frontend
```

### Ver Uso de Recursos

```bash
docker stats
```

### Health Checks

```bash
# Backend
curl http://localhost:8000/health

# Frontend
curl http://localhost:3000
```

---

## 🔄 Atualizar Aplicação

Quando fizer alterações no código:

```bash
# 1. Conectar ao servidor
ssh root@82.25.92.217
cd /var/www/debrief

# 2. Puxar atualizações
git pull

# 3. Rebuild e reiniciar
docker-compose down
docker-compose up -d --build

# 4. Verificar
docker-compose logs -f
```

---

## 🗄️ Backup do Banco de Dados

### Backup Manual

```bash
# Backup completo
pg_dump -h 82.25.92.217 -U root -d dbrief > /backups/dbrief_$(date +%Y%m%d_%H%M%S).sql

# Backup comprimido
pg_dump -h 82.25.92.217 -U root -d dbrief | gzip > /backups/dbrief_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Backup Automático (Cron)

```bash
# Criar diretório de backups
mkdir -p /backups

# Editar crontab
crontab -e

# Adicionar linha (backup diário às 3h)
0 3 * * * pg_dump -h 82.25.92.217 -U root -d dbrief | gzip > /backups/dbrief_$(date +\%Y\%m\%d).sql.gz
```

### Restore

```bash
# Restore de backup
psql -h 82.25.92.217 -U root -d dbrief < backup.sql

# Restore de backup comprimido
gunzip -c backup.sql.gz | psql -h 82.25.92.217 -U root -d dbrief
```

---

## 🐛 Troubleshooting

### Container não inicia

```bash
# Ver logs detalhados
docker-compose logs backend
docker-compose logs frontend

# Rebuild forçado
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Erro de conexão com banco

```bash
# Testar conexão
docker-compose exec backend python -c "from app.core.database import engine; engine.connect()"

# Verificar variáveis
docker-compose exec backend env | grep DATABASE
```

### Porta já em uso

```bash
# Ver processos usando portas
lsof -i :2022
lsof -i :8000

# Matar processo
kill -9 <PID>
```

### Sem espaço em disco

```bash
# Ver uso de disco
df -h

# Limpar Docker
docker system prune -a --volumes
```

### Frontend não carrega

```bash
# Rebuild frontend
docker-compose build frontend --no-cache
docker-compose up -d frontend

# Testar nginx
docker-compose exec frontend nginx -t
```

---

## 🔧 Comandos Úteis

```bash
# Entrar no container backend
docker-compose exec backend bash

# Entrar no container frontend
docker-compose exec frontend sh

# Ver status
docker-compose ps

# Parar aplicação
docker-compose down

# Iniciar aplicação
docker-compose up -d

# Reiniciar serviço específico
docker-compose restart backend
docker-compose restart frontend

# Ver logs das últimas 100 linhas
docker-compose logs --tail=100

# Remover tudo e reiniciar
docker-compose down -v
docker-compose up -d --build
```

---

## 📈 Otimizações de Produção

### 1. Aumentar Workers do Backend

Editar `docker-compose.yml`:

```yaml
backend:
  command: gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### 2. Configurar Nginx como Proxy Reverso

```bash
# Instalar nginx no host
apt-get install nginx -y

# Configurar proxy
nano /etc/nginx/sites-available/debrief
```

```nginx
server {
    listen 80;
    server_name seudominio.com;

    location / {
        proxy_pass http://localhost:2022;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Ativar site
ln -s /etc/nginx/sites-available/debrief /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### 3. Configurar Auto-restart

```bash
# Criar systemd service
nano /etc/systemd/system/debrief.service
```

```ini
[Unit]
Description=DeBrief Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/var/www/debrief
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
# Ativar serviço
systemctl enable debrief
systemctl start debrief
```

---

## 🔐 Segurança Adicional

### 1. Mudar Porta SSH (Recomendado)

```bash
nano /etc/ssh/sshd_config
# Alterar: Port 22 -> Port 2222
systemctl restart sshd

# Atualizar firewall
ufw allow 2222/tcp
ufw delete allow 22/tcp
```

### 2. Configurar Fail2Ban

```bash
apt-get install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

### 3. Desabilitar Login Root (Depois de criar outro usuário)

```bash
# Criar usuário admin
adduser admin
usermod -aG sudo admin

# Testar login com novo usuário
# Depois desabilitar root:
nano /etc/ssh/sshd_config
# PermitRootLogin no
systemctl restart sshd
```

---

## ✅ Checklist de Deploy

- [ ] Conectado ao servidor via SSH
- [ ] Docker e Docker Compose instalados
- [ ] Repositório clonado do GitHub
- [ ] Variáveis de ambiente configuradas
- [ ] SECRET_KEY e ENCRYPTION_KEY geradas
- [ ] Aplicação iniciada com docker-compose
- [ ] Banco de dados inicializado
- [ ] Firewall configurado
- [ ] Aplicação acessível via navegador
- [ ] Login funcionando
- [ ] Backup configurado
- [ ] (Opcional) Domínio configurado
- [ ] (Opcional) SSL configurado
- [ ] (Opcional) Monitoramento configurado

---

## 📞 Comandos Rápidos (Copy & Paste)

### Deploy Inicial Completo

```bash
# 1. Conectar
ssh root@82.25.92.217

# 2. Clonar
cd /var/www
git clone https://github.com/SEU-USUARIO/debrief.git
cd debrief

# 3. Configurar
cp env.docker.example backend/.env
nano backend/.env
# Configure SECRET_KEY, ENCRYPTION_KEY

# 4. Deploy
chmod +x docker-deploy.sh
docker-compose up -d --build

# 5. Inicializar DB
docker-compose exec backend alembic upgrade head
docker-compose exec backend python init_db.py

# 6. Verificar
docker-compose ps
docker-compose logs -f
```

### Acessar

```
Frontend: http://82.25.92.217:3000
Backend:  http://82.25.92.217:8000
Docs:     http://82.25.92.217:8000/docs
```

**Login:** admin / admin123

---

## 🎉 Pronto!

Seu sistema estará rodando em:
- **Frontend:** http://82.25.92.217:2022
- **Backend:** http://82.25.92.217:8000

Para acessar de qualquer lugar, use o IP do servidor ou configure um domínio!

---

**🚀 Deploy concluído com sucesso!**

**📊 Monitoramento:** `docker-compose logs -f`

**🔄 Atualizar:** `git pull && docker-compose up -d --build`

