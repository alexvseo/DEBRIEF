"""
Modelo de Usuário (User)
Representa a tabela 'users' no banco de dados PostgreSQL

Responsável por:
- Autenticação e autorização
- Gerenciamento de usuários do sistema
- Relacionamento com clientes
- Controle de acesso (master vs cliente)
"""
import enum
from typing import Optional, List
from sqlalchemy import Column, String, Boolean, Enum as SQLEnum, ForeignKey, Index, TypeDecorator
from sqlalchemy.orm import relationship, validates
from passlib.context import CryptContext
from app.models.base import BaseModel

# Configurar contexto de criptografia para senhas
# bcrypt é considerado seguro e resistente a ataques de força bruta
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class TipoUsuario(str, enum.Enum):
    """
    Enum para tipos de usuário no sistema
    
    MASTER: Administrador com acesso total ao sistema
            - Pode gerenciar todos os clientes
            - Pode criar/editar/deletar usuários
            - Pode acessar configurações globais
            - Pode ver relatórios de todos os clientes
    
    CLIENTE: Usuário normal vinculado a um cliente específico
             - Pode criar e gerenciar suas próprias demandas
             - Pode ver apenas dados do seu cliente
             - Acesso restrito às suas secretarias
    
    Nota: Valores minúsculos ('master', 'cliente') para compatibilidade com banco
    """
    MASTER = "master"  # Minúsculo para compatibilidade com banco
    CLIENTE = "cliente"  # Minúsculo para compatibilidade com banco


class TipoUsuarioType(TypeDecorator):
    """
    TypeDecorator para converter entre enum Python e string do banco
    Permite usar TipoUsuario.MASTER no código, mas armazena 'master' no banco
    """
    impl = String
    cache_ok = True
    
    def __init__(self):
        super().__init__(length=20)
    
    def process_bind_param(self, value, dialect):
        """Converter enum Python para string do banco"""
        if value is None:
            return None
        if isinstance(value, TipoUsuario):
            return value.value  # Retorna 'master' ou 'cliente'
        return str(value)
    
    def process_result_value(self, value, dialect):
        """Converter string do banco para enum Python"""
        if value is None:
            return None
        # Buscar enum pelo valor
        for tipo in TipoUsuario:
            if tipo.value == value:
                return tipo
        return value  # Retornar string se não encontrar


class User(BaseModel):
    """
    Modelo de Usuário do sistema DeBrief
    
    Tabela: users
    
    Relacionamentos:
    - cliente (Many-to-One): Cliente ao qual o usuário pertence
    - demandas (One-to-Many): Demandas criadas pelo usuário
    
    Campos:
    - username: Nome de usuário único para login
    - email: Email único do usuário
    - password_hash: Senha criptografada com bcrypt
    - nome_completo: Nome completo do usuário
    - tipo: Tipo de usuário (master ou cliente)
    - cliente_id: ID do cliente (NULL para masters)
    - ativo: Se o usuário está ativo no sistema
    """
    __tablename__ = "users"
    
    # ==================== CAMPOS BÁSICOS ====================
    
    username = Column(
        String(50),
        unique=True,
        nullable=False,
        index=True,
        comment="Nome de usuário para login (único)"
    )
    
    email = Column(
        String(100),
        unique=True,
        nullable=False,
        index=True,
        comment="Email do usuário (único)"
    )
    
    password_hash = Column(
        String(255),
        nullable=False,
        comment="Senha criptografada com bcrypt"
    )
    
    nome_completo = Column(
        String(200),
        nullable=False,
        comment="Nome completo do usuário"
    )
    
    # ==================== TIPO E PERMISSÕES ====================
    
    tipo = Column(
        TipoUsuarioType(),
        nullable=False,
        default=TipoUsuario.CLIENTE,
        index=True,
        comment="Tipo de usuário: master (admin) ou cliente"
    )
    
    # ==================== RELACIONAMENTOS ====================
    
    # Relacionamento com cliente (nullable para usuários master)
    cliente_id = Column(
        String(36),
        ForeignKey("clientes.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
        comment="ID do cliente (NULL para usuários master)"
    )
    
    # Relacionamento com cliente
    cliente = relationship(
        "Cliente",
        back_populates="usuarios",
        lazy="joined"  # Carrega cliente automaticamente
    )
    
    # ==================== STATUS ====================
    
    ativo = Column(
        Boolean,
        default=True,
        nullable=False,
        index=True,
        comment="Se o usuário está ativo no sistema"
    )
    
    # ==================== RELACIONAMENTOS INVERSOS ====================
    
    # Demandas criadas por este usuário
    # Usar lazy="noload" para evitar carregar automaticamente (evita erro de enum)
    # Quando necessário, usar query explícita: db.query(Demanda).filter(Demanda.usuario_id == self.id)
    demandas = relationship(
        "Demanda",
        back_populates="usuario",
        cascade="all, delete-orphan",
        lazy="noload"  # Nunca carregar automaticamente
    )
    
    # ==================== ÍNDICES COMPOSTOS ====================
    
    __table_args__ = (
        # Índice composto para buscar usuários ativos de um cliente
        Index('idx_user_cliente_ativo', 'cliente_id', 'ativo'),
        # Índice composto para buscar usuários por tipo e status
        Index('idx_user_tipo_ativo', 'tipo', 'ativo'),
    )
    
    # ==================== VALIDAÇÕES ====================
    
    @validates('username')
    def validate_username(self, key, username):
        """
        Valida o username
        
        Regras:
        - Mínimo 3 caracteres
        - Máximo 50 caracteres
        - Apenas letras, números, underscore e hífen
        """
        if not username:
            raise ValueError("Username é obrigatório")
        
        username = username.strip().lower()
        
        if len(username) < 3:
            raise ValueError("Username deve ter pelo menos 3 caracteres")
        
        if len(username) > 50:
            raise ValueError("Username deve ter no máximo 50 caracteres")
        
        # Caracteres permitidos: letras, números, underscore, hífen
        import re
        if not re.match(r'^[a-z0-9_-]+$', username):
            raise ValueError("Username deve conter apenas letras minúsculas, números, underscore e hífen")
        
        return username
    
    @validates('email')
    def validate_email(self, key, email):
        """
        Valida o email
        
        Regras:
        - Formato de email válido
        - Máximo 100 caracteres
        """
        if not email:
            raise ValueError("Email é obrigatório")
        
        email = email.strip().lower()
        
        if len(email) > 100:
            raise ValueError("Email deve ter no máximo 100 caracteres")
        
        # Validação básica de formato de email
        import re
        email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_regex, email):
            raise ValueError("Formato de email inválido")
        
        return email
    
    @validates('nome_completo')
    def validate_nome_completo(self, key, nome_completo):
        """
        Valida o nome completo
        
        Regras:
        - Mínimo 3 caracteres
        - Máximo 200 caracteres
        """
        if not nome_completo:
            raise ValueError("Nome completo é obrigatório")
        
        nome_completo = nome_completo.strip()
        
        if len(nome_completo) < 3:
            raise ValueError("Nome completo deve ter pelo menos 3 caracteres")
        
        if len(nome_completo) > 200:
            raise ValueError("Nome completo deve ter no máximo 200 caracteres")
        
        return nome_completo
    
    @validates('cliente_id')
    def validate_cliente_id(self, key, cliente_id):
        """
        Valida o cliente_id
        
        Regras:
        - Obrigatório para usuários tipo CLIENTE
        - Deve ser NULL para usuários tipo MASTER
        """
        # Converter string vazia para None
        if cliente_id == '' or cliente_id is None:
            cliente_id = None
        
        # Se tipo ainda não foi definido (durante criação), pular validação
        # O tipo será validado depois
        if not hasattr(self, 'tipo') or self.tipo is None:
            return cliente_id
        
        # Validar apenas se tipo já foi definido
        if self.tipo == TipoUsuario.CLIENTE and not cliente_id:
            raise ValueError("cliente_id é obrigatório para usuários do tipo CLIENTE")
        
        if self.tipo == TipoUsuario.MASTER and cliente_id:
            raise ValueError("Usuários MASTER não devem ter cliente_id")
        
        return cliente_id
    
    # ==================== MÉTODOS DE SENHA ====================
    
    def set_password(self, password: str) -> None:
        """
        Define a senha do usuário (criptografada)
        
        Args:
            password (str): Senha em texto plano
        
        Validações:
        - Mínimo 6 caracteres
        - Máximo 72 bytes (limite do bcrypt)
        
        Exemplo:
            user = User(username="joao")
            user.set_password("senha123")
        """
        if not password:
            raise ValueError("Senha é obrigatória")
        
        if len(password) < 6:
            raise ValueError("Senha deve ter pelo menos 6 caracteres")
        
        # Bcrypt tem limite de 72 bytes
        if len(password.encode('utf-8')) > 72:
            raise ValueError("Senha muito longa (máximo 72 bytes)")
        
        # Criptografar e armazenar
        self.password_hash = pwd_context.hash(password)
    
    def verify_password(self, password: str) -> bool:
        """
        Verifica se a senha fornecida está correta
        
        Args:
            password (str): Senha em texto plano para verificar
        
        Returns:
            bool: True se a senha está correta, False caso contrário
        
        Exemplo:
            if user.verify_password("senha123"):
                print("Senha correta!")
        """
        if not password or not self.password_hash:
            return False
        
        return pwd_context.verify(password, self.password_hash)
    
    def needs_password_rehash(self) -> bool:
        """
        Verifica se a senha precisa ser re-hashada
        (útil quando atualizamos o algoritmo de hash)
        
        Returns:
            bool: True se precisa rehash, False caso contrário
        """
        return pwd_context.needs_update(self.password_hash)
    
    # ==================== MÉTODOS DE PERMISSÃO ====================
    
    def is_master(self) -> bool:
        """
        Verifica se o usuário é master (administrador)
        
        Returns:
            bool: True se for master
        
        Exemplo:
            if user.is_master():
                # Permitir acesso a área admin
        """
        return self.tipo == TipoUsuario.MASTER
    
    def is_cliente(self) -> bool:
        """
        Verifica se o usuário é do tipo cliente
        
        Returns:
            bool: True se for cliente
        """
        return self.tipo == TipoUsuario.CLIENTE
    
    def can_access_cliente(self, cliente_id: str) -> bool:
        """
        Verifica se o usuário pode acessar dados de um cliente específico
        
        Args:
            cliente_id (str): ID do cliente a verificar
        
        Returns:
            bool: True se pode acessar, False caso contrário
        
        Regras:
        - Master pode acessar qualquer cliente
        - Cliente só pode acessar seu próprio cliente
        
        Exemplo:
            if user.can_access_cliente(demanda.cliente_id):
                # Permitir ver/editar demanda
        """
        if self.is_master():
            return True
        
        return self.cliente_id == cliente_id
    
    def can_edit_user(self, other_user: 'User') -> bool:
        """
        Verifica se este usuário pode editar outro usuário
        
        Args:
            other_user (User): Outro usuário a verificar
        
        Returns:
            bool: True se pode editar, False caso contrário
        
        Regras:
        - Master pode editar qualquer usuário
        - Cliente não pode editar outros usuários
        - Usuário pode editar a si mesmo
        """
        if self.id == other_user.id:
            return True
        
        if self.is_master():
            return True
        
        return False
    
    # ==================== MÉTODOS DE CONSULTA ====================
    
    def get_demandas_count(self, db) -> int:
        """
        Retorna o número de demandas criadas pelo usuário
        
        Args:
            db: Sessão do banco de dados
        
        Returns:
            int: Número de demandas
        
        Exemplo:
            total = user.get_demandas_count(db)
            print(f"Usuário criou {total} demandas")
        """
        from app.models.demanda import Demanda
        return db.query(Demanda).filter(Demanda.usuario_id == self.id).count()
    
    def get_demandas_abertas(self, db):
        """
        Retorna demandas abertas criadas pelo usuário
        
        Args:
            db: Sessão do banco de dados
        
        Returns:
            Query: Query de demandas abertas
        """
        from app.models.demanda import Demanda, StatusDemanda
        return db.query(Demanda).filter(
            Demanda.usuario_id == self.id,
            Demanda.status == StatusDemanda.ABERTA
        )
    
    def get_demandas_em_andamento(self, db):
        """
        Retorna demandas em andamento criadas pelo usuário
        
        Args:
            db: Sessão do banco de dados
        
        Returns:
            Query: Query de demandas em andamento
        """
        from app.models.demanda import Demanda, StatusDemanda
        return db.query(Demanda).filter(
            Demanda.usuario_id == self.id,
            Demanda.status == StatusDemanda.EM_ANDAMENTO
        )
    
    # ==================== MÉTODOS DE STATUS ====================
    
    def ativar(self) -> None:
        """
        Ativa o usuário no sistema
        
        Exemplo:
            user.ativar()
            db.commit()
        """
        self.ativo = True
    
    def desativar(self) -> None:
        """
        Desativa o usuário no sistema
        (soft delete - não remove do banco)
        
        Exemplo:
            user.desativar()
            db.commit()
        """
        self.ativo = False
    
    def is_ativo(self) -> bool:
        """
        Verifica se o usuário está ativo
        
        Returns:
            bool: True se ativo
        """
        return self.ativo
    
    # ==================== MÉTODOS DE SERIALIZAÇÃO ====================
    
    def to_dict(self, include_sensitive: bool = False) -> dict:
        """
        Converte usuário para dicionário
        
        Args:
            include_sensitive (bool): Se deve incluir dados sensíveis (password_hash)
        
        Returns:
            dict: Dicionário com dados do usuário
        
        Exemplo:
            user_data = user.to_dict()  # Sem dados sensíveis
            user_full = user.to_dict(include_sensitive=True)  # Com hash da senha
        """
        data = super().to_dict()
        
        # Sempre remover password_hash por padrão
        if not include_sensitive and 'password_hash' in data:
            del data['password_hash']
        
        # Adicionar informações calculadas
        data['is_master'] = self.is_master()
        data['demandas_count'] = self.get_demandas_count()
        
        # Adicionar nome do cliente se houver
        if self.cliente:
            data['cliente_nome'] = self.cliente.nome
        
        return data
    
    def to_dict_safe(self) -> dict:
        """
        Retorna apenas dados seguros para exibição pública
        Remove TODOS os dados sensíveis
        
        Returns:
            dict: Dicionário com dados públicos
        """
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'nome_completo': self.nome_completo,
            'tipo': self.tipo.value,
            'ativo': self.ativo,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
    
    # ==================== REPRESENTAÇÃO ====================
    
    def __repr__(self) -> str:
        """
        Representação string do usuário para debugging
        
        Returns:
            str: Representação do usuário
        """
        return f"<User(id='{self.id}', username='{self.username}', tipo='{self.tipo.value}', ativo={self.ativo})>"
    
    def __str__(self) -> str:
        """
        Representação string amigável do usuário
        
        Returns:
            str: Nome de usuário
        """
        return f"{self.username} ({self.nome_completo})"

