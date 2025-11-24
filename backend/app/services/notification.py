"""
Serviço de gerenciamento de notificações

Este serviço centraliza o envio de notificações através de diferentes canais
(WhatsApp, Email, etc) e mantém logs de notificações enviadas.

Funcionalidades:
- Enviar notificações multi-canal
- Log de notificações enviadas
- Retry automático em caso de falha (3 tentativas com backoff exponencial)
- Agrupamento de notificações

Autor: DeBrief Sistema
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from app.services.whatsapp import WhatsAppService
from app.models.demanda import Demanda
from app.models.notification_log import NotificationLog, TipoNotificacao, StatusNotificacao
import logging
import asyncio
import json

# Configurar logger
logger = logging.getLogger(__name__)

# Configurações de retry
MAX_RETRIES = 3
INITIAL_RETRY_DELAY = 1  # segundos
RETRY_BACKOFF_MULTIPLIER = 2  # Multiplicador para backoff exponencial


class NotificationService:
    """
    Serviço centralizado para notificações
    
    Gerencia o envio de notificações através de diferentes canais
    e mantém histórico de notificações enviadas.
    
    Exemplo de uso:
        ```python
        notification_service = NotificationService()
        await notification_service.notificar_nova_demanda(demanda, db)
        ```
    """
    
    def __init__(self):
        """
        Inicializar serviço de notificações
        """
        self.whatsapp = WhatsAppService()
        logger.info("NotificationService inicializado")
    
    async def _enviar_com_retry(
        self,
        func,
        demanda: Demanda,
        db: Session,
        tipo: TipoNotificacao,
        *args,
        **kwargs
    ) -> dict:
        """
        Enviar notificação com retry automático (3 tentativas com backoff exponencial)
        
        Args:
            func: Função async para enviar notificação
            demanda: Objeto Demanda
            db: Sessão do banco
            tipo: Tipo de notificação
            *args: Argumentos adicionais para func
            **kwargs: Argumentos nomeados para func
        
        Returns:
            dict: Resultado do envio
        """
        tentativas = 0
        delay = INITIAL_RETRY_DELAY
        ultimo_erro = None
        
        while tentativas < MAX_RETRIES:
            tentativas += 1
            
            try:
                # Tentar enviar
                success = await func(demanda, db, *args, **kwargs)
                
                if success:
                    # Sucesso - criar log
                    log = NotificationLog(
                        demanda_id=demanda.id,
                        tipo=tipo,
                        status=StatusNotificacao.ENVIADO,
                        tentativas=str(tentativas),
                        dados_enviados=json.dumps({
                            "demanda_id": demanda.id,
                            "demanda_nome": demanda.nome
                        })
                    )
                    db.add(log)
                    db.commit()
                    
                    logger.info(f"Notificação {tipo.value} enviada com sucesso (tentativa {tentativas})")
                    return {
                        'success': True,
                        'message': 'Enviado com sucesso',
                        'tentativas': tentativas
                    }
                else:
                    # Falha mas sem exceção
                    ultimo_erro = "Falha no envio (retornou False)"
                    
            except Exception as e:
                ultimo_erro = str(e)
                logger.warning(f"Tentativa {tentativas}/{MAX_RETRIES} falhou: {e}")
            
            # Se não foi a última tentativa, aguardar antes de tentar novamente
            if tentativas < MAX_RETRIES:
                logger.info(f"Aguardando {delay}s antes da próxima tentativa...")
                await asyncio.sleep(delay)
                delay *= RETRY_BACKOFF_MULTIPLIER  # Backoff exponencial
        
        # Todas as tentativas falharam - criar log de erro
        log = NotificationLog(
            demanda_id=demanda.id,
            tipo=tipo,
            status=StatusNotificacao.ERRO,
            mensagem_erro=ultimo_erro or "Falha após múltiplas tentativas",
            tentativas=str(tentativas),
            dados_enviados=json.dumps({
                "demanda_id": demanda.id,
                "demanda_nome": demanda.nome
            })
        )
        db.add(log)
        db.commit()
        
        logger.error(f"Falha ao enviar notificação {tipo.value} após {tentativas} tentativas: {ultimo_erro}")
        return {
            'success': False,
            'message': ultimo_erro or 'Falha após múltiplas tentativas',
            'tentativas': tentativas
        }
    
    async def notificar_nova_demanda(
        self,
        demanda: Demanda,
        db: Session,
        canais: Optional[List[str]] = None
    ) -> dict:
        """
        Enviar notificações sobre nova demanda com retry automático
        
        Args:
            demanda: Objeto Demanda
            db: Sessão do banco
            canais: Lista de canais (default: ['whatsapp'])
        
        Returns:
            Dicionário com resultado de cada canal
        """
        if canais is None:
            canais = ['whatsapp']
        
        resultados = {}
        
        # WhatsApp com retry
        if 'whatsapp' in canais:
            resultado = await self._enviar_com_retry(
                self.whatsapp.enviar_nova_demanda,
                demanda,
                db,
                TipoNotificacao.WHATSAPP
            )
            resultados['whatsapp'] = resultado
        
        # Email (futuro)
        if 'email' in canais:
            resultados['email'] = {
                'success': False,
                'message': 'Email não implementado ainda'
            }
        
        return resultados
    
    async def notificar_atualizacao_status(
        self,
        demanda: Demanda,
        db: Session,
        status_antigo: str,
        canais: Optional[List[str]] = None
    ) -> dict:
        """
        Enviar notificações sobre mudança de status com retry automático
        
        Args:
            demanda: Objeto Demanda
            db: Sessão do banco
            status_antigo: Status anterior
            canais: Lista de canais
        
        Returns:
            Dicionário com resultado de cada canal
        """
        if canais is None:
            canais = ['whatsapp']
        
        resultados = {}
        
        if 'whatsapp' in canais:
            resultado = await self._enviar_com_retry(
                self.whatsapp.enviar_atualizacao_status,
                demanda,
                db,
                TipoNotificacao.WHATSAPP,
                status_antigo
            )
            resultados['whatsapp'] = resultado
        
        return resultados
    
    async def notificar_lembrete_prazo(
        self,
        demanda: Demanda,
        db: Session,
        dias_faltando: int,
        canais: Optional[List[str]] = None
    ) -> dict:
        """
        Enviar lembretes de prazo próximo com retry automático
        
        Args:
            demanda: Objeto Demanda
            db: Sessão do banco
            dias_faltando: Dias até o prazo
            canais: Lista de canais
        
        Returns:
            Dicionário com resultado de cada canal
        """
        if canais is None:
            canais = ['whatsapp']
        
        resultados = {}
        
        if 'whatsapp' in canais:
            resultado = await self._enviar_com_retry(
                self.whatsapp.enviar_lembrete_prazo,
                demanda,
                db,
                TipoNotificacao.WHATSAPP,
                dias_faltando
            )
            resultados['whatsapp'] = resultado
        
        return resultados

