"""
Schemas Pydantic para Configuração Trello
Define modelos de validação para API de configuração do Trello
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid


# ==================== CREATE ====================

class ConfiguracaoTrelloCreate(BaseModel):
    """
    Schema para criar nova configuração Trello
    
    Exemplo:
        ```json
        {
            "api_key": "abc123...",
            "token": "def456...",
            "board_id": "5f7e8d9a...",
            "board_nome": "DeBrief - Demandas",
            "lista_id": "6a8b9c0d...",
            "lista_nome": "ENVIOS DOS CLIENTES VIA DEBRIEF"
        }
        ```
    """
    api_key: str = Field(..., description="API Key do Trello", min_length=1)
    token: str = Field(..., description="Token de autenticação", min_length=1)
    board_id: str = Field(..., description="ID do Board", min_length=1)
    board_nome: Optional[str] = Field(None, description="Nome do Board (cache)")
    lista_id: str = Field(..., description="ID da Lista", min_length=1)
    lista_nome: Optional[str] = Field(None, description="Nome da Lista (cache)")


# ==================== UPDATE ====================

class ConfiguracaoTrelloUpdate(BaseModel):
    """Schema para atualizar configuração Trello"""
    api_key: Optional[str] = Field(None, min_length=1)
    token: Optional[str] = Field(None, min_length=1)
    board_id: Optional[str] = Field(None, min_length=1)
    board_nome: Optional[str] = None
    lista_id: Optional[str] = Field(None, min_length=1)
    lista_nome: Optional[str] = None
    ativo: Optional[bool] = None


# ==================== RESPONSE ====================

class ConfiguracaoTrelloResponse(BaseModel):
    """
    Schema de resposta para configuração Trello
    
    Nota: api_key e token são mascarados por segurança
    """
    id: uuid.UUID
    api_key: str  # Será mascarado no endpoint
    token: str    # Será mascarado no endpoint
    board_id: str
    board_nome: Optional[str]
    lista_id: str
    lista_nome: Optional[str]
    ativo: bool
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True


# ==================== TEST ====================

class ConfiguracaoTrelloTest(BaseModel):
    """
    Schema para testar conexão com Trello
    
    Se board_id for fornecido, lista as listas do board.
    Se não, lista os boards disponíveis.
    
    Exemplo:
        ```json
        {
            "api_key": "abc123...",
            "token": "def456...",
            "board_id": "5f7e8d9a..." // opcional
        }
        ```
    """
    api_key: str = Field(..., min_length=1)
    token: str = Field(..., min_length=1)
    board_id: Optional[str] = Field(None, description="ID do Board (opcional)")


# ==================== AUXILIARES ====================

class TrelloBoardInfo(BaseModel):
    """Informações de um board do Trello"""
    id: str
    nome: str


class TrelloListaInfo(BaseModel):
    """Informações de uma lista do Trello"""
    id: str
    nome: str


class TrelloEtiquetaInfo(BaseModel):
    """Informações de uma etiqueta do Trello"""
    id: str
    nome: str
    cor: str

