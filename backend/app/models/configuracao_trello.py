"""
Modelo de Configuração Trello
Armazena credenciais e configuração do board/lista do Trello
"""
from sqlalchemy import Column, String, Boolean
from app.models.base import BaseModel


class ConfiguracaoTrello(BaseModel):
    """
    Configurações de integração com Trello
    
    Armazena credenciais (API Key e Token) e configuração
    do board e lista onde as demandas serão criadas.
    
    Apenas uma configuração pode estar ativa por vez.
    
    Atributos:
        api_key: Chave de API do Trello
        token: Token de autenticação do Trello
        board_id: ID do Board no Trello
        board_nome: Nome do Board (cache para exibição)
        lista_id: ID da Lista dentro do Board
        lista_nome: Nome da Lista (cache para exibição)
        ativo: Se esta configuração está ativa
    
    Exemplo:
        ```python
        config = ConfiguracaoTrello(
            api_key="abc123...",
            token="def456...",
            board_id="5f7e8d9a...",
            board_nome="DeBrief - Demandas",
            lista_id="6a8b9c0d...",
            lista_nome="ENVIOS DOS CLIENTES VIA DEBRIEF",
            ativo=True
        )
        ```
    """
    
    __tablename__ = "configuracoes_trello"
    
    # Credenciais Trello
    api_key = Column(
        String(100),
        nullable=False,
        comment="API Key do Trello"
    )
    
    token = Column(
        String(255),
        nullable=False,
        comment="Token de autenticação do Trello"
    )
    
    # Board e Lista
    board_id = Column(
        String(100),
        nullable=False,
        comment="ID do Board no Trello"
    )
    
    board_nome = Column(
        String(200),
        nullable=True,
        comment="Nome do Board (cache)"
    )
    
    lista_id = Column(
        String(100),
        nullable=False,
        comment="ID da Lista no Trello"
    )
    
    lista_nome = Column(
        String(200),
        nullable=True,
        comment="Nome da Lista (cache)"
    )
    
    # Status
    ativo = Column(
        Boolean,
        default=True,
        nullable=False,
        comment="Se está ativo (apenas uma por vez)"
    )
    
    def __repr__(self):
        return f"<ConfiguracaoTrello(board={self.board_nome}, lista={self.lista_nome}, ativo={self.ativo})>"
    
    @classmethod
    def get_ativa(cls, db):
        """
        Retorna a configuração ativa
        
        Args:
            db: Sessão do banco
            
        Returns:
            ConfiguracaoTrello ou None
        """
        return db.query(cls).filter(
            cls.ativo == True,
            cls.deleted_at == None
        ).first()
    
    @classmethod
    def desativar_todas(cls, db):
        """
        Desativa todas as configurações
        Útil antes de ativar uma nova
        
        Args:
            db: Sessão do banco
        """
        db.query(cls).filter(
            cls.deleted_at == None
        ).update({"ativo": False})
        db.commit()
    
    def pode_conectar(self) -> bool:
        """
        Verifica se configuração está completa para conectar
        
        Returns:
            bool: True se tem todas as credenciais necessárias
        """
        return bool(
            self.api_key and 
            self.token and 
            self.board_id and 
            self.lista_id and 
            self.ativo
        )

