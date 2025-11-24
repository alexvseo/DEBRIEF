"""
Schemas Pydantic para Prioridade
Validação de entrada/saída de dados
"""
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime
import re


class PrioridadeBase(BaseModel):
    """
    Schema base com campos comuns
    """
    nome: str = Field(..., min_length=2, max_length=50, description="Nome da prioridade")
    nivel: int = Field(..., ge=1, le=4, description="Nível (1-4)")
    cor: str = Field(..., pattern=r'^#[0-9A-Fa-f]{6}$', description="Cor hexadecimal")


class PrioridadeCreate(PrioridadeBase):
    """
    Schema para criar prioridade
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
            raise ValueError('Cor deve estar no formato hexadecimal: #RRGGBB')
        return v.upper()
    
    @validator('nivel')
    def validar_nivel(cls, v):
        """Valida range do nível"""
        if not 1 <= v <= 4:
            raise ValueError('Nível deve estar entre 1 (Baixa) e 4 (Urgente)')
        return v


class PrioridadeUpdate(BaseModel):
    """
    Schema para atualizar prioridade
    Todos os campos opcionais
    """
    nome: Optional[str] = Field(None, min_length=2, max_length=50)
    nivel: Optional[int] = Field(None, ge=1, le=4)
    cor: Optional[str] = Field(None, pattern=r'^#[0-9A-Fa-f]{6}$')
    
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


class PrioridadeResponse(PrioridadeBase):
    """
    Schema de resposta (com ID e timestamps)
    """
    id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class PrioridadeResponseComplete(PrioridadeResponse):
    """
    Schema de resposta completa (com estatísticas)
    """
    total_demandas: int = 0
    tem_demandas: bool = False
    emoji: str = "📌"
    
    class Config:
        from_attributes = True

