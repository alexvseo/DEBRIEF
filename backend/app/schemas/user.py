"""
Schemas Pydantic para User
Validação de dados de entrada/saída
"""
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime
from enum import Enum


class TipoUsuario(str, Enum):
    """Tipos de usuário"""
    MASTER = "master"
    CLIENTE = "cliente"


# Schemas de Input


class UserLogin(BaseModel):
    """Schema para login"""
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)


class UserCreate(BaseModel):
    """Schema para criar usuário"""
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)
    nome_completo: str = Field(..., min_length=3, max_length=200)
    tipo: TipoUsuario = TipoUsuario.CLIENTE
    cliente_id: Optional[str] = None
    whatsapp: Optional[str] = Field(None, max_length=20, description="Número WhatsApp com código do país (ex: 5511999999999)")
    receber_notificacoes: Optional[bool] = Field(default=True, description="Se deseja receber notificações via WhatsApp")
    
    @validator('username')
    def username_alphanumeric(cls, v):
        if not v.replace('_', '').replace('.', '').isalnum():
            raise ValueError('Username deve conter apenas letras, números, _ e .')
        return v.lower()
    
    @validator('whatsapp')
    def validar_whatsapp(cls, v):
        """Validar formato do número WhatsApp"""
        if v is None or v == '':
            return None
        
        # Remover espaços, parênteses, hífens, etc
        numero_limpo = ''.join(filter(str.isdigit, v))
        
        # Deve ter entre 10 e 15 dígitos
        if len(numero_limpo) < 10 or len(numero_limpo) > 15:
            raise ValueError('Número WhatsApp deve ter entre 10 e 15 dígitos')
        
        # Retornar apenas dígitos
        return numero_limpo


class UserUpdate(BaseModel):
    """Schema para atualizar usuário"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    nome_completo: Optional[str] = Field(None, min_length=3, max_length=200)
    password: Optional[str] = Field(None, min_length=6, description="Nova senha (deixe vazio para não alterar)")
    tipo: Optional[TipoUsuario] = None
    cliente_id: Optional[str] = None
    ativo: Optional[bool] = None
    whatsapp: Optional[str] = Field(None, max_length=20)
    receber_notificacoes: Optional[bool] = None
    
    @validator('username')
    def username_alphanumeric(cls, v):
        if v is None:
            return v
        if not v.replace('_', '').replace('.', '').replace('-', '').isalnum():
            raise ValueError('Username deve conter apenas letras, números, _, . e -')
        return v.lower()


class UserNotificationSettings(BaseModel):
    """Schema para atualizar configurações de notificação"""
    whatsapp: Optional[str] = Field(None, min_length=10, max_length=20, description="Número WhatsApp com código do país (ex: 5511999999999)")
    receber_notificacoes: Optional[bool] = Field(None, description="Se deseja receber notificações via WhatsApp")
    
    @validator('whatsapp')
    def validar_whatsapp(cls, v):
        """Validar formato do número WhatsApp"""
        if v is None:
            return v
        
        # Remover espaços, parênteses, hífens, etc
        numero_limpo = ''.join(filter(str.isdigit, v))
        
        # Deve ter entre 10 e 15 dígitos
        if len(numero_limpo) < 10 or len(numero_limpo) > 15:
            raise ValueError('Número WhatsApp deve ter entre 10 e 15 dígitos')
        
        # Retornar apenas dígitos
        return numero_limpo


class UserChangePassword(BaseModel):
    """Schema para alterar senha"""
    current_password: str
    new_password: str = Field(..., min_length=6)


# Schemas de Output


class UserResponse(BaseModel):
    """Schema de resposta de usuário (sem senha)"""
    id: str
    username: str
    email: str
    nome_completo: str
    tipo: TipoUsuario
    cliente_id: Optional[str]
    ativo: bool
    whatsapp: Optional[str] = None
    receber_notificacoes: bool = True
    created_at: datetime
    updated_at: datetime
    mfa_enabled: bool = False
    
    class Config:
        from_attributes = True  # Permite conversão de ORM
        use_enum_values = True  # Usa os valores do enum na serialização


class UserInDB(UserResponse):
    """Schema de usuário no banco (com senha)"""
    password_hash: str


# Schemas de Autenticação


class Token(BaseModel):
    """Schema de resposta de token"""
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Dados extraídos do token"""
    user_id: Optional[str] = None
    username: Optional[str] = None


class LoginResponse(BaseModel):
    """Resposta completa de login"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class RefreshTokenRequest(BaseModel):
    """Payload para renovar token de acesso"""
    refresh_token: str


class TwoFactorSetupResponse(BaseModel):
    """Resposta com dados para configurar MFA"""
    secret: str
    otpauth_url: str


class TwoFactorCodeRequest(BaseModel):
    """Payload para confirmar/disable MFA"""
    code: str = Field(..., min_length=6, max_length=6)


class LogoutRequest(BaseModel):
    """Payload opcional para logout"""
    refresh_token: Optional[str] = None

