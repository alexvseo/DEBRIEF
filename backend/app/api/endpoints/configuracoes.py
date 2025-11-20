"""
Endpoints para gerenciamento de configurações do sistema
CRUD completo + Testes de conexão - Apenas Master
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import require_master
from app.models.user import User
from app.models.configuracao import Configuracao, TipoConfiguracao
from app.schemas.configuracao import (
    ConfiguracaoCreate,
    ConfiguracaoUpdate,
    ConfiguracaoResponse,
    ConfiguracaoResponseSimples,
    ConfiguracaoPorTipo,
    ConfiguracaoTestarTrello,
    ConfiguracaoTestarWhatsApp,
    TesteConexaoResponse,
)

router = APIRouter()


@router.get("/", response_model=List[ConfiguracaoResponse])
def listar_configuracoes(
    tipo: TipoConfiguracao = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Listar todas as configurações
    
    **Permissão:** Apenas Master
    
    **Parâmetros:**
    - `tipo`: Filtrar por tipo (opcional)
    
    **Retorna:**
    - Lista de configurações com valores mascarados se sensíveis
    """
    if tipo:
        configs = Configuracao.get_all_by_tipo(db, tipo)
    else:
        configs = db.query(Configuracao).all()
    
    return [
        ConfiguracaoResponse(
            **config.to_dict(include_valor=True)
        ) for config in configs
    ]


# IMPORTANTE: Rotas específicas devem vir ANTES de rotas com parâmetros
# /agrupadas deve vir antes de /{configuracao_id} para evitar conflito
@router.get("/agrupadas", response_model=List[ConfiguracaoPorTipo])
def listar_configuracoes_agrupadas(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Listar configurações agrupadas por tipo
    
    **Permissão:** Apenas Master
    
    **Retorna:**
    - Configurações organizadas por tipo (Trello, WhatsApp, Sistema)
    """
    agrupadas = []
    
    for tipo in TipoConfiguracao:
        configs = Configuracao.get_all_by_tipo(db, tipo)
        if configs:
            agrupadas.append(
                ConfiguracaoPorTipo(
                    tipo=tipo,
                    configuracoes=[
                        ConfiguracaoResponse(**config.to_dict(include_valor=True))
                        for config in configs
                    ]
                )
            )
    
    return agrupadas


# Rotas com parâmetros devem vir DEPOIS de rotas específicas
@router.get("/chave/{chave}", response_model=ConfiguracaoResponse)
def buscar_configuracao_por_chave(
    chave: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Buscar configuração por chave
    
    **Permissão:** Apenas Master
    """
    config = Configuracao.get_by_chave(db, chave)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Configuração '{chave}' não encontrada"
        )
    
    return ConfiguracaoResponse(**config.to_dict(include_valor=True))


@router.get("/{configuracao_id}", response_model=ConfiguracaoResponse)
def buscar_configuracao(
    configuracao_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Buscar configuração por ID
    
    **Permissão:** Apenas Master
    """
    config = db.query(Configuracao).filter(Configuracao.id == configuracao_id).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    return ConfiguracaoResponse(**config.to_dict(include_valor=True))


@router.post("/", response_model=ConfiguracaoResponse, status_code=status.HTTP_201_CREATED)
def criar_configuracao(
    config_data: ConfiguracaoCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Criar nova configuração
    
    **Permissão:** Apenas Master
    
    **Body:**
    - `chave`: Identificador único
    - `valor`: Valor da configuração
    - `tipo`: Tipo (trello, whatsapp, sistema)
    - `descricao`: Descrição (opcional)
    - `is_sensivel`: Se deve criptografar (padrão: false)
    """
    # Verificar se já existe
    existing = Configuracao.get_by_chave(db, config_data.chave)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Configuração com chave '{config_data.chave}' já existe"
        )
    
    # Criar configuração
    config = Configuracao(
        chave=config_data.chave,
        tipo=config_data.tipo,
        descricao=config_data.descricao
    )
    config.set_valor(config_data.valor, config_data.is_sensivel)
    
    db.add(config)
    db.commit()
    db.refresh(config)
    
    return ConfiguracaoResponse(**config.to_dict(include_valor=True))


@router.put("/{configuracao_id}", response_model=ConfiguracaoResponse)
def atualizar_configuracao(
    configuracao_id: str,
    config_data: ConfiguracaoUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualizar configuração
    
    **Permissão:** Apenas Master
    
    **Body:**
    - `valor`: Novo valor (opcional)
    - `descricao`: Nova descrição (opcional)
    - `is_sensivel`: Se deve criptografar (opcional)
    """
    config = db.query(Configuracao).filter(Configuracao.id == configuracao_id).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    # Atualizar campos
    if config_data.valor is not None:
        is_sensivel = config_data.is_sensivel if config_data.is_sensivel is not None else (config.is_sensivel == "true")
        config.set_valor(config_data.valor, is_sensivel)
    
    if config_data.descricao is not None:
        config.descricao = config_data.descricao
    
    db.commit()
    db.refresh(config)
    
    return ConfiguracaoResponse(**config.to_dict(include_valor=True))


@router.delete("/{configuracao_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_configuracao(
    configuracao_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deletar configuração
    
    **Permissão:** Apenas Master
    
    **ATENÇÃO:** Esta ação é irreversível!
    """
    config = db.query(Configuracao).filter(Configuracao.id == configuracao_id).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    db.delete(config)
    db.commit()
    
    return None


@router.post("/seed", status_code=status.HTTP_201_CREATED)
def seed_configuracoes_padrao(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Criar configurações padrão do sistema
    
    **Permissão:** Apenas Master
    
    **Retorna:**
    - Número de configurações criadas
    """
    criadas = Configuracao.criar_configuracoes_padrao(db)
    
    return {
        "mensagem": f"{criadas} configurações padrão criadas com sucesso",
        "criadas": criadas
    }


# ==================== TESTES DE CONEXÃO ====================

@router.post("/testar/trello", response_model=TesteConexaoResponse)
def testar_conexao_trello(
    credentials: ConfiguracaoTestarTrello,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Testar conexão com Trello
    
    **Permissão:** Apenas Master
    
    **Body:**
    - `api_key`: API Key do Trello
    - `token`: Token do Trello
    - `board_id`: Board ID (opcional)
    
    **Retorna:**
    - `sucesso`: Se a conexão funcionou
    - `mensagem`: Mensagem de status
    - `detalhes`: Informações adicionais (boards, listas, etc)
    """
    try:
        from trello import TrelloClient
        
        # Tentar conectar
        client = TrelloClient(
            api_key=credentials.api_key,
            token=credentials.token
        )
        
        # Listar boards para validar
        boards = client.list_boards()
        
        detalhes = {
            "total_boards": len(boards),
            "boards": [{"id": b.id, "name": b.name} for b in boards[:5]]  # Primeiros 5
        }
        
        # Se board_id fornecido, buscar listas
        if credentials.board_id:
            try:
                board = client.get_board(credentials.board_id)
                lists = board.list_lists()
                detalhes["board_nome"] = board.name
                detalhes["total_listas"] = len(lists)
                detalhes["listas"] = [{"id": l.id, "name": l.name} for l in lists]
            except Exception as e:
                detalhes["erro_board"] = str(e)
        
        return TesteConexaoResponse(
            sucesso=True,
            mensagem="✅ Conexão com Trello estabelecida com sucesso!",
            detalhes=detalhes
        )
        
    except Exception as e:
        return TesteConexaoResponse(
            sucesso=False,
            mensagem=f"❌ Erro ao conectar com Trello: {str(e)}",
            detalhes={"erro": str(e)}
        )


@router.post("/testar/whatsapp", response_model=TesteConexaoResponse)
def testar_conexao_whatsapp(
    credentials: ConfiguracaoTestarWhatsApp,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Testar conexão com WhatsApp (WPPConnect)
    
    **Permissão:** Apenas Master
    
    **Body:**
    - `url`: URL da instância WPPConnect
    - `instance`: Nome da instância
    - `token`: Token de autenticação
    - `numero_teste`: Número para enviar mensagem teste (opcional)
    
    **Retorna:**
    - `sucesso`: Se a conexão funcionou
    - `mensagem`: Mensagem de status
    - `detalhes`: Status da conexão, bateria, etc
    """
    try:
        import requests
        
        # Verificar status da instância
        response = requests.get(
            f"{credentials.url}/api/{credentials.instance}/status-session",
            headers={"Authorization": f"Bearer {credentials.token}"},
            timeout=5
        )
        
        if response.status_code != 200:
            return TesteConexaoResponse(
                sucesso=False,
                mensagem=f"❌ Erro ao conectar: HTTP {response.status_code}",
                detalhes={"status_code": response.status_code, "response": response.text}
            )
        
        data = response.json()
        
        detalhes = {
            "status": data.get("status"),
            "state": data.get("state"),
            "battery": data.get("battery"),
        }
        
        # Se número de teste fornecido, enviar mensagem
        if credentials.numero_teste:
            try:
                msg_response = requests.post(
                    f"{credentials.url}/api/{credentials.instance}/send-message",
                    headers={"Authorization": f"Bearer {credentials.token}"},
                    json={
                        "phone": credentials.numero_teste,
                        "message": "✅ Teste de conexão DeBrief - Sistema operacional!"
                    },
                    timeout=10
                )
                detalhes["mensagem_enviada"] = msg_response.status_code == 200
            except Exception as e:
                detalhes["erro_envio"] = str(e)
        
        if data.get("state") == "CONNECTED":
            return TesteConexaoResponse(
                sucesso=True,
                mensagem="✅ Conexão com WhatsApp ativa e funcionando!",
                detalhes=detalhes
            )
        else:
            return TesteConexaoResponse(
                sucesso=False,
                mensagem=f"⚠️ WhatsApp não está conectado. Status: {data.get('state')}",
                detalhes=detalhes
            )
        
    except requests.exceptions.Timeout:
        return TesteConexaoResponse(
            sucesso=False,
            mensagem="❌ Timeout ao conectar com WPPConnect (sem resposta)",
            detalhes={"erro": "Timeout"}
        )
    except Exception as e:
        return TesteConexaoResponse(
            sucesso=False,
            mensagem=f"❌ Erro ao conectar com WhatsApp: {str(e)}",
            detalhes={"erro": str(e)}
        )

