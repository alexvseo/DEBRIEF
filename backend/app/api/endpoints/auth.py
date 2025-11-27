"""
Endpoints de autenticação
Login, refresh token, perfil do usuário
"""
from datetime import datetime, timedelta
from typing import Optional
import pyotp
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from fastapi import Body
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    verify_recaptcha,
    blacklist_token,
    hash_token,
    generate_totp_secret,
    verify_totp_code
)
from app.core.dependencies import get_current_user, get_current_active_user
from app.core.rate_limit import limiter
from app.models.user import User
from app.models.refresh_token import RefreshToken
from app.models.login_attempt import LoginAttempt
from app.schemas.user import (
    LoginResponse,
    UserResponse,
    UserCreate,
    UserUpdate,
    UserChangePassword,
    Token,
    RefreshTokenRequest,
    TwoFactorSetupResponse,
    TwoFactorCodeRequest,
    LogoutRequest
)

router = APIRouter()


def _client_ip(request: Request) -> str:
    """Extrair IP do cliente (IPv4/IPv6)."""
    if request.client and request.client.host:
        return request.client.host
    return "unknown"


async def _enforce_recaptcha(request: Request, context: str) -> None:
    """Validar reCAPTCHA se exigido pelo ambiente ou se o token vier preenchido."""
    token = request.headers.get("X-Recaptcha-Token")
    require = False
    
    if context == "login":
        require = settings.RECAPTCHA_REQUIRE_ON_LOGIN and bool(settings.RECAPTCHA_SECRET_KEY)
    elif context == "register":
        require = settings.RECAPTCHA_REQUIRE_ON_REGISTER and bool(settings.RECAPTCHA_SECRET_KEY)
    
    if require:
        if not token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="reCAPTCHA obrigatório"
            )
        is_valid = await verify_recaptcha(token)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="reCAPTCHA inválido"
            )
    elif token:
        is_valid = await verify_recaptcha(token)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="reCAPTCHA inválido"
            )


def _record_login_attempt(
    db: Session,
    *,
    username: str,
    ip: str,
    success: bool,
    user: Optional[User] = None,
    reason: Optional[str] = None,
    locked_out: bool = False,
) -> None:
    """Persistir tentativa de login para auditoria."""
    attempt = LoginAttempt(
        username=username,
        ip_address=ip,
        success=success,
        reason=reason,
        locked_out=locked_out
    )
    if user:
        attempt.user = user
    db.add(attempt)


def _handle_failed_login(
    db: Session,
    *,
    user: Optional[User],
    username: str,
    ip: str,
    reason: str
) -> None:
    """Atualizar contadores de falha e lançar a exceção apropriada."""
    now = datetime.utcnow()
    locked = False
    
    if user:
        user.failed_login_attempts += 1
        user.last_failed_login_at = now
        
        if user.failed_login_attempts >= settings.AUTH_MAX_FAILED_ATTEMPTS:
            user.locked_until = now + timedelta(minutes=settings.AUTH_LOCKOUT_MINUTES)
            user.failed_login_attempts = 0
            locked = True
        
        db.add(user)
    
    _record_login_attempt(
        db,
        username=username,
        ip=ip,
        success=False,
        user=user,
        reason=reason,
        locked_out=locked
    )
    db.commit()
    
    if locked and user and user.locked_until:
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail=f"Conta bloqueada temporariamente. Tente novamente após {user.locked_until.isoformat()}."
        )
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Usuário ou senha inválidos",
        headers={"WWW-Authenticate": "Bearer"},
    )


def _clear_lock_state(user: User) -> None:
    """Resetar contadores/locks após login bem-sucedido."""
    user.failed_login_attempts = 0
    user.last_failed_login_at = None
    user.locked_until = None


def _persist_refresh_token(db: Session, user: User, refresh_token: str, jti: str) -> RefreshToken:
    """Salvar refresh token rotativo."""
    record = RefreshToken(
        user_id=user.id,
        token_hash=hash_token(refresh_token),
        jti=jti,
        expires_at=datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        revoked=False
    )
    db.add(record)
    return record


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
    await _enforce_recaptcha(request, context="login")
    ip = _client_ip(request)
    
    # Buscar usuário por username ou email
    user = db.query(User).filter(
        (User.username == form_data.username) | (User.email == form_data.username)
    ).first()
    
    if user and user.locked_until and user.locked_until > datetime.utcnow():
        _record_login_attempt(
            db,
            username=form_data.username,
            ip=ip,
            success=False,
            user=user,
            reason="locked",
            locked_out=True
        )
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail="Conta temporariamente bloqueada por tentativas inválidas."
        )
    
    # Verificar credenciais
    if not user or not user.verify_password(form_data.password):
        _handle_failed_login(
            db,
            user=user,
            username=form_data.username,
            ip=ip,
            reason="invalid_credentials"
        )
    
    if not user.ativo:
        _record_login_attempt(
            db,
            username=form_data.username,
            ip=ip,
            success=False,
            user=user,
            reason="inactive"
        )
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário inativo"
        )
    
    # MFA (TOTP)
    if user.mfa_enabled:
        totp_code = request.headers.get("X-TOTP-Code")
        if not totp_code:
            _record_login_attempt(
                db,
                username=form_data.username,
                ip=ip,
                success=False,
                user=user,
                reason="totp_required"
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_412_PRECONDITION_FAILED,
                detail="Código TOTP obrigatório"
            )
        if not verify_totp_code(user.mfa_secret, totp_code):
            _record_login_attempt(
                db,
                username=form_data.username,
                ip=ip,
                success=False,
                user=user,
                reason="totp_invalid"
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Código TOTP inválido"
            )
    
    # Credenciais válidas
    _clear_lock_state(user)
    access_token = create_access_token(data={
        "sub": user.id,
        "username": user.username,
        "tipo": user.tipo
    })
    refresh_token, jti = create_refresh_token(data={
        "sub": user.id,
        "username": user.username
    })
    _persist_refresh_token(db, user, refresh_token, jti)
    _record_login_attempt(
        db,
        username=form_data.username,
        ip=ip,
        success=True,
        user=user,
        reason="ok"
    )
    db.commit()
    db.refresh(user)
    
    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserResponse.from_orm(user)
    )


@router.post("/refresh", response_model=LoginResponse)
async def refresh_tokens_endpoint(
    payload: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    """
    Rotacionar tokens usando refresh token válido.
    """
    refresh_payload = verify_token(
        payload.refresh_token,
        token_type="refresh",
        return_payload=True
    )
    
    if not refresh_payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token inválido"
        )
    
    user_id = refresh_payload.get("sub")
    jti = refresh_payload.get("jti")
    
    if not user_id or not jti:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token inválido"
        )
    
    token_entry = db.query(RefreshToken).filter(RefreshToken.jti == jti).first()
    if not token_entry or token_entry.revoked:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token revogado"
        )
    
    if token_entry.expires_at < datetime.utcnow():
        token_entry.revoked = True
        db.add(token_entry)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token expirado"
        )
    
    if hash_token(payload.refresh_token) != token_entry.token_hash:
        token_entry.revoked = True
        db.add(token_entry)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token inválido"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.ativo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário inválido"
        )
    
    access_token = create_access_token({
        "sub": user.id,
        "username": user.username,
        "tipo": user.tipo
    })
    new_refresh_token, new_jti = create_refresh_token({
        "sub": user.id,
        "username": user.username
    })
    
    token_entry.revoked = True
    token_entry.replaced_by_token = new_jti
    _persist_refresh_token(db, user, new_refresh_token, new_jti)
    db.add(token_entry)
    db.commit()
    db.refresh(user)
    
    return LoginResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
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


@router.post("/2fa/setup", response_model=TwoFactorSetupResponse)
async def setup_two_factor(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Gera/retorna segredo para configurar TOTP em apps autenticadores.
    """
    if not current_user.mfa_secret:
        current_user.mfa_secret = generate_totp_secret()
    
    current_user.mfa_enabled = False  # exige confirmação
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    
    label = current_user.email or current_user.username
    totp = pyotp.TOTP(current_user.mfa_secret, issuer=settings.MFA_ISSUER, name=label)
    
    return TwoFactorSetupResponse(
        secret=current_user.mfa_secret,
        otpauth_url=totp.provisioning_uri(name=label, issuer_name=settings.MFA_ISSUER)
    )


@router.post("/2fa/enable")
async def enable_two_factor(
    code_request: TwoFactorCodeRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Confirmar MFA com código válido.
    """
    if not current_user.mfa_secret:
        current_user.mfa_secret = generate_totp_secret()
    
    if not verify_totp_code(current_user.mfa_secret, code_request.code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Código TOTP inválido"
        )
    
    current_user.mfa_enabled = True
    db.add(current_user)
    db.commit()
    
    return {"message": "Autenticação em duas etapas habilitada."}


@router.post("/2fa/disable")
async def disable_two_factor(
    code_request: TwoFactorCodeRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Desativar MFA exigindo confirmação via TOTP.
    """
    if current_user.mfa_enabled:
        if not verify_totp_code(current_user.mfa_secret, code_request.code):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Código TOTP inválido"
            )
    
    current_user.mfa_enabled = False
    current_user.mfa_secret = None
    db.add(current_user)
    db.commit()
    
    return {"message": "Autenticação em duas etapas desativada."}


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    request: Request,
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
    await _enforce_recaptcha(request, context="register")
    
    # Verificar se username já existe
    existing_user_username = db.query(User).filter(
        User.username == user_data.username
    ).first()
    
    # Se usuário existe e está ATIVO, retornar erro
    if existing_user_username and existing_user_username.ativo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username já cadastrado"
        )
    
    # Verificar se email já existe
    existing_user_email = db.query(User).filter(
        User.email == user_data.email
    ).first()
    
    # Se usuário com email existe e está ATIVO, retornar erro
    if existing_user_email and existing_user_email.ativo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email já cadastrado"
        )
    
    # Se encontrou usuário INATIVO com mesmo username ou email, reativar e atualizar
    inactive_user = existing_user_username or existing_user_email
    
    if inactive_user and not inactive_user.ativo:
        # Reativar e atualizar usuário existente
        inactive_user.username = user_data.username
        inactive_user.email = user_data.email
        inactive_user.nome_completo = user_data.nome_completo
        inactive_user.tipo = user_data.tipo
        inactive_user.cliente_id = user_data.cliente_id
        inactive_user.set_password(user_data.password)
        inactive_user.ativo = True
        
        db.commit()
        db.refresh(inactive_user)
        
        return UserResponse.from_orm(inactive_user)
    
    # Se não existe ou não está inativo, criar novo usuário
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
    
    # Enviar notificação de cadastro via WhatsApp (se tiver WhatsApp cadastrado)
    try:
        from app.services.notification_whatsapp import NotificationWhatsAppService
        notification_service = NotificationWhatsAppService(db)
        # Passar a senha original para incluir na notificação
        notification_service.notificar_usuario_cadastrado(new_user, senha_original=user_data.password)
    except Exception as e:
        # Não falhar o registro se a notificação falhar
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Erro ao enviar notificação de cadastro para {new_user.username}: {str(e)}")
    
    return UserResponse.from_orm(new_user)


@router.post("/logout")
async def logout(
    request: Request,
    logout_data: Optional[LogoutRequest] = Body(default=None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
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
            token_invalidated = True
        else:
            token_invalidated = False
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Erro ao extrair token no logout: {e}")
        token_invalidated = False
    
    # Revogar refresh token se enviado
    if logout_data and logout_data.refresh_token:
        token_hash_value = hash_token(logout_data.refresh_token)
        refresh_entry = db.query(RefreshToken).filter(
            RefreshToken.token_hash == token_hash_value,
            RefreshToken.user_id == current_user.id,
            RefreshToken.revoked.is_(False)
        ).first()
        if refresh_entry:
            refresh_entry.revoked = True
            db.add(refresh_entry)
            db.commit()
    
    return {
        "message": "Logout realizado com sucesso",
        "token_invalidated": token_invalidated
    }
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Erro ao extrair token no logout: {e}")
    
    return {
        "message": "Logout realizado com sucesso",
        "token_invalidated": False,
        "note": "Token não pôde ser extraído, mas logout foi registrado"
    }

