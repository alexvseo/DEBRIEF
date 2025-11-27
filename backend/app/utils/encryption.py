"""
Utilitário para criptografar/decriptar campos sensíveis via Fernet.
"""
from sqlalchemy.types import TypeDecorator, String
from cryptography.fernet import Fernet, InvalidToken
from app.core.config import settings


class EncryptedString(TypeDecorator):
    """
    TypeDecorator que criptografa strings usando Fernet antes de persistir.
    """
    impl = String
    cache_ok = True
    
    def __init__(self, length: int = 512):
        super().__init__(length=length)
        key = settings.ENCRYPTION_KEY.encode() if settings.ENCRYPTION_KEY else None
        self._fernet = Fernet(key) if key else None
    
    def process_bind_param(self, value, dialect):
        if value is None or not self._fernet:
            return value
        if isinstance(value, str):
            return self._fernet.encrypt(value.encode()).decode()
        return value
    
    def process_result_value(self, value, dialect):
        if value is None or not self._fernet:
            return value
        try:
            return self._fernet.decrypt(value.encode()).decode()
        except InvalidToken:
            # Valor legacy em texto plano
            return value

