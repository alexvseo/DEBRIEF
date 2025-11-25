"""
Serviço de Notificações via WhatsApp
Gerencia envio de notificações individuais para usuários baseado em regras de negócio

Regras:
1. Usuários Master recebem notificações de TODAS as demandas
2. Usuários comuns recebem notificações APENAS de demandas do seu cliente
3. Apenas notificações individuais (sem grupos)
4. Usuários podem desabilitar notificações (campo receber_notificacoes)

Eventos que disparam notificações:
- Nova demanda criada
- Demanda atualizada
- Demanda excluída
- Status mudou para "em desenvolvimento"
- Status mudou para "concluída"
"""
import logging
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.demanda import Demanda, StatusDemanda
from app.models.notification_log import NotificationLog, TipoNotificacao, StatusNotificacao
from app.services.whatsapp import WhatsAppService
import json

logger = logging.getLogger(__name__)


class NotificationService:
    """
    Serviço de Notificações
    
    Gerencia o envio de notificações via WhatsApp para usuários,
    respeitando as regras de segmentação por cliente.
    
    Exemplo:
        ```python
        notification_service = NotificationService(db)
        notification_service.notificar_nova_demanda(demanda)
        ```
    """
    
    def __init__(self, db: Session):
        """
        Inicializar serviço de notificações
        
        Args:
            db: Sessão do banco de dados
        """
        self.db = db
        self.whatsapp_service = WhatsAppService()
    
    def _obter_usuarios_para_notificar(self, demanda: Demanda) -> List[User]:
        """
        Obter lista de usuários que devem receber notificação sobre uma demanda
        
        Regras:
        - Usuários Master: recebem TODAS as notificações
        - Usuários comuns: recebem apenas notificações do seu cliente
        - Apenas usuários ativos com WhatsApp cadastrado e notificações ativadas
        
        Args:
            demanda: Demanda relacionada à notificação
        
        Returns:
            Lista de usuários que devem receber notificação
        """
        # Query base: usuários ativos, com WhatsApp e notificações habilitadas
        query = self.db.query(User).filter(
            User.ativo == True,
            User.whatsapp.isnot(None),
            User.whatsapp != "",
            User.receber_notificacoes == True
        )
        
        # Buscar usuários Master (recebem tudo) + usuários do mesmo cliente
        usuarios = query.filter(
            (User.tipo == "master") | (User.cliente_id == demanda.cliente_id)
        ).all()
        
        logger.info(
            f"Notificação demanda {demanda.id}: "
            f"{len(usuarios)} usuários para notificar "
            f"(cliente: {demanda.cliente_id})"
        )
        
        return usuarios
    
    def _enviar_notificacao_usuario(
        self,
        usuario: User,
        mensagem: str,
        demanda: Demanda,
        evento: str
    ) -> bool:
        """
        Enviar notificação individual para um usuário
        
        Args:
            usuario: Usuário destinatário
            mensagem: Texto da mensagem
            demanda: Demanda relacionada
            evento: Tipo de evento (criar, atualizar, excluir, etc)
        
        Returns:
            True se enviado com sucesso
        """
        try:
            # Enviar mensagem individual
            sucesso = self.whatsapp_service.enviar_mensagem_individual(
                numero=usuario.whatsapp,
                mensagem=mensagem
            )
            
            # Registrar log
            log_status = StatusNotificacao.ENVIADO if sucesso else StatusNotificacao.ERRO
            log = NotificationLog(
                demanda_id=demanda.id,
                tipo=TipoNotificacao.WHATSAPP,
                status=log_status,
                mensagem_erro=None if sucesso else "Falha ao enviar mensagem",
                tentativas="1",
                dados_enviados=json.dumps({
                    "usuario_id": usuario.id,
                    "usuario_nome": usuario.nome_completo,
                    "whatsapp": usuario.whatsapp,
                    "evento": evento
                })
            )
            self.db.add(log)
            self.db.commit()
            
            if sucesso:
                logger.info(f"Notificação enviada para {usuario.nome_completo} ({usuario.whatsapp})")
            else:
                logger.warning(f"Falha ao enviar notificação para {usuario.nome_completo}")
            
            return sucesso
            
        except Exception as e:
            logger.error(f"Erro ao notificar {usuario.nome_completo}: {e}")
            
            # Registrar erro no log
            log = NotificationLog(
                demanda_id=demanda.id,
                tipo=TipoNotificacao.WHATSAPP,
                status=StatusNotificacao.ERRO,
                mensagem_erro=str(e),
                tentativas="1",
                dados_enviados=json.dumps({
                    "usuario_id": usuario.id,
                    "whatsapp": usuario.whatsapp,
                    "evento": evento
                })
            )
            self.db.add(log)
            self.db.commit()
            
            return False
    
    def notificar_nova_demanda(self, demanda: Demanda) -> int:
        """
        Notificar sobre nova demanda criada
        
        Args:
            demanda: Demanda criada
        
        Returns:
            Número de notificações enviadas com sucesso
        """
        logger.info(f"Iniciando notificações para nova demanda: {demanda.nome}")
        
        # Recarregar relacionamentos
        self.db.refresh(demanda)
        
        # Obter usuários para notificar
        usuarios = self._obter_usuarios_para_notificar(demanda)
        
        if not usuarios:
            logger.info("Nenhum usuário para notificar")
            return 0
        
        # Emoji de prioridade
        emoji_prioridade = {
            "Baixa": "🟢",
            "Média": "🟡",
            "Alta": "🟠",
            "Urgente": "🔴"
        }.get(demanda.prioridade.nome, "📌")
        
        # Obter URL do sistema
        from app.core.config import settings
        base_url = settings.FRONTEND_URL or "http://82.25.92.217:2022"
        url_sistema = f"{base_url}/demanda/{demanda.id}"
        
        # Construir mensagem
        mensagem = f"""
🔔 *Nova Demanda Criada!*

📋 *Demanda:* {demanda.nome}
🏢 *Cliente:* {demanda.cliente.nome}
🏛️ *Secretaria:* {demanda.secretaria.nome}
📌 *Tipo:* {demanda.tipo_demanda.nome}
{emoji_prioridade} *Prioridade:* {demanda.prioridade.nome}
📅 *Prazo:* {demanda.prazo_final.strftime('%d/%m/%Y')}

👤 *Solicitante:* {demanda.usuario.nome_completo}

🔗 *Ver no Sistema:* {url_sistema}

_ID: {demanda.id}_
        """.strip()
        
        # Enviar para cada usuário
        enviados = 0
        for usuario in usuarios:
            if self._enviar_notificacao_usuario(usuario, mensagem, demanda, "criar"):
                enviados += 1
        
        logger.info(f"Nova demanda: {enviados}/{len(usuarios)} notificações enviadas")
        return enviados
    
    def notificar_atualizacao_demanda(
        self,
        demanda: Demanda,
        campos_alterados: Optional[dict] = None
    ) -> int:
        """
        Notificar sobre atualização de demanda
        
        Args:
            demanda: Demanda atualizada
            campos_alterados: Dicionário com campos alterados (opcional)
        
        Returns:
            Número de notificações enviadas com sucesso
        """
        logger.info(f"Iniciando notificações para atualização da demanda: {demanda.nome}")
        
        # Recarregar relacionamentos
        self.db.refresh(demanda)
        
        # Obter usuários para notificar
        usuarios = self._obter_usuarios_para_notificar(demanda)
        
        if not usuarios:
            return 0
        
        # Obter URL do sistema
        from app.core.config import settings
        base_url = settings.FRONTEND_URL or "http://82.25.92.217:2022"
        url_sistema = f"{base_url}/demanda/{demanda.id}"
        
        # Construir mensagem
        mensagem = f"""
🔄 *Demanda Atualizada*

📋 *Demanda:* {demanda.nome}
🏢 *Cliente:* {demanda.cliente.nome}
🏛️ *Secretaria:* {demanda.secretaria.nome}
📊 *Status:* {demanda.status.value.replace('_', ' ').title()}

🔗 *Ver detalhes:* {url_sistema}

_ID: {demanda.id}_
        """.strip()
        
        # Enviar para cada usuário
        enviados = 0
        for usuario in usuarios:
            if self._enviar_notificacao_usuario(usuario, mensagem, demanda, "atualizar"):
                enviados += 1
        
        logger.info(f"Atualização: {enviados}/{len(usuarios)} notificações enviadas")
        return enviados
    
    def notificar_mudanca_status(
        self,
        demanda: Demanda,
        status_antigo: str,
        status_novo: str
    ) -> int:
        """
        Notificar sobre mudança de status
        
        Args:
            demanda: Demanda com status atualizado
            status_antigo: Status anterior
            status_novo: Novo status
        
        Returns:
            Número de notificações enviadas com sucesso
        """
        logger.info(f"Notificando mudança de status: {status_antigo} → {status_novo}")
        
        # Recarregar relacionamentos
        self.db.refresh(demanda)
        
        # Obter usuários para notificar
        usuarios = self._obter_usuarios_para_notificar(demanda)
        
        if not usuarios:
            return 0
        
        # Emoji de status
        emoji_status = {
            "aberta": "📂",
            "em_andamento": "⚙️",
            "em_desenvolvimento": "💻",
            "concluida": "✅",
            "cancelada": "❌"
        }.get(status_novo, "📊")
        
        # Mensagem especial para status importantes
        titulo = "🔄 *Status Atualizado*"
        if status_novo == "em_desenvolvimento":
            titulo = "💻 *Demanda em Desenvolvimento!*"
        elif status_novo == "concluida":
            titulo = "✅ *Demanda Concluída!*"
        
        # Obter URL do sistema
        from app.core.config import settings
        base_url = settings.FRONTEND_URL or "http://82.25.92.217:2022"
        url_sistema = f"{base_url}/demanda/{demanda.id}"
        
        mensagem = f"""
{titulo}

📋 *Demanda:* {demanda.nome}
🏢 *Cliente:* {demanda.cliente.nome}

{emoji_status} *Status:* {status_antigo.replace('_', ' ').title()} → *{status_novo.replace('_', ' ').title()}*

🔗 *Ver no Sistema:* {url_sistema}

_ID: {demanda.id}_
        """.strip()
        
        # Enviar para cada usuário
        enviados = 0
        for usuario in usuarios:
            if self._enviar_notificacao_usuario(usuario, mensagem, demanda, f"status_{status_novo}"):
                enviados += 1
        
        logger.info(f"Mudança status: {enviados}/{len(usuarios)} notificações enviadas")
        return enviados
    
    def notificar_exclusao_demanda(self, demanda: Demanda) -> int:
        """
        Notificar sobre exclusão de demanda
        
        Args:
            demanda: Demanda a ser excluída
        
        Returns:
            Número de notificações enviadas com sucesso
        """
        logger.info(f"Iniciando notificações para exclusão da demanda: {demanda.nome}")
        
        # Recarregar relacionamentos
        self.db.refresh(demanda)
        
        # Obter usuários para notificar
        usuarios = self._obter_usuarios_para_notificar(demanda)
        
        if not usuarios:
            return 0
        
        # Construir mensagem
        mensagem = f"""
🗑️ *Demanda Excluída*

📋 *Demanda:* {demanda.nome}
🏢 *Cliente:* {demanda.cliente.nome}
🏛️ *Secretaria:* {demanda.secretaria.nome}

⚠️ Esta demanda foi removida do sistema.

_ID: {demanda.id}_
        """.strip()
        
        # Enviar para cada usuário
        enviados = 0
        for usuario in usuarios:
            if self._enviar_notificacao_usuario(usuario, mensagem, demanda, "excluir"):
                enviados += 1
        
        logger.info(f"Exclusão: {enviados}/{len(usuarios)} notificações enviadas")
        return enviados
