# 🔧 Validação de Secretarias - Unicidade com Normalização de Acentuação

## 📋 Requisito

Na lista de secretarias, deve ser aceito apenas **uma secretaria por cliente**. Se ela tem acentuação diferente, deve considerar que já existe no banco de dados e não deixar inserir.

**Exemplos de duplicatas que devem ser bloqueadas:**
- "Secretaria de Saúde" vs "Secretaria de Saude"
- "Secretaria de Educação" vs "Secretaria de Educacao"
- "Secretaria de Saúde" vs "Secretaria de Saude" (mesmo cliente)

## ✅ Correções Aplicadas

### 1. **Função de Normalização** (`backend/app/core/utils.py`)
- Criada função `normalizar_nome()` que:
  - Remove acentos (á -> a, é -> e, etc.)
  - Remove espaços extras
  - Converte para minúsculo
  - Remove caracteres especiais (mantém apenas letras, números e espaços)
- Criada função `comparar_nomes_ignorando_acentos()` para comparação

### 2. **Validação na Criação** (`backend/app/api/endpoints/secretarias.py`)
- Modificado `criar_secretaria()` para:
  - Normalizar o nome antes de verificar duplicatas
  - Comparar nomes normalizados (sem acentos) de todas as secretarias ativas do mesmo cliente
  - Bloquear criação se encontrar nome equivalente

### 3. **Validação na Atualização** (`backend/app/api/endpoints/secretarias.py`)
- Modificado `atualizar_secretaria()` para:
  - Normalizar o nome antes de verificar duplicatas
  - Comparar nomes normalizados ao atualizar
  - Bloquear atualização se encontrar nome equivalente

### 4. **Script de Verificação** (`scripts/deploy/verificar-constraint-secretarias.sh`)
- Criado script para verificar:
  - Constraints existentes no banco
  - Índices únicos
  - Duplicatas por cliente (ignorando acentuação)
  - Estrutura da tabela

## 🔍 Como Funciona

### Normalização de Nome

```python
# Exemplo de normalização
normalizar_nome("Secretaria de Saúde")  # -> "secretaria de saude"
normalizar_nome("Secretaria de Educação")  # -> "secretaria de educacao"
normalizar_nome("  Secretaria   de   Saúde  ")  # -> "secretaria de saude"
```

### Validação

1. **Ao criar secretaria:**
   - Normaliza o nome informado
   - Busca todas as secretarias ATIVAS do mesmo cliente
   - Normaliza cada nome existente
   - Compara nomes normalizados
   - Bloqueia se encontrar equivalente

2. **Ao atualizar secretaria:**
   - Normaliza o novo nome
   - Busca todas as secretarias ATIVAS do mesmo cliente (exceto a atual)
   - Normaliza cada nome existente
   - Compara nomes normalizados
   - Bloqueia se encontrar equivalente

## 🚀 Como Aplicar no Servidor

```bash
# 1. Fazer pull das alterações
git pull

# 2. Reconstruir e reiniciar containers
docker-compose down
docker-compose build --no-cache backend
docker-compose up -d

# 3. Aguardar containers ficarem healthy
docker-compose ps

# 4. Verificar constraints no banco (opcional)
./scripts/deploy/verificar-constraint-secretarias.sh
```

## 🧪 Testar Validação

### Teste 1: Criar secretaria duplicada (com acentuação diferente)

```bash
# Obter token
TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

# Tentar criar "Secretaria de Saúde" (se já existe "Secretaria de Saude")
curl -X POST "http://localhost:8000/api/secretarias/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Secretaria de Saúde",
    "cliente_id": "ID_DO_CLIENTE",
    "ativo": true
  }'
```

**Resultado esperado:** Erro 400 com mensagem informando que a secretaria já existe.

### Teste 2: Atualizar secretaria para nome duplicado

```bash
# Tentar atualizar nome para "Secretaria de Saúde" (se já existe "Secretaria de Saude")
curl -X PUT "http://localhost:8000/api/secretarias/ID_DA_SECRETARIA" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Secretaria de Saúde"
  }'
```

**Resultado esperado:** Erro 400 com mensagem informando que a secretaria já existe.

## 📝 Notas

- A validação é feita **apenas no backend** (não há constraint no banco)
- Apenas secretarias **ATIVAS** são consideradas na validação
- Secretarias **INATIVAS** não bloqueiam a criação de novas com mesmo nome
- A normalização remove acentos, converte para minúsculo e remove espaços extras
- A comparação é feita após normalização, então "Saúde" e "Saude" são considerados iguais

## 🔍 Verificar Duplicatas Existentes

Execute no servidor para verificar se há duplicatas:

```bash
./scripts/deploy/verificar-constraint-secretarias.sh
```

O script mostrará:
- Constraints existentes
- Índices únicos
- Duplicatas por cliente (ignorando acentuação)
- Estrutura da tabela

