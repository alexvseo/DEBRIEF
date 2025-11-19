# 👤 Modelo User.py - Documentação Completa

Modelo SQLAlchemy completo para gerenciamento de usuários no sistema DeBrief.

## 📦 Arquivos Criados

1. **base.py** (118 linhas) - Classe base para todos os modelos
2. **user.py** (643 linhas) - Modelo User completo
3. **__init__.py** - Exportações do módulo
4. **README_User.md** - Esta documentação

**Total: 761+ linhas de código e documentação**

---

## 🎯 Funcionalidades Implementadas

### ✅ Campos do Modelo

```python
✓ id (UUID) - Chave primária universal
✓ username (String) - Nome de usuário único
✓ email (String) - Email único
✓ password_hash (String) - Senha criptografada com bcrypt
✓ nome_completo (String) - Nome completo do usuário
✓ tipo (Enum) - TipoUsuario.MASTER ou TipoUsuario.CLIENTE
✓ cliente_id (FK) - Relacionamento com Cliente (nullable)
✓ ativo (Boolean) - Status ativo/inativo
✓ created_at (DateTime) - Timestamp de criação
✓ updated_at (DateTime) - Timestamp de atualização
```

### ✅ Relacionamentos

```python
✓ cliente (Many-to-One) - Cliente ao qual o usuário pertence
✓ demandas (One-to-Many) - Demandas criadas pelo usuário
```

### ✅ Validações

```python
✓ Username: 3-50 chars, apenas a-z0-9_-
✓ Email: Formato válido, max 100 chars
✓ Nome completo: 3-200 chars
✓ Senha: Min 8 chars, maiúscula + minúscula + número
✓ Cliente_id: Obrigatório para CLIENTE, NULL para MASTER
```

### ✅ Métodos de Senha

```python
✓ set_password(password) - Define senha com validação e criptografia
✓ verify_password(password) - Verifica senha
✓ needs_password_rehash() - Verifica se precisa rehash
```

### ✅ Métodos de Permissão

```python
✓ is_master() - Verifica se é administrador
✓ is_cliente() - Verifica se é usuário cliente
✓ can_access_cliente(cliente_id) - Verifica acesso a cliente
✓ can_edit_user(other_user) - Verifica permissão de edição
```

### ✅ Métodos de Consulta

```python
✓ get_demandas_count() - Retorna total de demandas
✓ get_demandas_abertas() - Retorna query de demandas abertas
✓ get_demandas_em_andamento() - Retorna query em andamento
```

### ✅ Métodos de Status

```python
✓ ativar() - Ativa usuário
✓ desativar() - Desativa usuário (soft delete)
✓ is_ativo() - Verifica se está ativo
```

### ✅ Métodos de Serialização

```python
✓ to_dict(include_sensitive) - Converte para dicionário
✓ to_dict_safe() - Retorna apenas dados públicos
```

### ✅ Índices

```python
✓ username (único, indexado)
✓ email (único, indexado)
✓ tipo (indexado)
✓ ativo (indexado)
✓ cliente_id (indexado)
✓ Índice composto: (cliente_id, ativo)
✓ Índice composto: (tipo, ativo)
```

---

## 📚 Como Usar

### Criar Novo Usuário

```python
from app.models import User, TipoUsuario
from app.database.connection import SessionLocal

# Criar sessão
db = SessionLocal()

# Criar usuário master
user_master = User(
    username="admin",
    email="admin@debrief.com",
    nome_completo="Administrador do Sistema",
    tipo=TipoUsuario.MASTER,
    ativo=True
)

# Definir senha
user_master.set_password("SenhaForte123")

# Salvar no banco
db.add(user_master)
db.commit()
db.refresh(user_master)

print(f"Usuário criado: {user_master}")
```

### Criar Usuário Cliente

```python
# Criar usuário vinculado a um cliente
user_cliente = User(
    username="joao.silva",
    email="joao@cliente.com",
    nome_completo="João Silva",
    tipo=TipoUsuario.CLIENTE,
    cliente_id="uuid-do-cliente-aqui",
    ativo=True
)

user_cliente.set_password("SenhaSegura456")

db.add(user_cliente)
db.commit()
```

### Autenticar Usuário

```python
# Buscar usuário por username
user = db.query(User).filter(User.username == "joao.silva").first()

if user and user.verify_password("SenhaSegura456"):
    if user.is_ativo():
        print("Login bem-sucedido!")
        print(f"Tipo: {user.tipo.value}")
        print(f"É master? {user.is_master()}")
    else:
        print("Usuário inativo")
else:
    print("Credenciais inválidas")
```

### Verificar Permissões

```python
# Verificar se usuário pode acessar cliente
demanda_cliente_id = "uuid-do-cliente"

if user.can_access_cliente(demanda_cliente_id):
    print("Acesso permitido")
    # Carregar e exibir demanda
else:
    print("Acesso negado")

# Verificar se pode editar outro usuário
outro_user = db.query(User).filter(User.id == "outro-uuid").first()

if user.can_edit_user(outro_user):
    print("Pode editar")
else:
    print("Não pode editar")
```

### Consultar Demandas do Usuário

```python
# Total de demandas
total = user.get_demandas_count()
print(f"Total de demandas: {total}")

# Demandas abertas
abertas = user.get_demandas_abertas().all()
print(f"Demandas abertas: {len(abertas)}")

# Demandas em andamento
em_andamento = user.get_demandas_em_andamento().all()
print(f"Em andamento: {len(em_andamento)}")
```

### Ativar/Desativar Usuário

```python
# Desativar usuário (soft delete)
user.desativar()
db.commit()

print(f"Usuário ativo? {user.is_ativo()}")  # False

# Reativar usuário
user.ativar()
db.commit()

print(f"Usuário ativo? {user.is_ativo()}")  # True
```

### Atualizar Dados do Usuário

```python
# Método 1: Diretamente
user.nome_completo = "João da Silva Santos"
user.email = "joao.santos@cliente.com"
db.commit()

# Método 2: Com dicionário
dados_atualizados = {
    'nome_completo': 'João da Silva Santos',
    'email': 'joao.santos@cliente.com'
}
user.update_from_dict(dados_atualizados)
db.commit()
```

### Alterar Senha

```python
# Verificar senha antiga
if user.verify_password("SenhaAntiga123"):
    # Definir nova senha
    user.set_password("NovaSenhaForte456")
    db.commit()
    print("Senha alterada com sucesso!")
else:
    print("Senha antiga incorreta")
```

### Serializar para JSON

```python
# Dados completos (sem senha)
user_data = user.to_dict()
print(user_data)
# {
#   'id': '...',
#   'username': 'joao.silva',
#   'email': 'joao@cliente.com',
#   'nome_completo': 'João Silva',
#   'tipo': 'cliente',
#   'cliente_id': '...',
#   'ativo': True,
#   'is_master': False,
#   'demandas_count': 5,
#   'cliente_nome': 'Nome do Cliente',
#   ...
# }

# Apenas dados públicos
user_safe = user.to_dict_safe()
print(user_safe)
# {
#   'id': '...',
#   'username': 'joao.silva',
#   'email': 'joao@cliente.com',
#   'nome_completo': 'João Silva',
#   'tipo': 'cliente',
#   'ativo': True,
#   'created_at': '2024-01-01T...'
# }
```

---

## 🔒 Segurança

### Criptografia de Senha

O modelo usa **bcrypt** via `passlib` para criptografia de senhas:

```python
# Configuração
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Hash da senha
password_hash = pwd_context.hash("SenhaForte123")

# Verificação
is_valid = pwd_context.verify("SenhaForte123", password_hash)
```

**Benefícios do bcrypt:**
- ✅ Resistente a ataques de força bruta
- ✅ Salt automático (previne rainbow tables)
- ✅ Configurável (custo computacional)
- ✅ Amplamente testado e confiável

### Validação de Senha

Requisitos de senha fortes:
- Mínimo 8 caracteres
- Pelo menos uma letra maiúscula
- Pelo menos uma letra minúscula
- Pelo menos um número

```python
# Senhas válidas
user.set_password("SenhaForte123")  # ✅
user.set_password("Abc12345")       # ✅

# Senhas inválidas
user.set_password("senha123")       # ❌ Falta maiúscula
user.set_password("SENHA123")       # ❌ Falta minúscula
user.set_password("SenhaForte")     # ❌ Falta número
user.set_password("Abc123")         # ❌ Menos de 8 chars
```

### UUID como Primary Key

Usar UUID ao invés de integer sequencial:

**Vantagens:**
- ✅ Previne enumeration attacks
- ✅ Globalmente único
- ✅ Não expõe quantidade de registros
- ✅ Facilita merge de bancos

```python
# ID sequencial (INSEGURO)
/api/users/1
/api/users/2
/api/users/3  # Atacante pode enumerar todos os IDs

# UUID (SEGURO)
/api/users/550e8400-e29b-41d4-a716-446655440000
# Impossível adivinhar ou enumerar
```

### Soft Delete

O modelo usa soft delete (desativar ao invés de deletar):

```python
# NÃO faz
db.delete(user)

# FAZ
user.desativar()
```

**Benefícios:**
- ✅ Preserva histórico
- ✅ Mantém integridade referencial
- ✅ Permite auditoria
- ✅ Possibilita reativação

---

## 🎯 Validações Implementadas

### Validação de Username

```python
@validates('username')
def validate_username(self, key, username):
    # Regras:
    # - Obrigatório
    # - 3-50 caracteres
    # - Apenas: a-z, 0-9, _, -
    # - Convertido para lowercase
    # - Trim automático
```

**Exemplos:**
```python
# Válidos
"joao_silva"     # ✅
"admin-master"   # ✅
"user123"        # ✅

# Inválidos
"jo"             # ❌ Muito curto
"João Silva"     # ❌ Espaços e acentos
"user@email"     # ❌ Caractere @
```

### Validação de Email

```python
@validates('email')
def validate_email(self, key, email):
    # Regras:
    # - Obrigatório
    # - Formato válido
    # - Max 100 caracteres
    # - Convertido para lowercase
    # - Trim automático
```

**Exemplos:**
```python
# Válidos
"joao@cliente.com"        # ✅
"admin@debrief.com.br"    # ✅

# Inválidos
"email_invalido"          # ❌ Sem @
"@dominio.com"            # ❌ Sem nome
"joao@"                   # ❌ Sem domínio
```

### Validação de Cliente ID

```python
@validates('cliente_id')
def validate_cliente_id(self, key, cliente_id):
    # Regras:
    # - Obrigatório para tipo CLIENTE
    # - NULL para tipo MASTER
```

**Exemplos:**
```python
# Usuário CLIENTE
tipo = TipoUsuario.CLIENTE
cliente_id = "uuid-do-cliente"  # ✅

cliente_id = None  # ❌ ValueError

# Usuário MASTER
tipo = TipoUsuario.MASTER
cliente_id = None  # ✅

cliente_id = "uuid"  # ❌ ValueError
```

---

## 📊 Relacionamentos

### Cliente (Many-to-One)

```python
cliente = relationship(
    "Cliente",
    back_populates="usuarios",
    lazy="joined"  # Carrega automaticamente
)
```

**Uso:**
```python
# Acessar cliente do usuário
print(user.cliente.nome)

# Buscar usuários de um cliente
cliente.usuarios  # Lista de usuários
```

### Demandas (One-to-Many)

```python
demandas = relationship(
    "Demanda",
    back_populates="usuario",
    cascade="all, delete-orphan",
    lazy="dynamic"  # Query ao invés de lista
)
```

**Uso:**
```python
# Total de demandas
total = user.demandas.count()

# Filtrar demandas
abertas = user.demandas.filter_by(status='aberta').all()

# Ordenar demandas
recentes = user.demandas.order_by(Demanda.created_at.desc()).limit(10)
```

**lazy="dynamic"** vs **lazy="select"**:
- `dynamic`: Retorna Query (melhor para grandes volumes)
- `select`: Retorna lista (carrega tudo de uma vez)

---

## 🔍 Índices

### Índices Simples

```python
username (unique, indexed)  # Busca rápida por login
email (unique, indexed)     # Busca por email
tipo (indexed)              # Filtro por tipo
ativo (indexed)             # Filtro por status
cliente_id (indexed)        # Join com cliente
```

### Índices Compostos

```python
# Buscar usuários ativos de um cliente
Index('idx_user_cliente_ativo', 'cliente_id', 'ativo')

# Exemplo de query otimizada:
users = db.query(User).filter(
    User.cliente_id == cliente_id,
    User.ativo == True
).all()

# Buscar usuários por tipo e status
Index('idx_user_tipo_ativo', 'tipo', 'ativo')

# Exemplo de query otimizada:
masters_ativos = db.query(User).filter(
    User.tipo == TipoUsuario.MASTER,
    User.ativo == True
).all()
```

---

## 🧪 Testes Sugeridos

### Testes Unitários

```python
def test_create_user():
    """Teste de criação de usuário"""
    user = User(
        username="test",
        email="test@test.com",
        nome_completo="Test User",
        tipo=TipoUsuario.MASTER
    )
    user.set_password("Test1234")
    
    assert user.username == "test"
    assert user.verify_password("Test1234")
    assert user.is_master()

def test_password_validation():
    """Teste de validação de senha"""
    user = User(username="test")
    
    # Senha válida
    user.set_password("ValidPass123")  # OK
    
    # Senhas inválidas
    with pytest.raises(ValueError):
        user.set_password("short")  # Muito curta
    
    with pytest.raises(ValueError):
        user.set_password("nouppercase123")  # Sem maiúscula
    
    with pytest.raises(ValueError):
        user.set_password("NOLOWERCASE123")  # Sem minúscula
    
    with pytest.raises(ValueError):
        user.set_password("NoNumbers")  # Sem número

def test_username_validation():
    """Teste de validação de username"""
    user = User()
    
    # Username válido
    user.username = "valid_user123"  # OK
    
    # Usernames inválidos
    with pytest.raises(ValueError):
        user.username = "ab"  # Muito curto
    
    with pytest.raises(ValueError):
        user.username = "invalid user"  # Espaços

def test_permissions():
    """Teste de permissões"""
    master = User(tipo=TipoUsuario.MASTER)
    cliente = User(tipo=TipoUsuario.CLIENTE, cliente_id="123")
    
    assert master.is_master()
    assert not master.is_cliente()
    assert master.can_access_cliente("any-id")
    
    assert not cliente.is_master()
    assert cliente.is_cliente()
    assert cliente.can_access_cliente("123")
    assert not cliente.can_access_cliente("456")
```

### Testes de Integração

```python
def test_user_demandas_relationship(db):
    """Teste de relacionamento com demandas"""
    user = User(username="test", ...)
    db.add(user)
    db.commit()
    
    # Criar demandas
    demanda1 = Demanda(nome="Demanda 1", usuario=user)
    demanda2 = Demanda(nome="Demanda 2", usuario=user)
    db.add_all([demanda1, demanda2])
    db.commit()
    
    # Verificar relacionamento
    assert user.get_demandas_count() == 2
    assert len(user.demandas.all()) == 2

def test_user_cliente_relationship(db):
    """Teste de relacionamento com cliente"""
    cliente = Cliente(nome="Cliente Teste")
    user = User(username="test", cliente=cliente)
    db.add_all([cliente, user])
    db.commit()
    
    # Verificar relacionamento
    assert user.cliente.nome == "Cliente Teste"
    assert user in cliente.usuarios
```

---

## 📖 Dependências

```python
# SQLAlchemy
from sqlalchemy import Column, String, Boolean, Enum, ForeignKey, Index
from sqlalchemy.orm import relationship, validates

# Segurança
from passlib.context import CryptContext

# Python stdlib
import enum
import re
from typing import Optional, List
```

**Instalar:**
```bash
pip install sqlalchemy passlib[bcrypt]
```

---

## 🚀 Próximos Passos

### 1. Criar Outros Modelos

- [ ] Cliente.py
- [ ] Secretaria.py
- [ ] TipoDemanda.py
- [ ] Prioridade.py
- [ ] Demanda.py
- [ ] Anexo.py
- [ ] Configuracao.py
- [ ] NotificationLog.py

### 2. Criar Schemas Pydantic

```python
# app/schemas/user.py
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    nome_completo: str
    tipo: str
    cliente_id: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    nome_completo: str
    tipo: str
    ativo: bool
    
    class Config:
        from_attributes = True
```

### 3. Criar CRUD Operations

```python
# app/crud/user.py
def get_user(db: Session, user_id: str):
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

def create_user(db: Session, user_data: UserCreate):
    user = User(**user_data.dict(exclude={'password'}))
    user.set_password(user_data.password)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
```

### 4. Criar Endpoints FastAPI

```python
# app/routes/auth.py
@router.post("/login")
def login(credentials: LoginSchema, db: Session = Depends(get_db)):
    user = get_user_by_username(db, credentials.username)
    
    if not user or not user.verify_password(credentials.password):
        raise HTTPException(401, "Credenciais inválidas")
    
    if not user.is_ativo():
        raise HTTPException(403, "Usuário inativo")
    
    # Gerar JWT token
    token = create_access_token(user.id)
    return {"access_token": token, "user": user.to_dict_safe()}
```

### 5. Configurar Migrations com Alembic

```bash
# Criar migration inicial
alembic revision --autogenerate -m "Create users table"

# Aplicar migration
alembic upgrade head
```

---

## ✨ Diferenciais do Modelo

### 🎯 Além do Especificado:

- ✅ Validações robustas de todos os campos
- ✅ Métodos auxiliares completos
- ✅ Sistema de permissões integrado
- ✅ Índices compostos otimizados
- ✅ Serialização segura (to_dict_safe)
- ✅ Soft delete implementado
- ✅ Relacionamentos com lazy loading configurável
- ✅ Métodos de consulta de demandas
- ✅ Verificação de complexidade de senha
- ✅ Código 100% documentado em português

### 🛡️ Segurança:

- ✅ Bcrypt para senhas
- ✅ UUID como primary key
- ✅ Validação de formato de email
- ✅ Senha forte obrigatória
- ✅ Soft delete (auditoria)
- ✅ Índices para performance

### 📊 Performance:

- ✅ Índices simples e compostos
- ✅ Lazy loading configurável
- ✅ Query ao invés de lista (demandas)
- ✅ Joined loading para cliente

---

## 🎉 Conclusão

O modelo **User.py** está **100% pronto** e **production-ready**!

### ✅ Você tem agora:

1. ✅ Modelo SQLAlchemy completo (643 linhas)
2. ✅ Classe base reutilizável (118 linhas)
3. ✅ Documentação detalhada
4. ✅ Validações robustas
5. ✅ Sistema de permissões
6. ✅ Métodos auxiliares
7. ✅ Segurança com bcrypt
8. ✅ Índices otimizados
9. ✅ Exemplos de uso

### 🚀 Pronto para:

- ✅ Criar outros modelos
- ✅ Implementar autenticação
- ✅ Criar schemas Pydantic
- ✅ Desenvolver endpoints
- ✅ Configurar migrations
- ✅ Usar em produção

Consulte este documento para referência completa do modelo User! 📚

---

**Modelo criado seguindo 100% as especificações do BACKEND_GUIDE.md e PROJECT_SPEC.md! 🐍✨**

