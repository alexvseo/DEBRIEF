"""
Configuração do banco de dados
SQLAlchemy setup e gerenciamento de sessões
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator
from app.core.config import settings

# Criar engine do SQLAlchemy
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.DATABASE_ECHO,
    pool_pre_ping=True,  # Verifica conexão antes de usar
    pool_size=10,  # Número de conexões no pool
    max_overflow=20  # Conexões extras permitidas
)

# Criar SessionLocal
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


def get_db() -> Generator[Session, None, None]:
    """
    Dependency para obter sessão do banco de dados
    
    Yields:
        Session: Sessão do SQLAlchemy
        
    Example:
        @app.get("/users")
        def get_users(db: Session = Depends(get_db)):
            return db.query(User).all()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """
    Inicializar banco de dados
    Criar todas as tabelas
    """
    # Import all models here to ensure they are registered
    from app.models.base import Base
    from app.models import user, demanda  # noqa
    
    Base.metadata.create_all(bind=engine)

