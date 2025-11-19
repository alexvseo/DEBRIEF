"""
Schemas Pydantic para Anexo
Validação de entrada/saída de dados
"""
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime


class AnexoBase(BaseModel):
    """
    Schema base com campos comuns
    """
    nome_arquivo: str = Field(..., max_length=500, description="Nome do arquivo")
    tamanho: int = Field(..., gt=0, description="Tamanho em bytes")
    tipo_mime: str = Field(..., max_length=100, description="Tipo MIME")


class AnexoCreate(AnexoBase):
    """
    Schema para criar anexo
    """
    demanda_id: str = Field(..., description="ID da demanda")
    caminho: str = Field(..., max_length=1000, description="Path do arquivo")
    trello_attachment_id: Optional[str] = Field(None, max_length=100)
    
    @validator('tamanho')
    def validar_tamanho(cls, v):
        """Valida tamanho máximo (50MB)"""
        max_size = 52428800  # 50MB
        if v > max_size:
            raise ValueError(f'Arquivo muito grande. Máximo: {max_size / 1024 / 1024:.0f}MB')
        return v
    
    @validator('tipo_mime')
    def validar_tipo_mime(cls, v):
        """Valida tipos MIME permitidos"""
        tipos_permitidos = [
            'application/pdf',
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/gif',
            'image/webp',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        ]
        if v not in tipos_permitidos:
            raise ValueError(f'Tipo de arquivo não permitido: {v}')
        return v


class AnexoUpdate(BaseModel):
    """
    Schema para atualizar anexo
    Geralmente anexos não são atualizados, apenas deletados
    """
    trello_attachment_id: Optional[str] = Field(None, max_length=100)


class AnexoResponse(AnexoBase):
    """
    Schema de resposta (com ID e timestamps)
    """
    id: str
    demanda_id: str
    caminho: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class AnexoResponseComplete(AnexoResponse):
    """
    Schema de resposta completa (com metadados extras)
    """
    extensao: Optional[str] = None
    tamanho_formatado: Optional[str] = None
    is_imagem: bool = False
    is_pdf: bool = False
    icone: str = "📎"
    demanda_nome: Optional[str] = None
    tem_trello: bool = False
    
    class Config:
        from_attributes = True

