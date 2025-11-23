"""
Serviço de integração com WPPConnect (WhatsApp)

Este serviço gerencia o envio de notificações via WhatsApp
para grupos de clientes quando há eventos importantes no sistema.

Funcionalidades:
- Enviar notificação de nova demanda
- Enviar atualização de status
- Enviar lembretes de prazo
- Enviar mensagens customizadas

Dependências:
- requests: Para chamadas HTTP à API do WPPConnect
- SQLAlchemy: Para acessar relacionamentos

Autor: DeBrief Sistema
"""
import requests
from sqlalchemy.orm import Session
from typing import Optional
from app.core.config import settings
from app.models.demanda import Demanda
import logging

# Configurar logger
logger = logging.getLogger(__name__)


class WhatsAppService:
    """
    Wrapper para WPPConnect API
    
    Gerencia o envio de mensagens via WhatsApp para grupos de clientes,
    notificando sobre demandas, atualizações e lembretes.
    
    Exemplo de uso:
        ```python
        whatsapp = WhatsAppService()
        await whatsapp.enviar_nova_demanda(demanda, db)
        ```
    """
    
    def __init__(self):
        """
        Inicializar serviço WhatsApp
        
        Configura URL base e credenciais do WPPConnect
        """
        self.base_url = settings.WPP_URL
        self.instance = settings.WPP_INSTANCE
        self.token = settings.WPP_TOKEN
        
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }
        
        logger.info("WhatsAppService inicializado")
    
    async def enviar_mensagem(
        self,
        group_id: str,
        mensagem: str,
        mencoes: Optional[list] = None
    ) -> bool:
        """
        Enviar mensagem para grupo do WhatsApp
        
        Args:
            group_id: ID do grupo (formato: numero@g.us)
            mensagem: Texto da mensagem (suporta markdown do WhatsApp)
            mencoes: Lista de números para mencionar (opcional)
        
        Returns:
            True se enviado com sucesso, False caso contrário
        
        Exemplo:
            ```python
            success = await whatsapp.enviar_mensagem(
                "123456789@g.us",
                "*Teste* de mensagem"
            )
            ```
        """
        url = f"{self.base_url}/api/{self.instance}/send-text"
        
        payload = {
            "phone": group_id,
            "message": mensagem,
            "isGroup": True
        }
        
        # Adicionar menções se fornecidas
        if mencoes:
            payload["mentions"] = mencoes
        
        try:
            logger.info(f"Enviando mensagem WhatsApp para grupo {group_id}")
            
            response = requests.post(
                url,
                json=payload,
                headers=self.headers,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"Mensagem WhatsApp enviada com sucesso para {group_id}")
                return True
            else:
                logger.error(f"Erro WhatsApp (status {response.status_code}): {response.text}")
                return False
                
        except requests.exceptions.Timeout:
            logger.error("Timeout ao enviar mensagem WhatsApp")
            return False
        except Exception as e:
            logger.error(f"Exceção ao enviar WhatsApp: {e}")
            return False
    
    def enviar_mensagem_individual(
        self,
        numero: str,
        mensagem: str
    ) -> bool:
        """
        Enviar mensagem individual para número WhatsApp
        
        Args:
            numero: Número WhatsApp (formato: 5511999999999)
            mensagem: Texto da mensagem (suporta markdown do WhatsApp)
        
        Returns:
            True se enviado com sucesso, False caso contrário
        
        Exemplo:
            ```python
            success = whatsapp.enviar_mensagem_individual(
                "5511999999999",
                "*Notificação*: Nova demanda criada"
            )
            ```
        """
        url = f"{self.base_url}/api/{self.instance}/send-text"
        
        # Garantir que número tenha apenas dígitos
        numero_limpo = ''.join(filter(str.isdigit, numero))
        
        payload = {
            "phone": numero_limpo,
            "message": mensagem,
            "isGroup": False
        }
        
        try:
            logger.info(f"Enviando mensagem WhatsApp individual para {numero_limpo}")
            
            response = requests.post(
                url,
                json=payload,
                headers=self.headers,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"Mensagem WhatsApp individual enviada com sucesso para {numero_limpo}")
                return True
            else:
                logger.error(f"Erro WhatsApp individual (status {response.status_code}): {response.text}")
                return False
                
        except requests.exceptions.Timeout:
            logger.error("Timeout ao enviar mensagem WhatsApp individual")
            return False
        except Exception as e:
            logger.error(f"Exceção ao enviar WhatsApp individual: {e}")
            return False
    
    async def enviar_nova_demanda(self, demanda: Demanda, db: Session) -> bool:
        """
        Enviar notificação de nova demanda
        
        Envia mensagem formatada para o grupo WhatsApp do cliente
        informando sobre a criação de uma nova demanda.
        
        Args:
            demanda: Objeto Demanda criado
            db: Sessão do banco
        
        Returns:
            True se enviado com sucesso
        
        Exemplo:
            ```python
            demanda = Demanda(nome="Nova demanda", ...)
            db.add(demanda)
            db.commit()
            
            whatsapp = WhatsAppService()
            await whatsapp.enviar_nova_demanda(demanda, db)
            ```
        """
        # Carregar relacionamentos
        db.refresh(demanda)
        
        # Verificar se cliente tem grupo configurado
        if not demanda.cliente.whatsapp_group_id:
            logger.warning(f"Cliente {demanda.cliente.nome} sem grupo WhatsApp configurado")
            return False
        
        # Emoji de prioridade
        emoji_prioridade = {
            "Baixa": "🟢",
            "Média": "🟡",
            "Alta": "🟠",
            "Urgente": "🔴"
        }.get(demanda.prioridade.nome, "📌")
        
        # Construir mensagem
        mensagem = f"""
🔔 *Nova Demanda Recebida!*

📋 *Demanda:* {demanda.nome}
🏢 *Secretaria:* {demanda.secretaria.nome}
📌 *Tipo:* {demanda.tipo_demanda.nome}
{emoji_prioridade} *Prioridade:* {demanda.prioridade.nome}
📅 *Prazo:* {demanda.prazo_final.strftime('%d/%m/%Y')}

👤 *Solicitante:* {demanda.usuario.nome_completo}

🔗 *Ver no Trello:* {demanda.trello_card_url or 'Processando...'}

_ID: {demanda.id}_
        """.strip()
        
        # Enviar
        return await self.enviar_mensagem(
            demanda.cliente.whatsapp_group_id,
            mensagem
        )
    
    async def enviar_atualizacao_status(
        self,
        demanda: Demanda,
        db: Session,
        status_antigo: str
    ) -> bool:
        """
        Enviar notificação de mudança de status
        
        Args:
            demanda: Objeto Demanda
            db: Sessão do banco
            status_antigo: Status anterior da demanda
        
        Returns:
            True se enviado com sucesso
        """
        db.refresh(demanda)
        
        if not demanda.cliente.whatsapp_group_id:
            return False
        
        # Emoji de status
        emoji_status = {
            "aberta": "📂",
            "em_andamento": "⚙️",
            "concluida": "✅",
            "cancelada": "❌"
        }.get(demanda.status.value, "📊")
        
        mensagem = f"""
🔄 *Atualização de Demanda*

📋 *Demanda:* {demanda.nome}

{emoji_status} *Status:* {status_antigo} → *{demanda.status.value.replace('_', ' ').title()}*

🔗 *Ver no Trello:* {demanda.trello_card_url}

_ID: {demanda.id}_
        """.strip()
        
        return await self.enviar_mensagem(
            demanda.cliente.whatsapp_group_id,
            mensagem
        )
    
    async def enviar_lembrete_prazo(self, demanda: Demanda, db: Session, dias_faltando: int) -> bool:
        """
        Enviar lembrete de prazo próximo
        
        Args:
            demanda: Objeto Demanda
            db: Sessão do banco
            dias_faltando: Quantidade de dias até o prazo
        
        Returns:
            True se enviado com sucesso
        """
        db.refresh(demanda)
        
        if not demanda.cliente.whatsapp_group_id:
            return False
        
        # Emoji baseado na urgência
        emoji = "⏰" if dias_faltando > 3 else "⚠️" if dias_faltando > 1 else "🚨"
        
        mensagem = f"""
{emoji} *Lembrete de Prazo!*

📋 *Demanda:* {demanda.nome}
📅 *Prazo:* {demanda.prazo_final.strftime('%d/%m/%Y')}
⏳ *Faltam:* {dias_faltando} dia(s)

🔗 *Ver no Trello:* {demanda.trello_card_url}

_ID: {demanda.id}_
        """.strip()
        
        return await self.enviar_mensagem(
            demanda.cliente.whatsapp_group_id,
            mensagem
        )
    
    async def enviar_mensagem_customizada(
        self,
        group_id: str,
        titulo: str,
        corpo: str,
        emoji: str = "📢"
    ) -> bool:
        """
        Enviar mensagem customizada
        
        Args:
            group_id: ID do grupo WhatsApp
            titulo: Título da mensagem
            corpo: Corpo da mensagem
            emoji: Emoji inicial (padrão: 📢)
        
        Returns:
            True se enviado com sucesso
        """
        mensagem = f"""
{emoji} *{titulo}*

{corpo}
        """.strip()
        
        return await self.enviar_mensagem(group_id, mensagem)
    
    async def verificar_status_instancia(self) -> dict:
        """
        Verificar status da instância WPPConnect
        
        Returns:
            Dicionário com informações da instância
        """
        url = f"{self.base_url}/api/{self.instance}/status"
        
        try:
            response = requests.get(url, headers=self.headers, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                logger.info(f"Status WPPConnect: {data}")
                return data
            else:
                logger.error(f"Erro ao verificar status: {response.text}")
                return {"error": response.text}
                
        except Exception as e:
            logger.error(f"Exceção ao verificar status: {e}")
            return {"error": str(e)}

