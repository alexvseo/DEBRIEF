"""
Modelo de Cliente
Representa empresas/órgãos que utilizam o sistema
"""
from sqlalchemy import Column, String, Boolean
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class Cliente(BaseModel):
    """
    Tabela de clientes (empresas/órgãos)
    
    Atributos:
        nome (str): Nome da empresa/órgão
        whatsapp_group_id (str): ID do grupo WhatsApp para notificações
        trello_member_id (str): ID do membro no Trello para atribuições
        ativo (bool): Status ativo/inativo do cliente
    
    Relacionamentos:
        usuarios: Lista de usuários vinculados ao cliente
        secretarias: Lista de secretarias do cliente
        demandas: Lista de demandas do cliente
    
    Exemplo:
        cliente = Cliente(
            nome="Prefeitura Municipal",
            whatsapp_group_id="123456789@g.us",
            trello_member_id="abc123def456",
            ativo=True
        )
    """
    __tablename__ = "clientes"
    
    # ==================== CAMPOS ====================
    
    nome = Column(
        String(200),
        nullable=False,
        index=True,
        comment="Nome da empresa/órgão cliente"
    )
    
    whatsapp_group_id = Column(
        String(100),
        nullable=True,
        comment="ID do grupo WhatsApp (formato: numero@g.us)"
    )
    
    trello_member_id = Column(
        String(100),
        nullable=True,
        comment="ID do membro no Trello para atribuir cards"
    )
    
    ativo = Column(
        Boolean,
        default=True,
        nullable=False,
        index=True,
        comment="Status ativo/inativo"
    )
    
    # ==================== RELACIONAMENTOS ====================
    
    # Relacionamento com usuários
    usuarios = relationship(
        "User",
        back_populates="cliente",
        lazy="select"
    )
    
    # Relacionamento com secretarias
    secretarias = relationship(
        "Secretaria",
        back_populates="cliente",
        cascade="all, delete-orphan",
        lazy="select"
    )
    
    # Relacionamento com demandas
    # Usar lazy="noload" para evitar carregar automaticamente (evita erro de enum)
    # Quando necessário, usar query explícita: db.query(Demanda).filter(Demanda.cliente_id == self.id)
    demandas = relationship(
        "Demanda",
        back_populates="cliente",
        lazy="noload"  # Nunca carregar automaticamente
    )
    
    # ==================== MÉTODOS ====================
    
    def __repr__(self):
        """Representação do objeto"""
        return f"<Cliente(id='{self.id}', nome='{self.nome}', ativo={self.ativo})>"
    
    def to_dict_summary(self):
        """
        Retorna dicionário com resumo do cliente
        Útil para listagens
        """
        return {
            'id': self.id,
            'nome': self.nome,
            'ativo': self.ativo,
            'tem_whatsapp': bool(self.whatsapp_group_id),
            'tem_trello': bool(self.trello_member_id),
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
    
    def to_dict_complete(self, db=None):
        """
        Retorna dicionário completo com estatísticas
        Útil para visualização detalhada
        
        Args:
            db: Sessão do banco (opcional, necessário para contar demandas)
        """
        # Contar usando query explícita para evitar erro de enum
        total_demandas = 0
        if db is not None:
            from app.models import Demanda
            total_demandas = db.query(Demanda).filter(Demanda.cliente_id == self.id).count()
        elif hasattr(self, '_sa_instance_state') and 'demandas' in getattr(self._sa_instance_state, 'loaded_attrs', {}):
            # Se relacionamento estiver carregado (não deveria com lazy="noload")
            total_demandas = len(self.demandas) if self.demandas else 0
        
        return {
            **self.to_dict(),
            'total_usuarios': len(self.usuarios) if self.usuarios else 0,
            'total_secretarias': len(self.secretarias) if self.secretarias else 0,
            'total_demandas': total_demandas,
        }
    
    @classmethod
    def get_ativos(cls, db):
        """
        Retorna apenas clientes ativos
        
        Args:
            db: Sessão do banco
        
        Returns:
            Query com clientes ativos
        """
        return db.query(cls).filter(cls.ativo == True)
    
    def desativar(self):
        """
        Desativa o cliente (soft delete)
        Mantém histórico no banco
        """
        self.ativo = False
    
    def ativar(self):
        """Ativa o cliente"""
        self.ativo = True
    
    def pode_receber_notificacoes(self):
        """Verifica se cliente pode receber notificações WhatsApp"""
        return self.ativo and bool(self.whatsapp_group_id)
    
    def pode_criar_cards_trello(self):
        """Verifica se cliente pode ter cards criados no Trello"""
        return self.ativo and bool(self.trello_member_id)


# ==================== ÍNDICES ====================
# Índices adicionais são criados automaticamente:
# - id (primary key, unique)
# - nome (index para buscas)
# - ativo (index para filtros)

