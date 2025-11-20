"""
Endpoints para gerenciamento de usuários (Admin)
CRUD completo - Apenas Master pode gerenciar
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_master
from app.models import User
from app.models.user import TipoUsuario
from app.schemas.user import (
    UserCreate,
    UserUpdate,
    UserResponse,
    UserChangePassword
)

router = APIRouter()


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
    
    # Validar cliente_id se tipo for cliente
    if user_data.tipo == TipoUsuario.CLIENTE and not user_data.cliente_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="cliente_id é obrigatório para usuários do tipo 'cliente'"
        )
    
    # Preparar dados para criação do usuário
    # Se tipo for master, garantir que cliente_id seja None (não string vazia)
    user_kwargs = {
        'username': user_data.username,
        'email': user_data.email,
        'nome_completo': user_data.nome_completo,
        'tipo': user_data.tipo
    }
    
    if user_data.tipo == TipoUsuario.MASTER:
        # Master não deve ter cliente_id
        user_kwargs['cliente_id'] = None
    elif user_data.tipo == TipoUsuario.CLIENTE:
        # Cliente deve ter cliente_id
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
    
    # Verificar username único
    if 'username' in update_data and update_data['username'] != usuario.username:
        if db.query(User).filter(User.username == update_data['username']).first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username já cadastrado"
            )
    
    # Verificar email único
    if 'email' in update_data and update_data['email'] != usuario.email:
        if db.query(User).filter(User.email == update_data['email']).first():
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

