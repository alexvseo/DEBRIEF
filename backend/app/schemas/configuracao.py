"""
Schemas Pydantic para Configuração
Validação de dados de entrada/saída
"""
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime
from enum import Enum


class TipoConfiguracao(str, Enum):
    """Tipos de configuração"""
    TRELLO = "trello"
    WHATSAPP = "whatsapp"
    SISTEMA = "sistema"
    EMAIL = "email"


# Schemas de Input

class ConfiguracaoCreate(BaseModel):
    """Schema para criar configuração"""
    chave: str = Field(..., min_length=3, max_length=100, description="Chave única da configuração")
    valor: str = Field(..., description="Valor da configuração")
    tipo: TipoConfiguracao = Field(default=TipoConfiguracao.SISTEMA, description="Tipo da configuração")
    descricao: Optional[str] = Field(None, max_length=500, description="Descrição da configuração")
    is_sensivel: bool = Field(default=False, description="Se o valor é sensível (será criptografado)")
    
    @validator('chave')
    def chave_lowercase(cls, v):
        """Converter chave para lowercase"""
        return v.lower().strip()


class ConfiguracaoUpdate(BaseModel):
    """Schema para atualizar configuração"""
    valor: Optional[str] = Field(None, description="Novo valor da configuração")
    descricao: Optional[str] = Field(None, max_length=500, description="Nova descrição")
    is_sensivel: Optional[bool] = Field(None, description="Se o valor é sensível")


class ConfiguracaoTestarTrello(BaseModel):
    """Schema para testar conexão Trello"""
    api_key: str = Field(..., description="API Key do Trello")
    token: str = Field(..., description="Token do Trello")
    board_id: Optional[str] = Field(None, description="Board ID (opcional)")


class ConfiguracaoTestarWhatsApp(BaseModel):
    """Schema para testar conexão WhatsApp"""
    url: str = Field(..., description="URL da instância WPPConnect")
    instance: str = Field(..., description="Nome da instância")
    token: str = Field(..., description="Token de autenticação")
    numero_teste: Optional[str] = Field(None, description="Número para enviar mensagem teste")


# Schemas de Output

class ConfiguracaoResponse(BaseModel):
    """Schema de resposta de configuração"""
    id: str
    chave: str
    valor: Optional[str] = None  # Mascarado se sensível
    tipo: TipoConfiguracao
    descricao: Optional[str]
    is_sensivel: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ConfiguracaoResponseSimples(BaseModel):
    """Schema simplificado de configuração (sem valor)"""
    id: str
    chave: str
    tipo: TipoConfiguracao
    descricao: Optional[str]
    is_sensivel: bool
    has_valor: bool = Field(description="Se tem valor configurado")
    created_at: datetime
    
    class Config:
        from_attributes = True


class ConfiguracaoPorTipo(BaseModel):
    """Schema de configurações agrupadas por tipo"""
    tipo: TipoConfiguracao
    configuracoes: list[ConfiguracaoResponse]


class TesteConexaoResponse(BaseModel):
    """Schema de resposta do teste de conexão"""
    sucesso: bool
    mensagem: str
    detalhes: Optional[dict] = None


__all__ = [
    "TipoConfiguracao",
    "ConfiguracaoCreate",
    "ConfiguracaoUpdate",
    "ConfiguracaoTestarTrello",
    "ConfiguracaoTestarWhatsApp",
    "ConfiguracaoResponse",
    "ConfiguracaoResponseSimples",
    "ConfiguracaoPorTipo",
    "TesteConexaoResponse",
]

