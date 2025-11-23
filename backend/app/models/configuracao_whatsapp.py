"""
Modelo de Configuração WhatsApp
Armazena configurações do número remetente WhatsApp Business
"""
from sqlalchemy import Column, String, Boolean
from app.models.base import BaseModel


class ConfiguracaoWhatsApp(BaseModel):
    """
    Configurações do número WhatsApp Business remetente
    
    Permite configurar qual número será usado para enviar
    notificações individuais para os usuários do sistema.
    
    Atributos:
        numero_remetente: Número WhatsApp Business (formato: 5511999999999)
        instancia_wpp: Nome da instância WPP Connect configurada
        ativo: Se esta configuração está ativa (apenas uma por vez)
    
    Exemplo:
        ```python
        config = ConfiguracaoWhatsApp(
            numero_remetente="5511999999999",
            instancia_wpp="debrief-instance",
            ativo=True
        )
        ```
    """
    
    __tablename__ = "configuracoes_whatsapp"
    
    # Número WhatsApp Business que enviará as mensagens
    numero_remetente = Column(
        String(20),
        nullable=False,
        comment="Número WhatsApp Business remetente (formato: 5511999999999)"
    )
    
    # Nome da instância WPP Connect
    instancia_wpp = Column(
        String(100),
        nullable=False,
        comment="Nome da instância WPP Connect"
    )
    
    # Flag para indicar se está ativa (apenas uma configuração ativa por vez)
    ativo = Column(
        Boolean,
        nullable=False,
        default=True,
        comment="Se esta configuração está ativa"
    )
    
    def __repr__(self):
        return f"<ConfiguracaoWhatsApp(numero={self.numero_remetente}, ativo={self.ativo})>"
    
    @classmethod
    def get_ativa(cls, db):
        """
        Retorna a configuração ativa
        
        Args:
            db: Sessão do banco
            
        Returns:
            ConfiguracaoWhatsApp ou None
        """
        return db.query(cls).filter(
            cls.ativo == True,
            cls.deleted_at == None
        ).first()
    
    @classmethod
    def desativar_todas(cls, db):
        """
        Desativa todas as configurações
        
        Args:
            db: Sessão do banco
        """
        db.query(cls).filter(
            cls.deleted_at == None
        ).update({"ativo": False})
        db.commit()

