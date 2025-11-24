"""
Schemas Pydantic para Etiqueta Trello por Cliente
Define modelos de validação para API de etiquetas Trello
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid


# ==================== CREATE ====================

class EtiquetaTrelloClienteCreate(BaseModel):
    """
    Schema para vincular etiqueta Trello a cliente
    
    Exemplo:
        ```json
        {
            "cliente_id": "uuid-do-cliente",
            "etiqueta_trello_id": "5f7e8d9a...",
            "etiqueta_nome": "RUSSAS",
            "etiqueta_cor": "green"
        }
        ```
    """
    cliente_id: uuid.UUID = Field(..., description="ID do cliente")
    etiqueta_trello_id: str = Field(..., description="ID da etiqueta no Trello", min_length=1)
    etiqueta_nome: str = Field(..., description="Nome da etiqueta", min_length=1)
    etiqueta_cor: str = Field(..., description="Cor da etiqueta (ex: green, red)", min_length=1)


# ==================== UPDATE ====================

class EtiquetaTrelloClienteUpdate(BaseModel):
    """Schema para atualizar vinculação de etiqueta"""
    etiqueta_trello_id: Optional[str] = Field(None, min_length=1)
    etiqueta_nome: Optional[str] = Field(None, min_length=1)
    etiqueta_cor: Optional[str] = Field(None, min_length=1)
    ativo: Optional[bool] = None


# ==================== RESPONSE ====================

class EtiquetaTrelloClienteResponse(BaseModel):
    """
    Schema de resposta para etiqueta Trello por cliente
    
    Inclui nome do cliente para facilitar exibição
    """
    id: uuid.UUID
    cliente_id: uuid.UUID
    cliente_nome: str  # Adicionado dinamicamente
    etiqueta_trello_id: str
    etiqueta_nome: str
    etiqueta_cor: str
    ativo: bool
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True


# ==================== AUXILIARES ====================

class EtiquetaTrelloDisponivel(BaseModel):
    """
    Etiqueta disponível no board do Trello
    
    Usada para listagem ao vincular clientes
    """
    id: str
    nome: str
    cor: str

