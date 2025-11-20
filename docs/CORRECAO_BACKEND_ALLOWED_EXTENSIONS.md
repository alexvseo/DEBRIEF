# 🔧 Correção: Backend não inicia - Erro ALLOWED_EXTENSIONS

**Data:** 19/11/2025  
**Problema:** Backend não inicia, erro ao fazer parse de `ALLOWED_EXTENSIONS`  
**Causa:** Pydantic não consegue converter string em lista automaticamente  
**Status:** ✅ CORRIGIDO

---

## 🔴 Problema Identificado

O backend estava falhando ao iniciar com o erro:

```
pydantic_settings.sources.SettingsError: error parsing value for field "ALLOWED_EXTENSIONS" from source "DotEnvSettingsSource"
```

**Causa:**
- No `.env` ou variáveis de ambiente, `ALLOWED_EXTENSIONS` vem como string: `"pdf,jpg,jpeg,png"`
- O Pydantic espera uma lista: `["pdf", "jpg", "jpeg", "png"]`
- O Pydantic não converte automaticamente string separada por vírgulas em lista

---

## ✅ Solução Implementada

### 1. Adicionar validador no `config.py`

```python
from pydantic import field_validator
from typing import Union

ALLOWED_EXTENSIONS: Union[str, list[str]] = ["pdf", "jpg", "jpeg", "png"]

@field_validator('ALLOWED_EXTENSIONS', mode='before')
@classmethod
def parse_allowed_extensions(cls, v):
    """Converter string separada por vírgulas em lista"""
    if isinstance(v, str):
        # Remover espaços e dividir por vírgula
        return [ext.strip() for ext in v.split(',') if ext.strip()]
    return v
```

**Resultado:**
- ✅ Aceita string: `"pdf,jpg,jpeg,png"` → converte para `["pdf", "jpg", "jpeg", "png"]`
- ✅ Aceita lista: `["pdf", "jpg"]` → mantém como está
- ✅ Funciona tanto no `.env` quanto em variáveis de ambiente Docker

### 2. Adicionar no `docker-compose.yml`

```yaml
environment:
  - ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png
```

---

## 🚀 Como Aplicar no Servidor

### Passo 1: Push (já feito)
```bash
git push
```

### Passo 2: No servidor - Rebuild do backend

```bash
ssh root@82.25.92.217
cd ~/debrief

# Pull atualizações
git pull

# Parar containers
docker-compose down

# Rebuild do backend
docker-compose build --no-cache backend

# Iniciar containers
docker-compose up -d

# Verificar logs
docker-compose logs -f backend
```

### Passo 3: Verificar se backend iniciou

```bash
# Verificar status
docker-compose ps

# Testar health check
curl http://localhost:8000/health

# Verificar logs (não deve ter mais erros)
docker-compose logs backend | tail -20
```

---

## 🔍 Verificações

### 1. Verificar se backend está rodando

```bash
docker-compose ps backend
# Deve mostrar: Up X minutes (healthy)
```

### 2. Testar endpoint de health

```bash
curl http://localhost:8000/health
# Deve retornar: {"status":"healthy",...}
```

### 3. Testar endpoint de login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
# Deve retornar token JWT
```

### 4. Verificar logs (sem erros)

```bash
docker-compose logs backend | grep -i "error\|exception\|traceback"
# Não deve retornar nada (ou apenas erros antigos)
```

---

## 🐛 Troubleshooting

### Erro persiste após rebuild

1. **Verificar se há `.env` no servidor com formato incorreto:**
   ```bash
   # No servidor
   cat backend/.env | grep ALLOWED_EXTENSIONS
   # Se existir, deve ser: ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png
   ```

2. **Remover `.env` se estiver causando conflito:**
   ```bash
   # No servidor
   rm backend/.env
   # O docker-compose.yml já define as variáveis
   ```

3. **Verificar variáveis de ambiente no container:**
   ```bash
   docker-compose exec backend env | grep ALLOWED_EXTENSIONS
   # Deve mostrar: ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png
   ```

### Backend ainda não inicia

1. **Ver logs completos:**
   ```bash
   docker-compose logs backend
   ```

2. **Verificar se há outros erros:**
   ```bash
   docker-compose logs backend | grep -i "error\|exception" | tail -10
   ```

3. **Testar configuração localmente:**
   ```bash
   docker-compose exec backend python -c "
   from app.core.config import settings
   print(f'ALLOWED_EXTENSIONS: {settings.ALLOWED_EXTENSIONS}')
   print(f'Tipo: {type(settings.ALLOWED_EXTENSIONS)}')
   "
   # Deve mostrar: ALLOWED_EXTENSIONS: ['pdf', 'jpg', 'jpeg', 'png']
   # Tipo: <class 'list'>
   ```

---

## 📊 Antes vs Depois

### Antes (❌ Erro):
```python
ALLOWED_EXTENSIONS: list[str] = ["pdf", "jpg", "jpeg", "png"]

# No .env: ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png
# Erro: Pydantic não consegue converter string → list
```

### Depois (✅ Funcionando):
```python
ALLOWED_EXTENSIONS: Union[str, list[str]] = ["pdf", "jpg", "jpeg", "png"]

@field_validator('ALLOWED_EXTENSIONS', mode='before')
@classmethod
def parse_allowed_extensions(cls, v):
    if isinstance(v, str):
        return [ext.strip() for ext in v.split(',') if ext.strip()]
    return v

# No .env: ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png
# ✅ Converte automaticamente para lista
```

---

## ✅ Checklist de Verificação

- [ ] Código atualizado (`config.py`)
- [ ] `docker-compose.yml` atualizado
- [ ] Push feito para GitHub
- [ ] Pull feito no servidor
- [ ] Backend rebuildado
- [ ] Containers reiniciados
- [ ] Backend iniciando sem erros
- [ ] Health check funcionando
- [ ] Login funcionando

---

## 📝 Arquivos Modificados

1. ✅ `backend/app/core/config.py` - Validador adicionado
2. ✅ `docker-compose.yml` - Variável ALLOWED_EXTENSIONS adicionada

---

## 🎯 Resultado Esperado

Após aplicar a correção:

1. ✅ Backend inicia sem erros
2. ✅ Health check retorna `200 OK`
3. ✅ Endpoint de login funciona
4. ✅ `ALLOWED_EXTENSIONS` é uma lista corretamente
5. ✅ Sem erros nos logs

---

## 🚀 Próximos Passos

1. ✅ **Fazer push** das alterações:
   ```bash
   git add .
   git commit -m "🔧 fix: Corrigir parse de ALLOWED_EXTENSIONS no config"
   git push
   ```

2. ✅ **No servidor, fazer pull e rebuild:**
   ```bash
   git pull
   docker-compose build --no-cache backend
   docker-compose up -d
   ```

3. ✅ **Verificar se funcionou:**
   ```bash
   docker-compose ps
   curl http://localhost:8000/health
   ```

---

**✅ Problema corrigido!**

**🔧 O backend deve iniciar corretamente agora!**

