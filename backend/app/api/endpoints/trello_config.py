"""
Endpoints de Configuração do Trello
Gerencia configurações de integração com Trello (credenciais, board, lista)
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from trello import TrelloClient
from app.core.dependencies import get_db, require_master
from app.models import User, ConfiguracaoTrello
from app.schemas.configuracao_trello import (
    ConfiguracaoTrelloCreate,
    ConfiguracaoTrelloUpdate,
    ConfiguracaoTrelloResponse,
    ConfiguracaoTrelloTest,
    TrelloBoardInfo,
    TrelloListaInfo,
    TrelloEtiquetaInfo
)
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/trello-config", tags=["Configuração Trello"])


# ==================== CRIAR/ATUALIZAR CONFIGURAÇÃO ====================

@router.post("/", response_model=ConfiguracaoTrelloResponse, status_code=status.HTTP_201_CREATED)
def salvar_configuracao_trello(
    config: ConfiguracaoTrelloCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Salva configuração do Trello
    
    - Desativa configurações anteriores automaticamente
    - Apenas uma configuração pode estar ativa por vez
    - Requer permissão de Master
    
    **Parâmetros:**
    - api_key: API Key do Trello
    - token: Token de autenticação
    - board_id: ID do Board
    - lista_id: ID da Lista
    """
    try:
        # Desativar todas as configurações existentes
        ConfiguracaoTrello.desativar_todas(db)
        
        # Criar nova configuração
        nova_config = ConfiguracaoTrello(**config.model_dump())
        db.add(nova_config)
        db.commit()
        db.refresh(nova_config)
        
        logger.info(f"Configuração Trello salva por {current_user.email}")
        
        return nova_config
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao salvar configuração Trello: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao salvar configuração: {str(e)}"
        )


# ==================== BUSCAR CONFIGURAÇÃO ATIVA ====================

@router.get("/ativa", response_model=ConfiguracaoTrelloResponse)
def get_configuracao_ativa(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Retorna a configuração ativa do Trello
    
    - Mascarar dados sensíveis (API Key e Token parcialmente ocultos)
    - Apenas Master pode acessar
    """
    config = ConfiguracaoTrello.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhuma configuração Trello ativa encontrada"
        )
    
    # Mascarar dados sensíveis para exibição
    config_dict = config.to_dict()
    if config.api_key and len(config.api_key) > 8:
        config_dict['api_key'] = config.api_key[:4] + "..." + config.api_key[-4:]
    if config.token and len(config.token) > 12:
        config_dict['token'] = config.token[:8] + "..."
    
    return config_dict


# ==================== TESTAR CONEXÃO ====================

@router.post("/testar")
def testar_conexao_trello(
    credentials: ConfiguracaoTrelloTest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Testa conexão com Trello
    
    **Se board_id não for fornecido:**
    - Retorna lista de boards disponíveis
    
    **Se board_id for fornecido:**
    - Retorna listas do board especificado
    """
    try:
        # Inicializar cliente Trello com credenciais fornecidas
        client = TrelloClient(
            api_key=credentials.api_key,
            api_secret=credentials.token
        )
        
        if credentials.board_id:
            # Testar acesso ao board específico
            board = client.get_board(credentials.board_id)
            listas = board.list_lists()
            
            return {
                "sucesso": True,
                "mensagem": "Conexão estabelecida com sucesso!",
                "board": {
                    "id": board.id,
                    "nome": board.name,
                    "listas": [
                        {"id": l.id, "nome": l.name}
                        for l in listas
                    ]
                }
            }
        else:
            # Listar boards disponíveis
            boards = client.list_boards()
            
            return {
                "sucesso": True,
                "mensagem": "Conexão estabelecida! Selecione um board:",
                "boards": [
                    {"id": b.id, "nome": b.name}
                    for b in boards
                ]
            }
            
    except Exception as e:
        logger.error(f"Erro ao testar conexão Trello: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erro ao conectar com Trello: {str(e)}"
        )


# ==================== LISTAR LISTAS DE UM BOARD ====================

@router.get("/boards/{board_id}/listas", response_model=dict)
def listar_listas_board(
    board_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Lista todas as listas de um board específico
    
    Usa a configuração ativa para conectar ao Trello.
    """
    config = ConfiguracaoTrello.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configure o Trello primeiro"
        )
    
    try:
        client = TrelloClient(
            api_key=config.api_key,
            api_secret=config.token
        )
        
        board = client.get_board(board_id)
        listas = board.list_lists()
        
        return {
            "board_nome": board.name,
            "listas": [
                {"id": l.id, "nome": l.name}
                for l in listas
            ]
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar listas: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erro ao buscar listas: {str(e)}"
        )


# ==================== LISTAR ETIQUETAS DE UM BOARD ====================

@router.get("/boards/{board_id}/etiquetas", response_model=dict)
def listar_etiquetas_board(
    board_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Lista todas as etiquetas disponíveis em um board
    
    Usado para vincular etiquetas a clientes.
    """
    config = ConfiguracaoTrello.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configure o Trello primeiro"
        )
    
    try:
        client = TrelloClient(
            api_key=config.api_key,
            api_secret=config.token
        )
        
        board = client.get_board(board_id)
        labels = board.get_labels()
        
        return {
            "board_nome": board.name,
            "etiquetas": [
                {
                    "id": label.id,
                    "nome": label.name if label.name else f"Etiqueta {label.color}",
                    "cor": label.color
                }
                for label in labels
            ]
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar etiquetas: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erro ao buscar etiquetas: {str(e)}"
        )


# ==================== ATUALIZAR CONFIGURAÇÃO ====================

@router.patch("/{config_id}", response_model=ConfiguracaoTrelloResponse)
def atualizar_configuracao(
    config_id: str,
    config_update: ConfiguracaoTrelloUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualiza uma configuração existente
    """
    config = db.query(ConfiguracaoTrello).filter(
        ConfiguracaoTrello.id == config_id,
        ConfiguracaoTrello.deleted_at == None
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    try:
        # Atualizar campos fornecidos
        for key, value in config_update.model_dump(exclude_unset=True).items():
            setattr(config, key, value)
        
        db.commit()
        db.refresh(config)
        
        logger.info(f"Configuração Trello {config_id} atualizada por {current_user.email}")
        
        return config
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao atualizar configuração: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao atualizar configuração: {str(e)}"
        )


# ==================== DELETAR CONFIGURAÇÃO ====================

@router.delete("/{config_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_configuracao(
    config_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deleta (soft delete) uma configuração
    """
    config = db.query(ConfiguracaoTrello).filter(
        ConfiguracaoTrello.id == config_id,
        ConfiguracaoTrello.deleted_at == None
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    try:
        config.delete()  # Soft delete (BaseModel)
        db.commit()
        
        logger.info(f"Configuração Trello {config_id} deletada por {current_user.email}")
        
        return None
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao deletar configuração: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao deletar configuração: {str(e)}"
        )

