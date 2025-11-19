"""
Schemas Pydantic para TipoDemanda
Validação de entrada/saída de dados
"""
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime
import re


class TipoDemandaBase(BaseModel):
    """
    Schema base com campos comuns
    """
    nome: str = Field(..., min_length=2, max_length=100, description="Nome do tipo")
    cor: str = Field(..., pattern=r'^#[0-9A-Fa-f]{6}$', description="Cor hexadecimal (ex: #3B82F6)")
    ativo: bool = Field(True, description="Status ativo/inativo")


class TipoDemandaCreate(TipoDemandaBase):
    """
    Schema para criar tipo de demanda
    """
    @validator('nome')
    def nome_nao_vazio(cls, v):
        """Valida que nome não é apenas espaços"""
        if not v.strip():
            raise ValueError('Nome não pode ser vazio')
        return v.strip()
    
    @validator('cor')
    def validar_cor_hex(cls, v):
        """Valida formato hexadecimal da cor"""
        if not re.match(r'^#[0-9A-Fa-f]{6}$', v):
            raise ValueError('Cor deve estar no formato hexadecimal: #RRGGBB (ex: #3B82F6)')
        return v.upper()


class TipoDemandaUpdate(BaseModel):
    """
    Schema para atualizar tipo de demanda
    Todos os campos opcionais
    """
    nome: Optional[str] = Field(None, min_length=2, max_length=100)
    cor: Optional[str] = Field(None, pattern=r'^#[0-9A-Fa-f]{6}$')
    ativo: Optional[bool] = None
    
    @validator('nome')
    def nome_nao_vazio(cls, v):
        """Valida que nome não é apenas espaços"""
        if v is not None and not v.strip():
            raise ValueError('Nome não pode ser vazio')
        return v.strip() if v else None
    
    @validator('cor')
    def validar_cor_hex(cls, v):
        """Valida formato hexadecimal da cor"""
        if v and not re.match(r'^#[0-9A-Fa-f]{6}$', v):
            raise ValueError('Cor deve estar no formato hexadecimal: #RRGGBB')
        return v.upper() if v else None


class TipoDemandaResponse(TipoDemandaBase):
    """
    Schema de resposta (com ID e timestamps)
    """
    id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class TipoDemandaResponseComplete(TipoDemandaResponse):
    """
    Schema de resposta completa (com estatísticas)
    """
    total_demandas: int = 0
    tem_demandas: bool = False
    
    class Config:
        from_attributes = True

