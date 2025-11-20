# 🔧 Correção: Erro ao Fazer Login no Servidor

**Data:** 19/11/2025  
**Problema:** Erro "Erro ao fazer login" ao acessar http://82.25.92.217:2022/login  
**Status:** ✅ CORRIGIDO

---

## 🔴 Problema Identificado

O frontend estava tentando se conectar ao backend usando uma URL absoluta (`http://localhost:8000/api`), mas quando rodando no servidor, essa URL não estava acessível.

**Causa:**
- Frontend configurado para usar `http://localhost:8000/api` por padrão
- No Docker, o nginx já faz proxy de `/api` para o backend
- O frontend não estava usando a URL relativa `/api` em produção

---

## ✅ Solução Implementada

### 1. **Atualizar `api.js` para usar URL relativa em produção**

```javascript
// Antes
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

// Depois
const API_BASE_URL = import.meta.env.VITE_API_URL || 
  (import.meta.env.PROD ? '/api' : 'http://localhost:8000/api')
```

**Resultado:**
- ✅ Em produção (Docker): usa `/api` (proxy do nginx)
- ✅ Em desenvolvimento: usa `http://localhost:8000/api`

### 2. **Atualizar `Dockerfile` para aceitar build args**

```dockerfile
# Build args para variáveis de ambiente
ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

# Build da aplicação para produção
RUN npm run build
```

### 3. **Atualizar `docker-compose.yml` para passar build arg**

```yaml
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile
    args:
      - VITE_API_URL=/api
```

### 4. **Atualizar `env.example`**

```bash
# URL da API Backend
# Desenvolvimento: http://localhost:8000/api
# Produção (Docker): /api (usa proxy do nginx)
VITE_API_URL=/api
```

---

## 🚀 Como Aplicar no Servidor

### Opção 1: Rebuild Completo (Recomendado)

```bash
# No servidor
ssh root@82.25.92.217
cd ~/debrief  # ou /var/www/debrief

# Pull das atualizações
git pull

# Parar containers
docker-compose down

# Rebuild do frontend (força rebuild)
docker-compose build --no-cache frontend

# Iniciar containers
docker-compose up -d

# Verificar logs
docker-compose logs -f frontend
```

### Opção 2: Rebuild Rápido

```bash
# No servidor
cd ~/debrief

# Pull atualizações
git pull

# Rebuild e reiniciar
docker-compose up -d --build frontend

# Verificar
docker-compose ps
docker-compose logs frontend | tail -20
```

---

## 🔍 Verificações

### 1. Verificar se o frontend está usando `/api`

```bash
# No servidor, verificar logs do frontend
docker-compose logs frontend | grep -i "api\|error"

# Verificar se o container está rodando
docker-compose ps
```

### 2. Testar Conexão

```bash
# Testar se o nginx está fazendo proxy corretamente
curl http://82.25.92.217:2022/api/health

# Deve retornar: {"status":"ok"}
```

### 3. Verificar no Navegador

1. Abra o DevTools (F12)
2. Vá para a aba **Network**
3. Tente fazer login
4. Verifique se as requisições estão indo para `/api/auth/login`
5. Verifique se não há erros de CORS ou conexão

---

## 📊 Fluxo de Requisições

### Antes (❌ Erro):
```
Frontend (82.25.92.217:2022)
  ↓
Tenta: http://localhost:8000/api/auth/login
  ↓
❌ Erro: localhost não acessível do navegador
```

### Depois (✅ Funcionando):
```
Frontend (82.25.92.217:2022)
  ↓
Requisição: /api/auth/login
  ↓
Nginx Proxy: /api → http://backend:8000
  ↓
Backend: Processa login
  ↓
✅ Sucesso
```

---

## 🐛 Troubleshooting

### Erro persiste após rebuild

1. **Limpar cache do navegador:**
   - Pressione `Ctrl+Shift+Delete`
   - Limpe cache e cookies
   - Ou use modo anônimo

2. **Verificar se o backend está rodando:**
   ```bash
   docker-compose ps backend
   docker-compose logs backend | tail -20
   ```

3. **Verificar se o nginx está fazendo proxy:**
   ```bash
   # Testar proxy diretamente
   curl -v http://82.25.92.217:2022/api/health
   ```

4. **Verificar variável de ambiente no build:**
   ```bash
   # Verificar se a variável foi passada no build
   docker-compose exec frontend env | grep VITE
   ```

### Erro de CORS

Se ainda houver erro de CORS:

1. Verificar se o backend tem a URL do frontend no CORS:
   ```python
   # backend/app/core/config.py
   CORS_ORIGINS: list[str] = [
       "http://82.25.92.217:2022",
       # ...
   ]
   ```

2. Reiniciar o backend:
   ```bash
   docker-compose restart backend
   ```

### Erro 502 Bad Gateway

Isso significa que o nginx não consegue se conectar ao backend:

1. Verificar se o backend está na mesma rede Docker:
   ```bash
   docker network inspect debrief_debrief-network
   ```

2. Verificar se o backend está respondendo:
   ```bash
   docker-compose exec backend curl http://localhost:8000/health
   ```

3. Verificar logs do nginx:
   ```bash
   docker-compose logs frontend | grep -i error
   ```

---

## ✅ Checklist de Verificação

- [ ] Código atualizado no repositório
- [ ] Pull feito no servidor
- [ ] Frontend rebuildado (`docker-compose build --no-cache frontend`)
- [ ] Containers reiniciados (`docker-compose up -d`)
- [ ] Backend rodando (`docker-compose ps backend`)
- [ ] Frontend rodando (`docker-compose ps frontend`)
- [ ] Proxy funcionando (`curl http://82.25.92.217:2022/api/health`)
- [ ] Login funcionando no navegador

---

## 📝 Arquivos Modificados

1. ✅ `frontend/src/services/api.js` - URL relativa em produção
2. ✅ `frontend/Dockerfile` - Build args para VITE_API_URL
3. ✅ `frontend/env.example` - Documentação atualizada
4. ✅ `docker-compose.yml` - Build args configurados

---

## 🎯 Resultado Esperado

Após aplicar as correções:

1. ✅ Frontend acessível em: http://82.25.92.217:2022
2. ✅ Login funcionando corretamente
3. ✅ Requisições indo para `/api` (proxy do nginx)
4. ✅ Backend respondendo corretamente
5. ✅ Sem erros no console do navegador

---

## 🚀 Próximos Passos

1. ✅ **Fazer push** das alterações:
   ```bash
   git add .
   git commit -m "🔧 fix: Corrigir URL da API no frontend para usar proxy nginx"
   git push
   ```

2. ✅ **No servidor, fazer pull e rebuild:**
   ```bash
   git pull
   docker-compose build --no-cache frontend
   docker-compose up -d
   ```

3. ✅ **Testar login:**
   - Acesse: http://82.25.92.217:2022/login
   - Credenciais: `admin` / `admin123`
   - Deve funcionar sem erros

---

**✅ Problema corrigido!**

**🔧 Execute o rebuild do frontend no servidor para aplicar as correções!**

