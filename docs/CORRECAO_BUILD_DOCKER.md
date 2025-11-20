# 🐛 Correção: Erro de Build Docker Frontend

**Data:** 19/11/2025  
**Status:** ✅ CORRIGIDO

---

## 🔍 Problemas Identificados

### 1️⃣ Versão do Node.js Incompatível

**Erro:**
```
You are using Node.js 18.20.8. Vite requires Node.js version 20.19+ or 22.12+.
```

**Causa:**
- Dockerfile estava usando `node:18-alpine`
- Vite 7.2.2 requer Node.js 20.19+ ou 22.12+

**Solução:**
- ✅ Atualizado para `node:20-alpine`

---

### 2️⃣ Import Case-Sensitive (Linux)

**Erro:**
```
Could not load /app/src/components/ui/input (imported by src/components/forms/DemandaForm.jsx): 
ENOENT: no such file or directory
```

**Causa:**
- Arquivo real: `Input.jsx` (maiúscula)
- Import usado: `@/components/ui/input` (minúscula)
- Linux é case-sensitive, então não encontra o arquivo

**Solução:**
- ✅ Corrigido imports para usar maiúsculas:
  - `button` → `Button`
  - `input` → `Input`
  - `card` → `Card`
  - `alert` → `Alert`

---

## ✅ Correções Aplicadas

### Arquivo: `frontend/Dockerfile`

**Antes:**
```dockerfile
FROM node:18-alpine AS builder
```

**Depois:**
```dockerfile
FROM node:20-alpine AS builder
```

### Arquivo: `frontend/src/components/forms/DemandaForm.jsx`

**Antes:**
```javascript
import Button from '@/components/ui/button'
import Input from '@/components/ui/input'
import { Card, ... } from '@/components/ui/card'
import { Alert, ... } from '@/components/ui/alert'
```

**Depois:**
```javascript
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import { Card, ... } from '@/components/ui/Card'
import { Alert, ... } from '@/components/ui/Alert'
```

---

## 🚀 Como Testar

### Localmente (antes de fazer push):

```bash
cd frontend
docker build -t debrief-frontend .
```

### No Servidor (após push):

```bash
cd /var/www/debrief
git pull
docker-compose build frontend --no-cache
docker-compose up -d frontend
docker-compose logs frontend
```

---

## 📝 Notas Importantes

### Por que isso aconteceu?

1. **Node.js 18 vs 20:**
   - Vite foi atualizado para versão 7
   - Vite 7 requer Node.js mais recente
   - Dockerfile não foi atualizado junto

2. **Case-Sensitive:**
   - macOS é case-insensitive por padrão
   - Funciona localmente mesmo com minúsculas
   - Linux (Docker) é case-sensitive
   - Erro só aparece no build Docker

### Prevenção Futura

1. **Sempre usar maiúsculas nos imports:**
   ```javascript
   // ✅ Correto
   import Button from '@/components/ui/Button'
   
   // ❌ Errado (pode funcionar no Mac, mas falha no Linux)
   import Button from '@/components/ui/button'
   ```

2. **Verificar versões:**
   - Verificar requisitos do Vite no `package.json`
   - Atualizar Dockerfile quando necessário

3. **Testar build Docker localmente:**
   ```bash
   docker-compose build
   docker-compose up -d
   ```

---

## ✅ Status

- [x] Node.js atualizado para 20
- [x] Imports corrigidos (case-sensitive)
- [x] Commit realizado
- [ ] Push para GitHub
- [ ] Rebuild no servidor

---

## 🔄 Próximos Passos

1. **Fazer push:**
   ```bash
   git push
   ```

2. **No servidor, fazer rebuild:**
   ```bash
   ssh root@82.25.92.217
   cd /var/www/debrief
   git pull
   docker-compose build frontend --no-cache
   docker-compose up -d
   docker-compose logs -f
   ```

3. **Verificar:**
   - Frontend deve carregar em http://82.25.92.217:3000
   - Sem erros nos logs

---

## 🎉 Resultado

✅ **Build do Docker corrigido!**

**Agora o frontend deve compilar corretamente no servidor!**

---

**Commit:** `e88356c` - 🐛 fix: Corrigir build Docker do frontend

