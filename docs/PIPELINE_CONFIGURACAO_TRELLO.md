# 🎯 PIPELINE DE CONFIGURAÇÃO - MÓDULO TRELLO

## 📋 VISÃO GERAL

Sistema de integração completa com Trello para criação automática de cards de demandas, com suporte a:
- ✅ Configuração de Board e Lista únicos
- ✅ Etiquetas personalizadas por cliente
- ✅ Título do card = Nome do Cliente
- ✅ Gerenciamento via interface Master

---

## 📊 FASES DE IMPLEMENTAÇÃO

### **FASE 1: BANCO DE DADOS** 🗄️
Criação de estrutura para armazenar configurações do Trello

#### 1.1. Nova Tabela: `configuracoes_trello`
```sql
CREATE TABLE configuracoes_trello (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Credenciais Trello
    api_key VARCHAR(100) NOT NULL,
    token VARCHAR(255) NOT NULL,
    
    -- Board e Lista
    board_id VARCHAR(100) NOT NULL,
    board_nome VARCHAR(200),
    lista_id VARCHAR(100) NOT NULL,
    lista_nome VARCHAR(200),
    
    -- Status
    ativo BOOLEAN DEFAULT TRUE,
    
    -- Metadados
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    -- Constraint: apenas uma configuração ativa
    CONSTRAINT unique_ativo CHECK (
        ativo = FALSE OR 
        NOT EXISTS (
            SELECT 1 FROM configuracoes_trello ct2 
            WHERE ct2.ativo = TRUE 
            AND ct2.id != configuracoes_trello.id
            AND ct2.deleted_at IS NULL
        )
    )
);

CREATE INDEX idx_config_trello_ativo ON configuracoes_trello(ativo);
```

#### 1.2. Nova Tabela: `etiquetas_trello_cliente`
```sql
CREATE TABLE etiquetas_trello_cliente (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relacionamentos
    cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    
    -- Etiqueta Trello
    etiqueta_trello_id VARCHAR(100) NOT NULL,  -- ID da label no Trello
    etiqueta_nome VARCHAR(100) NOT NULL,        -- Nome da etiqueta
    etiqueta_cor VARCHAR(20) NOT NULL,          -- Cor da etiqueta (ex: "green", "red")
    
    -- Status
    ativo BOOLEAN DEFAULT TRUE,
    
    -- Metadados
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    -- Constraints
    UNIQUE(cliente_id, deleted_at),  -- Um cliente = uma etiqueta ativa
    
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
);

CREATE INDEX idx_etiqueta_cliente ON etiquetas_trello_cliente(cliente_id);
CREATE INDEX idx_etiqueta_ativo ON etiquetas_trello_cliente(ativo);
```

#### 1.3. Atualizar Tabela: `clientes`
```sql
-- Adicionar campo para ID do membro Trello (já existe)
-- Apenas garantir que está presente

-- Campo já existente:
-- trello_member_id VARCHAR(100) NULL
```

#### 1.4. Migration Alembic
```python
# backend/alembic/versions/005_create_configuracao_trello.py

"""create configuracao trello tables

Revision ID: 005_config_trello
Revises: 004_notification_logs
Create Date: 2025-11-23
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '005_config_trello'
down_revision = '004_notification_logs'
branch_labels = None
depends_on = None

def upgrade():
    # Tabela configuracoes_trello
    op.create_table(
        'configuracoes_trello',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('api_key', sa.String(100), nullable=False),
        sa.Column('token', sa.String(255), nullable=False),
        sa.Column('board_id', sa.String(100), nullable=False),
        sa.Column('board_nome', sa.String(200), nullable=True),
        sa.Column('lista_id', sa.String(100), nullable=False),
        sa.Column('lista_nome', sa.String(200), nullable=True),
        sa.Column('ativo', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.func.now(), onupdate=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
    )
    
    op.create_index('idx_config_trello_ativo', 'configuracoes_trello', ['ativo'])
    
    # Tabela etiquetas_trello_cliente
    op.create_table(
        'etiquetas_trello_cliente',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('cliente_id', UUID(as_uuid=True), nullable=False),
        sa.Column('etiqueta_trello_id', sa.String(100), nullable=False),
        sa.Column('etiqueta_nome', sa.String(100), nullable=False),
        sa.Column('etiqueta_cor', sa.String(20), nullable=False),
        sa.Column('ativo', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.func.now(), onupdate=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        sa.ForeignKeyConstraint(['cliente_id'], ['clientes.id'], ondelete='CASCADE'),
    )
    
    op.create_index('idx_etiqueta_cliente', 'etiquetas_trello_cliente', ['cliente_id'])
    op.create_index('idx_etiqueta_ativo', 'etiquetas_trello_cliente', ['ativo'])

def downgrade():
    op.drop_table('etiquetas_trello_cliente')
    op.drop_table('configuracoes_trello')
```

---

### **FASE 2: BACKEND (SQLAlchemy Models)** 🐍

#### 2.1. Model: `ConfiguracaoTrello`
```python
# backend/app/models/configuracao_trello.py

from sqlalchemy import Column, String, Boolean
from app.models.base import BaseModel

class ConfiguracaoTrello(BaseModel):
    """
    Configurações de integração com Trello
    
    Armazena credenciais e configuração do board/lista
    onde as demandas serão criadas.
    """
    
    __tablename__ = "configuracoes_trello"
    
    # Credenciais
    api_key = Column(String(100), nullable=False)
    token = Column(String(255), nullable=False)
    
    # Board e Lista
    board_id = Column(String(100), nullable=False)
    board_nome = Column(String(200), nullable=True)
    lista_id = Column(String(100), nullable=False)
    lista_nome = Column(String(200), nullable=True)
    
    # Status
    ativo = Column(Boolean, default=True, nullable=False)
    
    @classmethod
    def get_ativa(cls, db):
        """Retorna a configuração ativa"""
        return db.query(cls).filter(
            cls.ativo == True,
            cls.deleted_at == None
        ).first()
    
    @classmethod
    def desativar_todas(cls, db):
        """Desativa todas as configurações"""
        db.query(cls).filter(
            cls.deleted_at == None
        ).update({"ativo": False})
        db.commit()
```

#### 2.2. Model: `EtiquetaTrelloCliente`
```python
# backend/app/models/etiqueta_trello_cliente.py

from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class EtiquetaTrelloCliente(BaseModel):
    """
    Etiquetas do Trello vinculadas a clientes
    
    Cada cliente pode ter uma etiqueta no Trello que
    será aplicada automaticamente aos cards de suas demandas.
    """
    
    __tablename__ = "etiquetas_trello_cliente"
    
    # Relacionamento com cliente
    cliente_id = Column(UUID(as_uuid=True), ForeignKey('clientes.id', ondelete='CASCADE'), nullable=False)
    cliente = relationship("Cliente", back_populates="etiqueta_trello")
    
    # Dados da etiqueta Trello
    etiqueta_trello_id = Column(String(100), nullable=False)
    etiqueta_nome = Column(String(100), nullable=False)
    etiqueta_cor = Column(String(20), nullable=False)
    
    # Status
    ativo = Column(Boolean, default=True, nullable=False)
    
    @classmethod
    def get_by_cliente(cls, db, cliente_id):
        """Retorna etiqueta ativa de um cliente"""
        return db.query(cls).filter(
            cls.cliente_id == cliente_id,
            cls.ativo == True,
            cls.deleted_at == None
        ).first()
```

#### 2.3. Atualizar Model: `Cliente`
```python
# backend/app/models/cliente.py

# Adicionar relacionamento
from sqlalchemy.orm import relationship

class Cliente(BaseModel):
    # ... campos existentes ...
    
    # NOVO RELACIONAMENTO
    etiqueta_trello = relationship(
        "EtiquetaTrelloCliente",
        back_populates="cliente",
        uselist=False,  # Um cliente = uma etiqueta
        cascade="all, delete-orphan"
    )
```

---

### **FASE 3: BACKEND (Schemas Pydantic)** 📦

#### 3.1. Schema: `ConfiguracaoTrelloSchema`
```python
# backend/app/schemas/configuracao_trello.py

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid

# CREATE
class ConfiguracaoTrelloCreate(BaseModel):
    api_key: str = Field(..., description="API Key do Trello")
    token: str = Field(..., description="Token de autenticação")
    board_id: str = Field(..., description="ID do Board")
    board_nome: Optional[str] = Field(None, description="Nome do Board")
    lista_id: str = Field(..., description="ID da Lista")
    lista_nome: Optional[str] = Field(None, description="Nome da Lista")

# UPDATE
class ConfiguracaoTrelloUpdate(BaseModel):
    api_key: Optional[str] = None
    token: Optional[str] = None
    board_id: Optional[str] = None
    board_nome: Optional[str] = None
    lista_id: Optional[str] = None
    lista_nome: Optional[str] = None
    ativo: Optional[bool] = None

# RESPONSE
class ConfiguracaoTrelloResponse(BaseModel):
    id: uuid.UUID
    api_key: str  # Mascarado no endpoint
    token: str    # Mascarado no endpoint
    board_id: str
    board_nome: Optional[str]
    lista_id: str
    lista_nome: Optional[str]
    ativo: bool
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# TESTAR CONEXÃO
class ConfiguracaoTrelloTest(BaseModel):
    api_key: str
    token: str
    board_id: Optional[str] = None
```

#### 3.2. Schema: `EtiquetaTrelloClienteSchema`
```python
# backend/app/schemas/etiqueta_trello_cliente.py

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid

# CREATE
class EtiquetaTrelloClienteCreate(BaseModel):
    cliente_id: uuid.UUID
    etiqueta_trello_id: str = Field(..., description="ID da etiqueta no Trello")
    etiqueta_nome: str = Field(..., description="Nome da etiqueta")
    etiqueta_cor: str = Field(..., description="Cor da etiqueta (ex: green, red)")

# UPDATE
class EtiquetaTrelloClienteUpdate(BaseModel):
    etiqueta_trello_id: Optional[str] = None
    etiqueta_nome: Optional[str] = None
    etiqueta_cor: Optional[str] = None
    ativo: Optional[bool] = None

# RESPONSE
class EtiquetaTrelloClienteResponse(BaseModel):
    id: uuid.UUID
    cliente_id: uuid.UUID
    cliente_nome: str  # Incluir nome do cliente
    etiqueta_trello_id: str
    etiqueta_nome: str
    etiqueta_cor: str
    ativo: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# LISTAR ETIQUETAS DISPONÍVEIS NO TRELLO
class EtiquetaTrelloDisponivel(BaseModel):
    id: str
    nome: str
    cor: str
```

---

### **FASE 4: BACKEND (Endpoints API)** 🚀

#### 4.1. Endpoints: Configuração Trello
```python
# backend/app/api/endpoints/trello_config.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.core.dependencies import get_db, require_master
from app.models import User, ConfiguracaoTrello
from app.schemas.configuracao_trello import *
from trello import TrelloClient

router = APIRouter(prefix="/api/trello-config", tags=["Configuração Trello"])

# 1. CRIAR/ATUALIZAR CONFIGURAÇÃO
@router.post("/", response_model=ConfiguracaoTrelloResponse)
def salvar_configuracao_trello(
    config: ConfiguracaoTrelloCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Salva configuração do Trello
    Desativa configurações anteriores automaticamente
    """
    # Desativar todas
    ConfiguracaoTrello.desativar_todas(db)
    
    # Criar nova
    nova_config = ConfiguracaoTrello(**config.model_dump())
    db.add(nova_config)
    db.commit()
    db.refresh(nova_config)
    
    return nova_config

# 2. BUSCAR CONFIGURAÇÃO ATIVA
@router.get("/ativa", response_model=ConfiguracaoTrelloResponse)
def get_configuracao_ativa(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Retorna a configuração ativa do Trello"""
    config = ConfiguracaoTrello.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhuma configuração Trello ativa"
        )
    
    # Mascarar dados sensíveis
    config.api_key = config.api_key[:4] + "..." + config.api_key[-4:]
    config.token = config.token[:8] + "..."
    
    return config

# 3. TESTAR CONEXÃO
@router.post("/testar")
def testar_conexao_trello(
    credentials: ConfiguracaoTrelloTest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Testa conexão com Trello
    Retorna boards disponíveis se board_id não for fornecido
    """
    try:
        client = TrelloClient(
            api_key=credentials.api_key,
            api_secret=credentials.token
        )
        
        if credentials.board_id:
            # Testar acesso ao board específico
            board = client.get_board(credentials.board_id)
            listas = board.list_lists()
            
            return {
                "sucesso": True,
                "mensagem": "Conexão estabelecida com sucesso!",
                "board": {
                    "id": board.id,
                    "nome": board.name,
                    "listas": [
                        {"id": l.id, "nome": l.name} 
                        for l in listas
                    ]
                }
            }
        else:
            # Listar boards disponíveis
            boards = client.list_boards()
            
            return {
                "sucesso": True,
                "mensagem": "Conexão estabelecida! Selecione um board:",
                "boards": [
                    {"id": b.id, "nome": b.name}
                    for b in boards
                ]
            }
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erro ao conectar: {str(e)}"
        )

# 4. LISTAR LISTAS DE UM BOARD
@router.get("/boards/{board_id}/listas")
def listar_listas_board(
    board_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Lista todas as listas de um board"""
    config = ConfiguracaoTrello.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configure o Trello primeiro"
        )
    
    try:
        client = TrelloClient(
            api_key=config.api_key,
            api_secret=config.token
        )
        
        board = client.get_board(board_id)
        listas = board.list_lists()
        
        return {
            "board_nome": board.name,
            "listas": [
                {"id": l.id, "nome": l.name}
                for l in listas
            ]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erro ao buscar listas: {str(e)}"
        )

# 5. LISTAR ETIQUETAS DE UM BOARD
@router.get("/boards/{board_id}/etiquetas")
def listar_etiquetas_board(
    board_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Lista todas as etiquetas disponíveis em um board"""
    config = ConfiguracaoTrello.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configure o Trello primeiro"
        )
    
    try:
        client = TrelloClient(
            api_key=config.api_key,
            api_secret=config.token
        )
        
        board = client.get_board(board_id)
        labels = board.get_labels()
        
        return {
            "board_nome": board.name,
            "etiquetas": [
                {
                    "id": label.id,
                    "nome": label.name if label.name else f"Etiqueta {label.color}",
                    "cor": label.color
                }
                for label in labels
            ]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erro ao buscar etiquetas: {str(e)}"
        )

# 6. DELETAR CONFIGURAÇÃO
@router.delete("/{config_id}")
def deletar_configuracao(
    config_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Deleta (soft delete) uma configuração"""
    config = db.query(ConfiguracaoTrello).filter(
        ConfiguracaoTrello.id == config_id
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    config.delete()  # Soft delete (BaseModel)
    db.commit()
    
    return {"mensagem": "Configuração deletada com sucesso"}
```

#### 4.2. Endpoints: Etiquetas Trello por Cliente
```python
# backend/app/api/endpoints/trello_etiquetas.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.core.dependencies import get_db, require_master
from app.models import User, EtiquetaTrelloCliente, Cliente
from app.schemas.etiqueta_trello_cliente import *

router = APIRouter(prefix="/api/trello-etiquetas", tags=["Etiquetas Trello"])

# 1. VINCULAR ETIQUETA A CLIENTE
@router.post("/", response_model=EtiquetaTrelloClienteResponse)
def vincular_etiqueta_cliente(
    etiqueta: EtiquetaTrelloClienteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Vincula uma etiqueta do Trello a um cliente
    Se já existir, atualiza
    """
    # Verificar se cliente existe
    cliente = db.query(Cliente).filter(Cliente.id == etiqueta.cliente_id).first()
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cliente não encontrado"
        )
    
    # Verificar se já existe etiqueta para este cliente
    etiqueta_existente = EtiquetaTrelloCliente.get_by_cliente(db, etiqueta.cliente_id)
    
    if etiqueta_existente:
        # Atualizar
        for key, value in etiqueta.model_dump().items():
            if key != 'cliente_id':
                setattr(etiqueta_existente, key, value)
        db.commit()
        db.refresh(etiqueta_existente)
        
        # Adicionar nome do cliente
        etiqueta_existente.cliente_nome = cliente.nome
        return etiqueta_existente
    else:
        # Criar nova
        nova_etiqueta = EtiquetaTrelloCliente(**etiqueta.model_dump())
        db.add(nova_etiqueta)
        db.commit()
        db.refresh(nova_etiqueta)
        
        # Adicionar nome do cliente
        nova_etiqueta.cliente_nome = cliente.nome
        return nova_etiqueta

# 2. LISTAR TODAS AS ETIQUETAS
@router.get("/", response_model=List[EtiquetaTrelloClienteResponse])
def listar_etiquetas_clientes(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Lista todas as etiquetas vinculadas a clientes"""
    etiquetas = db.query(EtiquetaTrelloCliente).filter(
        EtiquetaTrelloCliente.deleted_at == None
    ).all()
    
    # Adicionar nome do cliente
    for etiqueta in etiquetas:
        db.refresh(etiqueta)
        etiqueta.cliente_nome = etiqueta.cliente.nome
    
    return etiquetas

# 3. BUSCAR ETIQUETA DE UM CLIENTE
@router.get("/cliente/{cliente_id}", response_model=EtiquetaTrelloClienteResponse)
def get_etiqueta_cliente(
    cliente_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Retorna a etiqueta de um cliente específico"""
    etiqueta = EtiquetaTrelloCliente.get_by_cliente(db, cliente_id)
    
    if not etiqueta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etiqueta não configurada para este cliente"
        )
    
    db.refresh(etiqueta)
    etiqueta.cliente_nome = etiqueta.cliente.nome
    
    return etiqueta

# 4. DELETAR ETIQUETA
@router.delete("/{etiqueta_id}")
def deletar_etiqueta(
    etiqueta_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Deleta (soft delete) uma etiqueta"""
    etiqueta = db.query(EtiquetaTrelloCliente).filter(
        EtiquetaTrelloCliente.id == etiqueta_id
    ).first()
    
    if not etiqueta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etiqueta não encontrada"
        )
    
    etiqueta.delete()  # Soft delete
    db.commit()
    
    return {"mensagem": "Etiqueta removida com sucesso"}
```

---

### **FASE 5: BACKEND (Atualizar TrelloService)** 🔧

#### 5.1. Atualizar Serviço Trello
```python
# backend/app/services/trello.py

from trello import TrelloClient
from sqlalchemy.orm import Session
from app.models import Demanda, ConfiguracaoTrello, EtiquetaTrelloCliente
import logging

logger = logging.getLogger(__name__)

class TrelloService:
    """Serviço de integração com Trello"""
    
    def __init__(self, db: Session):
        """
        Inicializa com configuração do banco
        Não mais do .env, mas sim de configuracoes_trello
        """
        self.db = db
        config = ConfiguracaoTrello.get_ativa(db)
        
        if not config:
            raise Exception("Trello não configurado. Configure em Configurações Master.")
        
        self.client = TrelloClient(
            api_key=config.api_key,
            api_secret=config.token
        )
        
        self.board = self.client.get_board(config.board_id)
        self.list = self.board.get_list(config.lista_id)
        
        logger.info(f"TrelloService inicializado - Board: {config.board_nome}")
    
    async def criar_card(self, demanda: Demanda) -> dict:
        """
        Cria card no Trello
        
        NOVA LÓGICA:
        - Título = Nome do Cliente (não mais "Demanda - Cliente")
        - Etiqueta do cliente aplicada automaticamente
        """
        try:
            # Carregar relacionamentos
            self.db.refresh(demanda)
            
            # ========== TÍTULO DO CARD ==========
            # APENAS o nome do cliente
            card_name = demanda.cliente.nome
            
            # ========== DESCRIÇÃO DO CARD ==========
            card_desc = f"""
**Demanda:** {demanda.nome}
**Secretaria:** {demanda.secretaria.nome}
**Tipo:** {demanda.tipo_demanda.nome}
**Prioridade:** {demanda.prioridade.nome}
**Prazo:** {demanda.prazo_final.strftime('%d/%m/%Y')}

**Descrição:**
{demanda.descricao}

**Solicitante:** {demanda.usuario.nome_completo}
**Email:** {demanda.usuario.email}

---
**ID da Demanda:** {demanda.id}
**Status:** {demanda.status.value}
            """.strip()
            
            logger.info(f"Criando card no Trello para demanda {demanda.id}")
            
            # Criar card
            card = self.list.add_card(
                name=card_name,
                desc=card_desc,
                position='top'
            )
            
            # ========== APLICAR ETIQUETA DO CLIENTE ==========
            etiqueta_cliente = EtiquetaTrelloCliente.get_by_cliente(
                self.db, 
                demanda.cliente_id
            )
            
            if etiqueta_cliente and etiqueta_cliente.ativo:
                try:
                    # Buscar label no board
                    for label in self.board.get_labels():
                        if label.id == etiqueta_cliente.etiqueta_trello_id:
                            card.add_label(label)
                            logger.info(
                                f"Etiqueta '{etiqueta_cliente.etiqueta_nome}' "
                                f"aplicada ao card"
                            )
                            break
                except Exception as e:
                    logger.warning(f"Erro ao aplicar etiqueta: {e}")
            else:
                logger.warning(
                    f"Cliente {demanda.cliente.nome} sem etiqueta configurada"
                )
            
            # ========== LABEL DE PRIORIDADE (OPCIONAL) ==========
            try:
                prioridade_nome = demanda.prioridade.nome
                for label in self.board.get_labels():
                    if label.name and label.name.lower() == prioridade_nome.lower():
                        card.add_label(label)
                        logger.info(f"Label '{prioridade_nome}' adicionado")
                        break
            except Exception as e:
                logger.warning(f"Erro ao adicionar label de prioridade: {e}")
            
            # ========== MEMBER (CLIENTE - OPCIONAL) ==========
            if demanda.cliente.trello_member_id:
                try:
                    card.add_member(demanda.cliente.trello_member_id)
                    logger.info(
                        f"Membro {demanda.cliente.trello_member_id} atribuído"
                    )
                except Exception as e:
                    logger.warning(f"Erro ao adicionar membro: {e}")
            
            # ========== RETORNAR INFO DO CARD ==========
            return {
                'id': card.id,
                'url': card.url,
                'nome': card.name
            }
            
        except Exception as e:
            logger.error(f"Erro ao criar card no Trello: {e}")
            raise
```

---

### **FASE 6: FRONTEND (Páginas)** 🎨

#### 6.1. Página: Configuração Trello Master
```jsx
// frontend/src/pages/admin/ConfiguracaoTrello.jsx

import React, { useState, useEffect } from 'react';
import axios from 'axios';
import {
  Box, Card, CardContent, Typography, TextField, Button,
  Alert, Select, MenuItem, FormControl, InputLabel,
  CircularProgress, Divider, Grid
} from '@mui/material';
import { CheckCircle, Error, Settings } from '@mui/icons-material';

export default function ConfiguracaoTrello() {
  const [config, setConfig] = useState({
    api_key: '',
    token: '',
    board_id: '',
    board_nome: '',
    lista_id: '',
    lista_nome: ''
  });
  
  const [boards, setBoards] = useState([]);
  const [listas, setListas] = useState([]);
  const [testando, setTestando] = useState(false);
  const [salvando, setSalvando] = useState(false);
  const [mensagem, setMensagem] = useState(null);
  const [configAtiva, setConfigAtiva] = useState(null);
  
  // Carregar configuração ativa
  useEffect(() => {
    buscarConfigAtiva();
  }, []);
  
  const buscarConfigAtiva = async () => {
    try {
      const response = await axios.get('/api/trello-config/ativa');
      setConfigAtiva(response.data);
    } catch (error) {
      console.log('Nenhuma configuração ativa');
    }
  };
  
  const testarConexao = async () => {
    setTestando(true);
    setMensagem(null);
    
    try {
      const response = await axios.post('/api/trello-config/testar', {
        api_key: config.api_key,
        token: config.token,
        board_id: config.board_id || null
      });
      
      if (response.data.boards) {
        // Listar boards
        setBoards(response.data.boards);
        setMensagem({
          tipo: 'success',
          texto: 'Conexão OK! Selecione um board abaixo.'
        });
      } else if (response.data.board) {
        // Listar listas do board
        setListas(response.data.board.listas);
        setConfig({
          ...config,
          board_nome: response.data.board.nome
        });
        setMensagem({
          tipo: 'success',
          texto: 'Board encontrado! Selecione uma lista.'
        });
      }
    } catch (error) {
      setMensagem({
        tipo: 'error',
        texto: error.response?.data?.detail || 'Erro ao testar conexão'
      });
    } finally {
      setTestando(false);
    }
  };
  
  const buscarListas = async (boardId) => {
    try {
      const response = await axios.get(`/api/trello-config/boards/${boardId}/listas`);
      setListas(response.data.listas);
      setConfig({
        ...config,
        board_id: boardId,
        board_nome: response.data.board_nome
      });
    } catch (error) {
      setMensagem({
        tipo: 'error',
        texto: 'Erro ao buscar listas do board'
      });
    }
  };
  
  const salvarConfiguracao = async () => {
    setSalvando(true);
    setMensagem(null);
    
    try {
      await axios.post('/api/trello-config/', config);
      setMensagem({
        tipo: 'success',
        texto: 'Configuração salva com sucesso!'
      });
      buscarConfigAtiva();
    } catch (error) {
      setMensagem({
        tipo: 'error',
        texto: error.response?.data?.detail || 'Erro ao salvar configuração'
      });
    } finally {
      setSalvando(false);
    }
  };
  
  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        <Settings sx={{ mr: 1, verticalAlign: 'middle' }} />
        Configuração do Trello
      </Typography>
      
      {/* CONFIGURAÇÃO ATIVA */}
      {configAtiva && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <strong>Configuração Ativa:</strong><br />
          Board: {configAtiva.board_nome}<br />
          Lista: {configAtiva.lista_nome}
        </Alert>
      )}
      
      {mensagem && (
        <Alert severity={mensagem.tipo} sx={{ mb: 3 }}>
          {mensagem.texto}
        </Alert>
      )}
      
      <Card>
        <CardContent>
          {/* CREDENCIAIS */}
          <Typography variant="h6" gutterBottom>
            1. Credenciais do Trello
          </Typography>
          
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="API Key"
                value={config.api_key}
                onChange={(e) => setConfig({ ...config, api_key: e.target.value })}
                helperText="Obtenha em: https://trello.com/app-key"
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Token"
                value={config.token}
                onChange={(e) => setConfig({ ...config, token: e.target.value })}
                type="password"
                helperText="Clique em 'Token' na página da API Key"
              />
            </Grid>
          </Grid>
          
          <Button
            variant="outlined"
            onClick={testarConexao}
            disabled={!config.api_key || !config.token || testando}
            startIcon={testando ? <CircularProgress size={20} /> : null}
          >
            {testando ? 'Testando...' : 'Testar Conexão'}
          </Button>
          
          <Divider sx={{ my: 3 }} />
          
          {/* BOARD */}
          {boards.length > 0 && (
            <>
              <Typography variant="h6" gutterBottom>
                2. Selecionar Board
              </Typography>
              
              <FormControl fullWidth sx={{ mb: 3 }}>
                <InputLabel>Board do Trello</InputLabel>
                <Select
                  value={config.board_id}
                  onChange={(e) => buscarListas(e.target.value)}
                >
                  {boards.map((board) => (
                    <MenuItem key={board.id} value={board.id}>
                      {board.nome}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              
              <Divider sx={{ my: 3 }} />
            </>
          )}
          
          {/* LISTA */}
          {listas.length > 0 && (
            <>
              <Typography variant="h6" gutterBottom>
                3. Selecionar Lista
              </Typography>
              
              <FormControl fullWidth sx={{ mb: 3 }}>
                <InputLabel>Lista de Demandas</InputLabel>
                <Select
                  value={config.lista_id}
                  onChange={(e) => {
                    const lista = listas.find(l => l.id === e.target.value);
                    setConfig({
                      ...config,
                      lista_id: e.target.value,
                      lista_nome: lista?.nome
                    });
                  }}
                >
                  {listas.map((lista) => (
                    <MenuItem key={lista.id} value={lista.id}>
                      {lista.nome}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              
              <Button
                variant="contained"
                color="primary"
                onClick={salvarConfiguracao}
                disabled={!config.lista_id || salvando}
                startIcon={salvando ? <CircularProgress size={20} /> : <CheckCircle />}
              >
                {salvando ? 'Salvando...' : 'Salvar Configuração'}
              </Button>
            </>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}
```

#### 6.2. Página: Gerenciar Etiquetas por Cliente
```jsx
// frontend/src/pages/admin/EtiquetasTrelloClientes.jsx

import React, { useState, useEffect } from 'react';
import axios from 'axios';
import {
  Box, Card, CardContent, Typography, Button, Table,
  TableBody, TableCell, TableContainer, TableHead, TableRow,
  Dialog, DialogTitle, DialogContent, DialogActions,
  TextField, Select, MenuItem, FormControl, InputLabel,
  Chip, IconButton, Alert
} from '@mui/material';
import { Add, Edit, Delete, Label } from '@mui/icons-material';

export default function EtiquetasTrelloClientes() {
  const [etiquetas, setEtiquetas] = useState([]);
  const [clientes, setClientes] = useState([]);
  const [etiquetasDisponiveis, setEtiquetasDisponiveis] = useState([]);
  const [modalAberto, setModalAberto] = useState(false);
  const [etiquetaAtual, setEtiquetaAtual] = useState({
    cliente_id: '',
    etiqueta_trello_id: '',
    etiqueta_nome: '',
    etiqueta_cor: ''
  });
  const [mensagem, setMensagem] = useState(null);
  
  useEffect(() => {
    buscarEtiquetas();
    buscarClientes();
    buscarEtiquetasDisponiveis();
  }, []);
  
  const buscarEtiquetas = async () => {
    try {
      const response = await axios.get('/api/trello-etiquetas/');
      setEtiquetas(response.data);
    } catch (error) {
      console.error('Erro ao buscar etiquetas:', error);
    }
  };
  
  const buscarClientes = async () => {
    try {
      const response = await axios.get('/api/clientes/');
      setClientes(response.data);
    } catch (error) {
      console.error('Erro ao buscar clientes:', error);
    }
  };
  
  const buscarEtiquetasDisponiveis = async () => {
    try {
      const configResponse = await axios.get('/api/trello-config/ativa');
      const boardId = configResponse.data.board_id;
      
      const etiquetasResponse = await axios.get(
        `/api/trello-config/boards/${boardId}/etiquetas`
      );
      
      setEtiquetasDisponiveis(etiquetasResponse.data.etiquetas);
    } catch (error) {
      console.error('Erro ao buscar etiquetas disponíveis:', error);
    }
  };
  
  const salvarEtiqueta = async () => {
    try {
      await axios.post('/api/trello-etiquetas/', etiquetaAtual);
      setMensagem({
        tipo: 'success',
        texto: 'Etiqueta vinculada com sucesso!'
      });
      buscarEtiquetas();
      fecharModal();
    } catch (error) {
      setMensagem({
        tipo: 'error',
        texto: error.response?.data?.detail || 'Erro ao vincular etiqueta'
      });
    }
  };
  
  const deletarEtiqueta = async (id) => {
    if (window.confirm('Deseja realmente remover esta etiqueta?')) {
      try {
        await axios.delete(`/api/trello-etiquetas/${id}`);
        setMensagem({
          tipo: 'success',
          texto: 'Etiqueta removida com sucesso!'
        });
        buscarEtiquetas();
      } catch (error) {
        setMensagem({
          tipo: 'error',
          texto: 'Erro ao remover etiqueta'
        });
      }
    }
  };
  
  const abrirModal = (etiqueta = null) => {
    if (etiqueta) {
      setEtiquetaAtual(etiqueta);
    } else {
      setEtiquetaAtual({
        cliente_id: '',
        etiqueta_trello_id: '',
        etiqueta_nome: '',
        etiqueta_cor: ''
      });
    }
    setModalAberto(true);
  };
  
  const fecharModal = () => {
    setModalAberto(false);
    setEtiquetaAtual({
      cliente_id: '',
      etiqueta_trello_id: '',
      etiqueta_nome: '',
      etiqueta_cor: ''
    });
  };
  
  const selecionarEtiqueta = (etiquetaId) => {
    const etiqueta = etiquetasDisponiveis.find(e => e.id === etiquetaId);
    if (etiqueta) {
      setEtiquetaAtual({
        ...etiquetaAtual,
        etiqueta_trello_id: etiqueta.id,
        etiqueta_nome: etiqueta.nome,
        etiqueta_cor: etiqueta.cor
      });
    }
  };
  
  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">
          <Label sx={{ mr: 1, verticalAlign: 'middle' }} />
          Etiquetas Trello por Cliente
        </Typography>
        
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => abrirModal()}
        >
          Nova Etiqueta
        </Button>
      </Box>
      
      {mensagem && (
        <Alert severity={mensagem.tipo} sx={{ mb: 3 }}>
          {mensagem.texto}
        </Alert>
      )}
      
      <Card>
        <CardContent>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell><strong>Cliente</strong></TableCell>
                  <TableCell><strong>Etiqueta Trello</strong></TableCell>
                  <TableCell><strong>Cor</strong></TableCell>
                  <TableCell align="right"><strong>Ações</strong></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {etiquetas.map((etiqueta) => (
                  <TableRow key={etiqueta.id}>
                    <TableCell>{etiqueta.cliente_nome}</TableCell>
                    <TableCell>
                      <Chip
                        label={etiqueta.etiqueta_nome}
                        sx={{
                          backgroundColor: `#${etiqueta.etiqueta_cor}`,
                          color: '#fff'
                        }}
                      />
                    </TableCell>
                    <TableCell>{etiqueta.etiqueta_cor}</TableCell>
                    <TableCell align="right">
                      <IconButton
                        color="primary"
                        onClick={() => abrirModal(etiqueta)}
                      >
                        <Edit />
                      </IconButton>
                      <IconButton
                        color="error"
                        onClick={() => deletarEtiqueta(etiqueta.id)}
                      >
                        <Delete />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
                
                {etiquetas.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={4} align="center">
                      Nenhuma etiqueta configurada
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
      
      {/* MODAL */}
      <Dialog open={modalAberto} onClose={fecharModal} maxWidth="sm" fullWidth>
        <DialogTitle>Vincular Etiqueta a Cliente</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Cliente</InputLabel>
              <Select
                value={etiquetaAtual.cliente_id}
                onChange={(e) =>
                  setEtiquetaAtual({ ...etiquetaAtual, cliente_id: e.target.value })
                }
              >
                {clientes.map((cliente) => (
                  <MenuItem key={cliente.id} value={cliente.id}>
                    {cliente.nome}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <FormControl fullWidth>
              <InputLabel>Etiqueta do Trello</InputLabel>
              <Select
                value={etiquetaAtual.etiqueta_trello_id}
                onChange={(e) => selecionarEtiqueta(e.target.value)}
              >
                {etiquetasDisponiveis.map((etiqueta) => (
                  <MenuItem key={etiqueta.id} value={etiqueta.id}>
                    <Chip
                      label={etiqueta.nome}
                      sx={{
                        backgroundColor: `#${etiqueta.cor}`,
                        color: '#fff',
                        mr: 1
                      }}
                      size="small"
                    />
                    {etiqueta.nome}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={fecharModal}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={salvarEtiqueta}
            disabled={!etiquetaAtual.cliente_id || !etiquetaAtual.etiqueta_trello_id}
          >
            Salvar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
```

---

### **FASE 7: INTEGRAÇÃO FINAL** 🔗

#### 7.1. Registrar Rotas no Backend
```python
# backend/app/main.py

from app.api.endpoints import trello_config, trello_etiquetas

# Adicionar routers
app.include_router(trello_config.router)
app.include_router(trello_etiquetas.router)
```

#### 7.2. Adicionar Rotas no Frontend
```jsx
// frontend/src/App.jsx

import ConfiguracaoTrello from './pages/admin/ConfiguracaoTrello';
import EtiquetasTrelloClientes from './pages/admin/EtiquetasTrelloClientes';

// Adicionar rotas
<Route path="/admin/trello-config" element={<ConfiguracaoTrello />} />
<Route path="/admin/trello-etiquetas" element={<EtiquetasTrelloClientes />} />
```

#### 7.3. Adicionar Link no Menu
```jsx
// frontend/src/components/Sidebar.jsx

// Seção Master
{
  titulo: 'Configurações Trello',
  icon: <IntegrationInstructions />,
  items: [
    { nome: 'Configuração Geral', path: '/admin/trello-config' },
    { nome: 'Etiquetas por Cliente', path: '/admin/trello-etiquetas' }
  ]
}
```

---

## 🎯 RESUMO DO FLUXO

### 1️⃣ **Usuário Master Acessa Configurações**
- Menu: Configurações Master → Trello → Configuração Geral

### 2️⃣ **Configura Credenciais**
- Insere API Key e Token
- Testa conexão
- Seleciona Board
- Seleciona Lista

### 3️⃣ **Vincula Etiquetas aos Clientes**
- Menu: Configurações Master → Trello → Etiquetas por Cliente
- Para cada cliente:
  - Seleciona etiqueta do Trello
  - Salva vinculação

### 4️⃣ **Criação Automática de Cards**
Quando usuário cria demanda:
```
1. Sistema cria demanda no banco
2. TrelloService.criar_card() é chamado
3. Card criado com:
   - Título = Nome do Cliente
   - Etiqueta = Etiqueta do Cliente
   - Lista = Lista configurada
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Banco de Dados
- [ ] Criar migration `005_create_configuracao_trello.py`
- [ ] Executar migration no local
- [ ] Executar migration no VPS

### Backend
- [ ] Criar models (ConfiguracaoTrello, EtiquetaTrelloCliente)
- [ ] Criar schemas Pydantic
- [ ] Criar endpoints de configuração
- [ ] Criar endpoints de etiquetas
- [ ] Atualizar TrelloService
- [ ] Registrar routers no main.py

### Frontend
- [ ] Criar página ConfiguracaoTrello.jsx
- [ ] Criar página EtiquetasTrelloClientes.jsx
- [ ] Adicionar rotas no App.jsx
- [ ] Adicionar links no menu

### Testes
- [ ] Testar conexão Trello
- [ ] Testar seleção de board e lista
- [ ] Testar vinculação de etiquetas
- [ ] Testar criação de card
- [ ] Validar etiqueta aplicada no card

---

## 📝 INFORMAÇÕES NECESSÁRIAS DO USUÁRIO

Para iniciar a implementação, precisamos:

1. ✅ **API Key do Trello**
   - Como obter: https://trello.com/app-key
   
2. ✅ **Token do Trello**
   - Clicar em "Token" na página da API Key
   
3. ✅ **ID do Board**
   - Será obtido via interface após teste de conexão
   
4. ✅ **ID da Lista**
   - Será obtido via interface após seleção do board
   
5. ✅ **Etiquetas Existentes**
   - Serão listadas automaticamente do board
   
6. ⚠️ **Decisão**: Criar etiquetas automaticamente ou usar existentes?
   - Opção A: Sistema cria etiquetas novas para cada cliente
   - Opção B: Usar apenas etiquetas já criadas no board (RECOMENDADO)

---

## 🚀 PRÓXIMOS PASSOS

Confirme se este pipeline atende suas necessidades e podemos:

1. ✅ Iniciar pela Fase 1 (Banco de Dados)
2. ✅ Seguir para Fase 2 (Backend Models)
3. ✅ Continuar até conclusão
4. ✅ Testar integração completa

**Deseja que eu inicie a implementação?** 🎯

