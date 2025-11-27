"""
Configurações da aplicação e carregamento de segredos externos.
"""
from __future__ import annotations

import os
import secrets as secret_generator
from pathlib import Path
from typing import Optional, Union

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings

from app.core.secrets_loader import load_external_secrets

load_external_secrets()

BASE_DIR = Path(__file__).resolve().parents[2]
DEFAULT_UPLOAD_DIR = os.getenv("DEBRIEF_UPLOAD_DIR") or str(BASE_DIR / "uploads")


class Settings(BaseSettings):
    """
    Configurações centrais da aplicação.
    """
    
    # Ambiente
    APP_NAME: str = "DeBrief API"
    APP_VERSION: str = "1.1.0"
    ENVIRONMENT: str = "production"
    DEBUG: bool = False
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Banco
    DATABASE_URL: str = Field(
        default="postgresql://debrief_app:debrief_app@debrief_db:5432/dbrief"
    )
    DATABASE_ECHO: bool = False
    
    # Autenticação & criptografia
    SECRET_KEY: str = Field(default_factory=lambda: secret_generator.token_urlsafe(64))
    ENCRYPTION_KEY: Optional[str] = None
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    AUTH_MAX_FAILED_ATTEMPTS: int = 5
    AUTH_LOCKOUT_MINUTES: int = 15
    
    # Rate limiting / Redis
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_DEFAULT: str = "100/minute"
    RATE_LIMIT_AUTH: str = "5/minute"
    RATE_LIMIT_UPLOAD: str = "10/minute"
    RATE_LIMIT_REPORTS: str = "20/minute"
    RATE_LIMIT_STORAGE_URI: str = "memory://"
    REDIS_URL: Optional[str] = None
    TOKEN_BLACKLIST_PREFIX: str = "security:jwt:blacklist"
    CSRF_REDIS_PREFIX: str = "security:csrf"
    
    # CORS
    CORS_ORIGINS: Union[str, list[str]] = [
        "http://localhost:5173",
        "http://localhost:3000",
    ]
    FRONTEND_URL: str = "http://localhost:5173"
    
    # Uploads
    MAX_FILE_SIZE: int = 50 * 1024 * 1024
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024
    ALLOWED_EXTENSIONS: Union[str, list[str]] = ["pdf", "jpg", "jpeg", "png"]
    MAX_FILES_PER_DEMANDA: int = 5
    UPLOAD_DIR: str = DEFAULT_UPLOAD_DIR
    ANTIVIRUS_ENABLED: bool = False
    ANTIVIRUS_COMMAND: str = "clamscan --no-summary --stdout"
    
    # Paginação
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    # Email
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: Optional[int] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    EMAILS_FROM_EMAIL: Optional[str] = None
    EMAILS_FROM_NAME: Optional[str] = None
    
    # Integrações Trello
    TRELLO_API_KEY: Optional[str] = None
    TRELLO_TOKEN: Optional[str] = None
    TRELLO_BOARD_ID: Optional[str] = None
    TRELLO_LIST_ID: Optional[str] = None
    
    # Integrações WhatsApp
    ZAPI_INSTANCE_ID: Optional[str] = None
    ZAPI_TOKEN: Optional[str] = None
    ZAPI_CLIENT_TOKEN: Optional[str] = None
    ZAPI_BASE_URL: str = "https://api.z-api.io"
    ZAPI_PHONE_NUMBER: Optional[str] = None
    WHATSAPP_API_URL: str = "http://localhost:21465"
    WHATSAPP_API_KEY: Optional[str] = None
    WPP_URL: Optional[str] = None
    WPP_INSTANCE: Optional[str] = None
    WPP_TOKEN: Optional[str] = None
    
    # reCAPTCHA
    RECAPTCHA_SECRET_KEY: Optional[str] = None
    RECAPTCHA_SITE_KEY: Optional[str] = None
    RECAPTCHA_REQUIRE_ON_LOGIN: bool = False
    RECAPTCHA_REQUIRE_ON_REGISTER: bool = False
    
    # CSRF
    CSRF_ENABLED: bool = True
    CSRF_TOKEN_EXPIRE_SECONDS: int = 3600
    
    # MFA
    MFA_ISSUER: str = "DeBrief"
    MFA_TOTP_WINDOW: int = 1
    
    # Senhas
    PWD_CONTEXT_SCHEMES: list[str] = ["bcrypt"]
    PWD_CONTEXT_DEPRECATED: str = "auto"
    
    # Segredos externos
    SECRETS_PROVIDER: Optional[str] = Field(default=None, alias="DEBRIEF_SECRETS_PROVIDER")
    SECRETS_FILE: Optional[str] = Field(default=None, alias="DEBRIEF_SECRETS_FILE")
    
    @field_validator('ALLOWED_EXTENSIONS', mode='before')
    @classmethod
    def parse_allowed_extensions(cls, value):
        if isinstance(value, str):
            return [ext.strip().lower() for ext in value.split(',') if ext.strip()]
        return value
    
    @field_validator('CORS_ORIGINS', mode='before')
    @classmethod
    def parse_cors(cls, value):
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(',') if origin.strip()]
        return value
    
    @field_validator('UPLOAD_DIR', mode='before')
    @classmethod
    def ensure_upload_dir(cls, value):
        return value or DEFAULT_UPLOAD_DIR
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


settings = Settings()

