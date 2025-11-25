"""
Configurações da aplicação
Gerencia variáveis de ambiente e configurações globais
"""
import json
from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import Optional, Union


class Settings(BaseSettings):
    """
    Configurações da aplicação
    Carrega automaticamente do .env
    """
    
    # Aplicação
    APP_NAME: str = "DeBrief API"
    APP_VERSION: str = "1.1.0"
    DEBUG: bool = True
    
    # Servidor
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Banco de Dados PostgreSQL
    # URL padrão aponta para o servidor remoto
    # Para desenvolvimento local, sobrescreva no .env
    DATABASE_URL: str = "postgresql://root:Mslestra%402025@82.25.92.217:5432/dbrief"
    DATABASE_ECHO: bool = False  # SQL logs
    
    # JWT
    SECRET_KEY: str = "seu-secret-key-super-seguro-mude-em-producao"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 horas
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7  # 7 dias
    
    # CORS
    CORS_ORIGINS: list[str] = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://localhost:2022",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:2022",
        "http://82.25.92.217:2022",
    ]
    
    # Senha
    PWD_CONTEXT_SCHEMES: list = ["bcrypt"]
    PWD_CONTEXT_DEPRECATED: str = "auto"
    
    # Upload de Arquivos
    MAX_FILE_SIZE: int = 50 * 1024 * 1024  # 50MB
    ALLOWED_FILE_TYPES: list = [
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/jpg"
    ]
    MAX_FILES_PER_DEMANDA: int = 5
    UPLOAD_DIR: str = "uploads"
    
    # Paginação
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    # Email (opcional - configurar depois)
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: Optional[int] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    EMAILS_FROM_EMAIL: Optional[str] = None
    EMAILS_FROM_NAME: Optional[str] = None
    
    # Trello Integration
    TRELLO_API_KEY: Optional[str] = None
    TRELLO_TOKEN: Optional[str] = None
    TRELLO_BOARD_ID: Optional[str] = None
    TRELLO_LIST_ID: Optional[str] = None
    
    # WhatsApp/WPPConnect Integration (Deprecated - usar WHATSAPP_API_*)
    WPP_URL: Optional[str] = None
    WPP_INSTANCE: Optional[str] = None
    WPP_TOKEN: Optional[str] = None
    
    # WhatsApp API (Z-API)
    ZAPI_INSTANCE_ID: str = "3EABC3821EF52114B8836EDB289F0F12"
    ZAPI_TOKEN: str = "F9BFDFA1F0A75E79536CE12D"
    ZAPI_CLIENT_TOKEN: str = "F47cfa53858ee4869bf3e027187aa6742S"
    ZAPI_BASE_URL: str = "https://api.z-api.io"
    ZAPI_PHONE_NUMBER: str = "5585991042626"
    
    # Compatibilidade (mantido para não quebrar imports existentes)
    WHATSAPP_API_URL: str = f"https://api.z-api.io/instances/3EABC3821EF52114B8836EDB289F0F12/token/F9BFDFA1F0A75E79536CE12D"
    WHATSAPP_API_KEY: str = "F9BFDFA1F0A75E79536CE12D"
    
    # Google reCAPTCHA
    RECAPTCHA_SECRET_KEY: Optional[str] = None
    RECAPTCHA_SITE_KEY: Optional[str] = None  # Chave pública (para frontend)
    
    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_DEFAULT: str = "100/minute"
    RATE_LIMIT_AUTH: str = "5/minute"
    RATE_LIMIT_UPLOAD: str = "10/minute"
    RATE_LIMIT_REPORTS: str = "20/minute"
    
    # CSRF Protection
    CSRF_ENABLED: bool = True
    CSRF_TOKEN_EXPIRE_SECONDS: int = 3600  # 1 hora
    
    # Environment
    ENVIRONMENT: str = "development"
    FRONTEND_URL: str = "http://82.25.92.217:2022"  # URL do frontend em produção
    MAX_UPLOAD_SIZE: int = 52428800  # 50MB
    ALLOWED_EXTENSIONS: Union[str, list[str]] = ["pdf", "jpg", "jpeg", "png"]
    
    @field_validator('ALLOWED_EXTENSIONS', mode='before')
    @classmethod
    def parse_allowed_extensions(cls, v):
        """Converter string separada por vírgulas em lista"""
        if isinstance(v, str):
            # Remover espaços e dividir por vírgula
            return [ext.strip() for ext in v.split(',') if ext.strip()]
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Instância global das configurações
settings = Settings()

