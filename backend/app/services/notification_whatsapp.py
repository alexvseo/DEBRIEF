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
            "trello_card_url": demanda.trello_card_url or ""
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

