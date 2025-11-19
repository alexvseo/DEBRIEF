"""
Schemas Pydantic para Cliente
Validação de entrada/saída de dados
"""
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime


class ClienteBase(BaseModel):
    """
    Schema base com campos comuns
    """
    nome: str = Field(..., min_length=3, max_length=200, description="Nome da empresa/órgão")
    whatsapp_group_id: Optional[str] = Field(None, max_length=100, description="ID do grupo WhatsApp")
    trello_member_id: Optional[str] = Field(None, max_length=100, description="ID do membro no Trello")
    ativo: bool = Field(True, description="Status ativo/inativo")


class ClienteCreate(ClienteBase):
    """
    Schema para criar cliente
    """
    @validator('nome')
    def nome_nao_vazio(cls, v):
        """Valida que nome não é apenas espaços"""
        if not v.strip():
            raise ValueError('Nome não pode ser vazio')
        return v.strip()
    
    @validator('whatsapp_group_id')
    def validar_whatsapp_id(cls, v):
        """Valida formato do ID do grupo WhatsApp (opcional)"""
        if v and not v.endswith('@g.us'):
            raise ValueError('WhatsApp group ID deve terminar com @g.us')
        return v


class ClienteUpdate(BaseModel):
    """
    Schema para atualizar cliente
    Todos os campos opcionais
    """
    nome: Optional[str] = Field(None, min_length=3, max_length=200)
    whatsapp_group_id: Optional[str] = Field(None, max_length=100)
    trello_member_id: Optional[str] = Field(None, max_length=100)
    ativo: Optional[bool] = None
    
    @validator('nome')
    def nome_nao_vazio(cls, v):
        """Valida que nome não é apenas espaços"""
        if v is not None and not v.strip():
            raise ValueError('Nome não pode ser vazio')
        return v.strip() if v else None


class ClienteResponse(ClienteBase):
    """
    Schema de resposta (com ID e timestamps)
    """
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ClienteResponseComplete(ClienteResponse):
    """
    Schema de resposta completa (com estatísticas)
    """
    total_usuarios: int = 0
    total_secretarias: int = 0
    total_demandas: int = 0
    tem_whatsapp: bool = False
    tem_trello: bool = False
    
    class Config:
        from_attributes = True

