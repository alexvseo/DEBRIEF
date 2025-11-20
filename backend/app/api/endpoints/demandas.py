"""
Endpoints de Demandas
CRUD completo de demandas
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_master_user
from app.models.user import User
from app.models.demanda import Demanda, StatusDemanda
from app.schemas.demanda import (
    DemandaCreate,
    DemandaUpdate,
    DemandaResponse,
    DemandaListResponse
)

router = APIRouter()


@router.post("", response_model=DemandaResponse, status_code=status.HTTP_201_CREATED)
async def create_demanda(
    demanda_data: DemandaCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Criar nova demanda
    
    Args:
        demanda_data: Dados da nova demanda
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        DemandaResponse: Demanda criada
    """
    # Criar nova demanda
    new_demanda = Demanda(
        nome=demanda_data.nome,
        descricao=demanda_data.descricao,
        prioridade=demanda_data.prioridade,
        prazo_final=demanda_data.prazo_final,
        tipo_demanda_id=demanda_data.tipo_demanda_id,
        secretaria_id=demanda_data.secretaria_id,
        usuario_id=current_user.id
    )
    
    db.add(new_demanda)
    db.commit()
    db.refresh(new_demanda)
    
    return DemandaResponse.from_orm(new_demanda)


@router.get("", response_model=List[DemandaResponse])
async def list_demandas(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    status: str = Query(None),
    prioridade: str = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Listar demandas do usuário
    
    Args:
        skip: Número de registros para pular (paginação)
        limit: Número máximo de registros
        status: Filtrar por status (opcional)
        prioridade: Filtrar por prioridade (opcional)
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        List[DemandaResponse]: Lista de demandas
    """
    # Query base
    query = db.query(Demanda)
    
    # Se não for master, filtrar apenas demandas do usuário
    if not current_user.is_master():
        query = query.filter(Demanda.usuario_id == current_user.id)
    
    # Filtros opcionais
    if status:
        query = query.filter(Demanda.status == status)
    
    if prioridade:
        query = query.filter(Demanda.prioridade == prioridade)
    
    # Ordenar por data de criação (mais recentes primeiro)
    query = query.order_by(Demanda.created_at.desc())
    
    # Paginação
    demandas = query.offset(skip).limit(limit).all()
    
    return [DemandaResponse.from_orm(d) for d in demandas]


@router.get("/{demanda_id}", response_model=DemandaResponse)
async def get_demanda(
    demanda_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obter demanda por ID
    
    Args:
        demanda_id: ID da demanda
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        DemandaResponse: Demanda encontrada
        
    Raises:
        HTTPException: Se demanda não encontrada ou sem permissão
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    # Verificar permissão de visualização
    if not demanda.pode_visualizar(current_user.id, current_user.is_master()):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para visualizar esta demanda"
        )
    
    return DemandaResponse.from_orm(demanda)


@router.put("/{demanda_id}", response_model=DemandaResponse)
async def update_demanda(
    demanda_id: str,
    demanda_data: DemandaUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Atualizar demanda
    
    Args:
        demanda_id: ID da demanda
        demanda_data: Dados para atualizar
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        DemandaResponse: Demanda atualizada
        
    Raises:
        HTTPException: Se demanda não encontrada ou sem permissão
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    # Verificar permissão de edição
    if not current_user.is_master() and not demanda.pode_editar(current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para editar esta demanda"
        )
    
    # Atualizar campos fornecidos
    update_data = demanda_data.dict(exclude_unset=True)
    
    for field, value in update_data.items():
        setattr(demanda, field, value)
    
    # Se status mudou para concluída, registrar data
    if demanda_data.status == StatusDemanda.CONCLUIDA and demanda.data_conclusao is None:
        demanda.concluir()
    
    db.commit()
    db.refresh(demanda)
    
    return DemandaResponse.from_orm(demanda)


@router.delete("/{demanda_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_demanda(
    demanda_id: str,
    current_user: User = Depends(get_current_master_user),
    db: Session = Depends(get_db)
):
    """
    Deletar demanda (apenas master)
    
    Args:
        demanda_id: ID da demanda
        current_user: Usuário master autenticado
        db: Sessão do banco
        
    Raises:
        HTTPException: Se demanda não encontrada
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    db.delete(demanda)
    db.commit()
    
    return None


@router.get("/stats/summary")
async def get_demandas_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obter estatísticas de demandas
    
    Args:
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        dict: Estatísticas (total, por status, etc)
    """
    # Query base
    query = db.query(Demanda)
    
    # Se não for master, filtrar apenas demandas do usuário
    if not current_user.is_master():
        query = query.filter(Demanda.usuario_id == current_user.id)
    
    # Total
    total = query.count()
    
    # Por status
    abertas = query.filter(Demanda.status == StatusDemanda.ABERTA).count()
    em_andamento = query.filter(Demanda.status == StatusDemanda.EM_ANDAMENTO).count()
    concluidas = query.filter(Demanda.status == StatusDemanda.CONCLUIDA).count()
    canceladas = query.filter(Demanda.status == StatusDemanda.CANCELADA).count()
    
    # Atrasadas (prazo vencido e não concluída)
    from datetime import date
    atrasadas = query.filter(
        Demanda.prazo_final < date.today(),
        Demanda.status.in_([StatusDemanda.ABERTA.value, StatusDemanda.EM_ANDAMENTO.value])
    ).count()
    
    return {
        "total": total,
        "abertas": abertas,
        "em_andamento": em_andamento,
        "concluidas": concluidas,
        "canceladas": canceladas,
        "atrasadas": atrasadas
    }

