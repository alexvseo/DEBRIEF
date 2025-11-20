"""
Modelo de Configuração
Armazena configurações do sistema (Trello, WhatsApp, etc)
"""
import enum
from sqlalchemy import Column, String, Text, Enum, Index
from sqlalchemy.sql import func
from datetime import datetime
from app.models.base import BaseModel
from cryptography.fernet import Fernet
import os


class TipoConfiguracao(str, enum.Enum):
    """Tipos de configuração"""
    TRELLO = "trello"
    WHATSAPP = "whatsapp"
    SISTEMA = "sistema"
    EMAIL = "email"


class Configuracao(BaseModel):
    """
    Modelo de Configuração
    
    Armazena configurações do sistema de forma segura
    Valores sensíveis são criptografados
    
    Campos:
        chave: Identificador único da configuração (ex: "trello_api_key")
        valor: Valor da configuração (criptografado se sensível)
        tipo: Categoria da configuração (trello, whatsapp, sistema)
        descricao: Descrição da configuração
        is_sensivel: Se o valor deve ser criptografado
        
    Exemplo:
        config = Configuracao(
            chave="trello_api_key",
            valor="abc123...",
            tipo=TipoConfiguracao.TRELLO,
            descricao="Chave de API do Trello",
            is_sensivel=True
        )
    """
    
    __tablename__ = "configuracoes"
    
    # Campos principais
    chave = Column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
        comment="Identificador único da configuração"
    )
    
    valor = Column(
        Text,
        nullable=False,
        comment="Valor da configuração (criptografado se sensível)"
    )
    
    tipo = Column(
        Enum(TipoConfiguracao, native_enum=False),
        nullable=False,
        default=TipoConfiguracao.SISTEMA,
        index=True,
        comment="Categoria da configuração"
    )
    
    descricao = Column(
        String(500),
        nullable=True,
        comment="Descrição da configuração"
    )
    
    is_sensivel = Column(
        String(10),
        nullable=False,
        default="false",
        comment="Se o valor é sensível (será criptografado)"
    )
    
    # Índices para queries comuns
    __table_args__ = (
        Index('idx_configuracao_tipo', 'tipo'),
        Index('idx_configuracao_chave', 'chave'),
    )
    
    def __repr__(self):
        return f"<Configuracao(chave={self.chave}, tipo={self.tipo})>"
    
    @staticmethod
    def _get_cipher():
        """Obter cipher para criptografia"""
        key = os.getenv("ENCRYPTION_KEY")
        if not key:
            # Gerar chave temporária para desenvolvimento
            # PRODUÇÃO: Usar variável de ambiente
            key = Fernet.generate_key()
        if isinstance(key, str):
            key = key.encode()
        return Fernet(key)
    
    def set_valor(self, valor: str, is_sensivel: bool = False):
        """
        Definir valor da configuração
        Criptografa automaticamente se sensível
        
        Args:
            valor: Valor a ser armazenado
            is_sensivel: Se deve criptografar
        """
        self.is_sensivel = "true" if is_sensivel else "false"
        
        if is_sensivel and valor:
            cipher = self._get_cipher()
            self.valor = cipher.encrypt(valor.encode()).decode()
        else:
            self.valor = valor
    
    def get_valor(self) -> str:
        """
        Obter valor da configuração
        Descriptografa automaticamente se sensível
        
        Returns:
            str: Valor descriptografado
        """
        if self.is_sensivel == "true" and self.valor:
            try:
                cipher = self._get_cipher()
                return cipher.decrypt(self.valor.encode()).decode()
            except Exception as e:
                print(f"Erro ao descriptografar: {e}")
                return ""
        return self.valor
    
    @classmethod
    def get_by_chave(cls, db, chave: str) -> "Configuracao":
        """
        Buscar configuração por chave
        
        Args:
            db: Sessão do banco
            chave: Chave da configuração
            
        Returns:
            Configuracao ou None
        """
        return db.query(cls).filter(cls.chave == chave).first()
    
    @classmethod
    def get_valor_by_chave(cls, db, chave: str, default: str = None) -> str:
        """
        Obter valor de uma configuração por chave
        
        Args:
            db: Sessão do banco
            chave: Chave da configuração
            default: Valor padrão se não encontrado
            
        Returns:
            str: Valor da configuração
        """
        config = cls.get_by_chave(db, chave)
        if config:
            return config.get_valor()
        return default
    
    @classmethod
    def set_valor_by_chave(
        cls, 
        db, 
        chave: str, 
        valor: str, 
        tipo: TipoConfiguracao = TipoConfiguracao.SISTEMA,
        descricao: str = None,
        is_sensivel: bool = False
    ):
        """
        Definir valor de uma configuração (cria se não existe)
        
        Args:
            db: Sessão do banco
            chave: Chave da configuração
            valor: Valor a ser armazenado
            tipo: Tipo da configuração
            descricao: Descrição
            is_sensivel: Se deve criptografar
        """
        config = cls.get_by_chave(db, chave)
        
        if config:
            config.set_valor(valor, is_sensivel)
            if descricao:
                config.descricao = descricao
        else:
            config = cls(
                chave=chave,
                tipo=tipo,
                descricao=descricao
            )
            config.set_valor(valor, is_sensivel)
            db.add(config)
        
        db.commit()
        db.refresh(config)
        return config
    
    @classmethod
    def get_all_by_tipo(cls, db, tipo: TipoConfiguracao):
        """
        Buscar todas configurações de um tipo
        
        Args:
            db: Sessão do banco
            tipo: Tipo de configuração
            
        Returns:
            List[Configuracao]
        """
        return db.query(cls).filter(cls.tipo == tipo).all()
    
    @classmethod
    def criar_configuracoes_padrao(cls, db):
        """
        Criar configurações padrão do sistema
        
        Args:
            db: Sessão do banco
        """
        configs_padrao = [
            # Trello
            {
                "chave": "trello_api_key",
                "valor": "",
                "tipo": TipoConfiguracao.TRELLO,
                "descricao": "Chave de API do Trello",
                "is_sensivel": True
            },
            {
                "chave": "trello_token",
                "valor": "",
                "tipo": TipoConfiguracao.TRELLO,
                "descricao": "Token de autenticação do Trello",
                "is_sensivel": True
            },
            {
                "chave": "trello_board_id",
                "valor": "",
                "tipo": TipoConfiguracao.TRELLO,
                "descricao": "ID do Board do Trello"
            },
            {
                "chave": "trello_list_id",
                "valor": "",
                "tipo": TipoConfiguracao.TRELLO,
                "descricao": "ID da Lista 'ENVIOS DOS CLIENTES VIA DEBRIEF'"
            },
            
            # WhatsApp
            {
                "chave": "wpp_url",
                "valor": "http://localhost:21465",
                "tipo": TipoConfiguracao.WHATSAPP,
                "descricao": "URL da instância WPPConnect"
            },
            {
                "chave": "wpp_instance",
                "valor": "",
                "tipo": TipoConfiguracao.WHATSAPP,
                "descricao": "Nome da instância WPPConnect"
            },
            {
                "chave": "wpp_token",
                "valor": "",
                "tipo": TipoConfiguracao.WHATSAPP,
                "descricao": "Token de autenticação WPPConnect",
                "is_sensivel": True
            },
            
            # Sistema
            {
                "chave": "max_upload_size",
                "valor": "50",
                "tipo": TipoConfiguracao.SISTEMA,
                "descricao": "Tamanho máximo de upload (MB)"
            },
            {
                "chave": "allowed_extensions",
                "valor": "pdf,jpg,jpeg,png,doc,docx",
                "tipo": TipoConfiguracao.SISTEMA,
                "descricao": "Extensões de arquivo permitidas"
            },
            {
                "chave": "session_timeout",
                "valor": "480",
                "tipo": TipoConfiguracao.SISTEMA,
                "descricao": "Tempo de sessão (minutos)"
            },
        ]
        
        criadas = 0
        for config_data in configs_padrao:
            existing = cls.get_by_chave(db, config_data["chave"])
            if not existing:
                is_sensivel = config_data.get("is_sensivel", False)
                config = cls(
                    chave=config_data["chave"],
                    tipo=config_data["tipo"],
                    descricao=config_data["descricao"]
                )
                config.set_valor(config_data["valor"], is_sensivel)
                db.add(config)
                criadas += 1
        
        if criadas > 0:
            db.commit()
        
        return criadas
    
    def to_dict(self, include_valor: bool = False) -> dict:
        """
        Converter para dicionário
        
        Args:
            include_valor: Se deve incluir o valor (descriptografado)
            
        Returns:
            dict: Representação em dicionário
        """
        data = {
            "id": self.id,
            "chave": self.chave,
            "tipo": self.tipo.value if isinstance(self.tipo, enum.Enum) else self.tipo,
            "descricao": self.descricao,
            "is_sensivel": self.is_sensivel == "true",
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        
        if include_valor:
            if self.is_sensivel == "true":
                # Mascarar valores sensíveis
                valor_real = self.get_valor()
                if valor_real and len(valor_real) > 4:
                    data["valor"] = valor_real[:4] + "*" * (len(valor_real) - 4)
                else:
                    data["valor"] = "****"
            else:
                data["valor"] = self.get_valor()
        
        return data

