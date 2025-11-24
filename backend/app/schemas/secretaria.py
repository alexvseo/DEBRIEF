"""
Schemas Pydantic para Secretaria
Validação de entrada/saída de dados
"""
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime


class SecretariaBase(BaseModel):
    """
    Schema base com campos comuns
    """
    nome: str = Field(..., min_length=3, max_length=200, description="Nome da secretaria")
    cliente_id: str = Field(..., description="ID do cliente")
    ativo: bool = Field(True, description="Status ativo/inativo")


class SecretariaCreate(SecretariaBase):
    """
    Schema para criar secretaria
    """
    @validator('nome')
    def nome_nao_vazio(cls, v):
        """Valida que nome não é apenas espaços"""
        if not v.strip():
            raise ValueError('Nome não pode ser vazio')
        return v.strip()


class SecretariaUpdate(BaseModel):
    """
    Schema para atualizar secretaria
    Todos os campos opcionais
    """
    nome: Optional[str] = Field(None, min_length=3, max_length=200)
    ativo: Optional[bool] = None
    
    @validator('nome')
    def nome_nao_vazio(cls, v):
        """Valida que nome não é apenas espaços"""
        if v is not None and not v.strip():
            raise ValueError('Nome não pode ser vazio')
        return v.strip() if v else None


class SecretariaResponse(SecretariaBase):
    """
    Schema de resposta (com ID e timestamps)
    """
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class SecretariaResponseComplete(SecretariaResponse):
    """
    Schema de resposta completa (com cliente e estatísticas)
    """
    cliente_nome: Optional[str] = None
    total_demandas: int = 0
    tem_demandas: bool = False
    
    class Config:
        from_attributes = True

