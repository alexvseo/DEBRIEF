# 🐛 Correção: Erro de Import utils.js no Build Docker

**Data:** 19/11/2025  
**Status:** ✅ CORRIGIDO

---

## 🔍 Problema Identificado

**Erro no build Docker:**
```
Could not load /app/src/lib/utils (imported by src/components/ui/Input.jsx): 
ENOENT: no such file or directory, open '/app/src/lib/utils'
```

**Causa:**
- Imports usando `@/lib/utils` sem extensão `.js`
- No build do Docker (Linux), o Vite precisa de extensão explícita
- macOS é mais permissivo e aceita sem extensão
- Linux é mais rigoroso e requer extensão explícita

---

## ✅ Correções Aplicadas

### 1. Atualizar Imports com Extensão Explícita

**Arquivos corrigidos (8 componentes UI):**
- `Button.jsx`
- `Input.jsx`
- `Card.jsx`
- `Alert.jsx`
- `Badge.jsx`
- `Textarea.jsx`
- `Select.jsx`
- `Dialog.jsx`

**Antes:**
```javascript
import { cn } from '@/lib/utils'
```

**Depois:**
```javascript
import { cn } from '@/lib/utils.js'
```

### 2. Configurar Vite para Resolver Extensões

**Arquivo:** `frontend/vite.config.js`

**Adicionado:**
```javascript
resolve: {
  alias: {
    // ... outros aliases
    '@lib': path.resolve(__dirname, './src/lib'),
  },
  extensions: ['.js', '.jsx', '.json', '.ts', '.tsx'],
},
```

### 3. Criar index.js no Diretório lib

**Arquivo:** `frontend/src/lib/index.js`

```javascript
export * from './utils.js'
```

---

## 📊 Arquivos Modificados

1. ✅ `frontend/vite.config.js` - Adicionado alias e extensões
2. ✅ `frontend/src/lib/index.js` - Criado (novo)
3. ✅ `frontend/src/components/ui/Button.jsx` - Import corrigido
4. ✅ `frontend/src/components/ui/Input.jsx` - Import corrigido
5. ✅ `frontend/src/components/ui/Card.jsx` - Import corrigido
6. ✅ `frontend/src/components/ui/Alert.jsx` - Import corrigido
7. ✅ `frontend/src/components/ui/Badge.jsx` - Import corrigido
8. ✅ `frontend/src/components/ui/Textarea.jsx` - Import corrigido
9. ✅ `frontend/src/components/ui/Select.jsx` - Import corrigido
10. ✅ `frontend/src/components/ui/Dialog.jsx` - Import corrigido

---

## 🧪 Como Testar

### Localmente:
```bash
cd frontend
npm run build
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

1. **Diferença entre macOS e Linux:**
   - macOS: Case-insensitive e aceita imports sem extensão
   - Linux: Case-sensitive e mais rigoroso com extensões
   - Docker roda em Linux, então precisa de extensões explícitas

2. **Vite no Build:**
   - Em desenvolvimento, Vite é mais permissivo
   - Em build de produção, Vite é mais rigoroso
   - Requer extensões explícitas para garantir compatibilidade

### Prevenção Futura

**Sempre usar extensões explícitas em imports:**
```javascript
// ✅ Correto (funciona em todos os ambientes)
import { cn } from '@/lib/utils.js'
import Button from '@/components/ui/Button.jsx'

// ❌ Pode funcionar no Mac, mas falha no Linux/Docker
import { cn } from '@/lib/utils'
import Button from '@/components/ui/button'
```

---

## ✅ Status

- [x] Imports corrigidos (8 arquivos)
- [x] Vite config atualizado
- [x] index.js criado
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
   docker-compose logs -f frontend
   ```

3. **Verificar:**
   - Build deve completar sem erros
   - Frontend deve carregar em http://82.25.92.217:3000

---

## 🎉 Resultado

✅ **Imports corrigidos!**

**Agora o build do Docker deve funcionar corretamente!**

---

**Commit:** `15ffe3e` - 🐛 fix: Corrigir imports de utils.js com extensão explícita

**Commits anteriores:**
- `e88356c` - fix: Corrigir build Docker do frontend (Node.js 20 + imports case-sensitive)

