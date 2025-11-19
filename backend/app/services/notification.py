"""
Serviço de gerenciamento de notificações

Este serviço centraliza o envio de notificações através de diferentes canais
(WhatsApp, Email, etc) e mantém logs de notificações enviadas.

Funcionalidades:
- Enviar notificações multi-canal
- Log de notificações enviadas
- Retry automático em caso de falha
- Agrupamento de notificações

Autor: DeBrief Sistema
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from app.services.whatsapp import WhatsAppService
from app.models.demanda import Demanda
import logging

# Configurar logger
logger = logging.getLogger(__name__)


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
    
    async def notificar_nova_demanda(
        self,
        demanda: Demanda,
        db: Session,
        canais: Optional[List[str]] = None
    ) -> dict:
        """
        Enviar notificações sobre nova demanda
        
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
        
        # WhatsApp
        if 'whatsapp' in canais:
            try:
                success = await self.whatsapp.enviar_nova_demanda(demanda, db)
                resultados['whatsapp'] = {
                    'success': success,
                    'message': 'Enviado com sucesso' if success else 'Falha no envio'
                }
                logger.info(f"Notificação WhatsApp para demanda {demanda.id}: {success}")
            except Exception as e:
                logger.error(f"Erro ao enviar notificação WhatsApp: {e}")
                resultados['whatsapp'] = {
                    'success': False,
                    'message': str(e)
                }
        
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
        Enviar notificações sobre mudança de status
        
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
            try:
                success = await self.whatsapp.enviar_atualizacao_status(
                    demanda, db, status_antigo
                )
                resultados['whatsapp'] = {
                    'success': success,
                    'message': 'Enviado com sucesso' if success else 'Falha no envio'
                }
            except Exception as e:
                logger.error(f"Erro ao enviar atualização WhatsApp: {e}")
                resultados['whatsapp'] = {
                    'success': False,
                    'message': str(e)
                }
        
        return resultados
    
    async def notificar_lembrete_prazo(
        self,
        demanda: Demanda,
        db: Session,
        dias_faltando: int,
        canais: Optional[List[str]] = None
    ) -> dict:
        """
        Enviar lembretes de prazo próximo
        
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
            try:
                success = await self.whatsapp.enviar_lembrete_prazo(
                    demanda, db, dias_faltando
                )
                resultados['whatsapp'] = {
                    'success': success,
                    'message': 'Enviado com sucesso' if success else 'Falha no envio'
                }
            except Exception as e:
                logger.error(f"Erro ao enviar lembrete WhatsApp: {e}")
                resultados['whatsapp'] = {
                    'success': False,
                    'message': str(e)
                }
        
        return resultados

