# 🚀 Início Rápido - Docker DeBrief

## 3 Passos Para Iniciar

### 1️⃣ Configurar Variáveis

```bash
cp env.docker.example backend/.env
nano backend/.env
```

**Edite apenas estas linhas:**
```bash
SECRET_KEY=<cole-aqui-resultado-do-comando-abaixo>
ENCRYPTION_KEY=<cole-aqui-resultado-do-comando-abaixo>
```

**Gerar chaves:**
```bash
# SECRET_KEY
openssl rand -hex 32

# ENCRYPTION_KEY
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 2️⃣ Iniciar

```bash
./docker-deploy.sh
```

Escolha a opção **1** (Iniciar aplicação)

### 3️⃣ Acessar

- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8000
- **Docs:** http://localhost:8000/docs

---

## ✅ Login Padrão

```
Username: admin
Password: admin123
```

---

## 🛑 Parar

```bash
./docker-deploy.sh
```

Escolha a opção **2** (Parar aplicação)

---

## 📊 Ver Logs

```bash
./docker-deploy.sh
```

Escolha a opção **4** (Ver logs)

ou

```bash
docker-compose logs -f
```

---

## 🔧 Problemas?

### Container não inicia?
```bash
docker-compose logs backend
docker-compose logs frontend
```

### Erro de conexão com banco?
Verifique as credenciais em `backend/.env`:
```
DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief
```

### Frontend não carrega?
```bash
docker-compose restart frontend
```

---

## 📚 Documentação Completa

- `DOCKER_README.md` - Guia completo
- `DOCKER_CONFIGURADO.md` - Detalhes técnicos

---

**🎉 Isso é tudo! Sistema rodando em minutos!**

