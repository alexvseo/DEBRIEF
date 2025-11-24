"""
Dependencies FastAPI
Funções de dependência reutilizáveis
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from typing import Optional
from app.core.database import get_db
from app.core.security import verify_token
from app.models.user import User
from app.schemas.user import TokenData

# OAuth2 scheme (extrai token do header Authorization)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Obter usuário atual do token JWT
    
    Args:
        token: Token JWT do header Authorization
        db: Sessão do banco de dados
        
    Returns:
        User: Usuário autenticado
        
    Raises:
        HTTPException: Se token inválido ou usuário não encontrado
        
    Example:
        @app.get("/me")
        def get_me(current_user: User = Depends(get_current_user)):
            return current_user
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    # Verificar e decodificar token
    user_id = verify_token(token, token_type="access")
    
    if user_id is None:
        raise credentials_exception
    
    # Buscar usuário no banco
    user = db.query(User).filter(User.id == user_id).first()
    
    if user is None:
        raise credentials_exception
    
    # Verificar se usuário está ativo
    if not user.ativo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário inativo"
        )
    
    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Obter usuário ativo atual
    
    Args:
        current_user: Usuário do token
        
    Returns:
        User: Usuário ativo
        
    Raises:
        HTTPException: Se usuário inativo
    """
    if not current_user.ativo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuário inativo"
        )
    return current_user


async def get_current_master_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Obter usuário master atual (admin)
    
    Args:
        current_user: Usuário do token
        
    Returns:
        User: Usuário master
        
    Raises:
        HTTPException: Se não for master
        
    Example:
        @app.get("/admin")
        def admin_panel(user: User = Depends(get_current_master_user)):
            # Somente masters podem acessar
    """
    if not current_user.is_master():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permissões insuficientes. Apenas usuários master podem acessar."
        )
    return current_user


def get_optional_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """
    Obter usuário opcional (não obrigatório)
    Útil para endpoints que funcionam com ou sem autenticação
    
    Args:
        token: Token JWT (opcional)
        db: Sessão do banco
        
    Returns:
        User ou None: Usuário se autenticado, None caso contrário
    """
    if not token:
        return None
    
    user_id = verify_token(token, token_type="access")
    
    if user_id is None:
        return None
    
    return db.query(User).filter(User.id == user_id).first()


# Alias para compatibilidade
require_master = get_current_master_user

