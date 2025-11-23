"""
Modelo Demanda
Representa uma solicitação/briefing no sistema
"""
from sqlalchemy import Column, String, Text, Enum, Date, DateTime, ForeignKey, Index, TypeDecorator
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid
from app.models.base import BaseModel


class StatusDemanda(str, enum.Enum):
    """Status possíveis de uma demanda"""
    ABERTA = "aberta"
    EM_ANDAMENTO = "em_andamento"
    AGUARDANDO_CLIENTE = "aguardando_cliente"
    CONCLUIDA = "concluida"
    CANCELADA = "cancelada"


class StatusDemandaType(TypeDecorator):
    """
    TypeDecorator para converter entre enum Python e string do banco
    Permite usar StatusDemanda.ABERTA no código, mas armazena 'aberta' no banco
    """
    impl = String
    cache_ok = True
    
    def __init__(self):
        super().__init__(length=50)
    
    def process_bind_param(self, value, dialect):
        """Converter enum Python para string do banco"""
        if value is None:
            return None
        if isinstance(value, StatusDemanda):
            return value.value  # Retorna 'aberta', 'em_andamento', etc.
        # Se for string, verificar se é um valor válido do enum
        if isinstance(value, str):
            for status in StatusDemanda:
                if status.value == value.lower():
                    return status.value
        return str(value)
    
    def process_result_value(self, value, dialect):
        """Converter string do banco para enum Python"""
        if value is None:
            return None
        # Normalizar para minúsculo para garantir compatibilidade
        value_lower = str(value).lower()
        # Buscar enum pelo valor
        for status in StatusDemanda:
            if status.value == value_lower:
                return status
        # Se não encontrar, retornar string (para compatibilidade)
        return value


class PrioridadeDemanda(str, enum.Enum):
    """Prioridades de demanda"""
    BAIXA = "baixa"
    MEDIA = "media"
    ALTA = "alta"
    URGENTE = "urgente"


class Demanda(BaseModel):
    """
    Modelo de Demanda/Briefing
    
    Attributes:
        nome: Nome/título da demanda
        descricao: Descrição detalhada
        status: Status atual (aberta, em_andamento, etc)
        prioridade: Prioridade (baixa, media, alta, urgente)
        prazo_final: Data limite para conclusão
        data_conclusao: Data real de conclusão
        usuario_id: ID do usuário que criou
        tipo_demanda_id: ID do tipo de demanda
        secretaria_id: ID da secretaria responsável
    """
    
    __tablename__ = "demandas"
    
    # Campos principais
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    nome = Column(String(200), nullable=False)
    descricao = Column(Text, nullable=False)
    links_referencia = Column(Text, nullable=True, comment="Links de referência (JSON array)")
    
    # Status
    # Usar TypeDecorator customizado para converter entre enum Python e string do banco
    # Isso resolve problemas com enum nativo do PostgreSQL que tem valores em minúsculo
    status = Column(
        StatusDemandaType(),
        nullable=False,
        default=StatusDemanda.ABERTA,
        index=True
    )
    
    # Datas
    prazo_final = Column(Date, nullable=True)
    data_conclusao = Column(DateTime(timezone=True), nullable=True)
    
    # Relacionamentos
    usuario_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    cliente_id = Column(String(36), ForeignKey("clientes.id"), nullable=False, index=True)
    tipo_demanda_id = Column(String(36), ForeignKey("tipos_demanda.id"), nullable=False, index=True)
    secretaria_id = Column(String(36), ForeignKey("secretarias.id"), nullable=True, index=True)
    prioridade_id = Column(String(36), ForeignKey("prioridades.id"), nullable=False, index=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    usuario = relationship("User", back_populates="demandas")
    cliente = relationship("Cliente", back_populates="demandas")
    tipo_demanda = relationship("TipoDemanda", back_populates="demandas")
    secretaria = relationship("Secretaria", back_populates="demandas")
    prioridade = relationship("Prioridade", back_populates="demandas")
    anexos = relationship("Anexo", back_populates="demanda", cascade="all, delete-orphan")
    
    # Índices compostos para queries comuns
    __table_args__ = (
        Index('idx_demanda_usuario_status', 'usuario_id', 'status'),
        Index('idx_demanda_status_prioridade', 'status', 'prioridade_id'),
        Index('idx_demanda_prazo', 'prazo_final', 'status'),
    )
    
    def __repr__(self):
        return f"<Demanda(id={self.id}, nome={self.nome}, status={self.status})>"
    
    def is_atrasada(self) -> bool:
        """Verificar se demanda está atrasada"""
        from datetime import date
        if self.prazo_final and self.status not in [StatusDemanda.CONCLUIDA, StatusDemanda.CANCELADA]:
            return date.today() > self.prazo_final
        return False
    
    def pode_editar(self, user_id: str) -> bool:
        """Verificar se usuário pode editar demanda"""
        return self.usuario_id == user_id
    
    def pode_visualizar(self, user_id: str, is_master: bool = False) -> bool:
        """Verificar se usuário pode visualizar demanda"""
        if is_master:
            return True
        return self.usuario_id == user_id
    
    def concluir(self):
        """Marcar demanda como concluída"""
        from datetime import datetime
        self.status = StatusDemanda.CONCLUIDA
        self.data_conclusao = datetime.utcnow()
    
    def cancelar(self):
        """Marcar demanda como cancelada"""
        self.status = StatusDemanda.CANCELADA
    
    def iniciar(self):
        """Marcar demanda como em andamento"""
        self.status = StatusDemanda.EM_ANDAMENTO
    
    def aguardar_cliente(self):
        """Marcar demanda como aguardando cliente"""
        self.status = StatusDemanda.AGUARDANDO_CLIENTE
    
    def to_dict(self) -> dict:
        """Converter para dicionário"""
        return {
            "id": self.id,
            "nome": self.nome,
            "descricao": self.descricao,
            "status": self.status.value,
            "prioridade": self.prioridade.value,
            "prazo_final": self.prazo_final.isoformat() if self.prazo_final else None,
            "data_conclusao": self.data_conclusao.isoformat() if self.data_conclusao else None,
            "usuario_id": self.usuario_id,
            "tipo_demanda_id": self.tipo_demanda_id,
            "secretaria_id": self.secretaria_id,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }

