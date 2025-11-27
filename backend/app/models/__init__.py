"""
Módulo de Modelos SQLAlchemy
Contém todos os modelos (tabelas) do banco de dados

Modelos disponíveis:
- Base: Classe base com campos comuns (id, timestamps)
- User: Usuários do sistema
- Cliente: Empresas/órgãos clientes
- Secretaria: Secretarias/departamentos dos clientes
- TipoDemanda: Tipos de demanda (Design, Desenvolvimento, etc)
- Prioridade: Níveis de prioridade
- Demanda: Demandas/solicitações dos clientes
- Anexo: Arquivos anexados às demandas
- Configuracao: Configurações do sistema
- NotificationLog: Logs de notificações enviadas
"""

from app.models.base import Base, BaseModel
from app.models.user import User, TipoUsuario
from app.models.cliente import Cliente
from app.models.secretaria import Secretaria
from app.models.tipo_demanda import TipoDemanda
from app.models.prioridade import Prioridade
from app.models.demanda import Demanda, StatusDemanda
from app.models.anexo import Anexo
from app.models.configuracao import Configuracao, TipoConfiguracao

from app.models.notification_log import NotificationLog, TipoNotificacao, StatusNotificacao
from app.models.configuracao_whatsapp import ConfiguracaoWhatsApp
from app.models.template_mensagem import TemplateMensagem
from app.models.configuracao_trello import ConfiguracaoTrello
from app.models.etiqueta_trello_cliente import EtiquetaTrelloCliente
from app.models.refresh_token import RefreshToken
from app.models.login_attempt import LoginAttempt

__all__ = [
    'Base',
    'BaseModel',
    'User',
    'TipoUsuario',
    'Cliente',
    'Secretaria',
    'TipoDemanda',
    'Prioridade',
    'Demanda',
    'StatusDemanda',
    'Anexo',
    'Configuracao',
    'TipoConfiguracao',
    'NotificationLog',
    'TipoNotificacao',
    'StatusNotificacao',
    'ConfiguracaoWhatsApp',
    'TemplateMensagem',
    'ConfiguracaoTrello',
    'EtiquetaTrelloCliente',
    'RefreshToken',
    'LoginAttempt',
]

