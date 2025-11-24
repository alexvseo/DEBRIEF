# 🔧 Correção: Erro de Login - Content-Type Incorreto

**Data:** 19/11/2025  
**Problema:** Erro ao fazer login no servidor  
**Causa:** Content-Type incorreto na requisição  
**Status:** ✅ CORRIGIDO

---

## 🔴 Problema Identificado

O frontend estava enviando o login com `Content-Type: multipart/form-data`, mas o FastAPI `OAuth2PasswordRequestForm` espera `application/x-www-form-urlencoded`.

**Erro:**
- Frontend enviava: `multipart/form-data` com `FormData`
- Backend esperava: `application/x-www-form-urlencoded` com dados URL-encoded

---

## ✅ Solução Implementada

### Antes (❌ Erro):
```javascript
// FastAPI OAuth2 espera FormData
const formData = new FormData()
formData.append('username', username)
formData.append('password', password)

const response = await api.post('/auth/login', formData, {
  headers: {
    'Content-Type': 'multipart/form-data',  // ❌ ERRADO
  },
})
```

### Depois (✅ Correto):
```javascript
// FastAPI OAuth2PasswordRequestForm espera application/x-www-form-urlencoded
// Usar URLSearchParams ao invés de FormData
const params = new URLSearchParams()
params.append('username', username)
params.append('password', password)

const response = await api.post('/auth/login', params.toString(), {
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',  // ✅ CORRETO
  },
})
```

---

## 📝 Detalhes Técnicos

### FastAPI OAuth2PasswordRequestForm

O `OAuth2PasswordRequestForm` do FastAPI é compatível com o padrão OAuth2 e espera:

1. **Content-Type:** `application/x-www-form-urlencoded`
2. **Formato:** Dados URL-encoded (como `username=admin&password=senha`)
3. **Campos:** `username` e `password`

### Por que URLSearchParams?

- ✅ Gera automaticamente o formato `key=value&key2=value2`
- ✅ Compatível com `application/x-www-form-urlencoded`
- ✅ Mais simples que construir a string manualmente

---

## 🚀 Como Aplicar no Servidor

### Passo 1: Push (já feito)
```bash
git push
```

### Passo 2: No servidor - Rebuild do frontend

```bash
ssh root@82.25.92.217
cd ~/debrief  # ou /var/www/debrief

# Pull atualizações
git pull

# Rebuild do frontend
docker-compose build --no-cache frontend

# Reiniciar
docker-compose up -d

# Verificar logs
docker-compose logs -f frontend
```

### Passo 3: Testar Login

1. Acesse: http://82.25.92.217:2022/login
2. Credenciais: `admin` / `admin123`
3. Deve funcionar agora! ✅

---

## 🔍 Diagnóstico

Execute o script de diagnóstico no servidor:

```bash
cd ~/debrief
./diagnostico_login.sh
```

O script verifica:
- ✅ Containers rodando
- ✅ Backend acessível
- ✅ Frontend acessível
- ✅ Proxy nginx funcionando
- ✅ Endpoint de login funcionando
- ✅ Conexão com banco
- ✅ Logs de erro

---

## 🐛 Troubleshooting

### Erro persiste após rebuild

1. **Limpar cache do navegador:**
   - Pressione `Ctrl+Shift+Delete`
   - Limpe cache e cookies
   - Ou use modo anônimo

2. **Verificar no DevTools:**
   - Abra DevTools (F12)
   - Vá para aba **Network**
   - Tente fazer login
   - Verifique a requisição `/api/auth/login`:
     - **Request Headers:** Deve ter `Content-Type: application/x-www-form-urlencoded`
     - **Payload:** Deve ser `username=admin&password=admin123`
     - **Status:** Deve ser `200 OK`

3. **Testar endpoint diretamente:**
   ```bash
   # No servidor
   curl -X POST http://localhost:8000/api/auth/login \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin&password=admin123"
   ```

4. **Verificar logs do backend:**
   ```bash
   docker-compose logs backend | grep -i "login\|error\|401"
   ```

### Erro 422 (Unprocessable Entity)

Isso significa que o formato dos dados está incorreto:

1. Verificar se está usando `URLSearchParams` (não `FormData`)
2. Verificar se o Content-Type está correto
3. Verificar se os campos são `username` e `password` (não `email` ou outros)

### Erro 401 (Unauthorized)

Isso significa credenciais incorretas:

1. Verificar se o usuário existe no banco:
   ```bash
   docker-compose exec backend python -c "
   from app.core.database import SessionLocal
   from app.models.user import User
   db = SessionLocal()
   user = db.query(User).filter(User.username == 'admin').first()
   print(f'Usuário: {user.username if user else \"Não encontrado\"}')
   print(f'Ativo: {user.ativo if user else \"N/A\"}')
   "
   ```

2. Verificar se a senha está correta (hash no banco)

---

## 📊 Comparação de Formatos

### FormData (multipart/form-data) ❌
```
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary...

------WebKitFormBoundary...
Content-Disposition: form-data; name="username"

admin
------WebKitFormBoundary...
Content-Disposition: form-data; name="password"

admin123
------WebKitFormBoundary...--
```

### URLSearchParams (application/x-www-form-urlencoded) ✅
```
Content-Type: application/x-www-form-urlencoded

username=admin&password=admin123
```

---

## ✅ Checklist de Verificação

- [ ] Código atualizado (`authService.js`)
- [ ] Push feito para GitHub
- [ ] Pull feito no servidor
- [ ] Frontend rebuildado
- [ ] Containers reiniciados
- [ ] Teste de login funcionando
- [ ] DevTools mostra Content-Type correto
- [ ] Requisição retorna 200 OK

---

## 📝 Arquivos Modificados

1. ✅ `frontend/src/services/authService.js` - Content-Type corrigido
2. ✅ `diagnostico_login.sh` - Script de diagnóstico criado

---

## 🎯 Resultado Esperado

Após aplicar a correção:

1. ✅ Login funciona corretamente
2. ✅ Requisição usa `application/x-www-form-urlencoded`
3. ✅ Backend processa o login sem erros
4. ✅ Token JWT retornado corretamente
5. ✅ Usuário redirecionado para dashboard

---

## 🚀 Próximos Passos

1. ✅ **Fazer push** das alterações:
   ```bash
   git add .
   git commit -m "🔧 fix: Corrigir Content-Type do login para application/x-www-form-urlencoded"
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
   - Deve funcionar! ✅

---

**✅ Problema corrigido!**

**🔧 O Content-Type agora está correto e o login deve funcionar!**

