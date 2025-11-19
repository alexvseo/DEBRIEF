# 🎯 Deploy no Servidor - Passo a Passo

**Você está aqui:** Código no GitHub ✅  
**Próximo passo:** Deploy no servidor 🚀

---

## 📋 O que você precisa

- ✅ Código já no GitHub
- ✅ Servidor: 82.25.92.217
- ✅ Acesso SSH: root@82.25.92.217
- ✅ Banco: dbrief (já configurado)

---

## 🚀 OPÇÃO 1: Deploy Automatizado (Recomendado)

### Passo 1: Enviar arquivos para o GitHub

```bash
cd /Users/alexmini/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
git push
```

### Passo 2: Conectar ao servidor

```bash
ssh root@82.25.92.217
```

### Passo 3: Clonar e executar script

```bash
# Clonar repositório
mkdir -p /var/www && cd /var/www
git clone https://github.com/SEU-USUARIO/debrief.git
cd debrief

# Executar setup automatizado
chmod +x setup-servidor.sh
./setup-servidor.sh
```

O script vai:
- ✅ Instalar Docker e Docker Compose
- ✅ Configurar diretórios
- ✅ Iniciar aplicação
- ✅ Configurar banco de dados
- ✅ Configurar firewall

---

## 🚀 OPÇÃO 2: Deploy Manual (Passo a Passo)

### 1️⃣ Push para GitHub

```bash
cd /Users/alexmini/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
git push
```

### 2️⃣ Conectar ao Servidor

```bash
ssh root@82.25.92.217
```

### 3️⃣ Instalar Docker (se necessário)

```bash
# Atualizar sistema
apt-get update && apt-get upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verificar
docker --version
docker-compose --version
```

### 4️⃣ Clonar Repositório

```bash
mkdir -p /var/www && cd /var/www
git clone https://github.com/SEU-USUARIO/debrief.git
cd debrief
```

### 5️⃣ Configurar Variáveis

```bash
# Copiar template
cp env.docker.example backend/.env

# Editar
nano backend/.env
```

**Configurar estas variáveis:**

```bash
# Gerar chaves
openssl rand -hex 32  # SECRET_KEY
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"  # ENCRYPTION_KEY

# Colar no .env:
SECRET_KEY=<cole-aqui>
ENCRYPTION_KEY=<cole-aqui>
FRONTEND_URL=http://82.25.92.217:3000
```

### 6️⃣ Iniciar Aplicação

```bash
docker-compose up -d --build
```

### 7️⃣ Inicializar Banco

```bash
# Aguardar 30 segundos para containers iniciarem
sleep 30

# Executar migrations
docker-compose exec backend alembic upgrade head

# Criar dados iniciais
docker-compose exec backend python init_db.py
```

### 8️⃣ Configurar Firewall

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw enable
```

### 9️⃣ Verificar

```bash
docker-compose ps
docker-compose logs -f
```

---

## 🌐 Acessar Aplicação

Após o deploy:

- **Frontend:** http://82.25.92.217:3000
- **Backend API:** http://82.25.92.217:8000
- **Documentação:** http://82.25.92.217:8000/docs

**Login padrão:**
- Username: `admin`
- Password: `admin123`

---

## ✅ Verificações

```bash
# Status dos containers
docker-compose ps

# Logs em tempo real
docker-compose logs -f

# Testar backend
curl http://localhost:8000/health

# Testar frontend
curl http://localhost:3000
```

---

## 🔄 Atualizar Aplicação (Após Mudanças)

```bash
ssh root@82.25.92.217
cd /var/www/debrief
git pull
docker-compose down
docker-compose up -d --build
```

---

## 📊 Monitoramento

```bash
# Ver logs
docker-compose logs -f

# Ver recursos
docker stats

# Ver status
docker-compose ps
```

---

## 💾 Backup Automático

```bash
# Criar diretório
mkdir -p /backups

# Configurar cron
crontab -e

# Adicionar (backup diário às 3h)
0 3 * * * pg_dump -h 82.25.92.217 -U root -d dbrief | gzip > /backups/dbrief_$(date +\%Y\%m\%d).sql.gz
```

---

## 🐛 Problemas Comuns

### Container não inicia
```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose build --no-cache
docker-compose up -d
```

### Porta já em uso
```bash
lsof -i :3000
lsof -i :8000
kill -9 <PID>
```

### Erro de conexão com banco
```bash
docker-compose exec backend python -c "from app.core.database import engine; engine.connect()"
```

---

## 📚 Documentação Completa

- **`DEPLOY_SERVIDOR.md`** - Guia completo detalhado
- **`COMANDOS_DEPLOY.md`** - Comandos rápidos
- **`DOCKER_README.md`** - Documentação Docker
- **`setup-servidor.sh`** - Script automatizado

---

## 🎯 Resumo dos Comandos

### No seu computador (local):
```bash
cd /Users/alexmini/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
git push
```

### No servidor:
```bash
ssh root@82.25.92.217
mkdir -p /var/www && cd /var/www
git clone https://github.com/SEU-USUARIO/debrief.git
cd debrief
cp env.docker.example backend/.env
nano backend/.env  # Configure SECRET_KEY e ENCRYPTION_KEY
docker-compose up -d --build
docker-compose exec backend alembic upgrade head
docker-compose exec backend python init_db.py
```

### Acessar:
```
http://82.25.92.217:3000
Login: admin / admin123
```

---

## ✅ Checklist

- [ ] 1. Fazer push para GitHub
- [ ] 2. Conectar ao servidor SSH
- [ ] 3. Instalar Docker (se necessário)
- [ ] 4. Clonar repositório
- [ ] 5. Configurar variáveis (.env)
- [ ] 6. Iniciar com docker-compose
- [ ] 7. Inicializar banco de dados
- [ ] 8. Configurar firewall
- [ ] 9. Acessar aplicação
- [ ] 10. Trocar senha admin

---

## 🎉 Pronto!

Após seguir esses passos, sua aplicação estará rodando no servidor!

**Próximos passos (opcional):**
- [ ] Configurar domínio
- [ ] Instalar SSL (HTTPS)
- [ ] Configurar backup automático
- [ ] Configurar monitoramento

---

**🚀 Boa sorte com o deploy!**

**📞 Em caso de dúvidas, consulte `DEPLOY_SERVIDOR.md`**

