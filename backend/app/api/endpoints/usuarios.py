"""
Endpoints para gerenciamento de usuários (Admin)
CRUD completo - Apenas Master pode gerenciar
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import logging

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_master
from app.models import User
from app.models.user import TipoUsuario
from app.schemas.user import (
    UserCreate,
    UserUpdate,
    UserResponse,
    UserChangePassword,
    UserNotificationSettings
)
from app.services.notification_whatsapp import NotificationWhatsAppService

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/", response_model=List[UserResponse])
def listar_usuarios(
    skip: int = Query(0, ge=0, description="Registros a pular"),
    limit: int = Query(100, ge=1, le=100, description="Limite de registros"),
    apenas_ativos: bool = Query(True, description="Apenas usuários ativos"),
    tipo: Optional[TipoUsuario] = Query(None, description="Filtrar por tipo"),
    cliente_id: Optional[str] = Query(None, description="Filtrar por cliente"),
    busca: Optional[str] = Query(None, description="Buscar por nome ou email"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Lista todos os usuários (apenas master)
    
    **Permissão:** Master apenas
    
    **Filtros:**
    - apenas_ativos: Filtrar apenas usuários ativos
    - tipo: Filtrar por tipo (master/cliente)
    - cliente_id: Filtrar por cliente
    - busca: Buscar por nome ou email (case insensitive)
    - skip/limit: Paginação
    
    **Exemplo:**
    ```
    GET /api/usuarios?apenas_ativos=true&tipo=cliente&limit=50
    ```
    """
    query = db.query(User)
    
    # Filtro: apenas ativos
    if apenas_ativos:
        query = query.filter(User.ativo == True)
    
    # Filtro: por tipo
    if tipo:
        query = query.filter(User.tipo == tipo)
    
    # Filtro: por cliente
    if cliente_id:
        query = query.filter(User.cliente_id == cliente_id)
    
    # Filtro: busca por nome ou email
    if busca:
        query = query.filter(
            (User.nome_completo.ilike(f"%{busca}%")) |
            (User.email.ilike(f"%{busca}%")) |
            (User.username.ilike(f"%{busca}%"))
        )
    
    # Ordenação e paginação
    usuarios = query.order_by(User.created_at.desc()).offset(skip).limit(limit).all()
    
    return [UserResponse.from_orm(u) for u in usuarios]


@router.get("/me", response_model=UserResponse)
def obter_perfil_atual(
    current_user: User = Depends(get_current_user)
):
    """
    Retorna informações do usuário autenticado
    
    **Permissão:** Qualquer usuário autenticado
    
    **Retorna:** Dados completos do usuário logado (sem senha)
    """
    return UserResponse.from_orm(current_user)


@router.put("/me/notificacoes", response_model=UserResponse)
def atualizar_configuracoes_notificacao(
    settings: UserNotificationSettings,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Atualiza as configurações de notificação do usuário autenticado
    
    **Permissão:** Qualquer usuário autenticado (atualiza apenas sua própria conta)
    
    **Body:** (todos campos opcionais)
    ```json
    {
        "whatsapp": "5585996039026",
        "receber_notificacoes": true
    }
    ```
    
    **Exemplo de uso:**
    - Para adicionar/atualizar WhatsApp: envie o número com código do país
    - Para desabilitar notificações: envie receber_notificacoes=false
    - Para remover WhatsApp: envie whatsapp="" (string vazia)
    """
    # Atualizar apenas campos fornecidos
    update_data = settings.dict(exclude_unset=True)
    
    if 'whatsapp' in update_data:
        # Permitir string vazia para remover WhatsApp
        if update_data['whatsapp'] == '':
            current_user.whatsapp = None
        else:
            current_user.whatsapp = update_data['whatsapp']
    
    if 'receber_notificacoes' in update_data:
        current_user.receber_notificacoes = update_data['receber_notificacoes']
    
    db.commit()
    db.refresh(current_user)
    
    return UserResponse.from_orm(current_user)


@router.get("/{usuario_id}", response_model=UserResponse)
def buscar_usuario(
    usuario_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Busca um usuário por ID
    
    **Permissão:** Master apenas
    """
    usuario = db.query(User).filter(User.id == usuario_id).first()
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado"
        )
    
    return UserResponse.from_orm(usuario)


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def criar_usuario(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Cria um novo usuário
    
    **Permissão:** Master apenas
    
    **Body:**
    - username: Nome de usuário único
    - email: Email único
    - nome_completo: Nome completo
    - password: Senha (mínimo 6 caracteres)
    - tipo: Tipo (master/cliente)
    - cliente_id: ID do cliente (obrigatório se tipo=cliente)
    """
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
        inactive_user.set_password(user_data.password)
        inactive_user.ativo = True
        
        # Atualizar WhatsApp se fornecido
        if hasattr(user_data, 'whatsapp') and user_data.whatsapp:
            inactive_user.whatsapp = user_data.whatsapp
        if hasattr(user_data, 'receber_notificacoes'):
            inactive_user.receber_notificacoes = user_data.receber_notificacoes
        
        # Atualizar cliente_id
        if user_data.tipo == TipoUsuario.MASTER:
            inactive_user.cliente_id = None
        elif user_data.tipo == TipoUsuario.CLIENTE:
            if not user_data.cliente_id or user_data.cliente_id == '':
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="cliente_id é obrigatório para usuários do tipo 'cliente'"
                )
            inactive_user.cliente_id = user_data.cliente_id
        
        db.commit()
        db.refresh(inactive_user)
        
        # Enviar notificação de cadastro via WhatsApp (se tiver WhatsApp cadastrado)
        try:
            notification_service = NotificationWhatsAppService(db)
            notification_service.notificar_usuario_cadastrado(inactive_user)
        except Exception as e:
            # Não falhar a reativação se a notificação falhar
            logger.warning(f"Erro ao enviar notificação de cadastro para {inactive_user.username}: {str(e)}")
        
        return UserResponse.from_orm(inactive_user)
    
    # Se não existe ou não está inativo, criar novo usuário
    # Validar cliente_id se tipo for cliente
    if user_data.tipo == TipoUsuario.CLIENTE and not user_data.cliente_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="cliente_id é obrigatório para usuários do tipo 'cliente'"
        )
    
    # Preparar dados para criação do usuário
    user_kwargs = {
        'username': user_data.username,
        'email': user_data.email,
        'nome_completo': user_data.nome_completo,
        'tipo': user_data.tipo
    }
    
    # Adicionar WhatsApp se fornecido
    if hasattr(user_data, 'whatsapp') and user_data.whatsapp:
        user_kwargs['whatsapp'] = user_data.whatsapp
    if hasattr(user_data, 'receber_notificacoes'):
        user_kwargs['receber_notificacoes'] = user_data.receber_notificacoes
    
    if user_data.tipo == TipoUsuario.MASTER:
        user_kwargs['cliente_id'] = None
    elif user_data.tipo == TipoUsuario.CLIENTE:
        if not user_data.cliente_id or user_data.cliente_id == '':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="cliente_id é obrigatório para usuários do tipo 'cliente'"
            )
        user_kwargs['cliente_id'] = user_data.cliente_id
    
    # Criar novo usuário
    new_user = User(**user_kwargs)
    new_user.set_password(user_data.password)
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Enviar notificação de cadastro via WhatsApp (se tiver WhatsApp cadastrado)
    try:
        notification_service = NotificationWhatsAppService(db)
        notification_service.notificar_usuario_cadastrado(new_user)
    except Exception as e:
        # Não falhar a criação do usuário se a notificação falhar
        logger.warning(f"Erro ao enviar notificação de cadastro para {new_user.username}: {str(e)}")
    
    return UserResponse.from_orm(new_user)


@router.put("/{usuario_id}", response_model=UserResponse)
def atualizar_usuario(
    usuario_id: str,
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualiza um usuário existente
    
    **Permissão:** Master apenas
    
    **Body:** (todos campos opcionais)
    - username: Novo username
    - email: Novo email
    - nome_completo: Novo nome
    - tipo: Novo tipo
    - cliente_id: Novo cliente
    """
    usuario = db.query(User).filter(User.id == usuario_id).first()
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado"
        )
    
    # Atualizar campos fornecidos
    update_data = user_update.dict(exclude_unset=True)
    
    # Verificar username único (apenas usuários ativos)
    if 'username' in update_data and update_data['username'] != usuario.username:
        existing = db.query(User).filter(
            User.username == update_data['username'],
            User.ativo == True
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username já cadastrado"
            )
    
    # Verificar email único (apenas usuários ativos)
    if 'email' in update_data and update_data['email'] != usuario.email:
        existing = db.query(User).filter(
            User.email == update_data['email'],
            User.ativo == True
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email já cadastrado"
            )
    
    # Se tipo for master, garantir que cliente_id seja None
    if 'tipo' in update_data and update_data['tipo'] == TipoUsuario.MASTER:
        update_data['cliente_id'] = None
    
    # Validar cliente_id se tipo for cliente
    if 'tipo' in update_data and update_data['tipo'] == TipoUsuario.CLIENTE:
        if not update_data.get('cliente_id'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="cliente_id é obrigatório para usuários do tipo 'cliente'"
            )
    
    # Processar senha separadamente se fornecida
    if 'password' in update_data and update_data['password']:
        usuario.set_password(update_data['password'])
        update_data.pop('password')  # Remover para não tentar setar diretamente
    
    # Atualizar demais campos
    for field, value in update_data.items():
        setattr(usuario, field, value)
    
    db.commit()
    db.refresh(usuario)
    
    return UserResponse.from_orm(usuario)


@router.delete("/{usuario_id}", status_code=status.HTTP_204_NO_CONTENT)
def desativar_usuario(
    usuario_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Desativa um usuário (soft delete)
    
    **Permissão:** Master apenas
    
    **Nota:** O usuário não é deletado do banco, apenas marcado como inativo.
    """
    usuario = db.query(User).filter(User.id == usuario_id).first()
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado"
        )
    
    # Impedir auto-desativação
    if usuario.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Você não pode desativar sua própria conta"
        )
    
    usuario.ativo = False
    db.commit()
    
    return None


@router.post("/{usuario_id}/reativar", response_model=UserResponse)
def reativar_usuario(
    usuario_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Reativa um usuário desativado
    
    **Permissão:** Master apenas
    """
    usuario = db.query(User).filter(User.id == usuario_id).first()
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado"
        )
    
    if usuario.ativo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuário já está ativo"
        )
    
    usuario.ativo = True
    db.commit()
    db.refresh(usuario)
    
    return UserResponse.from_orm(usuario)


@router.delete("/{usuario_id}/permanente", status_code=status.HTTP_204_NO_CONTENT)
def excluir_usuario_permanente(
    usuario_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Exclui um usuário permanentemente do banco de dados (hard delete)
    
    **Permissão:** Master apenas
    
    **ATENÇÃO:** Esta operação é irreversível! O usuário será completamente removido do sistema.
    
    **Nota:** Recomenda-se usar a desativação (soft delete) ao invés de exclusão permanente
              para manter histórico e integridade referencial.
    """
    usuario = db.query(User).filter(User.id == usuario_id).first()
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado"
        )
    
    # Impedir auto-exclusão
    if usuario.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Você não pode excluir sua própria conta"
        )
    
    # Verificar se usuário tem demandas associadas
    from app.models.demanda import Demanda
    demandas_count = db.query(Demanda).filter(Demanda.usuario_id == usuario_id).count()
    
    if demandas_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Não é possível excluir este usuário pois ele possui {demandas_count} demanda(s) associada(s). Desative o usuário ao invés de excluí-lo."
        )
    
    # Deletar permanentemente
    db.delete(usuario)
    db.commit()
    
    return None


@router.post("/{usuario_id}/reset-password", status_code=status.HTTP_200_OK)
def resetar_senha(
    usuario_id: str,
    password_data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Reseta a senha de um usuário
    
    **Permissão:** Master apenas
    
    **Body:**
    ```json
    {
        "new_password": "novaSenha123"
    }
    ```
    """
    usuario = db.query(User).filter(User.id == usuario_id).first()
    
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado"
        )
    
    new_password = password_data.get('new_password')
    
    if not new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Campo 'new_password' é obrigatório"
        )
    
    if len(new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Senha deve ter no mínimo 6 caracteres"
        )
    
    usuario.set_password(new_password)
    db.commit()
    
    return {
        "message": "Senha resetada com sucesso",
        "usuario_id": usuario_id
    }


@router.get("/estatisticas/geral")
def estatisticas_usuarios(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Retorna estatísticas gerais dos usuários
    
    **Permissão:** Master apenas
    
    **Retorna:**
    - total: Total de usuários
    - ativos: Usuários ativos
    - inativos: Usuários inativos
    - masters: Usuários master
    - clientes: Usuários cliente
    """
    total = db.query(User).count()
    ativos = db.query(User).filter(User.ativo == True).count()
    inativos = db.query(User).filter(User.ativo == False).count()
    masters = db.query(User).filter(User.tipo == TipoUsuario.MASTER).count()
    clientes = db.query(User).filter(User.tipo == TipoUsuario.CLIENTE).count()
    
    return {
        "total": total,
        "ativos": ativos,
        "inativos": inativos,
        "masters": masters,
        "clientes": clientes
    }

