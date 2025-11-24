"""
Endpoints de Webhook do Trello
Recebe e processa eventos do Trello (movimentação de cards, atualizações, etc)
"""
from fastapi import APIRouter, Depends, HTTPException, status, Request, Header
from sqlalchemy.orm import Session
from typing import Optional
from app.core.dependencies import get_db
from app.models.demanda import Demanda, StatusDemanda
from app.models.configuracao_trello import ConfiguracaoTrello
from app.services.notification_whatsapp import NotificationWhatsAppService
import logging
import hashlib
import hmac
import base64

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/trello", tags=["Webhook Trello"])


# ==================== MAPEAMENTO LISTA → STATUS ====================

def mapear_lista_para_status(lista_id: str, config: ConfiguracaoTrello, db: Session) -> Optional[str]:
    """
    Mapeia o ID de uma lista do Trello para um status do DeBrief
    
    Usa mapeamento direto por ID para evitar chamadas à API do Trello
    que podem resultar em erro 403.
    
    Args:
        lista_id: ID da lista do Trello
        config: Configuração ativa do Trello (não usado, mantido por compatibilidade)
        db: Sessão do banco (não usado, mantido por compatibilidade)
    
    Returns:
        Status correspondente ou None
    """
    # Mapeamento DIRETO por ID de lista → status
    # Configurado para as listas específicas do board DeBrief
    mapeamento_por_id = {
        # Lista: ENVIOS DOS CLIENTES VIA DEBRIEF
        '6810f40131d456a240f184ba': StatusDemanda.ABERTA.value,
        
        # Lista: EM DESENVOLVIMENTO
        '68b82f29253b5480f0c06f3d': StatusDemanda.EM_ANDAMENTO.value,
        
        # Lista: EM ESPERA (= CONCLUÍDA no DeBrief)
        '5ea097406d864d89b0017aa3': StatusDemanda.CONCLUIDA.value,
    }
    
    # Buscar status pelo ID da lista
    status = mapeamento_por_id.get(lista_id)
    
    if status:
        logger.info(f"Lista ID '{lista_id}' mapeada para status '{status}'")
        return status
    else:
        logger.warning(f"Lista ID '{lista_id}' não encontrada no mapeamento")
        return None


# ==================== VALIDAR WEBHOOK ====================

def validar_webhook_trello(
    payload: bytes,
    signature: Optional[str],
    callback_url: str,
    secret: str
) -> bool:
    """
    Validar assinatura do webhook do Trello
    
    Args:
        payload: Corpo da requisição (bytes)
        signature: Assinatura enviada no header X-Trello-Webhook
        callback_url: URL do callback
        secret: Secret configurado no webhook
    
    Returns:
        True se válido, False caso contrário
    """
    if not signature or not secret:
        return False
    
    try:
        # Trello usa HMAC SHA1
        # Concatena: payload + callback_url
        content = payload + callback_url.encode('utf-8')
        
        # Calcular hash
        expected_signature = base64.b64encode(
            hmac.new(
                secret.encode('utf-8'),
                content,
                hashlib.sha1
            ).digest()
        ).decode('utf-8')
        
        # Comparar assinaturas
        return hmac.compare_digest(signature, expected_signature)
        
    except Exception as e:
        logger.error(f"Erro ao validar webhook: {e}")
        return False


# ==================== HEAD REQUEST (TRELLO VALIDATION) ====================

@router.head("/webhook")
async def webhook_head():
    """
    Endpoint HEAD para validação inicial do webhook pelo Trello
    
    O Trello envia um HEAD request para validar que a URL está acessível
    """
    return {"status": "ok"}


# ==================== WEBHOOK ENDPOINT ====================

@router.post("/webhook")
async def processar_webhook_trello(
    request: Request,
    db: Session = Depends(get_db),
    x_trello_webhook: Optional[str] = Header(None)
):
    """
    Processar eventos do webhook do Trello
    
    Eventos suportados:
    - updateCard: Quando um card é movido entre listas ou atualizado
    - commentCard: Quando um comentário é adicionado (futuro)
    
    Args:
        request: Requisição HTTP completa
        db: Sessão do banco
        x_trello_webhook: Assinatura do webhook (header)
    
    Returns:
        dict: Status do processamento
    """
    try:
        # Ler corpo da requisição
        payload_bytes = await request.body()
        payload = await request.json()
        
        # Log do evento recebido
        action_type = payload.get('action', {}).get('type')
        logger.info(f"Webhook Trello recebido: {action_type}")
        
        # Buscar configuração ativa
        config = ConfiguracaoTrello.get_ativa(db)
        if not config:
            logger.warning("Webhook recebido mas não há configuração Trello ativa")
            return {"status": "ignored", "reason": "no_active_config"}
        
        # Validar assinatura (opcional, mas recomendado em produção)
        # callback_url = str(request.url)
        # if not validar_webhook_trello(payload_bytes, x_trello_webhook, callback_url, "SEU_SECRET"):
        #     raise HTTPException(
        #         status_code=status.HTTP_401_UNAUTHORIZED,
        #         detail="Assinatura inválida"
        #     )
        
        # Processar evento
        action = payload.get('action', {})
        action_type = action.get('type')
        
        # ========== EVENTO: CARD MOVIDO ENTRE LISTAS ==========
        if action_type == 'updateCard':
            # Verificar se houve mudança de lista
            data = action.get('data', {})
            old_list = data.get('listBefore')
            new_list = data.get('listAfter')
            card_id = data.get('card', {}).get('id')
            
            if not card_id:
                logger.warning("Card ID não encontrado no webhook")
                return {"status": "ignored", "reason": "no_card_id"}
            
            # Se mudou de lista
            if old_list and new_list and old_list.get('id') != new_list.get('id'):
                logger.info(
                    f"Card {card_id} movido de "
                    f"'{old_list.get('name')}' para '{new_list.get('name')}'"
                )
                
                # Buscar demanda pelo trello_card_id
                demanda = db.query(Demanda).filter(
                    Demanda.trello_card_id == card_id
                ).first()
                
                if not demanda:
                    logger.warning(f"Demanda não encontrada para card {card_id}")
                    return {"status": "ignored", "reason": "demanda_not_found"}
                
                # Mapear nova lista para status
                novo_status = mapear_lista_para_status(
                    new_list.get('id'),
                    config,
                    db
                )
                
                if not novo_status:
                    logger.warning(f"Não foi possível mapear lista para status")
                    return {"status": "ignored", "reason": "no_status_mapping"}
                
                # Guardar status antigo
                status_antigo = demanda.status.value if demanda.status else None
                
                # Atualizar status da demanda
                demanda.status = novo_status
                db.commit()
                db.refresh(demanda)
                
                logger.info(
                    f"Demanda {demanda.id} atualizada: "
                    f"{status_antigo} → {novo_status}"
                )
                
                # Enviar notificação WhatsApp (opcional)
                try:
                    notification_service = NotificationWhatsAppService()
                    await notification_service.notificar_mudanca_status(
                        demanda=demanda,
                        status_antigo=status_antigo,
                        db=db
                    )
                    logger.info("Notificação WhatsApp enviada")
                except Exception as e:
                    logger.error(f"Erro ao enviar notificação: {e}")
                    # Não falhar o webhook por erro de notificação
                
                return {
                    "status": "success",
                    "demanda_id": demanda.id,
                    "status_antigo": status_antigo,
                    "status_novo": novo_status,
                    "card_id": card_id
                }
        
        # ========== OUTROS EVENTOS (FUTURO) ==========
        elif action_type == 'commentCard':
            # Processar comentários (implementação futura)
            logger.info("Evento de comentário recebido (não implementado)")
            return {"status": "ignored", "reason": "comment_not_implemented"}
        
        # Evento não tratado
        logger.info(f"Evento '{action_type}' não tratado")
        return {"status": "ignored", "reason": "event_not_handled"}
        
    except Exception as e:
        logger.error(f"Erro ao processar webhook: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao processar webhook: {str(e)}"
        )

