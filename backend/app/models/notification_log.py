"""
Modelo de Log de Notificações
Armazena histórico de notificações enviadas (WhatsApp, Trello, Email)
"""
import enum
from sqlalchemy import Column, String, Text, Enum, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class TipoNotificacao(str, enum.Enum):
    """Tipos de notificação"""
    WHATSAPP = "whatsapp"
    TRELLO = "trello"
    EMAIL = "email"


class StatusNotificacao(str, enum.Enum):
    """Status da notificação"""
    ENVIADO = "enviado"
    ERRO = "erro"
    PENDENTE = "pendente"


class NotificationLog(BaseModel):
    """
    Modelo de Log de Notificações
    
    Armazena histórico de todas as notificações enviadas pelo sistema,
    permitindo rastreabilidade e debugging.
    
    Campos:
        demanda_id: ID da demanda relacionada
        tipo: Tipo de notificação (whatsapp, trello, email)
        status: Status do envio (enviado, erro, pendente)
        mensagem_erro: Mensagem de erro se houver falha
        tentativas: Número de tentativas de envio
        dados_enviados: JSON com dados enviados (opcional)
        resposta: JSON com resposta do serviço (opcional)
        
    Relacionamentos:
        demanda: Demanda relacionada
        
    Exemplo:
        ```python
        log = NotificationLog(
            demanda_id="123",
            tipo=TipoNotificacao.WHATSAPP,
            status=StatusNotificacao.ENVIADO
        )
        db.add(log)
        db.commit()
        ```
    """
    
    __tablename__ = "notification_logs"
    
    # Relacionamento com demanda
    demanda_id = Column(
        String(36),
        ForeignKey("demandas.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID da demanda relacionada"
    )
    
    # Tipo e status
    tipo = Column(
        Enum(TipoNotificacao),
        nullable=False,
        index=True,
        comment="Tipo de notificação (whatsapp, trello, email)"
    )
    
    status = Column(
        Enum(StatusNotificacao),
        nullable=False,
        default=StatusNotificacao.PENDENTE,
        index=True,
        comment="Status do envio (enviado, erro, pendente)"
    )
    
    # Mensagem de erro
    mensagem_erro = Column(
        Text,
        nullable=True,
        comment="Mensagem de erro se houver falha"
    )
    
    # Tentativas
    tentativas = Column(
        String(10),
        nullable=False,
        default="1",
        comment="Número de tentativas de envio"
    )
    
    # Dados enviados (JSON string)
    dados_enviados = Column(
        Text,
        nullable=True,
        comment="JSON com dados enviados na notificação"
    )
    
    # Resposta do serviço (JSON string)
    resposta = Column(
        Text,
        nullable=True,
        comment="JSON com resposta do serviço externo"
    )
    
    # Relacionamento com demanda
    demanda = relationship(
        "Demanda",
        backref="notification_logs",
        lazy="joined"
    )
    
    # Índices compostos
    __table_args__ = (
        Index('idx_notification_demanda_tipo', 'demanda_id', 'tipo'),
        Index('idx_notification_status_tipo', 'status', 'tipo'),
    )
    
    def __repr__(self):
        return f"<NotificationLog(id={self.id}, tipo={self.tipo}, status={self.status})>"
    
    def to_dict(self):
        """
        Converter para dicionário
        
        Returns:
            dict: Dicionário com todos os campos
        """
        return {
            "id": self.id,
            "demanda_id": self.demanda_id,
            "tipo": self.tipo.value if isinstance(self.tipo, enum.Enum) else self.tipo,
            "status": self.status.value if isinstance(self.status, enum.Enum) else self.status,
            "mensagem_erro": self.mensagem_erro,
            "tentativas": self.tentativas,
            "dados_enviados": self.dados_enviados,
            "resposta": self.resposta,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

