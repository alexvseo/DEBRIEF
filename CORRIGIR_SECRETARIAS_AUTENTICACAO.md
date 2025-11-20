# 🔧 Corrigir Carregamento de Secretarias - Autenticação

## 📋 Problema Identificado

O script de diagnóstico estava retornando `401 Unauthorized` porque tentava acessar o endpoint `/api/secretarias/` sem autenticação. O endpoint requer autenticação e permissão de Master.

## ✅ Correções Aplicadas

### 1. **Backend** (`backend/app/api/endpoints/secretarias.py`)
- Melhorado o tratamento do parâmetro `apenas_ativas` para aceitar tanto boolean quanto string
- Adicionada validação mais robusta para converter strings como `'true'`, `'1'`, `'yes'` para boolean

### 2. **Frontend** (`frontend/src/pages/Configuracoes.jsx`)
- Adicionada verificação de token antes de fazer a requisição
- Melhorados os logs de debug para identificar problemas de autenticação
- Melhorado o tratamento de erros 401 (token inválido/expirado)

### 3. **Script de Diagnóstico** (`scripts/deploy/diagnosticar-secretarias.sh`)
- Adicionada obtenção automática de token via login
- Melhorados os testes para usar autenticação adequada
- Adicionadas instruções para verificar no navegador

## 🚀 Como Aplicar no Servidor

```bash
# 1. Fazer pull das alterações
git pull

# 2. Reconstruir e reiniciar containers
docker-compose down
docker-compose build --no-cache backend frontend
docker-compose up -d

# 3. Aguardar containers ficarem healthy
docker-compose ps

# 4. Executar diagnóstico
./scripts/deploy/diagnosticar-secretarias.sh
```

## 🔍 Verificar no Navegador

1. Abra o DevTools (F12)
2. Vá para a aba **Network**
3. Recarregue a página de Configurações
4. Procure por requisições para `/api/secretarias/`
5. Verifique:
   - ✅ Header `Authorization: Bearer ...` está presente
   - ✅ Status code é `200` (não `401`)
   - ✅ Response contém um array de secretarias

## 🐛 Se Ainda Não Funcionar

### Verificar Token no Console do Navegador

```javascript
// No console do navegador (F12)
const auth = JSON.parse(localStorage.getItem('debrief_auth'))
console.log('Token:', auth?.token)
console.log('User:', auth?.user)
```

### Verificar Logs do Backend

```bash
docker-compose logs backend | grep -iE "(secretaria|401|unauthorized)" | tail -50
```

### Testar Endpoint Manualmente

```bash
# 1. Obter token
TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

# 2. Testar endpoint
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/secretarias/?apenas_ativas=false&limit=10000" | \
  python3 -m json.tool | head -50
```

## 📝 Notas

- O endpoint `/api/secretarias/` requer autenticação e permissão de **Master**
- O parâmetro `apenas_ativas` pode ser enviado como `'false'` (string) ou `false` (boolean)
- Se o token estiver expirado, o interceptor do Axios redirecionará automaticamente para `/login`

