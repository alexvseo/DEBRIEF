# 🔧 Aplicar Correção de Enum - AGORA

## ✅ Problema Identificado

O erro `LookupError: 'aberta' is not among the defined enum values` ocorre porque:
- O PostgreSQL tem enum nativo com valores em minúsculo ('aberta')
- O SQLAlchemy está tentando fazer match com nomes de membros do enum Python (ABERTA)
- Quando carrega demandas do banco, falha na conversão

## ✅ Solução Aplicada

Alterado `Enum(StatusDemanda)` para `Enum(StatusDemanda, native_enum=False)`:
- Armazena como VARCHAR em vez de enum nativo
- Permite que valores em minúsculo do banco funcionem com enum Python
- Resolve o erro de LookupError

## 🚀 Aplicar no Servidor

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código
git pull

# 2. Reiniciar backend (importante para aplicar mudança no modelo)
docker-compose restart backend

# 3. Aguardar inicialização
sleep 15

# 4. Diagnosticar secretarias
./scripts/deploy/diagnosticar-secretarias.sh

# 5. Verificar logs
docker-compose logs backend | tail -30
```

## ✅ Verificar se Funcionou

1. **Logs do backend:**
   ```bash
   docker-compose logs backend | grep -E "LookupError|ERROR|secretarias" | tail -20
   ```
   Não deve ter erros de `LookupError`.

2. **Testar endpoint (com token válido):**
   ```bash
   # Primeiro, fazer login para obter token
   TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin&password=admin123" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
   
   # Testar endpoint de secretarias
   curl -X GET http://localhost:8000/api/secretarias/ \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json"
   ```
   Deve retornar JSON com lista de secretarias.

3. **Testar no frontend:**
   - Acesse: http://82.25.92.217:2022/configuracoes
   - As secretarias devem aparecer na lista
   - Não deve aparecer erro "Erro no servidor"

## 🔍 Se Ainda Não Funcionar

Execute o diagnóstico completo:

```bash
./scripts/deploy/diagnosticar-secretarias.sh
```

Isso mostrará:
- Quantas secretarias existem no banco
- Se há demandas vinculadas
- Valores de status encontrados

## 📋 O Que Mudou

1. **`backend/app/models/demanda.py`**:
   - `Enum(StatusDemanda)` → `Enum(StatusDemanda, native_enum=False)`

2. **`backend/app/models/configuracao.py`**:
   - `Enum(TipoConfiguracao)` → `Enum(TipoConfiguracao, native_enum=False)`

3. **`backend/app/models/secretaria.py`**:
   - Relacionamento `demandas`: `lazy="select"` → `lazy="noload"`
   - Métodos atualizados para usar queries explícitas

4. **`backend/app/api/endpoints/secretarias.py`**:
   - Usa queries explícitas para contar demandas em vez de carregar relacionamento

