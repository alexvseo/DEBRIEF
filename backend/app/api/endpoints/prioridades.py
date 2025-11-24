"""
Endpoints para gerenciamento de prioridades
CRUD completo - Apenas Master pode gerenciar
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Path
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_master
from app.models import Prioridade, User
from app.schemas import (
    PrioridadeCreate,
    PrioridadeUpdate,
    PrioridadeResponse,
    PrioridadeResponseComplete
)

router = APIRouter()


@router.get("/", response_model=List[PrioridadeResponse])
def listar_prioridades(
    skip: int = Query(0, ge=0, description="Registros a pular"),
    limit: int = Query(100, ge=1, le=100, description="Limite de registros"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Lista todas as prioridades ordenadas por nível
    
    **Permissão:** Qualquer usuário autenticado
    
    **Uso:** Usado em dropdowns do formulário de demandas
    
    **Ordenação:** Por nível (1=Baixa → 4=Urgente)
    
    **Exemplo:**
    ```
    GET /api/prioridades
    ```
    
    **Resposta:**
    ```json
    [
        {"id": "...", "nome": "Baixa", "nivel": 1, "cor": "#10B981"},
        {"id": "...", "nome": "Média", "nivel": 2, "cor": "#F59E0B"},
        {"id": "...", "nome": "Alta", "nivel": 3, "cor": "#F97316"},
        {"id": "...", "nome": "Urgente", "nivel": 4, "cor": "#EF4444"}
    ]
    ```
    """
    # Buscar prioridades ordenadas por nível
    prioridades = Prioridade.get_ordenadas(db).offset(skip).limit(limit).all()
    
    return prioridades


@router.get("/{prioridade_id}", response_model=PrioridadeResponseComplete)
def buscar_prioridade(
    prioridade_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Busca prioridade por ID com estatísticas
    
    **Permissão:** Master apenas
    
    **Retorna:**
    - Dados da prioridade
    - Total de demandas com esta prioridade
    - Emoji correspondente
    """
    prioridade = db.query(Prioridade).filter(Prioridade.id == prioridade_id).first()
    
    if not prioridade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Prioridade ID {prioridade_id} não encontrada"
        )
    
    # Montar resposta completa
    response = PrioridadeResponseComplete(
        **prioridade.to_dict(),
        total_demandas=len(prioridade.demandas) if prioridade.demandas else 0,
        tem_demandas=prioridade.tem_demandas(),
        emoji=prioridade.get_label_emoji()
    )
    
    return response


@router.post("/", response_model=PrioridadeResponse, status_code=status.HTTP_201_CREATED)
def criar_prioridade(
    prioridade_data: PrioridadeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Cria uma nova prioridade
    
    **Permissão:** Master apenas
    
    **Validações:**
    - Nome único
    - Nível entre 1 e 4
    - Cor no formato hexadecimal (#RRGGBB)
    - Nome mínimo 2 caracteres
    
    **Níveis recomendados:**
    - 1: Baixa (🟢 #10B981)
    - 2: Média (🟡 #F59E0B)
    - 3: Alta (🟠 #F97316)
    - 4: Urgente (🔴 #EF4444)
    
    **Exemplo:**
    ```json
    {
        "nome": "Alta",
        "nivel": 3,
        "cor": "#F97316"
    }
    ```
    """
    # Verificar se já existe prioridade com esse nome
    existe_nome = db.query(Prioridade).filter(
        Prioridade.nome.ilike(prioridade_data.nome)
    ).first()
    
    if existe_nome:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Prioridade '{prioridade_data.nome}' já existe"
        )
    
    # Verificar se já existe prioridade com esse nível
    existe_nivel = db.query(Prioridade).filter(
        Prioridade.nivel == prioridade_data.nivel
    ).first()
    
    if existe_nivel:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Já existe prioridade com nível {prioridade_data.nivel}: {existe_nivel.nome}"
        )
    
    # Criar prioridade
    nova_prioridade = Prioridade(**prioridade_data.model_dump())
    
    db.add(nova_prioridade)
    db.commit()
    db.refresh(nova_prioridade)
    
    return nova_prioridade


@router.put("/{prioridade_id}", response_model=PrioridadeResponse)
def atualizar_prioridade(
    prioridade_id: str,
    prioridade_data: PrioridadeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualiza dados de uma prioridade
    
    **Permissão:** Master apenas
    
    **Campos atualizáveis:**
    - nome
    - nivel
    - cor
    
    **Observações:**
    - Somente campos enviados serão atualizados
    - Nível deve estar entre 1 e 4
    - Cor deve estar no formato hexadecimal
    
    **Atenção:**
    - Alterar o nível pode afetar a ordenação
    - Demandas existentes mantêm a prioridade original
    """
    # Buscar prioridade
    prioridade = db.query(Prioridade).filter(Prioridade.id == prioridade_id).first()
    
    if not prioridade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Prioridade ID {prioridade_id} não encontrada"
        )
    
    # Verificar nome duplicado (se estiver atualizando nome)
    if prioridade_data.nome and prioridade_data.nome != prioridade.nome:
        existe = db.query(Prioridade).filter(
            Prioridade.nome.ilike(prioridade_data.nome),
            Prioridade.id != prioridade_id
        ).first()
        
        if existe:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Prioridade '{prioridade_data.nome}' já existe"
            )
    
    # Verificar nível duplicado (se estiver atualizando nível)
    if prioridade_data.nivel and prioridade_data.nivel != prioridade.nivel:
        existe = db.query(Prioridade).filter(
            Prioridade.nivel == prioridade_data.nivel,
            Prioridade.id != prioridade_id
        ).first()
        
        if existe:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Já existe prioridade com nível {prioridade_data.nivel}: {existe.nome}"
            )
    
    # Atualizar campos
    update_data = prioridade_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(prioridade, field, value)
    
    db.commit()
    db.refresh(prioridade)
    
    return prioridade


@router.delete("/{prioridade_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_prioridade(
    prioridade_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deleta uma prioridade (hard delete)
    
    **Permissão:** Master apenas
    
    **Atenção:**
    - NÃO pode deletar se houver demandas vinculadas
    - Prioridade é removida permanentemente do banco
    - Não há soft delete para prioridades
    
    **Recomendação:**
    - Crie novas prioridades ao invés de deletar
    - Mantenha ao menos 4 níveis (Baixa, Média, Alta, Urgente)
    """
    # Buscar prioridade
    prioridade = db.query(Prioridade).filter(Prioridade.id == prioridade_id).first()
    
    if not prioridade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Prioridade ID {prioridade_id} não encontrada"
        )
    
    # Verificar se tem demandas vinculadas
    if prioridade.tem_demandas():
        total = len(prioridade.demandas)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Não é possível deletar. Prioridade possui {total} demanda(s) vinculada(s)."
        )
    
    # Deletar
    db.delete(prioridade)
    db.commit()
    
    return None


@router.post("/seed", response_model=List[PrioridadeResponse])
def criar_prioridades_padroes(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Cria prioridades padrões (se não existirem)
    
    **Permissão:** Master apenas
    
    **Prioridades criadas:**
    - Baixa (Nível 1, 🟢 #10B981)
    - Média (Nível 2, 🟡 #F59E0B)
    - Alta (Nível 3, 🟠 #F97316)
    - Urgente (Nível 4, 🔴 #EF4444)
    
    **Uso:** Executar na inicialização do sistema
    
    **Exemplo:**
    ```
    POST /api/prioridades/seed
    ```
    """
    prioridades_criadas = Prioridade.criar_prioridades_padroes(db)
    
    if not prioridades_criadas:
        raise HTTPException(
            status_code=status.HTTP_200_OK,
            detail="Prioridades padrões já existem"
        )
    
    return prioridades_criadas


@router.get("/nivel/{nivel}", response_model=PrioridadeResponse)
def buscar_prioridade_por_nivel(
    nivel: int = Path(..., ge=1, le=4, description="Nível da prioridade (1-4)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Busca prioridade por nível
    
    **Permissão:** Qualquer usuário autenticado
    
    **Uso:** Útil para lógicas automáticas
    
    **Exemplo:**
    ```
    GET /api/prioridades/nivel/3  # Retorna prioridade "Alta"
    ```
    """
    prioridade = Prioridade.get_por_nivel(db, nivel)
    
    if not prioridade:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Prioridade com nível {nivel} não encontrada"
        )
    
    return prioridade

