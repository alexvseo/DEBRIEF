"""
Classe base para todos os modelos SQLAlchemy
Define campos comuns (ID, timestamps) e métodos auxiliares
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from sqlalchemy.ext.declarative import declarative_base

# Criar classe base para todos os modelos
Base = declarative_base()


class BaseModel(Base):
    """
    Classe abstrata com campos comuns a todos os modelos
    Todos os modelos do sistema herdarão desta classe
    
    Fornece:
    - id (UUID): Chave primária universal
    - created_at: Timestamp de criação automático
    - updated_at: Timestamp de atualização automático
    - to_dict(): Método para converter modelo em dicionário
    """
    __abstract__ = True  # Não cria tabela no banco
    
    # UUID como chave primária (mais seguro que int sequencial)
    # UUID evita enumeration attacks e é globalmente único
    id = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True,
        comment="Identificador único universal (UUID v4)"
    )
    
    # Timestamp de criação (automático pelo banco de dados)
    # server_default garante que o valor seja gerado pelo PostgreSQL
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        comment="Data e hora de criação do registro"
    )
    
    # Timestamp de última atualização (automático)
    # onupdate atualiza automaticamente quando o registro é modificado
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
        comment="Data e hora da última atualização"
    )
    
    def to_dict(self):
        """
        Converte o modelo em dicionário
        
        Útil para:
        - Serialização JSON
        - Logs
        - Debugging
        
        Returns:
            dict: Dicionário com todos os campos do modelo
        
        Exemplo:
            user = User(username="joao", email="joao@example.com")
            print(user.to_dict())
            # {'id': '...', 'username': 'joao', 'email': 'joao@example.com', ...}
        """
        result = {}
        for column in self.__table__.columns:
            value = getattr(self, column.name)
            
            # Converter datetime para string ISO 8601
            if isinstance(value, datetime):
                result[column.name] = value.isoformat()
            # Converter enums para string
            elif hasattr(value, 'value'):
                result[column.name] = value.value
            else:
                result[column.name] = value
        
        return result
    
    def update_from_dict(self, data: dict):
        """
        Atualiza o modelo a partir de um dicionário
        
        Args:
            data (dict): Dicionário com campos a serem atualizados
        
        Exemplo:
            user.update_from_dict({'nome_completo': 'João Silva'})
        """
        for key, value in data.items():
            if hasattr(self, key) and key not in ['id', 'created_at']:
                setattr(self, key, value)
    
    def __repr__(self):
        """
        Representação string do objeto para debugging
        """
        return f"<{self.__class__.__name__}(id='{self.id}')>"

