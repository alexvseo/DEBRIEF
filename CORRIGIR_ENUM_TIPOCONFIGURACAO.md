# 🔧 Corrigir Enum tipoconfiguracao

## 📋 Problema Identificado

O banco de dados tem um enum nativo `tipoconfiguracao` que está causando o erro:
```
psycopg2.errors.InvalidTextRepresentation: invalid input value for enum tipoconfiguracao: "TRELLO"
```

O problema é que o SQLAlchemy está tentando usar o nome do enum (`TRELLO`) em vez do valor (`trello`), e o enum nativo do PostgreSQL não aceita isso.

## ✅ Correções Aplicadas

### 1. **Backend** (`backend/app/models/configuracao.py`)
- Criado `TipoConfiguracaoType` (TypeDecorator) similar ao `StatusDemandaType`
- Modificado o modelo para usar `TipoConfiguracaoType()` em vez de `Enum(TipoConfiguracao, native_enum=False)`
- O TypeDecorator garante que os valores sejam sempre em minúsculo (`trello`, `whatsapp`, etc.)

### 2. **Script de Conversão** (`scripts/deploy/converter-enum-tipoconfiguracao.sh`)
- Criado script para converter o enum nativo `tipoconfiguracao` para `VARCHAR`
- O script preserva todos os dados e converte valores para minúsculo

### 3. **Script de Diagnóstico** (`scripts/deploy/verificar-erro-500-configuracoes.sh`)
- Corrigido para usar queries SQL diretas quando o enum está quebrado
- Adicionada verificação se o enum precisa ser convertido

## 🚀 Como Aplicar no Servidor

```bash
# 1. Fazer pull das alterações
git pull

# 2. Converter enum nativo para VARCHAR
./scripts/deploy/converter-enum-tipoconfiguracao.sh

# 3. Reconstruir e reiniciar containers
docker-compose down
docker-compose build --no-cache backend
docker-compose up -d

# 4. Aguardar containers ficarem healthy
docker-compose ps

# 5. Executar diagnóstico
./scripts/deploy/verificar-erro-500-configuracoes.sh
```

## 🔍 Verificar Conversão

Após executar o script de conversão, verifique:

```bash
# Verificar estrutura da coluna
psql -h localhost -U postgres -d dbrief -c "
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'configuracoes' AND column_name = 'tipo';
"

# Verificar valores
psql -h localhost -U postgres -d dbrief -c "
SELECT DISTINCT tipo, COUNT(*) as total
FROM configuracoes
GROUP BY tipo
ORDER BY tipo;
"
```

A coluna `tipo` deve ser `character varying` (VARCHAR) e não `tipoconfiguracao` (enum).

## 📝 Notas

- O TypeDecorator garante compatibilidade entre Python enum e banco VARCHAR
- Valores são sempre armazenados em minúsculo no banco (`trello`, `whatsapp`, etc.)
- O código Python pode usar `TipoConfiguracao.TRELLO` normalmente
- A conversão é necessária apenas uma vez

