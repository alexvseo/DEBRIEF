"""
DeBrief API - FastAPI Application
Sistema de Gestão de Demandas e Briefings
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path
from app.core.config import settings
from app.core.database import init_db
from app.core.rate_limit import setup_rate_limiting
from app.api.endpoints import (
    auth,
    demandas,
    clientes,
    secretarias,
    tipos_demanda,
    prioridades,
    configuracoes,
    usuarios,
    relatorios,
    whatsapp,
    trello_config,
    trello_etiquetas,
    trello_webhook
)

# Criar aplicação FastAPI
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API para gestão de demandas e briefings",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configurar Rate Limiting
limiter = setup_rate_limiting(app)

# Middleware personalizado
from app.core.middleware import LoggingMiddleware
app.add_middleware(LoggingMiddleware)


# Event Handlers


@app.on_event("startup")
async def startup_event():
    """
    Executar na inicialização da aplicação
    """
    print(f"🚀 {settings.APP_NAME} v{settings.APP_VERSION} iniciando...")
    print(f"📝 Documentação: http://{settings.HOST}:{settings.PORT}/api/docs")
    
    # Inicializar banco de dados (não falha se banco não estiver disponível)
    try:
        init_db()
    except Exception as e:
        print(f"⚠️  Aviso na inicialização do banco: {e}")
        print("⚠️  A aplicação continuará, mas funcionalidades do banco podem não estar disponíveis")


@app.on_event("shutdown")
async def shutdown_event():
    """
    Executar no encerramento da aplicação
    """
    print("👋 Encerrando aplicação...")


# Rotas


@app.get("/", tags=["Root"])
async def root():
    """
    Rota raiz - Status da API
    """
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": f"http://{settings.HOST}:{settings.PORT}/api/docs"
    }


@app.get("/health", tags=["Health"])
@app.get("/api/health", tags=["Health"])
async def health_check():
    """
    Health check - Verificar se API está funcionando
    """
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION
    }


# Incluir rotas dos endpoints

# Autenticação
app.include_router(
    auth.router,
    prefix="/api/auth",
    tags=["Autenticação"]
)

# Demandas
app.include_router(
    demandas.router,
    prefix="/api/demandas",
    tags=["Demandas"]
)

# Clientes (Admin)
app.include_router(
    clientes.router,
    prefix="/api/clientes",
    tags=["Clientes - Admin"]
)

# Secretarias (Admin)
app.include_router(
    secretarias.router,
    prefix="/api/secretarias",
    tags=["Secretarias - Admin"]
)

# Tipos de Demanda (Admin)
app.include_router(
    tipos_demanda.router,
    prefix="/api/tipos-demanda",
    tags=["Tipos de Demanda - Admin"]
)

# Prioridades (Admin)
app.include_router(
    prioridades.router,
    prefix="/api/prioridades",
    tags=["Prioridades - Admin"]
)

# Configurações (Admin)
app.include_router(
    configuracoes.router,
    prefix="/api/configuracoes",
    tags=["Configurações - Admin"]
)

# Usuários (Admin)
app.include_router(
    usuarios.router,
    prefix="/api/usuarios",
    tags=["Usuários - Admin"]
)

# Relatórios
app.include_router(
    relatorios.router,
    prefix="/api/relatorios",
    tags=["Relatórios"]
)

# WhatsApp - Configurações e Templates
app.include_router(
    whatsapp.router,
    prefix="/api/whatsapp",
    tags=["WhatsApp - Notificações"]
)

# Trello - Configuração
app.include_router(
    trello_config.router
    # Já contém prefix="/api/trello-config" e tags=["Configuração Trello"]
)

# Trello - Etiquetas por Cliente
app.include_router(
    trello_etiquetas.router
    # Já contém prefix="/api/trello-etiquetas" e tags=["Etiquetas Trello"]
)

# Trello - Webhook (Sincronização Bidirecional)
app.include_router(
    trello_webhook.router
    # Já contém prefix="/api/trello" e tags=["Webhook Trello"]
)


# Servir arquivos de upload estáticos
@app.get("/uploads/{file_path:path}", tags=["Uploads"])
async def servir_arquivo_upload(file_path: str):
    """
    Servir arquivos de upload
    Exemplo: /uploads/cliente_id/demanda_id/arquivo.pdf
    """
    upload_dir = Path(settings.UPLOAD_DIR)
    file_full_path = upload_dir / file_path
    
    # Verificar se arquivo existe e está dentro do diretório de uploads
    if not file_full_path.exists() or not str(file_full_path).startswith(str(upload_dir)):
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arquivo não encontrado"
        )
    
    return FileResponse(
        path=file_full_path,
        media_type='application/octet-stream'
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

