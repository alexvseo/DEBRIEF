"""
Endpoints para gerenciamento de secretarias
CRUD completo - Apenas Master pode gerenciar
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_master
from app.models import Secretaria, Cliente, User, Demanda, Demanda
from app.schemas import (
    SecretariaCreate,
    SecretariaUpdate,
    SecretariaResponse,
    SecretariaResponseComplete
)

router = APIRouter()


@router.get("/", response_model=List[SecretariaResponseComplete])
def listar_secretarias(
    skip: int = Query(0, ge=0, description="Registros a pular"),
    limit: int = Query(1000, ge=1, le=10000, description="Limite de registros"),
    cliente_id: Optional[str] = Query(None, description="Filtrar por cliente"),
    apenas_ativas: bool = Query(True, description="Apenas secretarias ativas"),
    busca: Optional[str] = Query(None, description="Buscar por nome"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Lista todas as secretarias (apenas master)
    
    **Permissão:** Master apenas
    
    **Filtros:**
    - cliente_id: Filtrar por cliente específico
    - apenas_ativas: Apenas secretarias ativas
    - busca: Buscar por nome (case insensitive)
    - skip/limit: Paginação
    
    **Exemplo:**
    ```
    GET /api/secretarias?cliente_id=abc-123&apenas_ativas=true
    ```
    """
    query = db.query(Secretaria)
    
    # Filtro: cliente específico
    if cliente_id:
        query = query.filter(Secretaria.cliente_id == cliente_id)
    
    # Filtro: apenas ativas
    # Converter string "false" para boolean False se necessário
    if isinstance(apenas_ativas, str):
        apenas_ativas = apenas_ativas.lower() == 'true'
    
    if apenas_ativas:
        query = query.filter(Secretaria.ativo == True)
    
    # Filtro: busca por nome
    if busca:
        query = query.filter(Secretaria.nome.ilike(f"%{busca}%"))
    
    # Ordenação e paginação
    secretarias = query.order_by(Secretaria.nome).offset(skip).limit(limit).all()
    
    # Montar resposta completa
    # Usar query separada para contar demandas para evitar erro de enum
    from app.models import Demanda
    response = []
    for secretaria in secretarias:
        # Contar demandas sem carregar o relacionamento (evita erro de enum)
        total_demandas = db.query(Demanda).filter(
            Demanda.secretaria_id == secretaria.id
        ).count()
        
        response.append(SecretariaResponseComplete(
            **secretaria.to_dict(),
            cliente_nome=secretaria.cliente.nome if secretaria.cliente else None,
            total_demandas=total_demandas,
            tem_demandas=total_demandas > 0
        ))
    
    return response


@router.get("/cliente/{cliente_id}", response_model=List[SecretariaResponse])
def listar_secretarias_por_cliente(
    cliente_id: str,
    apenas_ativas: bool = Query(True, description="Apenas secretarias ativas"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Lista secretarias de um cliente específico
    
    **Permissão:** Qualquer usuário autenticado (para preencher formulários)
    
    **Uso:** Usado em dropdowns do formulário de demandas
    
    **Filtros:**
    - apenas_ativas: Apenas secretarias ativas (padrão: true)
    """
    # Verificar se cliente existe
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {cliente_id} não encontrado"
        )
    
    # Buscar secretarias
    query = Secretaria.get_por_cliente(db, cliente_id, apenas_ativas)
    secretarias = query.all()
    
    return secretarias


@router.get("/{secretaria_id}", response_model=SecretariaResponseComplete)
def buscar_secretaria(
    secretaria_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Busca secretaria por ID com informações completas
    
    **Permissão:** Master apenas
    
    **Retorna:**
    - Dados da secretaria
    - Dados do cliente
    - Total de demandas
    """
    secretaria = db.query(Secretaria).filter(Secretaria.id == secretaria_id).first()
    
    if not secretaria:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Secretaria ID {secretaria_id} não encontrada"
        )
    
    # Contar demandas sem carregar o relacionamento (evita erro de enum)
    total_demandas = db.query(Demanda).filter(
        Demanda.secretaria_id == secretaria_id
    ).count()
    
    # Montar resposta completa
    response = SecretariaResponseComplete(
        **secretaria.to_dict(),
        cliente_nome=secretaria.cliente.nome if secretaria.cliente else None,
        total_demandas=total_demandas,
        tem_demandas=total_demandas > 0
    )
    
    return response


@router.post("/", response_model=SecretariaResponse, status_code=status.HTTP_201_CREATED)
def criar_secretaria(
    secretaria_data: SecretariaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Cria uma nova secretaria
    
    **Permissão:** Master apenas
    
    **Validações:**
    - Cliente deve existir
    - Nome único dentro do mesmo cliente
    - Nome mínimo 3 caracteres
    
    **Exemplo:**
    ```json
    {
        "nome": "Secretaria de Saúde",
        "cliente_id": "abc-123-def-456",
        "ativo": true
    }
    ```
    """
    # Verificar se cliente existe
    cliente = db.query(Cliente).filter(Cliente.id == secretaria_data.cliente_id).first()
    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cliente ID {secretaria_data.cliente_id} não encontrado"
        )
    
    # Verificar se já existe secretaria ATIVA com esse nome no mesmo cliente
    # Permitir criar secretaria com mesmo nome se a anterior estiver inativa
    # Usar comparação case-insensitive (ilike) e verificar apenas ATIVAS
    # IMPORTANTE: Normalizar nome (trim e case-insensitive) para comparação
    nome_normalizado = secretaria_data.nome.strip()
    
    existe = db.query(Secretaria).filter(
        Secretaria.cliente_id == secretaria_data.cliente_id,
        Secretaria.nome.ilike(nome_normalizado),  # Case-insensitive
        Secretaria.ativo == True  # Apenas verificar secretarias ATIVAS
    ).first()
    
    if existe:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Secretaria '{nome_normalizado}' já existe para este cliente (ID: {existe.id}, Status: Ativa). Se você deletou uma secretaria, use o botão de deletar permanente (ícone de lixeira) em vez de desativar."
        )
    
    # Criar secretaria
    # Garantir que o nome está normalizado (trim)
    dados_criacao = secretaria_data.model_dump()
    dados_criacao['nome'] = nome_normalizado  # Usar nome normalizado
    
    nova_secretaria = Secretaria(**dados_criacao)
    
    db.add(nova_secretaria)
    db.commit()
    db.refresh(nova_secretaria)
    
    return nova_secretaria


@router.put("/{secretaria_id}", response_model=SecretariaResponse)
def atualizar_secretaria(
    secretaria_id: str,
    secretaria_data: SecretariaUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualiza dados de uma secretaria
    
    **Permissão:** Master apenas
    
    **Campos atualizáveis:**
    - nome
    - ativo
    
    **Observações:**
    - Não é possível alterar o cliente vinculado
    - Somente campos enviados serão atualizados
    """
    # Buscar secretaria
    secretaria = db.query(Secretaria).filter(Secretaria.id == secretaria_id).first()
    
    if not secretaria:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Secretaria ID {secretaria_id} não encontrada"
        )
    
    # Verificar nome duplicado (se estiver atualizando nome)
    # Apenas verificar secretarias ATIVAS
    if secretaria_data.nome and secretaria_data.nome.strip() != secretaria.nome:
        nome_normalizado = secretaria_data.nome.strip()
        existe = db.query(Secretaria).filter(
            Secretaria.cliente_id == secretaria.cliente_id,
            Secretaria.nome.ilike(nome_normalizado),  # Case-insensitive
            Secretaria.id != secretaria_id,
            Secretaria.ativo == True  # Apenas verificar secretarias ativas
        ).first()
        
        if existe:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Secretaria '{nome_normalizado}' já existe para este cliente (Status: Ativa)"
            )
    
    # Atualizar campos
    update_data = secretaria_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(secretaria, field, value)
    
    db.commit()
    db.refresh(secretaria)
    
    return secretaria


@router.delete("/{secretaria_id}/permanente", status_code=status.HTTP_204_NO_CONTENT)
def deletar_secretaria_permanente(
    secretaria_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deleta uma secretaria permanentemente do banco (hard delete)
    
    **Permissão:** Master apenas
    
    **Atenção:**
    - Esta ação é IRREVERSÍVEL
    - Secretaria será removida permanentemente do banco
    - Demandas vinculadas serão preservadas (secretaria_id ficará NULL)
    - Use com cuidado!
    
    **Não pode deletar se:**
    - Houver demandas vinculadas
    """
    # Buscar secretaria
    secretaria = db.query(Secretaria).filter(Secretaria.id == secretaria_id).first()
    
    if not secretaria:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Secretaria ID {secretaria_id} não encontrada"
        )
    
    # Verificar se tem demandas vinculadas
    total_demandas = db.query(Demanda).filter(Demanda.secretaria_id == secretaria_id).count()
    
    if total_demandas > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Não é possível deletar. Secretaria possui {total_demandas} demanda(s) vinculada(s). Desative a secretaria em vez de deletá-la."
        )
    
    # Deletar permanentemente
    db.delete(secretaria)
    db.commit()
    
    return None


@router.delete("/{secretaria_id}", status_code=status.HTTP_204_NO_CONTENT)
def desativar_secretaria(
    secretaria_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Desativa uma secretaria (soft delete)
    
    **Permissão:** Master apenas
    
    **Atenção:**
    - Secretaria não é deletada do banco (soft delete)
    - Secretarias inativas não aparecem em formulários
    - Demandas já criadas são preservadas
    - Para reativar, usar endpoint PUT com ativo=true
    
    **Pode desativar mesmo com demandas vinculadas**
    (diferente de clientes)
    """
    # Buscar secretaria
    secretaria = db.query(Secretaria).filter(Secretaria.id == secretaria_id).first()
    
    if not secretaria:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Secretaria ID {secretaria_id} não encontrada"
        )
    
    # Desativar
    secretaria.desativar()
    db.commit()
    
    return None


@router.post("/{secretaria_id}/reativar", response_model=SecretariaResponse)
def reativar_secretaria(
    secretaria_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Reativa uma secretaria desativada
    
    **Permissão:** Master apenas
    """
    secretaria = db.query(Secretaria).filter(Secretaria.id == secretaria_id).first()
    
    if not secretaria:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Secretaria ID {secretaria_id} não encontrada"
        )
    
    if secretaria.ativo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Secretaria já está ativa"
        )
    
    secretaria.ativar()
    db.commit()
    db.refresh(secretaria)
    
    return secretaria

