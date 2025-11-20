"""
Modelo de Secretaria
Representa departamentos/secretarias dentro de um cliente
"""
from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class Secretaria(BaseModel):
    """
    Tabela de secretarias/departamentos
    
    Cada cliente pode ter múltiplas secretarias.
    Exemplo: Secretaria de Saúde, Secretaria de Educação, etc.
    
    Atributos:
        nome (str): Nome da secretaria
        cliente_id (str): ID do cliente (FK)
        ativo (bool): Status ativo/inativo
    
    Relacionamentos:
        cliente: Cliente ao qual pertence
        demandas: Demandas da secretaria
    
    Exemplo:
        secretaria = Secretaria(
            nome="Secretaria de Saúde",
            cliente_id="cliente-uuid-123",
            ativo=True
        )
    """
    __tablename__ = "secretarias"
    
    # ==================== CAMPOS ====================
    
    nome = Column(
        String(200),
        nullable=False,
        index=True,
        comment="Nome da secretaria/departamento"
    )
    
    cliente_id = Column(
        String(36),
        ForeignKey("clientes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID do cliente (FK)"
    )
    
    ativo = Column(
        Boolean,
        default=True,
        nullable=False,
        index=True,
        comment="Status ativo/inativo"
    )
    
    # ==================== RELACIONAMENTOS ====================
    
    # Relacionamento com cliente
    cliente = relationship(
        "Cliente",
        back_populates="secretarias",
        lazy="joined"  # Carrega cliente automaticamente
    )
    
    # Relacionamento com demandas
    # Usar lazy="noload" para evitar carregar automaticamente (evita erro de enum)
    # Quando necessário, usar query explícita: db.query(Demanda).filter(Demanda.secretaria_id == self.id)
    demandas = relationship(
        "Demanda",
        back_populates="secretaria",
        lazy="noload"  # Nunca carregar automaticamente
    )
    
    # ==================== MÉTODOS ====================
    
    def __repr__(self):
        """Representação do objeto"""
        return f"<Secretaria(id='{self.id}', nome='{self.nome}', cliente_id='{self.cliente_id}')>"
    
    def to_dict_summary(self):
        """
        Retorna dicionário resumido
        Inclui informações do cliente
        """
        return {
            'id': self.id,
            'nome': self.nome,
            'cliente_id': self.cliente_id,
            'cliente_nome': self.cliente.nome if self.cliente else None,
            'ativo': self.ativo,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
    
    def to_dict_complete(self):
        """
        Retorna dicionário completo com estatísticas
        """
        return {
            **self.to_dict(),
            'cliente': self.cliente.to_dict_summary() if self.cliente else None,
            'total_demandas': len(self.demandas) if self.demandas else 0,
        }
    
    @classmethod
    def get_por_cliente(cls, db, cliente_id, apenas_ativas=True):
        """
        Retorna secretarias de um cliente específico
        
        Args:
            db: Sessão do banco
            cliente_id: ID do cliente
            apenas_ativas: Se True, retorna apenas secretarias ativas
        
        Returns:
            Query com secretarias filtradas
        
        Exemplo:
            secretarias = Secretaria.get_por_cliente(db, "cli-123")
        """
        query = db.query(cls).filter(cls.cliente_id == cliente_id)
        
        if apenas_ativas:
            query = query.filter(cls.ativo == True)
        
        return query.order_by(cls.nome)
    
    @classmethod
    def get_ativas(cls, db):
        """
        Retorna apenas secretarias ativas
        
        Args:
            db: Sessão do banco
        
        Returns:
            Query com secretarias ativas
        """
        return db.query(cls).filter(cls.ativo == True).order_by(cls.nome)
    
    def desativar(self):
        """
        Desativa a secretaria (soft delete)
        Mantém histórico no banco
        """
        self.ativo = False
    
    def ativar(self):
        """Ativa a secretaria"""
        self.ativo = True
    
    def tem_demandas(self, db=None):
        """
        Verifica se a secretaria tem demandas vinculadas
        
        Args:
            db: Sessão do banco (opcional, necessário se relacionamento não estiver carregado)
        
        Returns:
            bool: True se tiver demandas, False caso contrário
        """
        # Se relacionamento estiver carregado (não deveria com lazy="noload")
        if hasattr(self, '_sa_instance_state') and 'demandas' in self._sa_instance_state.loaded_attrs:
            return bool(self.demandas and len(self.demandas) > 0)
        
        # Se não, usar query explícita (requer db)
        if db is not None:
            from app.models import Demanda
            count = db.query(Demanda).filter(Demanda.secretaria_id == self.id).count()
            return count > 0
        
        # Se não tiver db, retornar False (assumir que não tem)
        return False
    
    def pode_ser_deletada(self, db=None):
        """
        Verifica se a secretaria pode ser deletada
        Não pode deletar se houver demandas vinculadas
        
        Args:
            db: Sessão do banco (opcional, necessário para verificar demandas)
        """
        return not self.tem_demandas(db)


# ==================== ÍNDICES ====================
# Índices adicionais são criados automaticamente:
# - id (primary key, unique)
# - nome (index para buscas)
# - cliente_id (index para filtros + FK)
# - ativo (index para filtros)

# Índice composto para buscas frequentes
from sqlalchemy import Index
Index(
    'ix_secretarias_cliente_ativo',
    Secretaria.cliente_id,
    Secretaria.ativo
)

