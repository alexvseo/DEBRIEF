# Correção: Erro ao Cadastrar Usuário

## ❌ Problema Identificado

Ao tentar cadastrar um novo usuário através do formulário de gerenciamento de usuários, o sistema retornava um erro interno (Internal Server Error 500).

### Erro Original

```
pydantic_core._pydantic_core.ValidationError: 1 validation error for UserResponse
tipo
  Input should be 'master' or 'cliente' [type=enum, input_value='TipoUsuario.MASTER', input_type=str]
```

## 🔍 Causa Raiz

O problema estava no `TipoUsuarioType` (TypeDecorator) do modelo `User`. Quando um novo usuário era criado:

1. O campo `tipo` era salvo no banco com o valor correto (`'master'` ou `'cliente'`)
2. Porém, em alguns casos, o valor estava sendo salvo como `'TipoUsuario.MASTER'` (string com o nome da enum)
3. Ao tentar serializar o objeto User para UserResponse, o Pydantic esperava apenas `'master'` ou `'cliente'`
4. Isso causava um erro de validação que quebrava o endpoint

### Problemas Encontrados

1. **TipoUsuarioType não tratava strings malformadas**: O `process_bind_param` e `process_result_value` não tratavam o caso onde o valor vinha como `'TipoUsuario.MASTER'`

2. **Senha do banco incorreta no docker-compose.prod.yml**: 
   - DATABASE_URL tinha `Mslestra%402025` (sem "db")
   - POSTGRES_PASSWORD tinha `Mslestra@2025` (sem "db")
   - A senha correta é `Mslestra@2025db`

3. **Registros antigos no banco**: Um usuário (tarcisio) tinha o campo tipo com valor `'TipoUsuario.MASTER'` ao invés de `'master'`

## ✅ Soluções Aplicadas

### 1. Correção do TipoUsuarioType

**Arquivo**: `backend/app/models/user.py`

Melhorias implementadas no `TipoUsuarioType`:

```python
def process_bind_param(self, value, dialect):
    """Converter enum Python para string do banco"""
    if value is None:
        return None
    if isinstance(value, TipoUsuario):
        return value.value  # Retorna 'master' ou 'cliente'
    # Se for string com formato 'TipoUsuario.MASTER', extrair apenas o valor
    if isinstance(value, str):
        if value.startswith('TipoUsuario.'):
            enum_name = value.split('.')[1]
            return enum_name.lower()
        return value.lower()
    return str(value).lower()

def process_result_value(self, value, dialect):
    """Converter string do banco para string Python (não enum)"""
    if value is None:
        return None
    # Se for enum, retorna apenas o valor em minúsculas
    if isinstance(value, TipoUsuario):
        return value.value
    # Se for string com formato 'TipoUsuario.MASTER', extrair apenas o valor
    if isinstance(value, str):
        if value.startswith('TipoUsuario.'):
            enum_name = value.split('.')[1]
            return enum_name.lower()
        # Garantir que retorne em minúsculas
        return value.lower()
    return str(value).lower()
```

**Benefícios**:
- Converte automaticamente `'TipoUsuario.MASTER'` → `'master'`
- Garante que sempre retorna em minúsculas
- Compatível com Pydantic enum validation
- Trata todos os casos possíveis de entrada

### 2. Correção dos Registros no Banco

Executado comando SQL para corrigir registros antigos:

```sql
UPDATE users SET tipo = 'master' WHERE tipo LIKE 'TipoUsuario%';
```

**Resultado**: 1 registro atualizado (usuário tarcisio)

### 3. Correção do docker-compose.prod.yml

**Mudanças**:

```yaml
# Antes
- DATABASE_URL=postgresql://postgres:Mslestra%402025@debrief_db:5432/dbrief
- POSTGRES_PASSWORD=Mslestra@2025

# Depois
- DATABASE_URL=postgresql://postgres:Mslestra%402025db@debrief_db:5432/dbrief
- POSTGRES_PASSWORD=Mslestra@2025db
```

## 🧪 Testes Realizados

### Teste Automatizado

Criado script de teste (`test_criar_usuario.py`) que:
1. ✅ Faz login como admin
2. ✅ Cria novo usuário master
3. ✅ Verifica resposta com campo `tipo` correto
4. ✅ Deleta usuário de teste

### Resultado do Teste

```
============================================================
TESTE DE CRIAÇÃO DE USUÁRIO - DeBrief
============================================================
🔐 Fazendo login como admin...
✅ Login bem-sucedido!

👤 Criando usuário de teste...
Status Code: 201
✅ Usuário criado com sucesso!
{
  "id": "73405fad-98f2-4efa-94a6-172e4e31a165",
  "username": "teste_1764005133",
  "email": "teste_1764005133@correcao.com",
  "nome_completo": "Usuário Teste Correção",
  "tipo": "master",  ← ✅ Campo tipo correto!
  "cliente_id": null,
  "ativo": true,
  "created_at": "2025-11-24T17:25:33.384256Z",
  "updated_at": "2025-11-24T17:25:33.384256Z"
}

🗑️  Deletando usuário de teste...
✅ Usuário deletado com sucesso!

============================================================
✅ TESTE CONCLUÍDO COM SUCESSO!
============================================================
```

## 📋 Verificações no Banco de Dados

### Antes da Correção

```sql
SELECT id, username, tipo FROM users LIMIT 5;

                  id                  |  username  |        tipo        
--------------------------------------+------------+--------------------
 fc50f55d-bcd2-498b-a723-dbe2b8cd156d | admin      | master
 3bc68f37-7b8a-4add-8b53-5b8074e75bdd | alex       | master
 f789a89c-1562-4feb-991a-301de649adec | alex_debug | master
 fddb6908-5310-4646-852c-2f0b1adf9bf7 | matheus    | master
 a652077c-dfaf-4d30-ba64-24743e62f9f7 | tarcisio   | TipoUsuario.MASTER ← ❌ Problema
```

### Depois da Correção

```sql
SELECT id, username, tipo FROM users LIMIT 5;

                  id                  |  username  |  tipo  
--------------------------------------+------------+--------
 fc50f55d-bcd2-498b-a723-dbe2b8cd156d | admin      | master ✅
 3bc68f37-7b8a-4add-8b53-5b8074e75bdd | alex       | master ✅
 f789a89c-1562-4feb-991a-301de649adec | alex_debug | master ✅
 fddb6908-5310-4646-852c-2f0b1adf9bf7 | matheus    | master ✅
 a652077c-dfaf-4d30-ba64-24743e62f9f7 | tarcisio   | master ✅
```

## 🚀 Deploy

### Commits Realizados

1. `6b6b557` - fix: corrigir serialização do campo tipo em User para compatibilidade com Pydantic
2. `1ca3861` - fix: corrigir senha do banco de dados no docker-compose.prod.yml

### Comandos Executados

```bash
# 1. Atualizar código no servidor
cd /var/www/debrief
git pull origin main

# 2. Rebuild e restart dos containers
docker-compose -f docker-compose.prod.yml up -d --force-recreate
```

### Status dos Containers

```
NAMES                        STATUS
debrief-frontend             Up (healthy)
debrief-backend              Up (healthy)
debrief_db                   Up (healthy)
```

## ✅ Resultado Final

- ✅ Cadastro de usuários funcionando corretamente
- ✅ Campo `tipo` sendo serializado corretamente como `'master'` ou `'cliente'`
- ✅ Todos os registros no banco corrigidos
- ✅ Senha do banco de dados correta
- ✅ Containers rodando sem erros
- ✅ Testes automatizados passando

## 📝 Notas Técnicas

### Por que o erro acontecia?

O Python/SQLAlchemy às vezes retorna enums como strings no formato `'ClassName.VALUE'` ao invés de apenas `'VALUE'`. Isso pode acontecer quando:

1. O enum é convertido para string implicitamente
2. Há problemas de serialização entre SQLAlchemy e Pydantic
3. Dados antigos no banco têm formato inconsistente

### Prevenção Futura

As melhorias no `TipoUsuarioType` agora garantem que:
- Qualquer formato de entrada seja normalizado
- O valor sempre seja retornado em minúsculas
- Seja compatível com validação Pydantic
- Funcione com dados novos e legados

---

**Data da Correção**: 24/11/2025  
**Status**: ✅ Resolvido  
**Tempo de Resolução**: ~30 minutos  
**Impacto**: Cadastro de usuários totalmente funcional

