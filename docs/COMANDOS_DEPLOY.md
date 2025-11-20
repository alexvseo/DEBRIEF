# 🚀 Comandos de Deploy - DeBrief

**Servidor:** 82.25.92.217  
**Banco:** dbrief (já configurado)

---

## ⚡ Deploy Rápido (5 minutos)

### 1️⃣ Conectar ao Servidor

```bash
ssh root@82.25.92.217
```

### 2️⃣ Clonar e Configurar

```bash
# Criar diretório
mkdir -p /var/www && cd /var/www

# Clonar repositório (SUBSTITUA SEU-USUARIO)
git clone https://github.com/SEU-USUARIO/debrief.git
cd debrief

# Configurar ambiente
cp env.docker.example backend/.env
nano backend/.env
```

**No arquivo `backend/.env`, configure:**
```bash
# Gerar SECRET_KEY
openssl rand -hex 32

# Gerar ENCRYPTION_KEY
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Colar as chaves geradas no .env:
SECRET_KEY=<cole-aqui>
ENCRYPTION_KEY=<cole-aqui>
FRONTEND_URL=http://82.25.92.217:2022
```

### 3️⃣ Deploy

```bash
# Iniciar aplicação
docker-compose up -d --build

# Aguardar 30 segundos
sleep 30

# Inicializar banco
docker-compose exec backend alembic upgrade head
docker-compose exec backend python init_db.py

# Verificar
docker-compose ps
docker-compose logs -f
```

### 4️⃣ Acessar

- **Frontend:** http://82.25.92.217:2022
- **Backend:** http://82.25.92.217:8000/docs
- **Login:** admin / admin123

---

## 🔄 Atualizar Aplicação

```bash
ssh root@82.25.92.217
cd /var/www/debrief
git pull
docker-compose down
docker-compose up -d --build
docker-compose logs -f
```

---

## 🐛 Troubleshooting

### Ver Logs
```bash
docker-compose logs -f
docker-compose logs backend
docker-compose logs frontend
```

### Reiniciar
```bash
docker-compose restart
```

### Rebuild Completo
```bash
docker-compose down -v
docker-compose up -d --build
```

### Entrar no Container
```bash
docker-compose exec backend bash
docker-compose exec frontend sh
```

---

## 📊 Monitoramento

```bash
# Status
docker-compose ps

# Recursos
docker stats

# Health
curl http://localhost:8000/health
curl http://localhost:3000
```

---

## 💾 Backup

```bash
# Backup manual
pg_dump -h 82.25.92.217 -U root -d dbrief > backup_$(date +%Y%m%d).sql

# Automatizar (cron)
crontab -e
# Adicionar: 0 3 * * * pg_dump -h 82.25.92.217 -U root -d dbrief | gzip > /backups/dbrief_$(date +\%Y\%m\%d).sql.gz
```

---

## 🔒 Firewall

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw enable
```

---

## 📝 Comandos Úteis

```bash
# Parar tudo
docker-compose down

# Iniciar tudo
docker-compose up -d

# Ver status
docker-compose ps

# Ver uso de disco
df -h
docker system df

# Limpar Docker
docker system prune -a

# Backup código
tar -czf debrief_backup_$(date +%Y%m%d).tar.gz /var/www/debrief
```

---

## ✅ Checklist

- [ ] Servidor acessível via SSH
- [ ] Repositório clonado
- [ ] Variáveis configuradas
- [ ] Docker instalado
- [ ] Aplicação rodando
- [ ] Banco inicializado
- [ ] Firewall configurado
- [ ] Acesso funcionando

---

**📚 Documentação completa:** `DEPLOY_SERVIDOR.md`

