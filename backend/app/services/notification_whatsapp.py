"""
Serviço de Notificações WhatsApp Individuais
Gerencia o envio de notificações para usuários individuais usando templates
"""
from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.demanda import Demanda
from app.models.user import User
from app.models.configuracao_whatsapp import ConfiguracaoWhatsApp
from app.models.template_mensagem import TemplateMensagem
from app.models.notification_log import NotificationLog, TipoNotificacao, StatusNotificacao
from app.services.whatsapp import WhatsAppService
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class NotificationWhatsAppService:
    """
    Serviço para enviar notificações WhatsApp individuais usando templates
    
    Este serviço:
    1. Busca usuários que devem receber notificações
    2. Busca o template apropriado para o evento
    3. Renderiza o template com dados da demanda
    4. Envia mensagem individual via WhatsApp
    5. Registra log de notificação
    
    Exemplo de uso:
        ```python
        service = NotificationWhatsAppService(db)
        service.notificar_demanda_criada(demanda)
        ```
    """
    
    def __init__(self, db: Session):
        """
        Inicializar serviço
        
        Args:
            db: Sessão do banco de dados
        """
        self.db = db
        self.whatsapp_service = WhatsAppService()
    
    def _obter_dados_demanda(self, demanda: Demanda) -> dict:
        """
        Extrair dados da demanda para usar no template
        
        Args:
            demanda: Objeto Demanda
            
        Returns:
            Dicionário com dados para renderizar template
        """
        # Refresh para garantir que relacionamentos estão carregados
        self.db.refresh(demanda)
        
        # Obter URL base do sistema
        from app.core.config import settings
        base_url = settings.FRONTEND_URL or "http://82.25.92.217:2022"
        url_sistema = f"{base_url}/demanda/{demanda.id}"
        
        dados = {
            "demanda_titulo": demanda.nome or "",
            "demanda_descricao": demanda.descricao or "",
            "cliente_nome": demanda.cliente.nome if demanda.cliente else "",
            "secretaria_nome": demanda.secretaria.nome if demanda.secretaria else "",
            "tipo_demanda": demanda.tipo_demanda.nome if demanda.tipo_demanda else "",
            "prioridade": demanda.prioridade.nome if demanda.prioridade else "",
            "prazo_final": demanda.prazo_final.strftime("%d/%m/%Y") if demanda.prazo_final else "",
            "usuario_responsavel": demanda.usuario.nome_completo if demanda.usuario else "",
            "usuario_nome": demanda.usuario.nome_completo if demanda.usuario else "",
            "usuario_email": demanda.usuario.email if demanda.usuario else "",
            "data_criacao": demanda.created_at.strftime("%d/%m/%Y %H:%M") if demanda.created_at else "",
            "data_atualizacao": demanda.updated_at.strftime("%d/%m/%Y %H:%M") if demanda.updated_at else "",
            "status": demanda.status.value if demanda.status else "",
            "trello_card_url": demanda.trello_card_url or "",
            "url_sistema": url_sistema
        }
        
        return dados
    
    def _obter_usuarios_para_notificar(self, demanda: Demanda) -> List[User]:
        """
        Obter lista de usuários que devem receber notificações
        
        Args:
            demanda: Objeto Demanda
            
        Returns:
            Lista de usuários que devem ser notificados
        """
        # Buscar usuários do mesmo cliente que:
        # 1. Tenham WhatsApp cadastrado
        # 2. Estejam com receber_notificacoes = True
        # 3. Estejam ativos
        
        usuarios = self.db.query(User).filter(
            User.cliente_id == demanda.cliente_id,
            User.whatsapp != None,
            User.whatsapp != "",
            User.receber_notificacoes == True,
            User.ativo == True,
            User.deleted_at == None
        ).all()
        
        logger.info(f"Encontrados {len(usuarios)} usuários para notificar sobre demanda {demanda.id}")
        
        return usuarios
    
    def _enviar_notificacao(
        self,
        usuario: User,
        mensagem: str,
        demanda: Demanda,
        tipo_evento: str
    ) -> bool:
        """
        Enviar notificação para um usuário e registrar log
        
        Args:
            usuario: Usuário destinatário
            mensagem: Mensagem renderizada
            demanda: Demanda relacionada
            tipo_evento: Tipo do evento
            
        Returns:
            True se enviado com sucesso
        """
        try:
            # Enviar mensagem
            sucesso = self.whatsapp_service.enviar_mensagem_individual(
                numero=usuario.whatsapp,
                mensagem=mensagem
            )
            
            # Registrar log
            log = NotificationLog(
                demanda_id=demanda.id,
                usuario_id=usuario.id,
                tipo=TipoNotificacao.WHATSAPP,
                destinatario=usuario.whatsapp,
                mensagem=mensagem,
                status=StatusNotificacao.ENVIADO if sucesso else StatusNotificacao.ERRO,
                erro_mensagem=None if sucesso else "Falha ao enviar mensagem",
                enviado_em=datetime.utcnow() if sucesso else None,
                metadata=f'{{"tipo_evento": "{tipo_evento}"}}'
            )
            
            self.db.add(log)
            self.db.commit()
            
            return sucesso
            
        except Exception as e:
            logger.error(f"Erro ao enviar notificação para usuário {usuario.id}: {str(e)}")
            
            # Registrar log de erro
            log = NotificationLog(
                demanda_id=demanda.id,
                usuario_id=usuario.id,
                tipo=TipoNotificacao.WHATSAPP,
                destinatario=usuario.whatsapp,
                mensagem=mensagem,
                status=StatusNotificacao.ERRO,
                erro_mensagem=str(e),
                metadata=f'{{"tipo_evento": "{tipo_evento}"}}'
            )
            
            self.db.add(log)
            self.db.commit()
            
            return False
    
    def notificar_evento(
        self,
        demanda: Demanda,
        tipo_evento: str
    ) -> dict:
        """
        Notificar usuários sobre um evento de demanda
        
        Args:
            demanda: Objeto Demanda
            tipo_evento: Tipo do evento (demanda_criada, demanda_atualizada, etc)
            
        Returns:
            Dicionário com estatísticas de envio
        """
        # Verificar se há configuração WhatsApp ativa
        config = ConfiguracaoWhatsApp.get_ativa(self.db)
        if not config:
            logger.warning("Nenhuma configuração WhatsApp ativa encontrada")
            return {
                "sucesso": False,
                "mensagem": "Nenhuma configuração WhatsApp ativa",
                "enviados": 0,
                "falhas": 0
            }
        
        # Buscar template para o tipo de evento
        template = TemplateMensagem.get_by_tipo_evento(self.db, tipo_evento)
        if not template:
            logger.warning(f"Nenhum template encontrado para evento: {tipo_evento}")
            return {
                "sucesso": False,
                "mensagem": f"Nenhum template encontrado para evento: {tipo_evento}",
                "enviados": 0,
                "falhas": 0
            }
        
        # Obter usuários para notificar
        usuarios = self._obter_usuarios_para_notificar(demanda)
        if not usuarios:
            logger.info("Nenhum usuário para notificar")
            return {
                "sucesso": True,
                "mensagem": "Nenhum usuário configurado para receber notificações",
                "enviados": 0,
                "falhas": 0
            }
        
        # Obter dados da demanda
        dados = self._obter_dados_demanda(demanda)
        
        # Renderizar mensagem
        mensagem = template.renderizar(dados)
        
        # Enviar para cada usuário
        enviados = 0
        falhas = 0
        
        for usuario in usuarios:
            sucesso = self._enviar_notificacao(
                usuario=usuario,
                mensagem=mensagem,
                demanda=demanda,
                tipo_evento=tipo_evento
            )
            
            if sucesso:
                enviados += 1
            else:
                falhas += 1
        
        logger.info(f"Notificações enviadas: {enviados} sucesso, {falhas} falhas")
        
        return {
            "sucesso": True,
            "mensagem": f"Notificações processadas: {enviados} enviadas, {falhas} falhas",
            "enviados": enviados,
            "falhas": falhas,
            "total_usuarios": len(usuarios)
        }
    
    def notificar_demanda_criada(self, demanda: Demanda) -> dict:
        """
        Notificar sobre criação de demanda
        
        Args:
            demanda: Demanda criada
            
        Returns:
            Estatísticas de envio
        """
        return self.notificar_evento(demanda, "demanda_criada")
    
    def notificar_demanda_atualizada(self, demanda: Demanda) -> dict:
        """
        Notificar sobre atualização de demanda
        
        Args:
            demanda: Demanda atualizada
            
        Returns:
            Estatísticas de envio
        """
        return self.notificar_evento(demanda, "demanda_atualizada")
    
    def notificar_demanda_concluida(self, demanda: Demanda) -> dict:
        """
        Notificar sobre conclusão de demanda
        
        Args:
            demanda: Demanda concluída
            
        Returns:
            Estatísticas de envio
        """
        return self.notificar_evento(demanda, "demanda_concluida")
    
    def notificar_demanda_cancelada(self, demanda: Demanda) -> dict:
        """
        Notificar sobre cancelamento de demanda
        
        Args:
            demanda: Demanda cancelada
            
        Returns:
            Estatísticas de envio
        """
        return self.notificar_evento(demanda, "demanda_cancelada")
    
    async def notificar_mudanca_status(
        self,
        demanda: Demanda,
        status_antigo: str,
        db: Session
    ) -> dict:
        """
        Notificar sobre mudança de status da demanda (vinda do Trello ou edição manual)
        
        Args:
            demanda: Demanda atualizada
            status_antigo: Status anterior da demanda
            db: Sessão do banco de dados
            
        Returns:
            Estatísticas de envio
        """
        # Verificar se o status realmente mudou
        if not hasattr(demanda, 'status') or demanda.status.value == status_antigo:
            logger.info("Status não mudou, notificação não enviada")
            return {
                "sucesso": True,
                "mensagem": "Status não mudou",
                "enviados": 0,
                "falhas": 0
            }
        
        # Emoji de status
        emoji_status = {
            "aberta": "📂",
            "em_andamento": "⚙️",
            "aguardando_cliente": "⏳",
            "concluida": "✅",
            "cancelada": "❌"
        }
        
        # Formatar nomes dos status
        status_antigo_formatado = status_antigo.replace('_', ' ').title()
        status_novo_formatado = demanda.status.value.replace('_', ' ').title()
        
        # Emoji do novo status
        emoji_novo = emoji_status.get(demanda.status.value, "📊")
        
        # Obter usuários para notificar
        usuarios = self._obter_usuarios_para_notificar(demanda)
        if not usuarios:
            logger.info("Nenhum usuário para notificar sobre mudança de status")
            return {
                "sucesso": True,
                "mensagem": "Nenhum usuário configurado para receber notificações",
                "enviados": 0,
                "falhas": 0
            }
        
        # Criar mensagem personalizada para mudança de status
        mensagem = f"""🔄 *Atualização de Status - Demanda*

📋 *Demanda:* {demanda.nome}
🏢 *Cliente:* {demanda.cliente.nome if demanda.cliente else 'N/A'}

{emoji_novo} *Status:* {status_antigo_formatado} → *{status_novo_formatado}*

🔗 *Ver no Trello:* {demanda.trello_card_url or 'Aguardando sincronização...'}

_ID: {demanda.id}_
        """.strip()
        
        # Enviar para cada usuário
        enviados = 0
        falhas = 0
        
        for usuario in usuarios:
            sucesso = self._enviar_notificacao(
                usuario=usuario,
                mensagem=mensagem,
                demanda=demanda,
                tipo_evento="mudanca_status"
            )
            
            if sucesso:
                enviados += 1
            else:
                falhas += 1
        
        logger.info(f"Notificações de mudança de status enviadas: {enviados} sucesso, {falhas} falhas")
        
        return {
            "sucesso": True,
            "mensagem": f"Notificações processadas: {enviados} enviadas, {falhas} falhas",
            "enviados": enviados,
            "falhas": falhas,
            "total_usuarios": len(usuarios),
            "status_antigo": status_antigo_formatado,
            "status_novo": status_novo_formatado
        }
    
    def notificar_usuario_cadastrado(self, usuario: User, senha_original: str = None) -> dict:
        """
        Notificar novo usuário que foi cadastrado no sistema
        
        Args:
            usuario: Usuário recém-cadastrado
            
        Returns:
            Estatísticas de envio
        """
        # Verificar se há configuração WhatsApp ativa
        config = ConfiguracaoWhatsApp.get_ativa(self.db)
        if not config:
            logger.warning("Nenhuma configuração WhatsApp ativa encontrada")
            return {
                "sucesso": False,
                "mensagem": "Nenhuma configuração WhatsApp ativa",
                "enviados": 0,
                "falhas": 0
            }
        
        # Verificar se o usuário tem WhatsApp cadastrado
        if not usuario.whatsapp or usuario.whatsapp == "":
            logger.info(f"Usuário {usuario.username} não tem WhatsApp cadastrado, notificação não enviada")
            return {
                "sucesso": True,
                "mensagem": "Usuário não possui WhatsApp cadastrado",
                "enviados": 0,
                "falhas": 0
            }
        
        # Buscar template para o evento usuario_cadastrado
        template = TemplateMensagem.get_by_tipo_evento(self.db, "usuario_cadastrado")
        if not template:
            logger.warning("Nenhum template encontrado para evento: usuario_cadastrado")
            return {
                "sucesso": False,
                "mensagem": "Nenhum template encontrado para evento: usuario_cadastrado",
                "enviados": 0,
                "falhas": 0
            }
        
        # Obter número do WhatsApp do DeBrief
        from app.core.config import settings
        whatsapp_debrief = settings.ZAPI_PHONE_NUMBER or "5585996039026"
        url_acesso = settings.FRONTEND_URL or "http://82.25.92.217:2022"
        
        # Refresh para garantir que relacionamentos estão carregados
        self.db.refresh(usuario)
        
        # Preparar dados para renderizar template
        dados = {
            "usuario_nome": usuario.nome_completo or usuario.username,
            "usuario_username": usuario.username,
            "usuario_email": usuario.email or "",
            "usuario_senha": senha_original or "******",
            "whatsapp_debrief": whatsapp_debrief,
            "url_acesso": url_acesso,
            "url_sistema": url_acesso,
            "cliente_nome": usuario.cliente.nome if hasattr(usuario, 'cliente') and usuario.cliente else ""
        }
        
        # Renderizar mensagem
        mensagem = template.renderizar(dados)
        
        # Enviar notificação para o novo usuário
        try:
            sucesso = self.whatsapp_service.enviar_mensagem_individual(
                numero=usuario.whatsapp,
                mensagem=mensagem
            )
            
            # Registrar log (sem demanda_id, pois não é relacionado a demanda)
            log = NotificationLog(
                demanda_id=None,
                usuario_id=usuario.id,
                tipo=TipoNotificacao.WHATSAPP,
                destinatario=usuario.whatsapp,
                mensagem=mensagem,
                status=StatusNotificacao.ENVIADO if sucesso else StatusNotificacao.ERRO,
                erro_mensagem=None if sucesso else "Falha ao enviar mensagem",
                enviado_em=datetime.utcnow() if sucesso else None,
                metadata='{"tipo_evento": "usuario_cadastrado"}'
            )
            
            self.db.add(log)
            self.db.commit()
            
            if sucesso:
                logger.info(f"Notificação de cadastro enviada para {usuario.nome_completo} ({usuario.whatsapp})")
                return {
                    "sucesso": True,
                    "mensagem": "Notificação enviada com sucesso",
                    "enviados": 1,
                    "falhas": 0
                }
            else:
                logger.warning(f"Falha ao enviar notificação de cadastro para {usuario.nome_completo}")
                return {
                    "sucesso": False,
                    "mensagem": "Falha ao enviar notificação",
                    "enviados": 0,
                    "falhas": 1
                }
                
        except Exception as e:
            logger.error(f"Erro ao enviar notificação de cadastro para usuário {usuario.id}: {str(e)}")
            
            # Registrar log de erro
            log = NotificationLog(
                demanda_id=None,
                usuario_id=usuario.id,
                tipo=TipoNotificacao.WHATSAPP,
                destinatario=usuario.whatsapp,
                mensagem=mensagem,
                status=StatusNotificacao.ERRO,
                erro_mensagem=str(e),
                metadata='{"tipo_evento": "usuario_cadastrado"}'
            )
            
            self.db.add(log)
            self.db.commit()
            
            return {
                "sucesso": False,
                "mensagem": f"Erro ao enviar notificação: {str(e)}",
                "enviados": 0,
                "falhas": 1
            }

