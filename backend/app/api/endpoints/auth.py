"""
Endpoints de autenticação
Login, refresh token, perfil do usuário
"""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    verify_recaptcha,
    blacklist_token
)
from app.core.dependencies import get_current_user, get_current_active_user
from app.core.rate_limit import limiter
from app.models.user import User
from app.schemas.user import (
    LoginResponse,
    UserResponse,
    UserCreate,
    UserUpdate,
    UserChangePassword,
    Token
)

router = APIRouter()


@router.post("/login", response_model=LoginResponse)
@limiter.limit("5/minute")  # Rate limit: 5 tentativas por minuto
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Login de usuário com reCAPTCHA (opcional)
    
    OAuth2 compatible token login, get an access token for future requests
    
    Args:
        request: Request object (para acessar headers)
        form_data: Dados de login (username e password)
        db: Sessão do banco de dados
        
    Returns:
        LoginResponse: Token de acesso e dados do usuário
        
    Raises:
        HTTPException: Se credenciais inválidas ou reCAPTCHA inválido
    """
    # Verificar reCAPTCHA se token fornecido via header
    recaptcha_token = request.headers.get("X-Recaptcha-Token")
    if recaptcha_token:
        is_valid = await verify_recaptcha(recaptcha_token)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="reCAPTCHA inválido"
            )
    
    # Buscar usuário por username ou email
    user = db.query(User).filter(
        (User.username == form_data.username) | (User.email == form_data.username)
    ).first()
    
    # Verificar se usuário existe e senha está correta
    if not user or not user.verify_password(form_data.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário ou senha inválidos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verificar se usuário está ativo
    if not user.ativo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário inativo"
        )
    
    # Criar token de acesso
    access_token = create_access_token(data={
        "sub": user.id,
        "username": user.username,
        "tipo": user.tipo.value
    })
    
    # Retornar token e dados do usuário
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.from_orm(user)
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """
    Obter perfil do usuário autenticado
    
    Args:
        current_user: Usuário autenticado (do token)
        
    Returns:
        UserResponse: Dados do usuário
    """
    return UserResponse.from_orm(current_user)


@router.put("/me", response_model=UserResponse)
async def update_current_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Atualizar perfil do usuário autenticado
    
    Args:
        user_update: Dados para atualizar
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        UserResponse: Usuário atualizado
    """
    # Atualizar campos fornecidos
    update_data = user_update.dict(exclude_unset=True)
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return UserResponse.from_orm(current_user)


@router.post("/change-password")
async def change_password(
    password_data: UserChangePassword,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Alterar senha do usuário autenticado
    
    Args:
        password_data: Senha atual e nova senha
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        dict: Mensagem de sucesso
        
    Raises:
        HTTPException: Se senha atual incorreta
    """
    # Verificar senha atual
    if not current_user.verify_password(password_data.current_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Senha atual incorreta"
        )
    
    # Atualizar senha
    current_user.set_password(password_data.new_password)
    db.commit()
    
    return {"message": "Senha alterada com sucesso"}


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """
    Registrar novo usuário (público)
    
    Args:
        user_data: Dados do novo usuário
        db: Sessão do banco
        
    Returns:
        UserResponse: Usuário criado
        
    Raises:
        HTTPException: Se username ou email já existe
    """
    # Verificar se username já existe
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username já cadastrado"
        )
    
    # Verificar se email já existe
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email já cadastrado"
        )
    
    # Criar novo usuário
    new_user = User(
        username=user_data.username,
        email=user_data.email,
        nome_completo=user_data.nome_completo,
        tipo=user_data.tipo,
        cliente_id=user_data.cliente_id
    )
    new_user.set_password(user_data.password)
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return UserResponse.from_orm(new_user)


@router.post("/logout")
async def logout(
    request: Request,
    current_user: User = Depends(get_current_active_user)
):
    """
    Logout de usuário
    
    Invalida o token JWT atual adicionando-o à blacklist.
    
    Args:
        request: Request object (para extrair token)
        current_user: Usuário autenticado
        
    Returns:
        dict: Mensagem de sucesso
    """
    # Extrair token do header Authorization
    try:
        authorization = request.headers.get("Authorization", "")
        if authorization.startswith("Bearer "):
            token = authorization.replace("Bearer ", "")
            blacklist_token(token)
            return {
                "message": "Logout realizado com sucesso",
                "token_invalidated": True
            }
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Erro ao extrair token no logout: {e}")
    
    return {
        "message": "Logout realizado com sucesso",
        "token_invalidated": False,
        "note": "Token não pôde ser extraído, mas logout foi registrado"
    }

