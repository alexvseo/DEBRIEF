"""
Rate Limiting Middleware
Protege a API contra abuso e ataques de força bruta
"""
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request
from app.core.config import settings

# Criar limiter
limiter = Limiter(
    key_func=get_remote_address,  # Usa IP do cliente
    default_limits=["100/minute"],  # Limite padrão: 100 requisições por minuto
    storage_uri="memory://",  # Usa memória (para produção, usar Redis)
)

# Configurações de rate limit por endpoint
RATE_LIMITS = {
    "auth": "5/minute",  # Login: 5 tentativas por minuto
    "default": "100/minute",  # Padrão: 100 requisições por minuto
    "upload": "10/minute",  # Upload: 10 arquivos por minuto
    "reports": "20/minute",  # Relatórios: 20 por minuto
}


def get_rate_limit_for_endpoint(endpoint: str) -> str:
    """
    Obter rate limit para um endpoint específico
    
    Args:
        endpoint: Nome do endpoint
        
    Returns:
        str: Rate limit string (ex: "5/minute")
    """
    # Endpoints de autenticação
    if "auth" in endpoint.lower() or "login" in endpoint.lower():
        return RATE_LIMITS["auth"]
    
    # Endpoints de upload
    if "upload" in endpoint.lower() or "anexo" in endpoint.lower():
        return RATE_LIMITS["upload"]
    
    # Endpoints de relatórios
    if "relatorio" in endpoint.lower() or "report" in endpoint.lower():
        return RATE_LIMITS["reports"]
    
    # Padrão
    return RATE_LIMITS["default"]


def setup_rate_limiting(app):
    """
    Configurar rate limiting na aplicação
    
    Args:
        app: Instância FastAPI
    """
    # Adicionar limiter ao app
    app.state.limiter = limiter
    
    # Adicionar handler de erro
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    
    return limiter

