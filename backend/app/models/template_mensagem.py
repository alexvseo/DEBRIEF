"""
Modelo de Template de Mensagem WhatsApp
Armazena templates personalizáveis de mensagens
"""
from sqlalchemy import Column, String, Text, Boolean
from app.models.base import BaseModel


class TemplateMensagem(BaseModel):
    """
    Templates de mensagens WhatsApp personalizáveis
    
    Permite criar mensagens padronizadas com variáveis dinâmicas
    que serão substituídas pelos dados reais da demanda/usuário.
    
    Atributos:
        nome: Nome identificador do template
        tipo_evento: Tipo de evento (demanda_criada, demanda_atualizada, etc)
        mensagem: Texto da mensagem com variáveis {nome_variavel}
        variaveis_disponiveis: JSON com lista de variáveis disponíveis
        ativo: Se o template está ativo
    
    Variáveis disponíveis:
        {demanda_titulo}, {demanda_descricao}, {cliente_nome},
        {secretaria_nome}, {tipo_demanda}, {prioridade},
        {prazo_final}, {usuario_responsavel}, {usuario_nome},
        {data_criacao}, {trello_card_url}
    
    Exemplo:
        ```python
        template = TemplateMensagem(
            nome="Nova Demanda",
            tipo_evento="demanda_criada",
            mensagem='''
🔔 *Nova Demanda Recebida!*

📋 *Demanda:* {demanda_titulo}
🏢 *Secretaria:* {secretaria_nome}
⚡ *Prioridade:* {prioridade}
📅 *Prazo:* {prazo_final}

👤 *Solicitante:* {usuario_nome}

🔗 Ver no Trello: {trello_card_url}
            ''',
            ativo=True
        )
        ```
    """
    
    __tablename__ = "templates_mensagens"
    
    # Nome identificador do template
    nome = Column(
        String(100),
        nullable=False,
        unique=True,
        comment="Nome identificador do template"
    )
    
    # Tipo de evento que dispara este template
    tipo_evento = Column(
        String(50),
        nullable=False,
        comment="Tipo de evento (demanda_criada, demanda_atualizada, etc)"
    )
    
    # Mensagem do template com variáveis
    mensagem = Column(
        Text,
        nullable=False,
        comment="Texto da mensagem com variáveis {nome_variavel}"
    )
    
    # JSON com variáveis disponíveis (para documentação/UI)
    variaveis_disponiveis = Column(
        Text,
        nullable=True,
        comment="JSON com lista de variáveis disponíveis"
    )
    
    # Flag para indicar se está ativo
    ativo = Column(
        Boolean,
        nullable=False,
        default=True,
        comment="Se o template está ativo"
    )
    
    def __repr__(self):
        return f"<TemplateMensagem(nome={self.nome}, tipo={self.tipo_evento}, ativo={self.ativo})>"
    
    @classmethod
    def get_by_tipo_evento(cls, db, tipo_evento: str):
        """
        Busca template ativo por tipo de evento
        
        Args:
            db: Sessão do banco
            tipo_evento: Tipo do evento
            
        Returns:
            TemplateMensagem ou None
        """
        return db.query(cls).filter(
            cls.tipo_evento == tipo_evento,
            cls.ativo == True,
            cls.deleted_at == None
        ).first()
    
    @classmethod
    def get_variaveis_padrao(cls):
        """
        Retorna lista de variáveis padrão disponíveis
        
        Returns:
            dict com variáveis e descrições
        """
        return {
            "demanda_titulo": "Título da demanda",
            "demanda_descricao": "Descrição completa da demanda",
            "cliente_nome": "Nome do cliente",
            "secretaria_nome": "Nome da secretaria",
            "tipo_demanda": "Tipo da demanda (Design, Desenvolvimento, etc)",
            "prioridade": "Nível de prioridade",
            "prazo_final": "Data de prazo final",
            "usuario_responsavel": "Nome do usuário responsável",
            "usuario_nome": "Nome do usuário que criou",
            "usuario_email": "Email do usuário",
            "data_criacao": "Data de criação da demanda",
            "data_atualizacao": "Data da última atualização",
            "status": "Status atual da demanda",
            "trello_card_url": "URL do card no Trello",
            "url_sistema": "URL da demanda no sistema DeBrief"
        }
    
    def renderizar(self, dados: dict) -> str:
        """
        Renderiza o template substituindo variáveis pelos valores
        
        Args:
            dados: Dicionário com valores para substituir
            
        Returns:
            Mensagem renderizada
        """
        mensagem = self.mensagem
        
        # Substituir cada variável pelos valores fornecidos
        for chave, valor in dados.items():
            placeholder = "{" + chave + "}"
            if placeholder in mensagem:
                # Converter None para string vazia
                valor_str = str(valor) if valor is not None else ""
                mensagem = mensagem.replace(placeholder, valor_str)
        
        return mensagem

