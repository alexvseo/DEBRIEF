# 🚀 Atualizar Servidor - Comandos Rápidos

## ⚡ Método Rápido (Recomendado)

Execute do seu computador:

```bash
./scripts/deploy/atualizar-servidor-completo.sh
```

O script fará tudo automaticamente!

---

## 📋 Método Manual (Passo a Passo)

### 1. Conectar ao servidor

```bash
ssh root@82.25.92.217
```

### 2. Ir para o diretório do projeto

```bash
cd /root/debrief
```

### 3. Atualizar código do Git

```bash
git checkout -- .
git reset --hard HEAD
git pull origin main
```

### 4. Parar containers

```bash
docker-compose down
```

### 5. Reconstruir imagens

```bash
docker-compose build --no-cache
```

⏱️ **Isso pode levar 5-10 minutos**

### 6. Iniciar containers

```bash
docker-compose up -d
```

### 7. Aguardar inicialização

```bash
sleep 60
```

### 8. Verificar status

```bash
docker-compose ps
```

### 9. Verificar saúde

```bash
# Backend
curl http://localhost:8000/health

# Frontend
curl -I http://localhost:2022
```

---

## ✅ Verificar se Funcionou

1. **Acesse no navegador:**
   - Frontend: http://82.25.92.217:2022
   - Backend: http://82.25.92.217:2025/api/docs

2. **Teste o login:**
   - Username: `admin`
   - Password: `admin123`

---

## 🔍 Se Algo Der Errado

### Ver logs:

```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose logs caddy
```

### Reiniciar um serviço:

```bash
docker-compose restart backend
```

### Ver status completo:

```bash
docker-compose ps
```

---

## 📚 Documentação Completa

Para mais detalhes, veja: `docs/ATUALIZAR_SERVIDOR_COMPLETO.md`

