# 🐍 BACKEND GUIDE - DeBrief Sistema

## 📋 ÍNDICE

1. [Setup Inicial](#setup-inicial)
2. [Estrutura de Pastas Detalhada](#estrutura-de-pastas-detalhada)
3. [Configurações e Banco de Dados](#configurações-e-banco-de-dados)
4. [Modelos SQLAlchemy](#modelos-sqlalchemy)
5. [Schemas Pydantic](#schemas-pydantic)
6. [Sistema de Autenticação](#sistema-de-autenticação)
7. [Rotas (Endpoints)](#rotas-endpoints)
8. [Serviços](#serviços)
9. [Integração Trello](#integração-trello)
10. [Integração WhatsApp](#integração-whatsapp)
11. [Upload de Arquivos](#upload-de-arquivos)
12. [Geração de Relatórios](#geração-de-relatórios)
13. [Migrations com Alembic](#migrations-com-alembic)
14. [Checklist de Desenvolvimento](#checklist-de-desenvolvimento)

---

## 🚀 SETUP INICIAL

### 1. Preparar Ambiente Python

```bash
# Navegar para a pasta do projeto
cd /home/seu-usuario/debrief

# Criar pasta backend
mkdir backend
cd backend

# Criar ambiente virtual (recomendado)
python3 -m venv venv

# Ativar ambiente virtual
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Atualizar pip
pip install --upgrade pip
```

### 2. Criar requirements.txt

```bash
# Criar arquivo de dependências
cat > requirements.txt << 'EOF'
# Framework Web
fastapi==0.110.0
uvicorn[standard]==0.27.1

# Banco de Dados
sqlalchemy==2.0.27
psycopg2-binary==2.9.9
alembic==1.13.1

# Autenticação e Segurança
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9

# Integrações
py-trello==0.19.0
requests==2.31.0

# Utilitários
python-dotenv==1.0.1
pydantic[email]==2.6.3
pydantic-settings==2.2.1

# Geração de Relatórios
reportlab==4.1.0
openpyxl==3.1.2
pillow==10.2.0

# Async e I/O
aiofiles==23.2.1

# Validações
email-validator==2.1.0.post1
EOF

# Instalar dependências
pip install -r requirements.txt
```

### 3. Criar Estrutura de Pastas

```bash
# Criar todas as pastas de uma vez
mkdir -p app/{models,schemas,routes,services,database,utils}
mkdir -p uploads
mkdir -p alembic
```

### 4. Estrutura Completa

```
backend/
├── venv/                    # Ambiente virtual (não commitar)
│
├── app/
│   ├── __init__.py
│   ├── main.py             # Arquivo principal FastAPI
│   ├── config.py           # Configurações do app
│   │
│   ├── models/             # Modelos SQLAlchemy (tabelas)
│   │   ├── __init__.py
│   │   ├── base.py         # Classe base
│   │   ├── user.py         # Model de usuários
│   │   ├── cliente.py      # Model de clientes
│   │   ├── secretaria.py   # Model de secretarias
│   │   ├── demanda.py      # Model de demandas
│   │   ├── anexo.py        # Model de anexos
│   │   ├── tipo_demanda.py # Model de tipos
│   │   ├── prioridade.py   # Model de prioridades
│   │   └── configuracao.py # Model de configs
│   │
│   ├── schemas/            # Schemas Pydantic (validação)
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── cliente.py
│   │   ├── demanda.py
│   │   ├── relatorio.py
│   │   └── token.py
│   │
│   ├── routes/             # Rotas/Endpoints da API
│   │   ├── __init__.py
│   │   ├── auth.py         # Login/logout
│   │   ├── demandas.py     # CRUD demandas
│   │   ├── usuarios.py     # CRUD usuários
│   │   ├── clientes.py     # CRUD clientes
│   │   ├── secretarias.py  # CRUD secretarias
│   │   ├── tipos_demanda.py
│   │   ├── prioridades.py
│   │   ├── configuracoes.py
│   │   └── relatorios.py   # Endpoints relatórios
│   │
│   ├── services/           # Lógica de negócio
│   │   ├── __init__.py
│   │   ├── trello.py       # Integração Trello
│   │   ├── whatsapp.py     # Integração WhatsApp
│   │   ├── upload.py       # Gerenciar uploads
│   │   ├── relatorio.py    # Gerar PDFs/Excel
│   │   └── notification.py # Logs de notificações
│   │
│   ├── database/           # Conexão DB e Session
│   │   ├── __init__.py
│   │   └── connection.py
│   │
│   └── utils/              # Funções auxiliares
│       ├── __init__.py
│       ├── security.py     # Hash, JWT
│       ├── validators.py   # Validações custom
│       └── helpers.py      # Funções helper
│
├── alembic/                # Migrations
│   ├── versions/           # Arquivos de migração
│   ├── env.py
│   ├── script.py.mako
│   └── alembic.ini
│
├── uploads/                # Arquivos enviados
│   └── .gitkeep
│
├── tests/                  # Testes (opcional)
│   └── __init__.py
│
├── .env                    # Variáveis de ambiente (SECRET!)
├── .env.example            # Exemplo de .env
├── .gitignore
├── requirements.txt
├── alembic.ini            # Config Alembic
└── README.md
```

---

## ⚙️ CONFIGURAÇÕES E BANCO DE DADOS

### 1. .env.example

```bash
# Database PostgreSQL
DATABASE_URL=postgresql://usuario:senha@localhost:5432/debrief

# JWT Secret Key (MUDAR EM PRODUÇÃO!)
SECRET_KEY=sua-chave-super-secreta-min-32-caracteres-aqui-123456789
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480

# Trello API
TRELLO_API_KEY=sua-trello-api-key
TRELLO_TOKEN=seu-trello-token
TRELLO_BOARD_ID=id-do-board-trello
TRELLO_LIST_ID=id-da-lista-envios

# WPPConnect
WPP_URL=http://localhost:21465
WPP_INSTANCE=debrief-instance
WPP_TOKEN=seu-token-wppconnect

# Google reCAPTCHA
RECAPTCHA_SECRET_KEY=sua-chave-secreta-recaptcha

# Upload Config
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=52428800  # 50MB
ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png

# CORS (Frontend URL)
FRONTEND_URL=http://localhost:5173

# Environment
ENVIRONMENT=development
```

### 2. app/config.py

```python
"""
Configurações do aplicativo
Carrega variáveis de ambiente e define constantes
"""
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    """
    Classe de configurações usando Pydantic Settings
    Carrega automaticamente do .env
    """
    
    # Database
    DATABASE_URL: str
    
    # JWT
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 480
    
    # Trello
    TRELLO_API_KEY: str
    TRELLO_TOKEN: str
    TRELLO_BOARD_ID: str
    TRELLO_LIST_ID: str
    
    # WPPConnect
    WPP_URL: str
    WPP_INSTANCE: str
    WPP_TOKEN: str
    
    # reCAPTCHA
    RECAPTCHA_SECRET_KEY: str
    
    # Upload
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE: int = 52428800  # 50MB
    ALLOWED_EXTENSIONS: List[str] = ["pdf", "jpg", "jpeg", "png"]
    
    # CORS
    FRONTEND_URL: str = "http://localhost:5173"
    
    # Environment
    ENVIRONMENT: str = "development"
    
    class Config:
        # Arquivo de onde carregar as variáveis
        env_file = ".env"
        case_sensitive = False

# Instância global de configurações
settings = Settings()
```

### 3. app/database/connection.py

```python
"""
Configuração da conexão com PostgreSQL usando SQLAlchemy
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings

# Criar engine do SQLAlchemy
# echo=True mostra SQL no console (útil para debug)
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.ENVIRONMENT == "development",
    pool_pre_ping=True,  # Verifica conexão antes de usar
    pool_size=10,         # Número de conexões no pool
    max_overflow=20       # Máximo de conexões extras
)

# Session factory
# Cada sessão representa uma "transação" com o banco
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Classe base para todos os modelos
Base = declarative_base()

def get_db():
    """
    Dependency Injection para obter sessão do banco
    
    Uso em endpoints:
    @app.get("/items")
    def get_items(db: Session = Depends(get_db)):
        return db.query(Item).all()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

---

## 📦 MODELOS SQLALCHEMY

### app/models/base.py

```python
"""
Classe base para todos os modelos
Define campos comuns (ID, timestamps)
"""
import uuid
from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from app.database.connection import Base

class BaseModel(Base):
    """
    Classe abstrata com campos comuns
    Todos os modelos herdarão destes campos
    """
    __abstract__ = True  # Não cria tabela
    
    # UUID como chave primária (mais seguro que int sequencial)
    id = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True
    )
    
    # Timestamp de criação (automático)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    
    # Timestamp de última atualização (automático)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
    
    def to_dict(self):
        """
        Converte modelo para dicionário
        Útil para serialização
        """
        return {
            column.name: getattr(self, column.name)
            for column in self.__table__.columns
        }
```

### app/models/user.py

```python
"""
Modelo de Usuário
Representa a tabela 'users' no banco
"""
from sqlalchemy import Column, String, Boolean, Enum, ForeignKey
from sqlalchemy.orm import relationship
import enum
from app.models.base import BaseModel

class TipoUsuario(str, enum.Enum):
    """
    Enum para tipos de usuário
    """
    MASTER = "master"
    CLIENTE = "cliente"

class User(BaseModel):
    """
    Tabela de usuários do sistema
    """
    __tablename__ = "users"
    
    # Campos básicos
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    nome_completo = Column(String(200), nullable=False)
    
    # Tipo de usuário (master ou cliente)
    tipo = Column(Enum(TipoUsuario), nullable=False, default=TipoUsuario.CLIENTE)
    
    # Relacionamento com cliente (nullable para masters)
    cliente_id = Column(String(36), ForeignKey("clientes.id"), nullable=True)
    cliente = relationship("Cliente", back_populates="usuarios")
    
    # Status ativo/inativo
    ativo = Column(Boolean, default=True, nullable=False)
    
    # Relacionamentos
    demandas = relationship("Demanda", back_populates="usuario")
    
    def __repr__(self):
        return f"<User(username='{self.username}', tipo='{self.tipo}')>"
```

### app/models/cliente.py

```python
"""
Modelo de Cliente
Representa empresas/órgãos que usam o sistema
"""
from sqlalchemy import Column, String, Boolean
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class Cliente(BaseModel):
    """
    Tabela de clientes
    """
    __tablename__ = "clientes"
    
    # Nome da empresa/órgão
    nome = Column(String(200), nullable=False)
    
    # ID do grupo no WhatsApp (para notificações)
    whatsapp_group_id = Column(String(100), nullable=True)
    
    # ID do membro no Trello (para atribuir cards)
    trello_member_id = Column(String(100), nullable=True)
    
    # Status ativo/inativo
    ativo = Column(Boolean, default=True, nullable=False)
    
    # Relacionamentos
    usuarios = relationship("User", back_populates="cliente")
    secretarias = relationship("Secretaria", back_populates="cliente")
    demandas = relationship("Demanda", back_populates="cliente")
    
    def __repr__(self):
        return f"<Cliente(nome='{self.nome}')>"
```

### app/models/secretaria.py

```python
"""
Modelo de Secretaria
Secretarias/departamentos dentro de um cliente
"""
from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class Secretaria(BaseModel):
    """
    Tabela de secretarias
    """
    __tablename__ = "secretarias"
    
    # Nome da secretaria
    nome = Column(String(200), nullable=False)
    
    # Cliente ao qual pertence
    cliente_id = Column(String(36), ForeignKey("clientes.id"), nullable=False)
    cliente = relationship("Cliente", back_populates="secretarias")
    
    # Status ativo/inativo
    ativo = Column(Boolean, default=True, nullable=False)
    
    # Relacionamentos
    demandas = relationship("Demanda", back_populates="secretaria")
    
    def __repr__(self):
        return f"<Secretaria(nome='{self.nome}')>"
```

### app/models/tipo_demanda.py

```python
"""
Modelo de Tipo de Demanda
Ex: Design, Desenvolvimento, Conteúdo, etc
"""
from sqlalchemy import Column, String, Boolean
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class TipoDemanda(BaseModel):
    """
    Tabela de tipos de demanda
    """
    __tablename__ = "tipos_demanda"
    
    # Nome do tipo
    nome = Column(String(100), nullable=False)
    
    # Cor para UI (hex color)
    cor = Column(String(7), nullable=False, default="#3B82F6")
    
    # Status ativo/inativo
    ativo = Column(Boolean, default=True, nullable=False)
    
    # Relacionamentos
    demandas = relationship("Demanda", back_populates="tipo_demanda")
    
    def __repr__(self):
        return f"<TipoDemanda(nome='{self.nome}')>"
```

### app/models/prioridade.py

```python
"""
Modelo de Prioridade
Ex: Baixa, Média, Alta, Urgente
"""
from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class Prioridade(BaseModel):
    """
    Tabela de prioridades
    """
    __tablename__ = "prioridades"
    
    # Nome da prioridade
    nome = Column(String(50), nullable=False)
    
    # Nível (1=Baixa, 2=Média, 3=Alta, 4=Urgente)
    nivel = Column(Integer, nullable=False)
    
    # Cor para UI (hex color)
    cor = Column(String(7), nullable=False, default="#10B981")
    
    # Relacionamentos
    demandas = relationship("Demanda", back_populates="prioridade")
    
    def __repr__(self):
        return f"<Prioridade(nome='{self.nome}', nivel={self.nivel})>"
```

### app/models/demanda.py

```python
"""
Modelo de Demanda
Tabela principal do sistema
"""
from sqlalchemy import Column, String, Text, Date, Enum, ForeignKey
from sqlalchemy.orm import relationship
import enum
from app.models.base import BaseModel

class StatusDemanda(str, enum.Enum):
    """
    Enum para status da demanda
    """
    ABERTA = "aberta"
    EM_ANDAMENTO = "em_andamento"
    CONCLUIDA = "concluida"
    CANCELADA = "cancelada"

class Demanda(BaseModel):
    """
    Tabela de demandas
    """
    __tablename__ = "demandas"
    
    # Informações básicas
    nome = Column(String(200), nullable=False)
    descricao = Column(Text, nullable=False)
    
    # Relacionamentos (Foreign Keys)
    secretaria_id = Column(String(36), ForeignKey("secretarias.id"), nullable=False)
    secretaria = relationship("Secretaria", back_populates="demandas")
    
    tipo_demanda_id = Column(String(36), ForeignKey("tipos_demanda.id"), nullable=False)
    tipo_demanda = relationship("TipoDemanda", back_populates="demandas")
    
    prioridade_id = Column(String(36), ForeignKey("prioridades.id"), nullable=False)
    prioridade = relationship("Prioridade", back_populates="demandas")
    
    # Usuário que criou
    usuario_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    usuario = relationship("User", back_populates="demandas")
    
    # Cliente (denormalizado para queries mais rápidas)
    cliente_id = Column(String(36), ForeignKey("clientes.id"), nullable=False)
    cliente = relationship("Cliente", back_populates="demandas")
    
    # Prazo
    prazo_final = Column(Date, nullable=False)
    
    # Integração Trello
    trello_card_id = Column(String(100), nullable=True)
    trello_card_url = Column(String(500), nullable=True)
    
    # Status
    status = Column(
        Enum(StatusDemanda),
        nullable=False,
        default=StatusDemanda.ABERTA
    )
    
    # Relacionamentos
    anexos = relationship("Anexo", back_populates="demanda", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Demanda(nome='{self.nome}', status='{self.status}')>"
```

### app/models/anexo.py

```python
"""
Modelo de Anexo
Arquivos vinculados a demandas
"""
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class Anexo(BaseModel):
    """
    Tabela de anexos
    """
    __tablename__ = "anexos"
    
    # Demanda ao qual pertence
    demanda_id = Column(String(36), ForeignKey("demandas.id"), nullable=False)
    demanda = relationship("Demanda", back_populates="anexos")
    
    # Informações do arquivo
    nome_arquivo = Column(String(500), nullable=False)
    caminho = Column(String(1000), nullable=False)  # Path no servidor
    tamanho = Column(Integer, nullable=False)        # Bytes
    tipo_mime = Column(String(100), nullable=False)  # Ex: application/pdf
    
    # ID do anexo no Trello (se aplicável)
    trello_attachment_id = Column(String(100), nullable=True)
    
    def __repr__(self):
        return f"<Anexo(nome='{self.nome_arquivo}')>"
```

### app/models/configuracao.py

```python
"""
Modelo de Configuração
Armazena configurações do sistema (APIs, etc)
"""
from sqlalchemy import Column, String, Text
from app.models.base import BaseModel

class Configuracao(BaseModel):
    """
    Tabela de configurações
    """
    __tablename__ = "configuracoes"
    
    # Chave única da configuração
    chave = Column(String(100), unique=True, nullable=False, index=True)
    
    # Valor (pode ser JSON, será criptografado)
    valor = Column(Text, nullable=True)
    
    # Descrição para UI
    descricao = Column(String(500), nullable=True)
    
    def __repr__(self):
        return f"<Configuracao(chave='{self.chave}')>"
```

### app/models/__init__.py

```python
"""
Importa todos os modelos
Facilita imports em outros arquivos
"""
from app.models.base import BaseModel
from app.models.user import User, TipoUsuario
from app.models.cliente import Cliente
from app.models.secretaria import Secretaria
from app.models.tipo_demanda import TipoDemanda
from app.models.prioridade import Prioridade
from app.models.demanda import Demanda, StatusDemanda
from app.models.anexo import Anexo
from app.models.configuracao import Configuracao

__all__ = [
    "BaseModel",
    "User",
    "TipoUsuario",
    "Cliente",
    "Secretaria",
    "TipoDemanda",
    "Prioridade",
    "Demanda",
    "StatusDemanda",
    "Anexo",
    "Configuracao",
]
```

---

## 📝 SCHEMAS PYDANTIC

### app/schemas/user.py

```python
"""
Schemas Pydantic para User
Validação de entrada/saída de dados
"""
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime
from app.models.user import TipoUsuario

class UserBase(BaseModel):
    """
    Schema base com campos comuns
    """
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    nome_completo: str = Field(..., min_length=3, max_length=200)
    tipo: TipoUsuario
    cliente_id: Optional[str] = None
    ativo: bool = True

class UserCreate(UserBase):
    """
    Schema para criar usuário
    Inclui senha
    """
    password: str = Field(..., min_length=8, max_length=50)
    
    @validator('password')
    def validate_password(cls, v):
        """
        Validar senha forte
        """
        if not any(char.isdigit() for char in v):
            raise ValueError('Senha deve conter pelo menos um número')
        if not any(char.isupper() for char in v):
            raise ValueError('Senha deve conter pelo menos uma letra maiúscula')
        return v

class UserUpdate(BaseModel):
    """
    Schema para atualizar usuário
    Todos os campos opcionais
    """
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    nome_completo: Optional[str] = Field(None, min_length=3, max_length=200)
    password: Optional[str] = Field(None, min_length=8, max_length=50)
    cliente_id: Optional[str] = None
    ativo: Optional[bool] = None

class UserResponse(UserBase):
    """
    Schema de resposta (não retorna senha)
    """
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        # Permite criar de modelos SQLAlchemy
        from_attributes = True

# Exemplo de uso:
# user_data = UserCreate(
#     username="joao",
#     email="joao@example.com",
#     nome_completo="João Silva",
#     tipo=TipoUsuario.CLIENTE,
#     password="Senha123"
# )
```

### app/schemas/demanda.py

```python
"""
Schemas Pydantic para Demanda
"""
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import date, datetime
from app.models.demanda import StatusDemanda

class DemandaBase(BaseModel):
    """
    Schema base de demanda
    """
    nome: str = Field(..., min_length=5, max_length=200)
    descricao: str = Field(..., min_length=10, max_length=2000)
    secretaria_id: str
    tipo_demanda_id: str
    prioridade_id: str
    prazo_final: date
    
    @validator('prazo_final')
    def validate_prazo(cls, v):
        """
        Prazo deve ser data futura
        """
        if v < date.today():
            raise ValueError('Prazo deve ser uma data futura')
        return v

class DemandaCreate(DemandaBase):
    """
    Schema para criar demanda
    """
    pass

class DemandaUpdate(BaseModel):
    """
    Schema para atualizar demanda
    Campos opcionais
    """
    nome: Optional[str] = Field(None, min_length=5, max_length=200)
    descricao: Optional[str] = Field(None, min_length=10, max_length=2000)
    tipo_demanda_id: Optional[str] = None
    prioridade_id: Optional[str] = None
    prazo_final: Optional[date] = None
    status: Optional[StatusDemanda] = None

class AnexoResponse(BaseModel):
    """
    Schema de resposta de anexo
    """
    id: str
    nome_arquivo: str
    caminho: str
    tamanho: int
    tipo_mime: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class DemandaResponse(DemandaBase):
    """
    Schema de resposta completa
    """
    id: str
    usuario_id: str
    cliente_id: str
    trello_card_id: Optional[str] = None
    trello_card_url: Optional[str] = None
    status: StatusDemanda
    created_at: datetime
    updated_at: datetime
    
    # Relacionamentos expandidos (opcional)
    anexos: Optional[List[AnexoResponse]] = []
    
    class Config:
        from_attributes = True

class DemandaListResponse(BaseModel):
    """
    Schema para listagem paginada
    """
    total: int
    items: List[DemandaResponse]
    page: int
    page_size: int
```

### app/schemas/token.py

```python
"""
Schemas para autenticação JWT
"""
from pydantic import BaseModel
from typing import Optional

class Token(BaseModel):
    """
    Schema de resposta de login
    """
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    """
    Dados extraídos do token JWT
    """
    user_id: Optional[str] = None
    username: Optional[str] = None

class LoginRequest(BaseModel):
    """
    Schema de requisição de login
    """
    username: str
    password: str
    recaptcha_token: Optional[str] = None
```

---

## 🔐 SISTEMA DE AUTENTICAÇÃO

### app/utils/security.py

```python
"""
Utilitários de segurança
Hash de senhas, JWT, etc
"""
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.config import settings

# Contexto para hash de senhas (bcrypt)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """
    Gera hash bcrypt da senha
    
    Args:
        password: Senha em texto plano
    
    Returns:
        Hash da senha
    """
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verifica se senha bate com hash
    
    Args:
        plain_password: Senha digitada
        hashed_password: Hash armazenado no banco
    
    Returns:
        True se senhas batem, False caso contrário
    """
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Cria token JWT
    
    Args:
        data: Dados a serem codificados (user_id, username)
        expires_delta: Tempo de expiração customizado (opcional)
    
    Returns:
        Token JWT assinado
    """
    to_encode = data.copy()
    
    # Definir expiração
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    # Adicionar campo de expiração
    to_encode.update({"exp": expire})
    
    # Criar token
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt

def decode_access_token(token: str) -> Optional[dict]:
    """
    Decodifica e valida token JWT
    
    Args:
        token: Token JWT
    
    Returns:
        Payload do token ou None se inválido
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None

# Exemplo de uso:
# 
# # Hash de senha ao criar usuário
# hashed = hash_password("minha_senha")
# user.password_hash = hashed
# 
# # Verificar senha no login
# if verify_password(password_digitada, user.password_hash):
#     # Login OK
# 
# # Criar token após login bem-sucedido
# token = create_access_token({"sub": user.id, "username": user.username})
```

### app/routes/auth.py

```python
"""
Rotas de autenticação
Login, logout, obter usuário atual
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.models.user import User
from app.schemas.token import Token, LoginRequest
from app.schemas.user import UserResponse
from app.utils.security import verify_password, create_access_token, decode_access_token

# Router
router = APIRouter(prefix="/auth", tags=["Autenticação"])

# OAuth2 scheme para extrair token do header Authorization
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency para obter usuário logado do token
    
    Uso em endpoints:
    @router.get("/protected")
    def protected_route(current_user: User = Depends(get_current_user)):
        return {"message": f"Olá {current_user.username}"}
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    # Decodificar token
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    
    # Extrair user_id
    user_id: str = payload.get("sub")
    if user_id is None:
        raise credentials_exception
    
    # Buscar usuário no banco
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    
    # Verificar se está ativo
    if not user.ativo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário desativado"
        )
    
    return user

@router.post("/login", response_model=Token)
def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """
    Endpoint de login
    Valida credenciais e retorna token JWT
    """
    # Buscar usuário
    user = db.query(User).filter(User.username == login_data.username).first()
    
    # Verificar se existe
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário ou senha incorretos"
        )
    
    # Verificar senha
    if not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário ou senha incorretos"
        )
    
    # Verificar se está ativo
    if not user.ativo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário desativado"
        )
    
    # TODO: Validar reCAPTCHA (se fornecido)
    # if login_data.recaptcha_token:
    #     validate_recaptcha(login_data.recaptcha_token)
    
    # Criar token JWT
    access_token = create_access_token(
        data={"sub": user.id, "username": user.username}
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Obter dados do usuário logado
    """
    return current_user

@router.post("/logout")
def logout(current_user: User = Depends(get_current_user)):
    """
    Logout (implementação básica)
    No frontend: apenas deletar token do localStorage
    
    Para implementação robusta:
    - Manter blacklist de tokens no Redis
    - Verificar blacklist no get_current_user
    """
    return {"message": "Logout realizado com sucesso"}
```

---

## 🛣️ ROTAS (ENDPOINTS)

### app/routes/demandas.py

```python
"""
Rotas de Demandas
CRUD completo + listagem com filtros
"""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List, Optional
from datetime import date, datetime
from app.database.connection import get_db
from app.models.user import User
from app.models.demanda import Demanda, StatusDemanda
from app.models.anexo import Anexo
from app.schemas.demanda import DemandaCreate, DemandaUpdate, DemandaResponse, DemandaListResponse
from app.routes.auth import get_current_user
from app.services.trello import TrelloService
from app.services.whatsapp import WhatsAppService
from app.services.upload import UploadService

router = APIRouter(prefix="/demandas", tags=["Demandas"])

@router.post("", response_model=DemandaResponse, status_code=status.HTTP_201_CREATED)
async def criar_demanda(
    # Campos do formulário
    nome: str = Form(...),
    descricao: str = Form(...),
    secretaria_id: str = Form(...),
    tipo_demanda_id: str = Form(...),
    prioridade_id: str = Form(...),
    prazo_final: date = Form(...),
    # Arquivos (opcional)
    files: List[UploadFile] = File(None),
    # Dependencies
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Criar nova demanda
    
    Fluxo:
    1. Validar dados
    2. Salvar no banco
    3. Upload de arquivos
    4. Criar card no Trello
    5. Enviar notificação WhatsApp
    """
    try:
        # Criar demanda no banco
        demanda = Demanda(
            nome=nome,
            descricao=descricao,
            secretaria_id=secretaria_id,
            tipo_demanda_id=tipo_demanda_id,
            prioridade_id=prioridade_id,
            prazo_final=prazo_final,
            usuario_id=current_user.id,
            cliente_id=current_user.cliente_id,
            status=StatusDemanda.ABERTA
        )
        db.add(demanda)
        db.commit()
        db.refresh(demanda)
        
        # Upload de arquivos (se houver)
        if files:
            upload_service = UploadService()
            for file in files:
                # Salvar arquivo
                file_path = await upload_service.save_file(
                    file,
                    cliente_id=current_user.cliente_id,
                    demanda_id=demanda.id
                )
                
                # Criar registro no banco
                anexo = Anexo(
                    demanda_id=demanda.id,
                    nome_arquivo=file.filename,
                    caminho=file_path,
                    tamanho=file.size,
                    tipo_mime=file.content_type
                )
                db.add(anexo)
            
            db.commit()
        
        # Criar card no Trello
        try:
            trello_service = TrelloService()
            card = await trello_service.criar_card(demanda, db)
            
            # Atualizar demanda com IDs do Trello
            demanda.trello_card_id = card['id']
            demanda.trello_card_url = card['url']
            db.commit()
            
        except Exception as e:
            # Log erro mas não falha a operação
            print(f"Erro ao criar card no Trello: {e}")
        
        # Enviar notificação WhatsApp
        try:
            whatsapp_service = WhatsAppService()
            await whatsapp_service.enviar_nova_demanda(demanda, db)
        except Exception as e:
            print(f"Erro ao enviar WhatsApp: {e}")
        
        # Recarregar com relacionamentos
        db.refresh(demanda)
        
        return demanda
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar demanda: {str(e)}"
        )

@router.get("", response_model=DemandaListResponse)
def listar_demandas(
    # Filtros opcionais
    secretaria_id: Optional[str] = None,
    tipo_demanda_id: Optional[str] = None,
    status: Optional[StatusDemanda] = None,
    data_inicial: Optional[date] = None,
    data_final: Optional[date] = None,
    busca: Optional[str] = None,
    # Paginação
    page: int = 1,
    page_size: int = 10,
    # Dependencies
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Listar demandas com filtros
    Usuários normais: apenas suas demandas
    Admin: todas as demandas
    """
    # Query base
    query = db.query(Demanda)
    
    # Filtrar por cliente (se não for admin)
    if current_user.tipo != "master":
        query = query.filter(Demanda.cliente_id == current_user.cliente_id)
    
    # Aplicar filtros
    if secretaria_id:
        query = query.filter(Demanda.secretaria_id == secretaria_id)
    
    if tipo_demanda_id:
        query = query.filter(Demanda.tipo_demanda_id == tipo_demanda_id)
    
    if status:
        query = query.filter(Demanda.status == status)
    
    if data_inicial:
        query = query.filter(Demanda.created_at >= data_inicial)
    
    if data_final:
        query = query.filter(Demanda.created_at <= data_final)
    
    if busca:
        # Busca no nome ou descrição
        query = query.filter(
            or_(
                Demanda.nome.ilike(f"%{busca}%"),
                Demanda.descricao.ilike(f"%{busca}%")
            )
        )
    
    # Total de resultados
    total = query.count()
    
    # Paginação
    offset = (page - 1) * page_size
    items = query.order_by(Demanda.created_at.desc()).offset(offset).limit(page_size).all()
    
    return {
        "total": total,
        "items": items,
        "page": page,
        "page_size": page_size
    }

@router.get("/{demanda_id}", response_model=DemandaResponse)
def get_demanda(
    demanda_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Buscar demanda por ID
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    # Verificar permissão
    if current_user.tipo != "master" and demanda.cliente_id != current_user.cliente_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para acessar esta demanda"
        )
    
    return demanda

@router.put("/{demanda_id}", response_model=DemandaResponse)
async def atualizar_demanda(
    demanda_id: str,
    demanda_update: DemandaUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Atualizar demanda
    Atualiza também o card no Trello
    """
    # Buscar demanda
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    # Verificar permissão
    if current_user.tipo != "master" and demanda.usuario_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para editar esta demanda"
        )
    
    # Atualizar campos
    update_data = demanda_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(demanda, field, value)
    
    db.commit()
    db.refresh(demanda)
    
    # Atualizar card no Trello
    try:
        trello_service = TrelloService()
        await trello_service.atualizar_card(demanda, db)
    except Exception as e:
        print(f"Erro ao atualizar Trello: {e}")
    
    return demanda

@router.delete("/{demanda_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_demanda(
    demanda_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Deletar demanda (soft delete)
    Muda status para CANCELADA
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    # Verificar permissão
    if current_user.tipo != "master" and demanda.usuario_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para deletar esta demanda"
        )
    
    # Soft delete
    demanda.status = StatusDemanda.CANCELADA
    db.commit()
    
    return None
```

---

## 🔗 SERVIÇOS

### app/services/trello.py

```python
"""
Serviço de integração com Trello API
"""
from trello import TrelloClient
from sqlalchemy.orm import Session
from typing import Dict
from app.config import settings
from app.models.demanda import Demanda

class TrelloService:
    """
    Wrapper para Trello API
    """
    
    def __init__(self):
        """
        Inicializar cliente Trello
        """
        self.client = TrelloClient(
            api_key=settings.TRELLO_API_KEY,
            api_secret=settings.TRELLO_TOKEN
        )
        
        # Obter board e list
        self.board = self.client.get_board(settings.TRELLO_BOARD_ID)
        self.list = self.board.get_list(settings.TRELLO_LIST_ID)
    
    async def criar_card(self, demanda: Demanda, db: Session) -> Dict:
        """
        Criar card no Trello para uma demanda
        
        Args:
            demanda: Objeto Demanda do SQLAlchemy
            db: Sessão do banco (para carregar relacionamentos)
        
        Returns:
            Dicionário com ID e URL do card
        """
        # Carregar relacionamentos necessários
        db.refresh(demanda)
        
        # Construir nome do card
        card_name = f"{demanda.nome} - {demanda.cliente.nome}"
        
        # Construir descrição
        card_desc = f"""
**Secretaria:** {demanda.secretaria.nome}
**Tipo:** {demanda.tipo_demanda.nome}
**Prioridade:** {demanda.prioridade.nome}
**Prazo:** {demanda.prazo_final.strftime('%d/%m/%Y')}

**Descrição:**
{demanda.descricao}

**Solicitante:** {demanda.usuario.nome_completo}
**Email:** {demanda.usuario.email}
        """.strip()
        
        # Criar card
        card = self.list.add_card(
            name=card_name,
            desc=card_desc,
            position='top'
        )
        
        # Adicionar label da prioridade
        # (Assumindo que labels já existem no board)
        try:
            card.add_label(demanda.prioridade.nome)
        except:
            pass
        
        # Adicionar member (cliente)
        if demanda.cliente.trello_member_id:
            try:
                card.add_member(demanda.cliente.trello_member_id)
            except:
                pass
        
        # Adicionar anexos
        for anexo in demanda.anexos:
            try:
                # Construir URL pública do anexo
                anexo_url = f"{settings.FRONTEND_URL}/uploads/{anexo.caminho}"
                card.attach(url=anexo_url, name=anexo.nome_arquivo)
            except Exception as e:
                print(f"Erro ao anexar arquivo: {e}")
        
        # Set due date
        card.set_due(demanda.prazo_final)
        
        return {
            'id': card.id,
            'url': card.url
        }
    
    async def atualizar_card(self, demanda: Demanda, db: Session):
        """
        Atualizar card existente no Trello
        """
        if not demanda.trello_card_id:
            return
        
        try:
            # Obter card
            card = self.board.get_card(demanda.trello_card_id)
            
            # Atualizar nome
            card_name = f"{demanda.nome} - {demanda.cliente.nome}"
            card.set_name(card_name)
            
            # Atualizar descrição
            card_desc = f"""
**Secretaria:** {demanda.secretaria.nome}
**Tipo:** {demanda.tipo_demanda.nome}
**Prioridade:** {demanda.prioridade.nome}
**Prazo:** {demanda.prazo_final.strftime('%d/%m/%Y')}
**Status:** {demanda.status.value}

**Descrição:**
{demanda.descricao}

**Solicitante:** {demanda.usuario.nome_completo}
            """.strip()
            
            card.set_description(card_desc)
            
            # Atualizar due date
            card.set_due(demanda.prazo_final)
            
        except Exception as e:
            print(f"Erro ao atualizar card Trello: {e}")
            raise
```

### app/services/whatsapp.py

```python
"""
Serviço de integração com WPPConnect
"""
import requests
from sqlalchemy.orm import Session
from app.config import settings
from app.models.demanda import Demanda

class WhatsAppService:
    """
    Wrapper para WPPConnect API
    """
    
    def __init__(self):
        self.base_url = settings.WPP_URL
        self.instance = settings.WPP_INSTANCE
        self.token = settings.WPP_TOKEN
        
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }
    
    async def enviar_mensagem(self, group_id: str, mensagem: str) -> bool:
        """
        Enviar mensagem para grupo do WhatsApp
        
        Args:
            group_id: ID do grupo
            mensagem: Texto da mensagem
        
        Returns:
            True se enviado com sucesso
        """
        url = f"{self.base_url}/api/{self.instance}/send-text"
        
        payload = {
            "phone": group_id,
            "message": mensagem,
            "isGroup": True
        }
        
        try:
            response = requests.post(
                url,
                json=payload,
                headers=self.headers,
                timeout=10
            )
            
            if response.status_code == 200:
                return True
            else:
                print(f"Erro WhatsApp: {response.text}")
                return False
                
        except Exception as e:
            print(f"Exceção ao enviar WhatsApp: {e}")
            return False
    
    async def enviar_nova_demanda(self, demanda: Demanda, db: Session) -> bool:
        """
        Enviar notificação de nova demanda
        """
        # Carregar relacionamentos
        db.refresh(demanda)
        
        # Verificar se cliente tem grupo configurado
        if not demanda.cliente.whatsapp_group_id:
            print("Cliente sem grupo WhatsApp configurado")
            return False
        
        # Construir mensagem
        mensagem = f"""
🔔 *Nova Demanda Recebida!*

📋 *Demanda:* {demanda.nome}
🏢 *Secretaria:* {demanda.secretaria.nome}
📌 *Tipo:* {demanda.tipo_demanda.nome}
⚡ *Prioridade:* {demanda.prioridade.nome}
📅 *Prazo:* {demanda.prazo_final.strftime('%d/%m/%Y')}

👤 *Solicitante:* {demanda.usuario.nome_completo}

🔗 *Ver no Trello:* {demanda.trello_card_url or 'Processando...'}
        """.strip()
        
        # Enviar
        return await self.enviar_mensagem(
            demanda.cliente.whatsapp_group_id,
            mensagem
        )
```

---

## 📤 UPLOAD DE ARQUIVOS

### app/services/upload.py

```python
"""
Serviço para gerenciar upload de arquivos
"""
import os
import uuid
import aiofiles
from pathlib import Path
from fastapi import UploadFile, HTTPException, status
from app.config import settings

class UploadService:
    """
    Gerenciar upload e armazenamento de arquivos
    """
    
    def __init__(self):
        self.upload_dir = Path(settings.UPLOAD_DIR)
        self.max_size = settings.MAX_UPLOAD_SIZE
        self.allowed_extensions = settings.ALLOWED_EXTENSIONS
    
    def validate_file(self, file: UploadFile):
        """
        Validar arquivo antes de salvar
        
        Validações:
        - Tamanho máximo
        - Extensão permitida
        """
        # Verificar tamanho
        if file.size > self.max_size:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Arquivo muito grande. Máximo: {self.max_size / 1024 / 1024}MB"
            )
        
        # Verificar extensão
        ext = file.filename.split('.')[-1].lower()
        if ext not in self.allowed_extensions:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Extensão não permitida. Permitidos: {', '.join(self.allowed_extensions)}"
            )
    
    async def save_file(
        self,
        file: UploadFile,
        cliente_id: str,
        demanda_id: str
    ) -> str:
        """
        Salvar arquivo no servidor
        
        Args:
            file: Arquivo enviado
            cliente_id: ID do cliente (para organizar pastas)
            demanda_id: ID da demanda
        
        Returns:
            Caminho relativo do arquivo salvo
        """
        # Validar arquivo
        self.validate_file(file)
        
        # Criar estrutura de pastas: uploads/{cliente_id}/{demanda_id}/
        dir_path = self.upload_dir / cliente_id / demanda_id
        dir_path.mkdir(parents=True, exist_ok=True)
        
        # Gerar nome único para arquivo
        ext = file.filename.split('.')[-1]
        unique_filename = f"{uuid.uuid4()}.{ext}"
        file_path = dir_path / unique_filename
        
        # Salvar arquivo
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        # Retornar caminho relativo
        relative_path = f"{cliente_id}/{demanda_id}/{unique_filename}"
        return relative_path
    
    def delete_file(self, file_path: str):
        """
        Deletar arquivo do servidor
        """
        full_path = self.upload_dir / file_path
        
        if full_path.exists():
            full_path.unlink()
```

---

## 📊 GERAÇÃO DE RELATÓRIOS

### app/services/relatorio.py

```python
"""
Serviço para geração de relatórios PDF e Excel
"""
from io import BytesIO
from datetime import datetime
from typing import List
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib.units import inch
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from app.models.demanda import Demanda

class RelatorioService:
    """
    Gerador de relatórios
    """
    
    def gerar_pdf(self, demandas: List[Demanda], filtros: dict) -> BytesIO:
        """
        Gerar relatório PDF
        
        Args:
            demandas: Lista de demandas
            filtros: Filtros aplicados (para mostrar no relatório)
        
        Returns:
            BytesIO com conteúdo do PDF
        """
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        elements = []
        styles = getSampleStyleSheet()
        
        # Título
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            textColor=colors.HexColor('#3B82F6'),
            spaceAfter=30,
            alignment=1  # Center
        )
        title = Paragraph("Relatório de Demandas", title_style)
        elements.append(title)
        
        # Data de geração
        date_text = f"Gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M')}"
        elements.append(Paragraph(date_text, styles['Normal']))
        elements.append(Spacer(1, 20))
        
        # Filtros aplicados
        if filtros:
            elements.append(Paragraph("<b>Filtros Aplicados:</b>", styles['Heading2']))
            for key, value in filtros.items():
                elements.append(Paragraph(f"• {key}: {value}", styles['Normal']))
            elements.append(Spacer(1, 20))
        
        # Resumo
        elements.append(Paragraph("<b>Resumo:</b>", styles['Heading2']))
        elements.append(Paragraph(f"Total de demandas: {len(demandas)}", styles['Normal']))
        elements.append(Spacer(1, 20))
        
        # Tabela de demandas
        if demandas:
            elements.append(Paragraph("<b>Lista de Demandas:</b>", styles['Heading2']))
            
            # Dados da tabela
            data = [['Nome', 'Tipo', 'Prioridade', 'Status', 'Prazo']]
            
            for demanda in demandas:
                data.append([
                    demanda.nome[:30],  # Truncar se muito longo
                    demanda.tipo_demanda.nome,
                    demanda.prioridade.nome,
                    demanda.status.value,
                    demanda.prazo_final.strftime('%d/%m/%Y')
                ])
            
            # Criar tabela
            table = Table(data, colWidths=[3*inch, 1.2*inch, 1*inch, 1*inch, 1*inch])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3B82F6')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            
            elements.append(table)
        
        # Gerar PDF
        doc.build(elements)
        buffer.seek(0)
        
        return buffer
    
    def gerar_excel(self, demandas: List[Demanda], filtros: dict) -> BytesIO:
        """
        Gerar relatório Excel
        
        Args:
            demandas: Lista de demandas
            filtros: Filtros aplicados
        
        Returns:
            BytesIO com conteúdo do Excel
        """
        buffer = BytesIO()
        wb = Workbook()
        
        # Aba: Resumo
        ws_resumo = wb.active
        ws_resumo.title = "Resumo"
        
        # Header
        ws_resumo['A1'] = 'Relatório de Demandas'
        ws_resumo['A1'].font = Font(size=16, bold=True)
        ws_resumo['A2'] = f"Gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M')}"
        
        ws_resumo['A4'] = 'Total de Demandas:'
        ws_resumo['B4'] = len(demandas)
        ws_resumo['B4'].font = Font(bold=True)
        
        # Aba: Dados Detalhados
        ws_dados = wb.create_sheet(title="Dados")
        
        # Header
        headers = ['ID', 'Nome', 'Tipo', 'Prioridade', 'Status', 'Prazo', 'Cliente', 'Solicitante']
        ws_dados.append(headers)
        
        # Formatar header
        for cell in ws_dados[1]:
            cell.font = Font(bold=True, color="FFFFFF")
            cell.fill = PatternFill(start_color="3B82F6", end_color="3B82F6", fill_type="solid")
            cell.alignment = Alignment(horizontal="center")
        
        # Dados
        for demanda in demandas:
            ws_dados.append([
                demanda.id,
                demanda.nome,
                demanda.tipo_demanda.nome,
                demanda.prioridade.nome,
                demanda.status.value,
                demanda.prazo_final.strftime('%d/%m/%Y'),
                demanda.cliente.nome,
                demanda.usuario.nome_completo
            ])
        
        # Autofit columns
        for column in ws_dados.columns:
            max_length = 0
            column_letter = column[0].column_letter
            for cell in column:
                try:
                    if len(str(cell.value)) > max_length:
                        max_length = len(cell.value)
                except:
                    pass
            adjusted_width = min(max_length + 2, 50)
            ws_dados.column_dimensions[column_letter].width = adjusted_width
        
        # Salvar
        wb.save(buffer)
        buffer.seek(0)
        
        return buffer
```

---

## 🗄️ MIGRATIONS COM ALEMBIC

### Configurar Alembic

```bash
# Inicializar Alembic (se ainda não fez)
alembic init alembic

# Editar alembic.ini
# Descomentar e editar linha:
# sqlalchemy.url = postgresql://user:pass@localhost/dbname
```

### alembic/env.py (editar)

```python
"""
Configuração do Alembic para migrations
"""
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# Importar Base e config
from app.database.connection import Base
from app.config import settings
import app.models  # Importar todos os modelos

# Alembic Config object
config = context.config

# Sobrescrever sqlalchemy.url com a do .env
config.set_main_option('sqlalchemy.url', settings.DATABASE_URL)

# Interpret the config file for Python logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Metadata dos modelos
target_metadata = Base.metadata

# ... resto do arquivo padrão do Alembic
```

### Criar primeira migration

```bash
# Gerar migration baseado nos modelos
alembic revision --autogenerate -m "Criar tabelas iniciais"

# Aplicar migration
alembic upgrade head
```

### Seeds (dados iniciais)

Criar arquivo `app/database/seeds.py`:

```python
"""
Seeds - Dados iniciais do banco
"""
from sqlalchemy.orm import Session
from app.database.connection import SessionLocal
from app.models import User, TipoUsuario, Prioridade, TipoDemanda
from app.utils.security import hash_password

def create_master_user(db: Session):
    """
    Criar usuário master inicial
    """
    # Verificar se já existe
    existing = db.query(User).filter(User.username == "admin").first()
    if existing:
        print("Usuário master já existe")
        return
    
    # Criar
    master = User(
        username="admin",
        email="admin@debrief.com",
        password_hash=hash_password("Admin@123"),
        nome_completo="Administrador",
        tipo=TipoUsuario.MASTER,
        ativo=True
    )
    db.add(master)
    db.commit()
    print("✓ Usuário master criado (username: admin, senha: Admin@123)")

def create_prioridades(db: Session):
    """
    Criar prioridades padrão
    """
    prioridades = [
        {"nome": "Baixa", "nivel": 1, "cor": "#10B981"},
        {"nome": "Média", "nivel": 2, "cor": "#F59E0B"},
        {"nome": "Alta", "nivel": 3, "cor": "#F97316"},
        {"nome": "Urgente", "nivel": 4, "cor": "#EF4444"},
    ]
    
    for p in prioridades:
        existing = db.query(Prioridade).filter(Prioridade.nome == p["nome"]).first()
        if not existing:
            prioridade = Prioridade(**p)
            db.add(prioridade)
    
    db.commit()
    print("✓ Prioridades criadas")

def create_tipos_demanda(db: Session):
    """
    Criar tipos de demanda padrão
    """
    tipos = [
        {"nome": "Design", "cor": "#3B82F6"},
        {"nome": "Desenvolvimento", "cor": "#8B5CF6"},
        {"nome": "Conteúdo", "cor": "#10B981"},
        {"nome": "Vídeo", "cor": "#F59E0B"},
    ]
    
    for t in tipos:
        existing = db.query(TipoDemanda).filter(TipoDemanda.nome == t["nome"]).first()
        if not existing:
            tipo = TipoDemanda(**t)
            db.add(tipo)
    
    db.commit()
    print("✓ Tipos de demanda criados")

def run_seeds():
    """
    Executar todos os seeds
    """
    print("Executando seeds...")
    db = SessionLocal()
    
    try:
        create_master_user(db)
        create_prioridades(db)
        create_tipos_demanda(db)
        print("\n✓ Seeds executados com sucesso!")
    except Exception as e:
        print(f"Erro ao executar seeds: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    run_seeds()
```

Executar seeds:

```bash
python -m app.database.seeds
```

---

## 🚀 ARQUIVO PRINCIPAL (main.py)

### app/main.py

```python
"""
Arquivo principal do FastAPI
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.config import settings
from app.database.connection import Base, engine

# Importar routers
from app.routes import auth, demandas, usuarios, clientes, secretarias
from app.routes import tipos_demanda, prioridades, configuracoes, relatorios

# Criar tabelas (em produção, usar Alembic)
# Base.metadata.create_all(bind=engine)

# Criar app FastAPI
app = FastAPI(
    title="DeBrief API",
    description="Sistema de Solicitação de Demandas e Envio de Briefings",
    version="1.0.0",
    docs_url="/docs",  # Swagger UI
    redoc_url="/redoc"  # ReDoc
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.FRONTEND_URL],  # URL do frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir arquivos estáticos (uploads)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Registrar routers
app.include_router(auth.router, prefix="/api")
app.include_router(demandas.router, prefix="/api")
app.include_router(usuarios.router, prefix="/api")
app.include_router(clientes.router, prefix="/api")
app.include_router(secretarias.router, prefix="/api")
app.include_router(tipos_demanda.router, prefix="/api")
app.include_router(prioridades.router, prefix="/api")
app.include_router(configuracoes.router, prefix="/api")
app.include_router(relatorios.router, prefix="/api")

# Rota raiz
@app.get("/")
def root():
    return {
        "message": "DeBrief API",
        "version": "1.0.0",
        "docs": "/docs"
    }

# Health check
@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Executar app
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.ENVIRONMENT == "development"
    )
```

---

## ✅ CHECKLIST DE DESENVOLVIMENTO BACKEND

### Fase 1: Setup ✅
- [ ] Criar ambiente virtual
- [ ] Instalar dependências
- [ ] Configurar .env
- [ ] Criar estrutura de pastas
- [ ] Configurar PostgreSQL

### Fase 2: Database ✅
- [ ] Criar todos os modelos SQLAlchemy
- [ ] Configurar Alembic
- [ ] Criar primeira migration
- [ ] Aplicar migration
- [ ] Criar seeds
- [ ] Executar seeds

### Fase 3: Autenticação ✅
- [ ] Implementar utils/security.py
- [ ] Criar schema de Token
- [ ] Criar rota de login
- [ ] Criar dependency get_current_user
- [ ] Testar login com Swagger

### Fase 4: CRUD Básico ✅
- [ ] Implementar rotas de demandas
- [ ] Implementar rotas de usuários
- [ ] Implementar rotas de clientes
- [ ] Testar todos os CRUDs

### Fase 5: Integração Trello ✅
- [ ] Implementar TrelloService
- [ ] Conectar com rota de criar demanda
- [ ] Conectar com rota de atualizar demanda
- [ ] Testar criação de cards

### Fase 6: Integração WhatsApp ✅
- [ ] Setup WPPConnect
- [ ] Implementar WhatsAppService
- [ ] Conectar com rota de criar demanda
- [ ] Testar envio de mensagens

### Fase 7: Upload de Arquivos ✅
- [ ] Implementar UploadService
- [ ] Validações de arquivo
- [ ] Conectar com demandas
- [ ] Anexar no Trello
- [ ] Testar uploads

### Fase 8: Relatórios ✅
- [ ] Implementar RelatorioService
- [ ] Endpoint de filtros
- [ ] Geração de PDF
- [ ] Geração de Excel
- [ ] Testar relatórios

### Fase 9: Polimento ✅
- [ ] Tratamento de erros global
- [ ] Logging
- [ ] Validações adicionais
- [ ] Otimizar queries
- [ ] Documentação da API

---

## 🎓 COMANDOS ÚTEIS

```bash
# Ativar ambiente virtual
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt

# Rodar servidor (desenvolvimento)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Criar migration
alembic revision --autogenerate -m "Descrição"

# Aplicar migrations
alembic upgrade head

# Rollback migration
alembic downgrade -1

# Executar seeds
python -m app.database.seeds

# Testar API
# Acessar: http://localhost:8000/docs
```

---

## 🚀 PRÓXIMOS PASSOS

Após completar o backend:

1. **Testar localmente:** Usar Swagger UI (/docs)
2. **Integrar com frontend:** Testar fluxo completo
3. **Deploy:** Configurar servidor de produção
4. **Monitoramento:** Setup de logs e alertas

---

**Bom desenvolvimento! 🐍🚀**
