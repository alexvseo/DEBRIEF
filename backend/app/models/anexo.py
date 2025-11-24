"""
Modelo de Anexo
Representa arquivos anexados às demandas
"""
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class Anexo(BaseModel):
    """
    Tabela de anexos
    
    Armazena metadados dos arquivos anexados às demandas.
    Os arquivos físicos são armazenados no sistema de arquivos.
    
    Atributos:
        demanda_id (str): ID da demanda (FK)
        nome_arquivo (str): Nome original do arquivo
        caminho (str): Path no servidor ou URL
        tamanho (int): Tamanho em bytes
        tipo_mime (str): Tipo MIME (ex: application/pdf)
        trello_attachment_id (str): ID do anexo no Trello (se aplicável)
    
    Relacionamentos:
        demanda: Demanda à qual o anexo pertence
    
    Exemplo:
        anexo = Anexo(
            demanda_id="dem-123",
            nome_arquivo="proposta.pdf",
            caminho="uploads/cli-123/dem-456/abc.pdf",
            tamanho=2048000,
            tipo_mime="application/pdf"
        )
    """
    __tablename__ = "anexos"
    
    # ==================== CAMPOS ====================
    
    demanda_id = Column(
        String(36),
        ForeignKey("demandas.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID da demanda (FK)"
    )
    
    nome_arquivo = Column(
        String(500),
        nullable=False,
        comment="Nome original do arquivo"
    )
    
    caminho = Column(
        String(1000),
        nullable=False,
        comment="Path relativo no servidor (ex: cliente_id/demanda_id/uuid.ext)"
    )
    
    tamanho = Column(
        Integer,
        nullable=False,
        comment="Tamanho do arquivo em bytes"
    )
    
    tipo_mime = Column(
        String(100),
        nullable=False,
        comment="Tipo MIME (ex: application/pdf, image/jpeg)"
    )
    
    trello_attachment_id = Column(
        String(100),
        nullable=True,
        comment="ID do anexo no Trello (se foi anexado no card)"
    )
    
    # ==================== RELACIONAMENTOS ====================
    
    # Relacionamento com demanda
    demanda = relationship(
        "Demanda",
        back_populates="anexos",
        lazy="joined"  # Carrega demanda automaticamente
    )
    
    # ==================== MÉTODOS ====================
    
    def __repr__(self):
        """Representação do objeto"""
        return f"<Anexo(id='{self.id}', nome='{self.nome_arquivo}', tamanho={self.tamanho})>"
    
    def to_dict_summary(self):
        """
        Retorna dicionário resumido
        Útil para listagens e APIs
        """
        return {
            'id': self.id,
            'nome_arquivo': self.nome_arquivo,
            'tamanho': self.tamanho,
            'tamanho_formatado': self.formatar_tamanho(),
            'tipo_mime': self.tipo_mime,
            'extensao': self.get_extensao(),
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
    
    def to_dict_complete(self):
        """
        Retorna dicionário completo com demanda
        """
        return {
            **self.to_dict(),
            'demanda_id': self.demanda_id,
            'demanda_nome': self.demanda.nome if self.demanda else None,
            'tem_trello': bool(self.trello_attachment_id),
        }
    
    def formatar_tamanho(self):
        """
        Formata tamanho em bytes para formato legível
        
        Returns:
            str: Tamanho formatado (ex: "2.5 MB")
        
        Exemplo:
            anexo.tamanho = 2500000
            anexo.formatar_tamanho()  # "2.38 MB"
        """
        tamanho = self.tamanho
        
        for unidade in ['B', 'KB', 'MB', 'GB']:
            if tamanho < 1024.0:
                return f"{tamanho:.2f} {unidade}"
            tamanho /= 1024.0
        
        return f"{tamanho:.2f} TB"
    
    def get_extensao(self):
        """
        Extrai extensão do nome do arquivo
        
        Returns:
            str: Extensão (ex: "pdf", "jpg")
        """
        if '.' in self.nome_arquivo:
            return self.nome_arquivo.rsplit('.', 1)[1].lower()
        return ''
    
    def is_imagem(self):
        """
        Verifica se o anexo é uma imagem
        
        Returns:
            bool: True se for imagem
        """
        tipos_imagem = [
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/gif',
            'image/webp',
            'image/svg+xml'
        ]
        return self.tipo_mime in tipos_imagem
    
    def is_pdf(self):
        """Verifica se o anexo é PDF"""
        return self.tipo_mime == 'application/pdf'
    
    def is_documento(self):
        """
        Verifica se o anexo é um documento
        (PDF, Word, Excel, etc)
        """
        tipos_documento = [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        ]
        return self.tipo_mime in tipos_documento
    
    def get_icone(self):
        """
        Retorna emoji/ícone baseado no tipo de arquivo
        
        Returns:
            str: Emoji representativo
        """
        if self.is_imagem():
            return "🖼️"
        elif self.is_pdf():
            return "📄"
        elif self.is_documento():
            return "📝"
        elif self.tipo_mime.startswith('video/'):
            return "🎥"
        elif self.tipo_mime.startswith('audio/'):
            return "🎵"
        else:
            return "📎"
    
    def validar_tamanho_maximo(self, max_bytes=52428800):
        """
        Valida se o tamanho está dentro do limite
        
        Args:
            max_bytes: Tamanho máximo em bytes (padrão: 50MB)
        
        Returns:
            bool: True se válido
        
        Raises:
            ValueError: Se tamanho excede o máximo
        """
        if self.tamanho > max_bytes:
            max_mb = max_bytes / 1024 / 1024
            atual_mb = self.tamanho / 1024 / 1024
            raise ValueError(
                f"Arquivo muito grande: {atual_mb:.2f}MB. "
                f"Tamanho máximo: {max_mb:.0f}MB"
            )
        return True
    
    @classmethod
    def get_por_demanda(cls, db, demanda_id):
        """
        Retorna anexos de uma demanda específica
        
        Args:
            db: Sessão do banco
            demanda_id: ID da demanda
        
        Returns:
            Query com anexos da demanda
        """
        return db.query(cls).filter(
            cls.demanda_id == demanda_id
        ).order_by(cls.created_at)
    
    @classmethod
    def get_estatisticas_por_tipo(cls, db):
        """
        Retorna estatísticas de arquivos por tipo MIME
        
        Args:
            db: Sessão do banco
        
        Returns:
            Dict com estatísticas
        """
        from sqlalchemy import func
        
        resultados = db.query(
            cls.tipo_mime,
            func.count(cls.id).label('quantidade'),
            func.sum(cls.tamanho).label('tamanho_total')
        ).group_by(cls.tipo_mime).all()
        
        stats = {}
        for tipo_mime, quantidade, tamanho_total in resultados:
            stats[tipo_mime] = {
                'quantidade': quantidade,
                'tamanho_total': tamanho_total,
                'tamanho_formatado': Anexo(
                    nome_arquivo='', 
                    caminho='', 
                    tamanho=tamanho_total or 0, 
                    tipo_mime=''
                ).formatar_tamanho()
            }
        
        return stats
    
    def foi_anexado_trello(self):
        """Verifica se foi anexado no Trello"""
        return bool(self.trello_attachment_id)


# ==================== ÍNDICES ====================
# Índices adicionais são criados automaticamente:
# - id (primary key, unique)
# - demanda_id (index + FK)

# Índice para buscar por tipo MIME
from sqlalchemy import Index
Index('ix_anexos_tipo_mime', Anexo.tipo_mime)

# ==================== VALIDAÇÕES ====================
from sqlalchemy import event

@event.listens_for(Anexo, 'before_insert')
def validar_antes_inserir(mapper, connection, target):
    """Valida tamanho antes de inserir"""
    target.validar_tamanho_maximo()

