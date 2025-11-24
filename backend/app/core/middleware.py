"""
Middleware personalizado
CSRF, logging, etc
"""
from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import time
import logging

logger = logging.getLogger(__name__)


class CSRFMiddleware(BaseHTTPMiddleware):
    """
    Middleware CSRF
    Protege contra Cross-Site Request Forgery
    """
    
    async def dispatch(self, request: Request, call_next):
        # Métodos seguros não precisam de CSRF
        if request.method in ["GET", "HEAD", "OPTIONS"]:
            return await call_next(request)
        
        # Endpoints públicos não precisam de CSRF
        if request.url.path in ["/api/docs", "/api/redoc", "/api/openapi.json", "/health", "/api/health"]:
            return await call_next(request)
        
        # Verificar CSRF para outros métodos
        # Nota: Implementação completa requer sessões
        # Por enquanto, apenas loga (pode ser implementado depois)
        
        response = await call_next(request)
        return response


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware de logging
    Registra todas as requisições
    """
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Log da requisição
        logger.info(
            f"{request.method} {request.url.path} - "
            f"IP: {request.client.host if request.client else 'unknown'}"
        )
        
        response = await call_next(request)
        
        # Calcular tempo de processamento
        process_time = time.time() - start_time
        
        # Adicionar header com tempo de processamento
        response.headers["X-Process-Time"] = str(process_time)
        
        # Log da resposta
        logger.info(
            f"{request.method} {request.url.path} - "
            f"Status: {response.status_code} - "
            f"Time: {process_time:.3f}s"
        )
        
        return response

