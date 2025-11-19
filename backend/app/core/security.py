"""
Utilitários de segurança
JWT, hash de senhas, etc.
"""
from datetime import datetime, timedelta
from typing import Optional, Union, Any
from jose import jwt, JWTError
from passlib.context import CryptContext
from app.core.config import settings

# Contexto para hash de senhas (bcrypt)
pwd_context = CryptContext(
    schemes=settings.PWD_CONTEXT_SCHEMES,
    deprecated=settings.PWD_CONTEXT_DEPRECATED
)


def hash_password(password: str) -> str:
    """
    Hash de senha usando bcrypt
    
    Args:
        password: Senha em texto plano
        
    Returns:
        str: Senha hasheada
        
    Example:
        hashed = hash_password("senha123")
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verificar senha
    
    Args:
        plain_password: Senha em texto plano
        hashed_password: Senha hasheada
        
    Returns:
        bool: True se senha correta
        
    Example:
        if verify_password("senha123", user.password_hash):
            # Senha correta
    """
    return pwd_context.verify(plain_password, hashed_password)


def needs_rehash(hashed_password: str) -> bool:
    """
    Verificar se senha precisa ser re-hasheada
    (algoritmo ou custo mudou)
    
    Args:
        hashed_password: Senha hasheada
        
    Returns:
        bool: True se precisa re-hashear
    """
    return pwd_context.needs_update(hashed_password)


def create_access_token(
    data: dict,
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Criar token JWT de acesso
    
    Args:
        data: Dados a incluir no token
        expires_delta: Tempo de expiração personalizado
        
    Returns:
        str: Token JWT
        
    Example:
        token = create_access_token(
            data={"sub": user.id, "username": user.username}
        )
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    to_encode.update({"exp": expire, "type": "access"})
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """
    Criar token JWT de refresh
    
    Args:
        data: Dados a incluir no token
        
    Returns:
        str: Token JWT
        
    Example:
        refresh = create_refresh_token(data={"sub": user.id})
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode.update({"exp": expire, "type": "refresh"})
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt


def decode_token(token: str) -> Optional[dict]:
    """
    Decodificar token JWT
    
    Args:
        token: Token JWT
        
    Returns:
        dict: Payload do token ou None se inválido
        
    Example:
        payload = decode_token(token)
        user_id = payload.get("sub")
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None


def verify_token(token: str, token_type: str = "access") -> Optional[str]:
    """
    Verificar token JWT e retornar subject (user_id)
    
    Args:
        token: Token JWT
        token_type: Tipo do token (access ou refresh)
        
    Returns:
        str: User ID ou None se inválido
        
    Example:
        user_id = verify_token(token)
        if user_id:
            # Token válido
    """
    payload = decode_token(token)
    
    if payload is None:
        return None
    
    # Verificar tipo do token
    if payload.get("type") != token_type:
        return None
    
    # Obter subject (user_id)
    user_id: str = payload.get("sub")
    
    if user_id is None:
        return None
    
    return user_id

