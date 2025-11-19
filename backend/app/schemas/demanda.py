"""
Schemas Pydantic para Demanda
Validação de dados de entrada/saída
"""
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import datetime, date
from enum import Enum


class StatusDemanda(str, Enum):
    """Status possíveis de uma demanda"""
    ABERTA = "aberta"
    EM_ANDAMENTO = "em_andamento"
    AGUARDANDO_CLIENTE = "aguardando_cliente"
    CONCLUIDA = "concluida"
    CANCELADA = "cancelada"


class PrioridadeDemanda(str, Enum):
    """Prioridades de demanda"""
    BAIXA = "baixa"
    MEDIA = "media"
    ALTA = "alta"
    URGENTE = "urgente"


# Schemas de Input


class DemandaCreate(BaseModel):
    """Schema para criar demanda"""
    nome: str = Field(..., min_length=5, max_length=200)
    descricao: str = Field(..., min_length=10, max_length=2000)
    tipo_demanda_id: str
    prioridade: PrioridadeDemanda = PrioridadeDemanda.MEDIA
    prazo_final: Optional[date] = None
    secretaria_id: Optional[str] = None
    
    @validator('prazo_final')
    def prazo_futuro(cls, v):
        if v and v < date.today():
            raise ValueError('Prazo deve ser uma data futura')
        return v


class DemandaUpdate(BaseModel):
    """Schema para atualizar demanda"""
    nome: Optional[str] = Field(None, min_length=5, max_length=200)
    descricao: Optional[str] = Field(None, min_length=10, max_length=2000)
    status: Optional[StatusDemanda] = None
    prioridade: Optional[PrioridadeDemanda] = None
    prazo_final: Optional[date] = None
    tipo_demanda_id: Optional[str] = None
    secretaria_id: Optional[str] = None
    
    @validator('prazo_final')
    def prazo_futuro(cls, v):
        if v and v < date.today():
            raise ValueError('Prazo deve ser uma data futura')
        return v


class DemandaFilter(BaseModel):
    """Schema para filtrar demandas"""
    status: Optional[StatusDemanda] = None
    prioridade: Optional[PrioridadeDemanda] = None
    usuario_id: Optional[str] = None
    secretaria_id: Optional[str] = None
    tipo_demanda_id: Optional[str] = None
    skip: int = Field(0, ge=0)
    limit: int = Field(20, ge=1, le=100)


# Schemas de Output


class DemandaResponse(BaseModel):
    """Schema de resposta de demanda"""
    id: str
    nome: str
    descricao: str
    status: StatusDemanda
    prioridade_id: str
    prazo_final: Optional[date]
    data_conclusao: Optional[datetime]
    usuario_id: str
    cliente_id: str
    tipo_demanda_id: str
    secretaria_id: Optional[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class DemandaDetalhada(DemandaResponse):
    """Schema detalhado de demanda (com relacionamentos)"""
    # Aqui podemos adicionar dados de usuário, tipo, etc
    # usuario: Optional[UserResponse] = None
    # arquivos: List[ArquivoResponse] = []
    pass


class DemandaListResponse(BaseModel):
    """Schema para lista de demandas com paginação"""
    items: List[DemandaResponse]
    total: int
    page: int
    pages: int

