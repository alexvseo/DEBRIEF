"""
Schemas Pydantic para Configuração WhatsApp
"""
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime


class ConfiguracaoWhatsAppBase(BaseModel):
    """Schema base para Configuração WhatsApp"""
    numero_remetente: str = Field(
        ...,
        min_length=10,
        max_length=20,
        description="Número WhatsApp Business (formato: 5511999999999)"
    )
    instancia_wpp: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Nome da instância WPP Connect"
    )
    token_wpp: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Token de autenticação da instância WPP Connect"
    )
    ativo: bool = Field(default=True, description="Se a configuração está ativa")
    
    @validator('numero_remetente')
    def validar_numero(cls, v):
        """Validar formato do número WhatsApp"""
        # Remover caracteres não numéricos
        numeros = ''.join(filter(str.isdigit, v))
        
        if len(numeros) < 10 or len(numeros) > 15:
            raise ValueError('Número WhatsApp deve ter entre 10 e 15 dígitos')
        
        return numeros


class ConfiguracaoWhatsAppCreate(ConfiguracaoWhatsAppBase):
    """Schema para criar configuração WhatsApp"""
    pass


class ConfiguracaoWhatsAppUpdate(BaseModel):
    """Schema para atualizar configuração WhatsApp"""
    numero_remetente: Optional[str] = Field(None, min_length=10, max_length=20)
    instancia_wpp: Optional[str] = Field(None, min_length=1, max_length=100)
    token_wpp: Optional[str] = Field(None, min_length=1, max_length=255)
    ativo: Optional[bool] = None
    
    @validator('numero_remetente')
    def validar_numero(cls, v):
        """Validar formato do número WhatsApp"""
        if v is None:
            return v
        numeros = ''.join(filter(str.isdigit, v))
        if len(numeros) < 10 or len(numeros) > 15:
            raise ValueError('Número WhatsApp deve ter entre 10 e 15 dígitos')
        return numeros


class ConfiguracaoWhatsAppResponse(ConfiguracaoWhatsAppBase):
    """Schema de resposta para configuração WhatsApp"""
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class TestarConexaoWhatsAppRequest(BaseModel):
    """Schema para testar conexão WhatsApp"""
    numero_teste: str = Field(
        ...,
        min_length=10,
        max_length=20,
        description="Número de WhatsApp para enviar mensagem de teste"
    )
    mensagem: Optional[str] = Field(
        default="✅ Teste de conexão WhatsApp - DeBrief Sistema",
        description="Mensagem personalizada para teste"
    )
    
    @validator('numero_teste')
    def validar_numero(cls, v):
        """Validar formato do número WhatsApp"""
        numeros = ''.join(filter(str.isdigit, v))
        if len(numeros) < 10 or len(numeros) > 15:
            raise ValueError('Número WhatsApp deve ter entre 10 e 15 dígitos')
        return numeros

