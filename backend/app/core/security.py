"""
Módulo de Segurança
Funções de segurança: JWT, blacklist, CSRF, reCAPTCHA
"""
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from app.core.config import settings
import httpx
import logging

logger = logging.getLogger(__name__)

# Blacklist de tokens (em memória - para produção, usar Redis)
_token_blacklist: set[str] = set()


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Criar token JWT de acesso
    
    Args:
        data: Dados para incluir no token
        expires_delta: Tempo de expiração (opcional)
        
    Returns:
        str: Token JWT
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({
        "exp": expire,
        "type": "access"
    })
    
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """
    Criar token JWT de refresh
    
    Args:
        data: Dados para incluir no token
        
    Returns:
        str: Token JWT de refresh
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode.update({
        "exp": expire,
        "type": "refresh"
    })
    
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def verify_token(token: str, token_type: str = "access") -> Optional[str]:
    """
    Verificar e decodificar token JWT
    
    Args:
        token: Token JWT
        token_type: Tipo do token ("access" ou "refresh")
        
    Returns:
        Optional[str]: ID do usuário se válido, None caso contrário
    """
    try:
        # Verificar se token está na blacklist
        if is_token_blacklisted(token):
            logger.warning(f"Token na blacklist tentou ser usado")
            return None
        
        # Decodificar token
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        # Verificar tipo do token
        if payload.get("type") != token_type:
            logger.warning(f"Tipo de token incorreto. Esperado: {token_type}, Recebido: {payload.get('type')}")
            return None
        
        # Extrair ID do usuário
        user_id: str = payload.get("sub")
        
        if user_id is None:
            return None
        
        return user_id
        
    except JWTError as e:
        logger.warning(f"Erro ao decodificar token: {e}")
        return None
    except Exception as e:
        logger.error(f"Erro inesperado ao verificar token: {e}")
        return None


def blacklist_token(token: str) -> bool:
    """
    Adicionar token à blacklist
    
    Args:
        token: Token JWT a ser invalidado
        
    Returns:
        bool: True se adicionado com sucesso
    """
    try:
        _token_blacklist.add(token)
        logger.info(f"Token adicionado à blacklist")
        return True
    except Exception as e:
        logger.error(f"Erro ao adicionar token à blacklist: {e}")
        return False


def is_token_blacklisted(token: str) -> bool:
    """
    Verificar se token está na blacklist
    
    Args:
        token: Token JWT
        
    Returns:
        bool: True se está na blacklist
    """
    return token in _token_blacklist


def clear_blacklist():
    """
    Limpar blacklist (útil para testes ou limpeza periódica)
    """
    _token_blacklist.clear()
    logger.info("Blacklist limpa")


async def verify_recaptcha(token: str) -> bool:
    """
    Verificar token reCAPTCHA com Google
    
    Args:
        token: Token reCAPTCHA do frontend
        
    Returns:
        bool: True se válido
    """
    if not settings.RECAPTCHA_SECRET_KEY:
        logger.warning("RECAPTCHA_SECRET_KEY não configurado, pulando verificação")
        return True  # Em desenvolvimento, permite se não configurado
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://www.google.com/recaptcha/api/siteverify",
                data={
                    "secret": settings.RECAPTCHA_SECRET_KEY,
                    "response": token
                },
                timeout=5.0
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("success", False)
            else:
                logger.error(f"Erro ao verificar reCAPTCHA: HTTP {response.status_code}")
                return False
                
    except Exception as e:
        logger.error(f"Exceção ao verificar reCAPTCHA: {e}")
        return False


def generate_csrf_token() -> str:
    """
    Gerar token CSRF
    
    Returns:
        str: Token CSRF
    """
    import secrets
    return secrets.token_urlsafe(32)


def verify_csrf_token(token: str, session_token: str) -> bool:
    """
    Verificar token CSRF
    
    Args:
        token: Token CSRF recebido
        session_token: Token CSRF da sessão
        
    Returns:
        bool: True se válido
    """
    return token == session_token and len(token) > 0
