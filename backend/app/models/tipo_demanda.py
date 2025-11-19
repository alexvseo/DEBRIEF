"""
Modelo de Tipo de Demanda
Representa categorias/tipos de demandas (Design, Desenvolvimento, Vídeo, etc)
"""
from sqlalchemy import Column, String, Boolean
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class TipoDemanda(BaseModel):
    """
    Tabela de tipos de demanda
    
    Define as categorias de demandas que podem ser criadas.
    Exemplos: Design, Desenvolvimento, Conteúdo, Vídeo, etc.
    
    Atributos:
        nome (str): Nome do tipo (ex: "Design")
        cor (str): Cor hexadecimal para UI (ex: "#3B82F6")
        ativo (bool): Status ativo/inativo
    
    Relacionamentos:
        demandas: Demandas deste tipo
    
    Exemplo:
        tipo = TipoDemanda(
            nome="Design",
            cor="#3B82F6",
            ativo=True
        )
    """
    __tablename__ = "tipos_demanda"
    
    # ==================== CAMPOS ====================
    
    nome = Column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
        comment="Nome do tipo de demanda"
    )
    
    cor = Column(
        String(7),
        nullable=False,
        default="#3B82F6",
        comment="Cor hexadecimal para UI (ex: #FF5733)"
    )
    
    ativo = Column(
        Boolean,
        default=True,
        nullable=False,
        index=True,
        comment="Status ativo/inativo"
    )
    
    # ==================== RELACIONAMENTOS ====================
    
    # Relacionamento com demandas
    demandas = relationship(
        "Demanda",
        back_populates="tipo_demanda",
        lazy="select"
    )
    
    # ==================== MÉTODOS ====================
    
    def __repr__(self):
        """Representação do objeto"""
        return f"<TipoDemanda(id='{self.id}', nome='{self.nome}', cor='{self.cor}')>"
    
    def to_dict_summary(self):
        """
        Retorna dicionário resumido
        Útil para dropdowns e listagens
        """
        return {
            'id': self.id,
            'nome': self.nome,
            'cor': self.cor,
            'ativo': self.ativo
        }
    
    def to_dict_complete(self):
        """
        Retorna dicionário completo com estatísticas
        """
        return {
            **self.to_dict(),
            'total_demandas': len(self.demandas) if self.demandas else 0,
        }
    
    @classmethod
    def get_ativos(cls, db):
        """
        Retorna apenas tipos ativos
        Útil para preencher dropdowns no formulário
        
        Args:
            db: Sessão do banco
        
        Returns:
            Query com tipos ativos ordenados por nome
        
        Exemplo:
            tipos = TipoDemanda.get_ativos(db).all()
        """
        return db.query(cls).filter(
            cls.ativo == True
        ).order_by(cls.nome)
    
    @classmethod
    def get_por_nome(cls, db, nome):
        """
        Busca tipo por nome (case insensitive)
        
        Args:
            db: Sessão do banco
            nome: Nome do tipo
        
        Returns:
            TipoDemanda ou None
        """
        return db.query(cls).filter(
            cls.nome.ilike(nome)
        ).first()
    
    def desativar(self):
        """
        Desativa o tipo (soft delete)
        Tipos inativos não aparecem em formulários
        """
        self.ativo = False
    
    def ativar(self):
        """Ativa o tipo"""
        self.ativo = True
    
    def tem_demandas(self):
        """Verifica se o tipo tem demandas vinculadas"""
        return bool(self.demandas and len(self.demandas) > 0)
    
    def validar_cor(self):
        """
        Valida se a cor está no formato hexadecimal correto
        
        Returns:
            bool: True se cor válida
        
        Raises:
            ValueError: Se cor inválida
        """
        import re
        if not re.match(r'^#[0-9A-Fa-f]{6}$', self.cor):
            raise ValueError(
                f"Cor inválida: {self.cor}. "
                "Formato esperado: #RRGGBB (ex: #3B82F6)"
            )
        return True
    
    @classmethod
    def criar_tipos_padroes(cls, db):
        """
        Cria tipos padrões se não existirem
        Útil para inicialização do sistema
        
        Args:
            db: Sessão do banco
        
        Returns:
            List[TipoDemanda]: Tipos criados
        """
        tipos_padroes = [
            {"nome": "Design", "cor": "#3B82F6"},        # Azul
            {"nome": "Desenvolvimento", "cor": "#8B5CF6"},  # Roxo
            {"nome": "Conteúdo", "cor": "#10B981"},     # Verde
            {"nome": "Vídeo", "cor": "#F59E0B"},        # Amarelo
        ]
        
        tipos_criados = []
        
        for tipo_data in tipos_padroes:
            # Verificar se já existe
            existe = cls.get_por_nome(db, tipo_data["nome"])
            
            if not existe:
                tipo = cls(**tipo_data, ativo=True)
                db.add(tipo)
                tipos_criados.append(tipo)
        
        if tipos_criados:
            db.commit()
            for tipo in tipos_criados:
                db.refresh(tipo)
        
        return tipos_criados


# ==================== ÍNDICES ====================
# Índices adicionais são criados automaticamente:
# - id (primary key, unique)
# - nome (unique, index para buscas)
# - ativo (index para filtros)

# ==================== VALIDAÇÕES ====================
from sqlalchemy import event

@event.listens_for(TipoDemanda, 'before_insert')
@event.listens_for(TipoDemanda, 'before_update')
def validar_cor_antes_salvar(mapper, connection, target):
    """Valida cor antes de inserir/atualizar"""
    target.validar_cor()

