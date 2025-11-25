"""
Schemas Pydantic para Template de Mensagem
"""
from pydantic import BaseModel, Field, validator
from typing import Optional, Dict
from datetime import datetime
import json


class TemplateMensagemBase(BaseModel):
    """Schema base para Template de Mensagem"""
    nome: str = Field(
        ...,
        min_length=3,
        max_length=100,
        description="Nome identificador do template"
    )
    tipo_evento: str = Field(
        ...,
        description="Tipo de evento (demanda_criada, demanda_atualizada, etc)"
    )
    mensagem: str = Field(
        ...,
        min_length=10,
        description="Texto da mensagem com variáveis {nome_variavel}"
    )
    ativo: bool = Field(default=True, description="Se o template está ativo")
    
    @validator('tipo_evento')
    def validar_tipo_evento(cls, v):
        """Validar tipo de evento"""
        tipos_validos = [
            'demanda_criada',
            'demanda_atualizada',
            'demanda_concluida',
            'demanda_cancelada',
            'nova_demanda',  # Compatibilidade com dados existentes
            'demanda_alterada',  # Compatibilidade com dados existentes  
            'demanda_deletada',  # Compatibilidade com dados existentes
            'usuario_cadastrado'  # Novo usuário cadastrado no sistema
        ]
        if v not in tipos_validos:
            raise ValueError(f'Tipo de evento deve ser um de: {", ".join(tipos_validos)}')
        return v


class TemplateMensagemCreate(TemplateMensagemBase):
    """Schema para criar template de mensagem"""
    pass


class TemplateMensagemUpdate(BaseModel):
    """Schema para atualizar template de mensagem"""
    nome: Optional[str] = Field(None, min_length=3, max_length=100)
    tipo_evento: Optional[str] = None
    mensagem: Optional[str] = Field(None, min_length=10)
    ativo: Optional[bool] = None
    
    @validator('tipo_evento')
    def validar_tipo_evento(cls, v):
        """Validar tipo de evento"""
        if v is None:
            return v
        tipos_validos = [
            'demanda_criada',
            'demanda_atualizada',
            'demanda_concluida',
            'demanda_cancelada',
            'usuario_cadastrado'  # Novo usuário cadastrado no sistema
        ]
        if v not in tipos_validos:
            raise ValueError(f'Tipo de evento deve ser um de: {", ".join(tipos_validos)}')
        return v


class TemplateMensagemResponse(TemplateMensagemBase):
    """Schema de resposta para template de mensagem"""
    id: str
    variaveis_disponiveis: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class VariaveisDisponiveisResponse(BaseModel):
    """Schema de resposta para variáveis disponíveis"""
    variaveis: Dict[str, str] = Field(
        ...,
        description="Dicionário com variáveis disponíveis e suas descrições"
    )


class PreviewTemplateRequest(BaseModel):
    """Schema para preview de template"""
    mensagem: str = Field(..., description="Mensagem do template com variáveis")
    dados_exemplo: Optional[Dict[str, str]] = Field(
        default=None,
        description="Dados de exemplo para renderizar o template"
    )


class PreviewTemplateResponse(BaseModel):
    """Schema de resposta para preview de template"""
    mensagem_original: str
    mensagem_renderizada: str
    variaveis_encontradas: list[str]
    variaveis_nao_substituidas: list[str]

