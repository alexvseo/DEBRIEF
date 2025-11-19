"""
Modelo de Prioridade
Representa níveis de prioridade das demandas
"""
from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class Prioridade(BaseModel):
    """
    Tabela de prioridades
    
    Define os níveis de prioridade para demandas.
    Exemplos: Baixa, Média, Alta, Urgente
    
    Atributos:
        nome (str): Nome da prioridade (ex: "Alta")
        nivel (int): Nível numérico (1-4) para ordenação
        cor (str): Cor hexadecimal para UI
    
    Relacionamentos:
        demandas: Demandas com esta prioridade
    
    Exemplo:
        prioridade = Prioridade(
            nome="Alta",
            nivel=3,
            cor="#F97316"
        )
    """
    __tablename__ = "prioridades"
    
    # ==================== CAMPOS ====================
    
    nome = Column(
        String(50),
        nullable=False,
        unique=True,
        index=True,
        comment="Nome da prioridade"
    )
    
    nivel = Column(
        Integer,
        nullable=False,
        index=True,
        comment="Nível numérico (1=Baixa, 2=Média, 3=Alta, 4=Urgente)"
    )
    
    cor = Column(
        String(7),
        nullable=False,
        default="#10B981",
        comment="Cor hexadecimal para UI (ex: #EF4444)"
    )
    
    # ==================== RELACIONAMENTOS ====================
    
    # Relacionamento com demandas
    demandas = relationship(
        "Demanda",
        back_populates="prioridade",
        lazy="select"
    )
    
    # ==================== MÉTODOS ====================
    
    def __repr__(self):
        """Representação do objeto"""
        return f"<Prioridade(id='{self.id}', nome='{self.nome}', nivel={self.nivel})>"
    
    def to_dict_summary(self):
        """
        Retorna dicionário resumido
        Útil para dropdowns e listagens
        """
        return {
            'id': self.id,
            'nome': self.nome,
            'nivel': self.nivel,
            'cor': self.cor
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
    def get_ordenadas(cls, db):
        """
        Retorna prioridades ordenadas por nível
        
        Args:
            db: Sessão do banco
        
        Returns:
            Query com prioridades ordenadas (Baixa -> Urgente)
        
        Exemplo:
            prioridades = Prioridade.get_ordenadas(db).all()
        """
        return db.query(cls).order_by(cls.nivel)
    
    @classmethod
    def get_por_nome(cls, db, nome):
        """
        Busca prioridade por nome (case insensitive)
        
        Args:
            db: Sessão do banco
            nome: Nome da prioridade
        
        Returns:
            Prioridade ou None
        """
        return db.query(cls).filter(
            cls.nome.ilike(nome)
        ).first()
    
    @classmethod
    def get_por_nivel(cls, db, nivel):
        """
        Busca prioridade por nível
        
        Args:
            db: Sessão do banco
            nivel: Nível (1-4)
        
        Returns:
            Prioridade ou None
        """
        return db.query(cls).filter(cls.nivel == nivel).first()
    
    def tem_demandas(self):
        """Verifica se a prioridade tem demandas vinculadas"""
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
                "Formato esperado: #RRGGBB (ex: #EF4444)"
            )
        return True
    
    def validar_nivel(self):
        """
        Valida se o nível está no range correto
        
        Returns:
            bool: True se nível válido
        
        Raises:
            ValueError: Se nível inválido
        """
        if not 1 <= self.nivel <= 4:
            raise ValueError(
                f"Nível inválido: {self.nivel}. "
                "Deve estar entre 1 (Baixa) e 4 (Urgente)"
            )
        return True
    
    def get_label_emoji(self):
        """
        Retorna emoji correspondente ao nível
        
        Returns:
            str: Emoji (🟢🟡🟠🔴)
        """
        emojis = {
            1: "🟢",  # Baixa
            2: "🟡",  # Média
            3: "🟠",  # Alta
            4: "🔴"   # Urgente
        }
        return emojis.get(self.nivel, "📌")
    
    @classmethod
    def criar_prioridades_padroes(cls, db):
        """
        Cria prioridades padrões se não existirem
        Útil para inicialização do sistema
        
        Args:
            db: Sessão do banco
        
        Returns:
            List[Prioridade]: Prioridades criadas
        """
        prioridades_padroes = [
            {"nome": "Baixa", "nivel": 1, "cor": "#10B981"},    # Verde
            {"nome": "Média", "nivel": 2, "cor": "#F59E0B"},    # Amarelo
            {"nome": "Alta", "nivel": 3, "cor": "#F97316"},     # Laranja
            {"nome": "Urgente", "nivel": 4, "cor": "#EF4444"},  # Vermelho
        ]
        
        prioridades_criadas = []
        
        for prioridade_data in prioridades_padroes:
            # Verificar se já existe
            existe = cls.get_por_nome(db, prioridade_data["nome"])
            
            if not existe:
                prioridade = cls(**prioridade_data)
                db.add(prioridade)
                prioridades_criadas.append(prioridade)
        
        if prioridades_criadas:
            db.commit()
            for prioridade in prioridades_criadas:
                db.refresh(prioridade)
        
        return prioridades_criadas


# ==================== ÍNDICES ====================
# Índices adicionais são criados automaticamente:
# - id (primary key, unique)
# - nome (unique, index para buscas)
# - nivel (index para ordenação)

# ==================== VALIDAÇÕES ====================
from sqlalchemy import event

@event.listens_for(Prioridade, 'before_insert')
@event.listens_for(Prioridade, 'before_update')
def validar_antes_salvar(mapper, connection, target):
    """Valida cor e nível antes de inserir/atualizar"""
    target.validar_cor()
    target.validar_nivel()

