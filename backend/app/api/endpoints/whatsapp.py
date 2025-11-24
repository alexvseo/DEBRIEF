"""
Endpoints para gerenciamento de configurações WhatsApp
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.dependencies import get_db, get_current_user, require_master
from app.models.user import User
from app.models.configuracao_whatsapp import ConfiguracaoWhatsApp
from app.models.template_mensagem import TemplateMensagem
from app.schemas.configuracao_whatsapp import (
    ConfiguracaoWhatsAppCreate,
    ConfiguracaoWhatsAppUpdate,
    ConfiguracaoWhatsAppResponse,
    TestarConexaoWhatsAppRequest
)
from app.schemas.template_mensagem import (
    TemplateMensagemCreate,
    TemplateMensagemUpdate,
    TemplateMensagemResponse,
    VariaveisDisponiveisResponse,
    PreviewTemplateRequest,
    PreviewTemplateResponse
)
from app.services.whatsapp import WhatsAppService
import logging
import re

router = APIRouter()
logger = logging.getLogger(__name__)

# ==================== CONFIGURAÇÕES WHATSAPP ====================

@router.get("/configuracoes", response_model=List[ConfiguracaoWhatsAppResponse])
def listar_configuracoes_whatsapp(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Listar todas as configurações WhatsApp
    
    Requer permissão: Master
    """
    configuracoes = db.query(ConfiguracaoWhatsApp).filter(
        ConfiguracaoWhatsApp.deleted_at == None
    ).all()
    
    return configuracoes


@router.get("/configuracoes/ativa", response_model=ConfiguracaoWhatsAppResponse)
def obter_configuracao_ativa(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Obter configuração WhatsApp ativa
    
    Requer permissão: Master
    """
    config = ConfiguracaoWhatsApp.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhuma configuração WhatsApp ativa encontrada"
        )
    
    return config


@router.post("/configuracoes", response_model=ConfiguracaoWhatsAppResponse, status_code=status.HTTP_201_CREATED)
def criar_configuracao_whatsapp(
    config_data: ConfiguracaoWhatsAppCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Criar nova configuração WhatsApp
    
    Se ativo=True, desativa todas as outras configurações
    
    Requer permissão: Master
    """
    # Se for ativa, desativar todas as outras
    if config_data.ativo:
        ConfiguracaoWhatsApp.desativar_todas(db)
    
    # Criar nova configuração
    nova_config = ConfiguracaoWhatsApp(**config_data.model_dump())
    db.add(nova_config)
    db.commit()
    db.refresh(nova_config)
    
    logger.info(f"Configuração WhatsApp criada: {nova_config.id} por usuário {current_user.username}")
    
    return nova_config


@router.put("/configuracoes/{config_id}", response_model=ConfiguracaoWhatsAppResponse)
def atualizar_configuracao_whatsapp(
    config_id: str,
    config_data: ConfiguracaoWhatsAppUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualizar configuração WhatsApp
    
    Se ativo=True, desativa todas as outras configurações
    
    Requer permissão: Master
    """
    config = db.query(ConfiguracaoWhatsApp).filter(
        ConfiguracaoWhatsApp.id == config_id,
        ConfiguracaoWhatsApp.deleted_at == None
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    # Se for ativar esta configuração, desativar todas as outras
    if config_data.ativo == True:
        ConfiguracaoWhatsApp.desativar_todas(db)
    
    # Atualizar campos fornecidos
    update_data = config_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(config, field, value)
    
    db.commit()
    db.refresh(config)
    
    logger.info(f"Configuração WhatsApp atualizada: {config.id} por usuário {current_user.username}")
    
    return config


@router.delete("/configuracoes/{config_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_configuracao_whatsapp(
    config_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deletar configuração WhatsApp (soft delete)
    
    Requer permissão: Master
    """
    config = db.query(ConfiguracaoWhatsApp).filter(
        ConfiguracaoWhatsApp.id == config_id,
        ConfiguracaoWhatsApp.deleted_at == None
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuração não encontrada"
        )
    
    # Soft delete
    from datetime import datetime
    config.deleted_at = datetime.utcnow()
    db.commit()
    
    logger.info(f"Configuração WhatsApp deletada: {config.id} por usuário {current_user.username}")
    
    return None


@router.post("/configuracoes/testar")
def testar_conexao_whatsapp(
    request: TestarConexaoWhatsAppRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Testar conexão WhatsApp enviando mensagem de teste
    
    Requer permissão: Master
    """
    # Obter configuração ativa
    config = ConfiguracaoWhatsApp.get_ativa(db)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhuma configuração WhatsApp ativa encontrada"
        )
    
    try:
        # Inicializar serviço WhatsApp
        whatsapp = WhatsAppService()
        
        # Enviar mensagem de teste
        sucesso = whatsapp.enviar_mensagem_individual(
            numero=request.numero_teste,
            mensagem=request.mensagem
        )
        
        if sucesso:
            return {
                "success": True,
                "message": "Mensagem de teste enviada com sucesso",
                "numero_destino": request.numero_teste
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Falha ao enviar mensagem de teste"
            )
    
    except Exception as e:
        logger.error(f"Erro ao testar conexão WhatsApp: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao testar conexão: {str(e)}"
        )


# ==================== TEMPLATES DE MENSAGENS ====================

@router.get("/templates", response_model=List[TemplateMensagemResponse])
def listar_templates(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Listar todos os templates de mensagens
    
    Requer permissão: Master
    """
    templates = db.query(TemplateMensagem).filter(
        TemplateMensagem.deleted_at == None
    ).all()
    
    return templates


@router.get("/templates/{template_id}", response_model=TemplateMensagemResponse)
def obter_template(
    template_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Obter template de mensagem por ID
    
    Requer permissão: Master
    """
    template = db.query(TemplateMensagem).filter(
        TemplateMensagem.id == template_id,
        TemplateMensagem.deleted_at == None
    ).first()
    
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Template não encontrado"
        )
    
    return template


@router.post("/templates", response_model=TemplateMensagemResponse, status_code=status.HTTP_201_CREATED)
def criar_template(
    template_data: TemplateMensagemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Criar novo template de mensagem
    
    Requer permissão: Master
    """
    # Verificar se já existe template com mesmo nome
    template_existente = db.query(TemplateMensagem).filter(
        TemplateMensagem.nome == template_data.nome,
        TemplateMensagem.deleted_at == None
    ).first()
    
    if template_existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Já existe um template com este nome"
        )
    
    # Criar template
    import json
    novo_template = TemplateMensagem(
        **template_data.model_dump(),
        variaveis_disponiveis=json.dumps(TemplateMensagem.get_variaveis_padrao())
    )
    
    db.add(novo_template)
    db.commit()
    db.refresh(novo_template)
    
    logger.info(f"Template criado: {novo_template.id} por usuário {current_user.username}")
    
    return novo_template


@router.put("/templates/{template_id}", response_model=TemplateMensagemResponse)
def atualizar_template(
    template_id: str,
    template_data: TemplateMensagemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Atualizar template de mensagem
    
    Requer permissão: Master
    """
    template = db.query(TemplateMensagem).filter(
        TemplateMensagem.id == template_id,
        TemplateMensagem.deleted_at == None
    ).first()
    
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Template não encontrado"
        )
    
    # Atualizar campos fornecidos
    update_data = template_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(template, field, value)
    
    db.commit()
    db.refresh(template)
    
    logger.info(f"Template atualizado: {template.id} por usuário {current_user.username}")
    
    return template


@router.delete("/templates/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_template(
    template_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """
    Deletar template de mensagem (soft delete)
    
    Requer permissão: Master
    """
    template = db.query(TemplateMensagem).filter(
        TemplateMensagem.id == template_id,
        TemplateMensagem.deleted_at == None
    ).first()
    
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Template não encontrado"
        )
    
    # Soft delete
    from datetime import datetime
    template.deleted_at = datetime.utcnow()
    db.commit()
    
    logger.info(f"Template deletado: {template.id} por usuário {current_user.username}")
    
    return None


@router.get("/templates/variaveis/disponiveis", response_model=VariaveisDisponiveisResponse)
def obter_variaveis_disponiveis(
    current_user: User = Depends(require_master)
):
    """
    Obter lista de variáveis disponíveis para usar nos templates
    
    Requer permissão: Master
    """
    return {
        "variaveis": TemplateMensagem.get_variaveis_padrao()
    }


@router.post("/templates/preview", response_model=PreviewTemplateResponse)
def preview_template(
    request: PreviewTemplateRequest,
    current_user: User = Depends(require_master)
):
    """
    Visualizar preview de template com dados de exemplo
    
    Requer permissão: Master
    """
    mensagem = request.mensagem
    
    # Encontrar todas as variáveis no template (formato {variavel})
    variaveis_encontradas = re.findall(r'\{(\w+)\}', mensagem)
    
    # Dados de exemplo padrão
    dados_padrao = {
        "demanda_titulo": "Criação de Landing Page",
        "demanda_descricao": "Desenvolver landing page responsiva para campanha de marketing",
        "cliente_nome": "Empresa XYZ Ltda",
        "secretaria_nome": "Comunicação Social",
        "tipo_demanda": "Desenvolvimento Web",
        "prioridade": "Alta",
        "prazo_final": "25/12/2025",
        "usuario_responsavel": "João Silva",
        "usuario_nome": "João Silva",
        "usuario_email": "joao@empresa.com",
        "data_criacao": "23/11/2025 15:30",
        "data_atualizacao": "23/11/2025 15:30",
        "status": "Em Andamento",
        "trello_card_url": "https://trello.com/c/ABC123"
    }
    
    # Usar dados fornecidos ou dados padrão
    dados = request.dados_exemplo if request.dados_exemplo else dados_padrao
    
    # Renderizar mensagem
    mensagem_renderizada = mensagem
    for chave, valor in dados.items():
        placeholder = "{" + chave + "}"
        if placeholder in mensagem_renderizada:
            mensagem_renderizada = mensagem_renderizada.replace(placeholder, str(valor))
    
    # Encontrar variáveis que não foram substituídas
    variaveis_nao_substituidas = re.findall(r'\{(\w+)\}', mensagem_renderizada)
    
    return {
        "mensagem_original": mensagem,
        "mensagem_renderizada": mensagem_renderizada,
        "variaveis_encontradas": list(set(variaveis_encontradas)),
        "variaveis_nao_substituidas": list(set(variaveis_nao_substituidas))
    }


# ==================== NOVOS ENDPOINTS - NOTIFICAÇÕES ====================

@router.get("/status")
async def verificar_status_whatsapp(
    current_user: User = Depends(get_current_user)
):
    """
    Verificar status da conexão Evolution API WhatsApp
    
    Requer: Usuário autenticado
    """
    try:
        whatsapp = WhatsAppService()
        status_info = await whatsapp.verificar_status_instancia()
        
        return {
            "connected": status_info.get("connected", False),
            "state": status_info.get("state", "unknown"),
            "instance": "debrief",
            "numero_remetente": "5585991042626",
            "details": status_info
        }
    except Exception as e:
        logger.error(f"Erro ao verificar status WhatsApp: {str(e)}")
        return {
            "connected": False,
            "state": "error",
            "instance": "debrief",
            "numero_remetente": "5585991042626",
            "error": str(e)
        }


@router.post("/testar")
def testar_notificacao_whatsapp(
    request: dict,
    current_user: User = Depends(get_current_user)
):
    """
    Enviar notificação de teste via WhatsApp
    
    Body:
    {
        "numero": "5585991042626",
        "mensagem": "Mensagem de teste"
    }
    
    Requer: Usuário autenticado
    """
    numero = request.get("numero")
    mensagem = request.get("mensagem")
    
    if not numero:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Número é obrigatório"
        )
    
    if not mensagem:
        mensagem = "✅ Teste de notificação WhatsApp - DeBrief\n\nSeu número está configurado corretamente!"
    
    try:
        # Inicializar serviço WhatsApp
        whatsapp = WhatsAppService()
        
        # Enviar mensagem de teste
        sucesso = whatsapp.enviar_mensagem_individual(
            numero=numero,
            mensagem=mensagem
        )
        
        if sucesso:
            logger.info(f"Teste de notificação enviado para {numero} por {current_user.username}")
            return {
                "success": True,
                "message": f"Notificação de teste enviada para {numero}",
                "numero_destino": numero
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Falha ao enviar notificação de teste"
            )
    
    except Exception as e:
        logger.error(f"Erro ao testar notificação WhatsApp: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao testar notificação: {str(e)}"
        )

