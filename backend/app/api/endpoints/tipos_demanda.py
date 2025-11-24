"""
Endpoints para gerenciamento de tipos de demanda
CRUD completo - Apenas Master pode gerenciar
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_master
from app.models import TipoDemanda, User
from app.schemas import (
    TipoDemandaCreate,
    TipoDemandaUpdate,
    TipoDemandaResponse,
    TipoDemandaResponseComplete
)

router = APIRouter()


@router.get("/", response_model=List[TipoDemandaResponse])
def listar_tipos_demanda(
    skip: int = Query(0, ge=0, description="Registros a pular"),
    limit: int = Query(100, ge=1, le=100, description="Limite de registros"),
    apenas_ativos: bool = Query(True, description="Apenas tipos ativos"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Lista todos os tipos de demanda
    
    **Permissão:** Qualquer usuário autenticado
    
    **Uso:** Usado em dropdowns do formulário de demandas
    
    **Filtros:**
    - apenas_ativos: Apenas tipos ativos (padrão: true)
    - skip/limit: Paginação
    
    **Exemplo:**
    ```
    GET /api/tipos-demanda?apenas_ativos=true
    ```
    """
    query = db.query(TipoDemanda)
    
    # Filtro: apenas ativos
    if apenas_ativos:
        query = query.filter(TipoDemanda.ativo == True)
    
    # Ordenação e paginação
    tipos = query.order_by(TipoDemanda.nome).offset(skip).limit(limit).all()
    
    return tipos


@router.get("/{tipo_id}", response_model=TipoDemandaResponseComplete)
def buscar_tipo_demanda(
    tipo_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Busca tipo de demanda por ID com estatísticas
    
    **Permissão:** Master apenas
    
    **Retorna:**
    - Dados do tipo
    - Total de demandas deste tipo
    """
    tipo = db.query(TipoDemanda).filter(TipoDemanda.id == tipo_id).first()
    
    if not tipo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de demanda ID {tipo_id} não encontrado"
        )
    
    # Montar resposta completa
    response = TipoDemandaResponseComplete(
        **tipo.to_dict(),
        total_demandas=len(tipo.demandas) if tipo.demandas else 0,
        tem_demandas=tipo.tem_demandas()
    )
    
    return response


@router.post("/", response_model=TipoDemandaResponse, status_code=status.HTTP_201_CREATED)
def criar_tipo_demanda(
    tipo_data: TipoDemandaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Cria um novo tipo de demanda
    
    **Permissão:** Master apenas
    
    **Validações:**
    - Nome único
    - Cor no formato hexadecimal (#RRGGBB)
    - Nome mínimo 2 caracteres
    
    **Cores sugeridas:**
    - Design: #3B82F6 (azul)
    - Desenvolvimento: #8B5CF6 (roxo)
    - Conteúdo: #10B981 (verde)
    - Vídeo: #F59E0B (amarelo)
    
    **Exemplo:**
    ```json
    {
        "nome": "Design",
        "cor": "#3B82F6",
        "ativo": true
    }
    ```
    """
    # Verificar se já existe tipo com esse nome
    existe = db.query(TipoDemanda).filter(
        TipoDemanda.nome.ilike(tipo_data.nome)
    ).first()
    
    if existe:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de demanda '{tipo_data.nome}' já existe"
        )
    
    # Criar tipo
    novo_tipo = TipoDemanda(**tipo_data.model_dump())
    
    db.add(novo_tipo)
    db.commit()
    db.refresh(novo_tipo)
    
    return novo_tipo


@router.put("/{tipo_id}", response_model=TipoDemandaResponse)
def atualizar_tipo_demanda(
    tipo_id: str,
    tipo_data: TipoDemandaUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualiza dados de um tipo de demanda
    
    **Permissão:** Master apenas
    
    **Campos atualizáveis:**
    - nome
    - cor
    - ativo
    
    **Observações:**
    - Somente campos enviados serão atualizados
    - Cor deve estar no formato hexadecimal
    """
    # Buscar tipo
    tipo = db.query(TipoDemanda).filter(TipoDemanda.id == tipo_id).first()
    
    if not tipo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de demanda ID {tipo_id} não encontrado"
        )
    
    # Verificar nome duplicado (se estiver atualizando nome)
    if tipo_data.nome and tipo_data.nome != tipo.nome:
        existe = db.query(TipoDemanda).filter(
            TipoDemanda.nome.ilike(tipo_data.nome),
            TipoDemanda.id != tipo_id
        ).first()
        
        if existe:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Tipo de demanda '{tipo_data.nome}' já existe"
            )
    
    # Atualizar campos
    update_data = tipo_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(tipo, field, value)
    
    db.commit()
    db.refresh(tipo)
    
    return tipo


@router.delete("/{tipo_id}", status_code=status.HTTP_204_NO_CONTENT)
def desativar_tipo_demanda(
    tipo_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Desativa um tipo de demanda (soft delete)
    
    **Permissão:** Master apenas
    
    **Atenção:**
    - Tipo não é deletado do banco (soft delete)
    - Tipos inativos não aparecem em formulários
    - Demandas já criadas com este tipo são preservadas
    - Para reativar, usar endpoint PUT com ativo=true
    """
    # Buscar tipo
    tipo = db.query(TipoDemanda).filter(TipoDemanda.id == tipo_id).first()
    
    if not tipo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de demanda ID {tipo_id} não encontrado"
        )
    
    # Desativar
    tipo.desativar()
    db.commit()
    
    return None


@router.post("/{tipo_id}/reativar", response_model=TipoDemandaResponse)
def reativar_tipo_demanda(
    tipo_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Reativa um tipo de demanda desativado
    
    **Permissão:** Master apenas
    """
    tipo = db.query(TipoDemanda).filter(TipoDemanda.id == tipo_id).first()
    
    if not tipo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de demanda ID {tipo_id} não encontrado"
        )
    
    if tipo.ativo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tipo de demanda já está ativo"
        )
    
    tipo.ativar()
    db.commit()
    db.refresh(tipo)
    
    return tipo


@router.post("/seed", response_model=List[TipoDemandaResponse])
def criar_tipos_padroes(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Cria tipos de demanda padrões (se não existirem)
    
    **Permissão:** Master apenas
    
    **Tipos criados:**
    - Design (#3B82F6)
    - Desenvolvimento (#8B5CF6)
    - Conteúdo (#10B981)
    - Vídeo (#F59E0B)
    
    **Uso:** Executar na inicialização do sistema
    """
    tipos_criados = TipoDemanda.criar_tipos_padroes(db)
    
    if not tipos_criados:
        raise HTTPException(
            status_code=status.HTTP_200_OK,
            detail="Tipos padrões já existem"
        )
    
    return tipos_criados

