"""
Endpoints de Etiquetas Trello por Cliente
Gerencia vinculação de etiquetas do Trello a clientes do sistema
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.core.dependencies import get_db, require_master
from app.models import User, EtiquetaTrelloCliente, Cliente
from app.schemas.etiqueta_trello_cliente import (
    EtiquetaTrelloClienteCreate,
    EtiquetaTrelloClienteUpdate,
    EtiquetaTrelloClienteResponse
)
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/trello-etiquetas", tags=["Etiquetas Trello"])


# ==================== VINCULAR ETIQUETA A CLIENTE ====================

@router.post("/", response_model=EtiquetaTrelloClienteResponse, status_code=status.HTTP_201_CREATED)
def vincular_etiqueta_cliente(
    etiqueta: EtiquetaTrelloClienteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Vincula uma etiqueta do Trello a um cliente
    
    - Se já existir uma etiqueta para o cliente, atualiza
    - Se não existir, cria nova
    - Requer permissão de Master
    
    **Parâmetros:**
    - cliente_id: UUID do cliente
    - etiqueta_trello_id: ID da etiqueta no Trello
    - etiqueta_nome: Nome da etiqueta
    - etiqueta_cor: Cor da etiqueta
    """
    # Verificar se cliente existe
    cliente = db.query(Cliente).filter(
        Cliente.id == etiqueta.cliente_id,
        Cliente.deleted_at == None
    ).first()
    
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cliente não encontrado"
        )
    
    try:
        # Verificar se já existe etiqueta para este cliente
        etiqueta_existente = EtiquetaTrelloCliente.get_by_cliente(db, etiqueta.cliente_id)
        
        if etiqueta_existente:
            # Atualizar etiqueta existente
            etiqueta_existente.etiqueta_trello_id = etiqueta.etiqueta_trello_id
            etiqueta_existente.etiqueta_nome = etiqueta.etiqueta_nome
            etiqueta_existente.etiqueta_cor = etiqueta.etiqueta_cor
            etiqueta_existente.ativo = True
            
            db.commit()
            db.refresh(etiqueta_existente)
            
            # Adicionar nome do cliente para resposta
            response = etiqueta_existente.to_dict()
            response['cliente_nome'] = cliente.nome
            
            logger.info(f"Etiqueta atualizada para cliente {cliente.nome} por {current_user.email}")
            
            return response
        else:
            # Criar nova etiqueta
            nova_etiqueta = EtiquetaTrelloCliente(**etiqueta.model_dump())
            db.add(nova_etiqueta)
            db.commit()
            db.refresh(nova_etiqueta)
            
            # Adicionar nome do cliente para resposta
            response = nova_etiqueta.to_dict()
            response['cliente_nome'] = cliente.nome
            
            logger.info(f"Etiqueta criada para cliente {cliente.nome} por {current_user.email}")
            
            return response
            
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao vincular etiqueta: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao vincular etiqueta: {str(e)}"
        )


# ==================== LISTAR TODAS AS ETIQUETAS ====================

@router.get("/", response_model=List[EtiquetaTrelloClienteResponse])
def listar_etiquetas_clientes(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Lista todas as etiquetas vinculadas a clientes
    
    Retorna apenas etiquetas ativas.
    """
    etiquetas = db.query(EtiquetaTrelloCliente).filter(
        EtiquetaTrelloCliente.deleted_at == None
    ).all()
    
    # Adicionar nome do cliente a cada etiqueta
    resultado = []
    for etiqueta in etiquetas:
        db.refresh(etiqueta)
        etiqueta_dict = etiqueta.to_dict()
        etiqueta_dict['cliente_nome'] = etiqueta.cliente.nome if etiqueta.cliente else "Cliente não encontrado"
        resultado.append(etiqueta_dict)
    
    return resultado


# ==================== BUSCAR ETIQUETA DE UM CLIENTE ====================

@router.get("/cliente/{cliente_id}", response_model=EtiquetaTrelloClienteResponse)
def get_etiqueta_cliente(
    cliente_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Retorna a etiqueta de um cliente específico
    """
    etiqueta = EtiquetaTrelloCliente.get_by_cliente(db, cliente_id)
    
    if not etiqueta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etiqueta não configurada para este cliente"
        )
    
    db.refresh(etiqueta)
    etiqueta_dict = etiqueta.to_dict()
    etiqueta_dict['cliente_nome'] = etiqueta.cliente.nome if etiqueta.cliente else "Cliente não encontrado"
    
    return etiqueta_dict


# ==================== ATUALIZAR ETIQUETA ====================

@router.patch("/{etiqueta_id}", response_model=EtiquetaTrelloClienteResponse)
def atualizar_etiqueta(
    etiqueta_id: str,
    etiqueta_update: EtiquetaTrelloClienteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualiza uma etiqueta existente
    """
    etiqueta = db.query(EtiquetaTrelloCliente).filter(
        EtiquetaTrelloCliente.id == etiqueta_id,
        EtiquetaTrelloCliente.deleted_at == None
    ).first()
    
    if not etiqueta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etiqueta não encontrada"
        )
    
    try:
        # Atualizar campos fornecidos
        for key, value in etiqueta_update.model_dump(exclude_unset=True).items():
            setattr(etiqueta, key, value)
        
        db.commit()
        db.refresh(etiqueta)
        
        # Adicionar nome do cliente para resposta
        etiqueta_dict = etiqueta.to_dict()
        etiqueta_dict['cliente_nome'] = etiqueta.cliente.nome if etiqueta.cliente else "Cliente não encontrado"
        
        logger.info(f"Etiqueta {etiqueta_id} atualizada por {current_user.email}")
        
        return etiqueta_dict
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao atualizar etiqueta: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao atualizar etiqueta: {str(e)}"
        )


# ==================== DELETAR ETIQUETA ====================

@router.delete("/{etiqueta_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_etiqueta(
    etiqueta_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deleta (soft delete) uma etiqueta
    """
    etiqueta = db.query(EtiquetaTrelloCliente).filter(
        EtiquetaTrelloCliente.id == etiqueta_id,
        EtiquetaTrelloCliente.deleted_at == None
    ).first()
    
    if not etiqueta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etiqueta não encontrada"
        )
    
    try:
        etiqueta.delete()  # Soft delete (BaseModel)
        db.commit()
        
        logger.info(f"Etiqueta {etiqueta_id} deletada por {current_user.email}")
        
        return None
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao deletar etiqueta: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao deletar etiqueta: {str(e)}"
        )


# ==================== DESATIVAR ETIQUETA ====================

@router.post("/{etiqueta_id}/desativar", response_model=EtiquetaTrelloClienteResponse)
def desativar_etiqueta(
    etiqueta_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Desativa uma etiqueta sem deletá-la
    """
    etiqueta = db.query(EtiquetaTrelloCliente).filter(
        EtiquetaTrelloCliente.id == etiqueta_id,
        EtiquetaTrelloCliente.deleted_at == None
    ).first()
    
    if not etiqueta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etiqueta não encontrada"
        )
    
    try:
        etiqueta.ativo = False
        db.commit()
        db.refresh(etiqueta)
        
        # Adicionar nome do cliente para resposta
        etiqueta_dict = etiqueta.to_dict()
        etiqueta_dict['cliente_nome'] = etiqueta.cliente.nome if etiqueta.cliente else "Cliente não encontrado"
        
        logger.info(f"Etiqueta {etiqueta_id} desativada por {current_user.email}")
        
        return etiqueta_dict
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao desativar etiqueta: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao desativar etiqueta: {str(e)}"
        )


# ==================== ATIVAR ETIQUETA ====================

@router.post("/{etiqueta_id}/ativar", response_model=EtiquetaTrelloClienteResponse)
def ativar_etiqueta(
    etiqueta_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Ativa uma etiqueta previamente desativada
    """
    etiqueta = db.query(EtiquetaTrelloCliente).filter(
        EtiquetaTrelloCliente.id == etiqueta_id,
        EtiquetaTrelloCliente.deleted_at == None
    ).first()
    
    if not etiqueta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etiqueta não encontrada"
        )
    
    try:
        etiqueta.ativo = True
        db.commit()
        db.refresh(etiqueta)
        
        # Adicionar nome do cliente para resposta
        etiqueta_dict = etiqueta.to_dict()
        etiqueta_dict['cliente_nome'] = etiqueta.cliente.nome if etiqueta.cliente else "Cliente não encontrado"
        
        logger.info(f"Etiqueta {etiqueta_id} ativada por {current_user.email}")
        
        return etiqueta_dict
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao ativar etiqueta: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao ativar etiqueta: {str(e)}"
        )

