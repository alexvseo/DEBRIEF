"""
Rate Limiting Middleware
Protege a API contra abuso e ataques de força bruta
"""
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.core.config import settings


class _NoopLimiter:
    """Decorador neutro quando rate limiting está desabilitado."""
    
    def limit(self, *_args, **_kwargs):
        def decorator(func):
            return func
        return decorator


# Criar limiter real ou no-op com base na configuração
if settings.RATE_LIMIT_ENABLED:
    limiter = Limiter(
        key_func=get_remote_address,
        default_limits=[settings.RATE_LIMIT_DEFAULT],
        storage_uri=settings.RATE_LIMIT_STORAGE_URI,
    )
else:
    limiter = _NoopLimiter()

# Configurações de rate limit por endpoint
RATE_LIMITS = {
    "auth": settings.RATE_LIMIT_AUTH,
    "default": settings.RATE_LIMIT_DEFAULT,
    "upload": settings.RATE_LIMIT_UPLOAD,
    "reports": settings.RATE_LIMIT_REPORTS,
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
    if settings.RATE_LIMIT_ENABLED:
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    
    return limiter

