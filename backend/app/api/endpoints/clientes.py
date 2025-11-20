"""
Endpoints para gerenciamento de clientes
CRUD completo - Apenas Master pode gerenciar
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_master
from app.models import Cliente, User
from app.schemas import (
    ClienteCreate,
    ClienteUpdate,
    ClienteResponse,
    ClienteResponseComplete
)

router = APIRouter()


@router.get("/", response_model=List[ClienteResponse])
def listar_clientes(
    skip: int = Query(0, ge=0, description="Registros a pular"),
    limit: int = Query(100, ge=1, le=100, description="Limite de registros"),
    apenas_ativos: bool = Query(True, description="Apenas clientes ativos"),
    busca: Optional[str] = Query(None, description="Buscar por nome"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Lista todos os clientes (apenas master)
    
    **Permissão:** Master apenas
    
    **Filtros:**
    - apenas_ativos: Filtrar apenas clientes ativos
    - busca: Buscar por nome (case insensitive)
    - skip/limit: Paginação
    
    **Exemplo:**
    ```
    GET /api/clientes?apenas_ativos=true&busca=prefeitura&limit=20
    ```
    """
    query = db.query(Cliente)
    
    # Filtro: apenas ativos
    if apenas_ativos:
        query = query.filter(Cliente.ativo == True)
    
    # Filtro: busca por nome
    if busca:
        query = query.filter(Cliente.nome.ilike(f"%{busca}%"))
    
    # Ordenação e paginação
    clientes = query.order_by(Cliente.nome).offset(skip).limit(limit).all()
    
    # Contar demandas para cada cliente usando query explícita
    from app.models import Demanda
    clientes_resposta = []
    for cliente in clientes:
        total_demandas = db.query(Demanda).filter(Demanda.cliente_id == cliente.id).count()
        # Criar resposta usando to_dict e adicionar total_demandas
        cliente_data = cliente.to_dict()
        cliente_data['total_demandas'] = total_demandas
        # Criar objeto ClienteResponse com os dados
        clientes_resposta.append(ClienteResponse(**cliente_data))
    
    return clientes_resposta


@router.get("/{cliente_id}", response_model=ClienteResponseComplete)
def buscar_cliente(
    cliente_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Busca cliente por ID com estatísticas completas
    
    **Permissão:** Master apenas
    
    **Retorna:**
    - Dados do cliente
    - Total de usuários
    - Total de secretarias
    - Total de demandas
    """
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {cliente_id} não encontrado"
        )
    
    # Contar demandas usando query explícita para evitar erro de enum
    from app.models import Demanda
    total_demandas = db.query(Demanda).filter(Demanda.cliente_id == cliente.id).count()
    
    # Montar resposta completa
    response = ClienteResponseComplete(
        **cliente.to_dict(),
        total_usuarios=len(cliente.usuarios) if cliente.usuarios else 0,
        total_secretarias=len(cliente.secretarias) if cliente.secretarias else 0,
        total_demandas=total_demandas,
        tem_whatsapp=bool(cliente.whatsapp_group_id),
        tem_trello=bool(cliente.trello_member_id)
    )
    
    return response


@router.post("/", response_model=ClienteResponse, status_code=status.HTTP_201_CREATED)
def criar_cliente(
    cliente_data: ClienteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Cria um novo cliente
    
    **Permissão:** Master apenas
    
    **Validações:**
    - Nome único (não pode duplicar)
    - Nome mínimo 3 caracteres
    - WhatsApp group ID no formato correto (opcional)
    
    **Exemplo:**
    ```json
    {
        "nome": "Prefeitura Municipal de São Paulo",
        "whatsapp_group_id": "5511999999999-1234567890@g.us",
        "trello_member_id": "abc123def456",
        "ativo": true
    }
    ```
    """
    # Verificar se já existe cliente com esse nome
    existe = db.query(Cliente).filter(
        Cliente.nome.ilike(cliente_data.nome)
    ).first()
    
    if existe:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cliente com nome '{cliente_data.nome}' já existe"
        )
    
    # Criar cliente
    novo_cliente = Cliente(**cliente_data.model_dump())
    
    db.add(novo_cliente)
    db.commit()
    db.refresh(novo_cliente)
    
    return novo_cliente


@router.put("/{cliente_id}", response_model=ClienteResponse)
def atualizar_cliente(
    cliente_id: str,
    cliente_data: ClienteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualiza dados de um cliente
    
    **Permissão:** Master apenas
    
    **Campos atualizáveis:**
    - nome
    - whatsapp_group_id
    - trello_member_id
    - ativo
    
    **Observações:**
    - Ao desativar, usuários vinculados não poderão mais fazer login
    - Somente campos enviados serão atualizados
    """
    # Buscar cliente
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {cliente_id} não encontrado"
        )
    
    # Verificar nome duplicado (se estiver atualizando nome)
    if cliente_data.nome and cliente_data.nome != cliente.nome:
        existe = db.query(Cliente).filter(
            Cliente.nome.ilike(cliente_data.nome),
            Cliente.id != cliente_id
        ).first()
        
        if existe:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cliente com nome '{cliente_data.nome}' já existe"
            )
    
    # Atualizar campos
    update_data = cliente_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(cliente, field, value)
    
    db.commit()
    db.refresh(cliente)
    
    return cliente


@router.delete("/{cliente_id}/permanente", status_code=status.HTTP_204_NO_CONTENT)
def deletar_cliente_permanente(
    cliente_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deleta um cliente permanentemente do banco (hard delete)
    
    **Permissão:** Master apenas
    
    **Atenção:**
    - Esta ação é IRREVERSÍVEL
    - Cliente será removido permanentemente do banco
    - Se houver demandas vinculadas, o campo cliente_id será definido como NULL
    - Se houver secretarias vinculadas, elas serão deletadas em cascata (CASCADE)
    - Se houver usuários vinculados, o campo cliente_id será definido como NULL
    - Use com cuidado!
    """
    # Buscar cliente
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {cliente_id} não encontrado"
        )
    
    # Verificar se tem demandas vinculadas
    from app.models import Demanda
    total_demandas = db.query(Demanda).filter(Demanda.cliente_id == cliente_id).count()
    
    # Se houver demandas vinculadas, definir cliente_id como NULL antes de deletar
    if total_demandas > 0:
        # Atualizar todas as demandas vinculadas para ter cliente_id = NULL
        db.query(Demanda).filter(Demanda.cliente_id == cliente_id).update(
            {Demanda.cliente_id: None},
            synchronize_session=False
        )
        db.flush()  # Aplicar mudanças sem commit
    
    # Verificar se tem usuários vinculados
    from app.models.user import User
    usuarios_vinculados = db.query(User).filter(User.cliente_id == cliente_id).count()
    
    # Se houver usuários vinculados, definir cliente_id como NULL antes de deletar
    if usuarios_vinculados > 0:
        # Atualizar todos os usuários vinculados para ter cliente_id = NULL
        db.query(User).filter(User.cliente_id == cliente_id).update(
            {User.cliente_id: None},
            synchronize_session=False
        )
        db.flush()  # Aplicar mudanças sem commit
    
    # Deletar permanentemente
    # Secretarias serão deletadas em cascata devido ao CASCADE na FK
    db.delete(cliente)
    db.commit()
    
    return None


@router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def desativar_cliente(
    cliente_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Desativa um cliente (soft delete)
    
    **Permissão:** Master apenas
    
    **Atenção:**
    - Cliente não é deletado do banco (soft delete)
    - Usuários vinculados não poderão mais fazer login
    - Demandas e histórico são preservados
    - Para reativar, usar endpoint PUT com ativo=true
    
    **Não pode desativar se:**
    - Houver demandas em andamento (status != concluída/cancelada)
    """
    # Buscar cliente
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {cliente_id} não encontrado"
        )
    
    # Verificar se tem demandas em andamento
    # Usar objetos enum diretamente - o TypeDecorator faz a conversão
    from app.models import Demanda, StatusDemanda
    demandas_abertas = db.query(Demanda).filter(
        Demanda.cliente_id == cliente_id,
        Demanda.status.in_([StatusDemanda.ABERTA, StatusDemanda.EM_ANDAMENTO])
    ).count()
    
    if demandas_abertas > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Não é possível desativar. Cliente possui {demandas_abertas} demanda(s) em andamento."
        )
    
    # Desativar
    cliente.desativar()
    db.commit()
    
    return None


@router.post("/{cliente_id}/reativar", response_model=ClienteResponse)
def reativar_cliente(
    cliente_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Reativa um cliente desativado
    
    **Permissão:** Master apenas
    """
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {cliente_id} não encontrado"
        )
    
    if cliente.ativo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cliente já está ativo"
        )
    
    cliente.ativar()
    db.commit()
    db.refresh(cliente)
    
    return cliente


@router.get("/{cliente_id}/estatisticas", response_model=dict)
def estatisticas_cliente(
    cliente_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Retorna estatísticas detalhadas de um cliente
    
    **Permissão:** Master apenas
    
    **Retorna:**
    - Total de usuários
    - Total de secretarias
    - Total de demandas (por status)
    - Demandas por tipo
    - Demandas por prioridade
    """
    from app.models import Demanda, StatusDemanda
    from sqlalchemy import func
    
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {cliente_id} não encontrado"
        )
    
    # Estatísticas de demandas por status
    demandas_por_status = db.query(
        Demanda.status,
        func.count(Demanda.id).label('total')
    ).filter(
        Demanda.cliente_id == cliente_id
    ).group_by(Demanda.status).all()
    
    stats_status = {status.value: 0 for status in StatusDemanda}
    for status, total in demandas_por_status:
        stats_status[status.value] = total
    
    # Contar demandas usando query explícita para evitar erro de enum
    total_demandas = db.query(Demanda).filter(Demanda.cliente_id == cliente_id).count()
    
    # Estatísticas gerais
    return {
        "cliente": {
            "id": cliente.id,
            "nome": cliente.nome,
            "ativo": cliente.ativo
        },
        "totais": {
            "usuarios": len(cliente.usuarios) if cliente.usuarios else 0,
            "secretarias": len(cliente.secretarias) if cliente.secretarias else 0,
            "demandas": total_demandas
        },
        "demandas_por_status": stats_status,
        "integrações": {
            "whatsapp_configurado": bool(cliente.whatsapp_group_id),
            "trello_configurado": bool(cliente.trello_member_id)
        }
    }

