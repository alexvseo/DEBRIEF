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
    
    @validator('username')
    def username_alphanumeric(cls, v):
        if not v.replace('_', '').replace('.', '').isalnum():
            raise ValueError('Username deve conter apenas letras, números, _ e .')
        return v.lower()


class UserUpdate(BaseModel):
    """Schema para atualizar usuário"""
    email: Optional[EmailStr] = None
    nome_completo: Optional[str] = Field(None, min_length=3, max_length=200)
    cliente_id: Optional[str] = None
    ativo: Optional[bool] = None


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
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True  # Permite conversão de ORM


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
    token_type: str = "bearer"
    user: UserResponse

