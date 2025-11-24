"""
Modelo de Etiqueta Trello por Cliente
Vincula etiquetas do Trello a clientes do sistema
"""
from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class EtiquetaTrelloCliente(BaseModel):
    """
    Etiquetas do Trello vinculadas a clientes
    
    Cada cliente pode ter uma etiqueta no Trello que
    será aplicada automaticamente aos cards de suas demandas.
    
    Atributos:
        cliente_id: ID do cliente
        etiqueta_trello_id: ID da label no Trello
        etiqueta_nome: Nome da etiqueta
        etiqueta_cor: Cor da etiqueta (ex: green, red, blue)
        ativo: Se está ativo
    
    Relacionamentos:
        cliente: Cliente associado a esta etiqueta
    
    Exemplo:
        ```python
        etiqueta = EtiquetaTrelloCliente(
            cliente_id="uuid-do-cliente",
            etiqueta_trello_id="5f7e8d9a...",
            etiqueta_nome="RUSSAS",
            etiqueta_cor="green",
            ativo=True
        )
        ```
    """
    
    __tablename__ = "etiquetas_trello_cliente"
    
    # Relacionamento com cliente
    cliente_id = Column(
        String(36),
        ForeignKey('clientes.id', ondelete='CASCADE'),
        nullable=False,
        comment="ID do cliente"
    )
    
    # Dados da etiqueta Trello
    etiqueta_trello_id = Column(
        String(100),
        nullable=False,
        comment="ID da label no Trello"
    )
    
    etiqueta_nome = Column(
        String(100),
        nullable=False,
        comment="Nome da etiqueta"
    )
    
    etiqueta_cor = Column(
        String(20),
        nullable=False,
        comment="Cor da etiqueta (ex: green, red, blue)"
    )
    
    # Status
    ativo = Column(
        Boolean,
        default=True,
        nullable=False,
        comment="Se está ativo"
    )
    
    # Relacionamento
    cliente = relationship(
        "Cliente",
        back_populates="etiqueta_trello"
    )
    
    def __repr__(self):
        return f"<EtiquetaTrelloCliente(cliente={self.cliente_id}, etiqueta={self.etiqueta_nome})>"
    
    @classmethod
    def get_by_cliente(cls, db, cliente_id):
        """
        Retorna etiqueta ativa de um cliente
        
        Args:
            db: Sessão do banco
            cliente_id: ID do cliente
            
        Returns:
            EtiquetaTrelloCliente ou None
        """
        return db.query(cls).filter(
            cls.cliente_id == cliente_id,
            cls.ativo == True
        ).first()
    
    @classmethod
    def get_todas_ativas(cls, db):
        """
        Retorna todas as etiquetas ativas
        
        Args:
            db: Sessão do banco
            
        Returns:
            List[EtiquetaTrelloCliente]
        """
        return db.query(cls).filter(
            cls.ativo == True
        ).all()
    
    def desativar(self, db):
        """
        Desativa esta etiqueta
        
        Args:
            db: Sessão do banco
        """
        self.ativo = False
        db.commit()
    
    def ativar(self, db):
        """
        Ativa esta etiqueta
        
        Args:
            db: Sessão do banco
        """
        self.ativo = True
        db.commit()

