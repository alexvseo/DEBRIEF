"""
CSRF Protection Middleware
Proteção contra Cross-Site Request Forgery
"""
from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.security import generate_csrf_token, verify_csrf_token
import secrets
import logging

logger = logging.getLogger(__name__)

# Armazenamento de tokens CSRF (em memória - para produção, usar Redis ou sessão)
_csrf_tokens: dict[str, str] = {}


def get_csrf_token(session_id: str = None) -> str:
    """
    Gerar token CSRF
    
    Args:
        session_id: ID da sessão (opcional)
        
    Returns:
        str: Token CSRF
    """
    token = generate_csrf_token()
    
    if session_id:
        _csrf_tokens[session_id] = token
    
    return token


def verify_csrf(request: Request, session_id: str = None) -> bool:
    """
    Verificar token CSRF na requisição
    
    Args:
        request: Request object
        session_id: ID da sessão
        
    Returns:
        bool: True se válido
        
    Raises:
        HTTPException: Se token inválido
    """
    # Obter token do header
    csrf_token = request.headers.get("X-CSRF-Token")
    
    if not csrf_token:
        # Para métodos seguros (GET, HEAD, OPTIONS), CSRF não é obrigatório
        if request.method in ["GET", "HEAD", "OPTIONS"]:
            return True
        
        logger.warning("Token CSRF não fornecido")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token CSRF não fornecido"
        )
    
    # Obter token da sessão
    if session_id:
        session_token = _csrf_tokens.get(session_id)
    else:
        # Tentar obter do cookie
        session_token = request.cookies.get("csrf_token")
    
    if not session_token:
        logger.warning("Token CSRF da sessão não encontrado")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sessão inválida"
        )
    
    # Verificar tokens
    if not verify_csrf_token(csrf_token, session_token):
        logger.warning("Token CSRF inválido")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token CSRF inválido"
        )
    
    return True


def clear_csrf_token(session_id: str):
    """
    Limpar token CSRF da sessão
    
    Args:
        session_id: ID da sessão
    """
    if session_id in _csrf_tokens:
        del _csrf_tokens[session_id]

