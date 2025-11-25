"""
Serviço de integração com Z-API WhatsApp

Este serviço gerencia o envio de notificações via WhatsApp
para usuários quando há eventos importantes no sistema.

Funcionalidades:
- Enviar notificação de nova demanda
- Enviar atualização de status
- Enviar lembretes de prazo
- Enviar mensagens customizadas

Dependências:
- requests: Para chamadas HTTP à Z-API
- SQLAlchemy: Para acessar relacionamentos

API: Z-API (https://www.z-api.io/)
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
    Wrapper para Z-API WhatsApp
    
    Gerencia o envio de mensagens via WhatsApp individuais,
    notificando usuários sobre demandas, atualizações e lembretes.
    
    Exemplo de uso:
        ```python
        whatsapp = WhatsAppService()
        await whatsapp.enviar_nova_demanda(demanda, db)
        ```
    """
    
    def __init__(self):
        """
        Inicializar serviço WhatsApp com Z-API
        
        Configura credenciais e URLs da Z-API
        """
        self.instance_id = settings.ZAPI_INSTANCE_ID
        self.token = settings.ZAPI_TOKEN
        self.client_token = settings.ZAPI_CLIENT_TOKEN
        self.base_url = f"https://api.z-api.io/instances/{self.instance_id}/token/{self.token}"
        self.phone_number = settings.ZAPI_PHONE_NUMBER
        
        self.headers = {
            "Content-Type": "application/json",
            "Client-Token": self.client_token  # Token de segurança da conta Z-API
        }
        
        logger.info(f"✅ WhatsAppService inicializado (Z-API) - Instância: {self.instance_id[:8]}...")
    
    async def enviar_mensagem(
        self,
        chat_id: str,
        mensagem: str,
        mencoes: Optional[list] = None
    ) -> bool:
        """
        Enviar mensagem para contato do WhatsApp via Z-API
        
        Args:
            chat_id: Número do WhatsApp (formato: 5511999999999 ou 5511999999999@c.us)
            mensagem: Texto da mensagem (suporta emojis e formatação WhatsApp)
            mencoes: Lista de números para mencionar (não usado na Z-API)
        
        Returns:
            True se enviado com sucesso, False caso contrário
        
        Exemplo:
            ```python
            success = await whatsapp.enviar_mensagem(
                "5585991042626",
                "✅ Teste de mensagem"
            )
            ```
        """
        # Z-API - Endpoint de envio de texto
        url = f"{self.base_url}/send-text"
        
        # Limpar número (remover @c.us se existir)
        numero = chat_id.split('@')[0] if '@' in chat_id else chat_id
        
        # Formato Z-API
        payload = {
            "phone": numero,
            "message": mensagem
        }
        
        try:
            logger.info(f"Enviando mensagem WhatsApp via Evolution API para {chat_id}")
            
            response = requests.post(
                url,
                json=payload,
                headers=self.headers,
                timeout=30
            )
            
            if response.status_code == 201 or response.status_code == 200:
                result = response.json()
                if result.get("key"):
                    message_id = result.get("key", {}).get("id", "")
                    logger.info(f"Mensagem WhatsApp enviada com sucesso para {chat_id}: {message_id}")
                    return True
                else:
                    logger.error(f"Erro WhatsApp: {result}")
                    return False
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
        Enviar mensagem individual para número WhatsApp via Z-API
        
        Args:
            numero: Número WhatsApp (formato: 5511999999999)
            mensagem: Texto da mensagem (suporta emojis e formatação WhatsApp)
        
        Returns:
            True se enviado com sucesso, False caso contrário
        
        Exemplo:
            ```python
            success = whatsapp.enviar_mensagem_individual(
                "5585991042626",
                "✅ Notificação: Nova demanda criada"
            )
            ```
        """
        # Garantir que número tenha apenas dígitos
        numero_limpo = ''.join(filter(str.isdigit, numero))
        
        # Z-API usa apenas o número (sem @c.us)
        chat_id = numero_limpo
        
        # Usar o método principal de envio (agora já adaptado para Z-API)
        return self.enviar_mensagem_sync(chat_id, mensagem)
    
    def enviar_mensagem_sync(self, chat_id: str, mensagem: str) -> bool:
        """
        Versão síncrona do enviar_mensagem (para uso sem async)
        
        Args:
            chat_id: Número do WhatsApp
            mensagem: Texto da mensagem
        
        Returns:
            True se enviado com sucesso
        """
        # Z-API - Endpoint de envio de texto
        url = f"{self.base_url}/send-text"
        
        # Limpar número (remover @c.us se existir)
        numero = chat_id.split('@')[0] if '@' in chat_id else chat_id
        
        # Formato Z-API
        payload = {
            "phone": numero,
            "message": mensagem
        }
        
        try:
            logger.info(f"Enviando mensagem WhatsApp via Z-API para {numero}")
            
            response = requests.post(
                url,
                json=payload,
                headers=self.headers,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get("messageId") or result.get("success"):
                    message_id = result.get("messageId", "")
                    logger.info(f"✅ Mensagem Z-API enviada com sucesso para {numero}: {message_id}")
                    return True
                else:
                    logger.error(f"❌ Erro Z-API: {result}")
                    return False
            else:
                logger.error(f"❌ Erro Z-API (status {response.status_code}): {response.text}")
                return False
                
        except requests.exceptions.Timeout:
            logger.error("⏱️ Timeout ao enviar mensagem Z-API")
            return False
        except Exception as e:
            logger.error(f"❌ Exceção ao enviar Z-API: {e}")
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
        Verificar status da conexão WhatsApp via Z-API
        
        Returns:
            Dicionário com informações da conexão
        """
        # Z-API - Endpoint de status
        url = f"{self.base_url}/status"
        
        try:
            response = requests.get(url, headers=self.headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                connected = data.get("connected", False)
                phone = data.get("phone", "")
                logger.info(f"✅ Status Z-API: conectado={connected}, phone={phone}")
                return {
                    "connected": connected,
                    "state": "open" if connected else "disconnected",
                    "phone": phone,
                    "instance": self.instance_id[:8] + "..."
                }
            else:
                logger.error(f"❌ Erro ao verificar status Z-API: {response.text}")
                return {"error": response.text, "connected": False}
                
        except Exception as e:
            logger.error(f"❌ Exceção ao verificar status Z-API: {e}")
            return {"error": str(e), "connected": False}
    
    def listar_grupos(self) -> list:
        """
        Listar todos os grupos WhatsApp via Evolution API
        
        Returns:
            Lista de grupos com id, nome e participantes
        """
        # Evolution API v1.8.5 - Endpoint de listagem de grupos
        url = f"{self.base_url}/group/fetchAllGroups/{self.instance_name}"
        params = {"getParticipants": "true"}
        
        try:
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            
            if response.status_code == 200:
                grupos = response.json()
                if isinstance(grupos, list):
                    logger.info(f"Encontrados {len(grupos)} grupos WhatsApp")
                    return grupos
                else:
                    logger.warning(f"Resposta inesperada ao listar grupos: {grupos}")
                    return []
            else:
                logger.error(f"Erro ao listar grupos: {response.text}")
                return []
                
        except Exception as e:
            logger.error(f"Exceção ao listar grupos: {e}")
            return []

