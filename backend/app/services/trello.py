"""
Serviço de integração com Trello API

Este serviço gerencia a criação e atualização de cards no Trello
sempre que uma demanda é criada ou modificada no sistema.

Funcionalidades:
- Criar card no Trello ao criar demanda
- Atualizar card ao modificar demanda
- Adicionar anexos ao card
- Atribuir membros ao card
- Definir labels e due dates

Dependências:
- py-trello: Biblioteca Python para Trello API
- SQLAlchemy: Para acessar relacionamentos da demanda

Autor: DeBrief Sistema
"""
from trello import TrelloClient
from sqlalchemy.orm import Session
from typing import Dict, Optional
from app.core.config import settings
from app.models.demanda import Demanda
import logging

# Configurar logger
logger = logging.getLogger(__name__)


class TrelloService:
    """
    Wrapper para Trello API
    
    Gerencia a comunicação com o Trello para criação e
    atualização de cards baseados nas demandas do sistema.
    
    Exemplo de uso:
        ```python
        trello_service = TrelloService()
        card = await trello_service.criar_card(demanda, db)
        print(f"Card criado: {card['url']}")
        ```
    """
    
    def __init__(self):
        """
        Inicializar cliente Trello
        
        Conecta com a API do Trello usando credenciais do .env
        e carrega o board e lista configurados.
        
        Raises:
            Exception: Se credenciais inválidas ou board não encontrado
        """
        try:
            self.client = TrelloClient(
                api_key=settings.TRELLO_API_KEY,
                api_secret=settings.TRELLO_TOKEN
            )
            
            # Obter board e list
            self.board = self.client.get_board(settings.TRELLO_BOARD_ID)
            self.list = self.board.get_list(settings.TRELLO_LIST_ID)
            
            logger.info("TrelloService inicializado com sucesso")
            
        except Exception as e:
            logger.error(f"Erro ao inicializar TrelloService: {e}")
            raise
    
    async def criar_card(self, demanda: Demanda, db: Session) -> Dict:
        """
        Criar card no Trello para uma demanda
        
        Cria um novo card no Trello com todas as informações da demanda,
        incluindo descrição, prazo, anexos e atribuição de membro.
        
        Args:
            demanda: Objeto Demanda do SQLAlchemy
            db: Sessão do banco (para carregar relacionamentos)
        
        Returns:
            Dicionário com ID e URL do card criado
            Exemplo: {'id': '123abc', 'url': 'https://trello.com/c/123abc'}
        
        Raises:
            Exception: Se falhar ao criar card no Trello
        
        Exemplo:
            ```python
            trello_service = TrelloService()
            card_info = await trello_service.criar_card(demanda, db)
            demanda.trello_card_id = card_info['id']
            demanda.trello_card_url = card_info['url']
            db.commit()
            ```
        """
        try:
            # Carregar relacionamentos necessários
            db.refresh(demanda)
            
            # Construir nome do card
            card_name = f"{demanda.nome} - {demanda.cliente.nome}"
            
            # Construir descrição formatada
            card_desc = f"""
**Secretaria:** {demanda.secretaria.nome}
**Tipo:** {demanda.tipo_demanda.nome}
**Prioridade:** {demanda.prioridade.nome}
**Prazo:** {demanda.prazo_final.strftime('%d/%m/%Y')}

**Descrição:**
{demanda.descricao}

**Solicitante:** {demanda.usuario.nome_completo}
**Email:** {demanda.usuario.email}

---
**ID da Demanda:** {demanda.id}
**Status:** {demanda.status.value}
            """.strip()
            
            logger.info(f"Criando card no Trello para demanda {demanda.id}")
            
            # Criar card
            card = self.list.add_card(
                name=card_name,
                desc=card_desc,
                position='top'  # Adicionar no topo da lista
            )
            
            # Adicionar label da prioridade
            # (Assumindo que labels já existem no board)
            try:
                # Buscar label por nome
                prioridade_nome = demanda.prioridade.nome
                for label in self.board.get_labels():
                    if label.name.lower() == prioridade_nome.lower():
                        card.add_label(label)
                        logger.info(f"Label '{prioridade_nome}' adicionado ao card")
                        break
            except Exception as e:
                logger.warning(f"Não foi possível adicionar label: {e}")
            
            # Adicionar member (cliente)
            if demanda.cliente.trello_member_id:
                try:
                    card.add_member(demanda.cliente.trello_member_id)
                    logger.info(f"Membro {demanda.cliente.trello_member_id} atribuído ao card")
                except Exception as e:
                    logger.warning(f"Não foi possível adicionar membro: {e}")
            
            # Adicionar anexos
            if demanda.anexos:
                for anexo in demanda.anexos:
                    try:
                        # Construir URL pública do anexo
                        # Nota: Ajustar conforme configuração do servidor
                        anexo_url = f"{settings.FRONTEND_URL}/uploads/{anexo.caminho}"
                        card.attach(url=anexo_url, name=anexo.nome_arquivo)
                        logger.info(f"Anexo '{anexo.nome_arquivo}' adicionado ao card")
                    except Exception as e:
                        logger.warning(f"Erro ao anexar arquivo '{anexo.nome_arquivo}': {e}")
            
            # Definir due date (prazo)
            try:
                card.set_due(demanda.prazo_final)
                logger.info(f"Due date definido: {demanda.prazo_final}")
            except Exception as e:
                logger.warning(f"Erro ao definir due date: {e}")
            
            logger.info(f"Card criado com sucesso: {card.url}")
            
            return {
                'id': card.id,
                'url': card.url,
                'short_url': card.shortUrl if hasattr(card, 'shortUrl') else card.url
            }
            
        except Exception as e:
            logger.error(f"Erro ao criar card no Trello para demanda {demanda.id}: {e}")
            raise
    
    async def atualizar_card(self, demanda: Demanda, db: Session) -> bool:
        """
        Atualizar card existente no Trello
        
        Atualiza as informações do card quando a demanda é modificada,
        incluindo nome, descrição, prazo e labels.
        
        Args:
            demanda: Objeto Demanda do SQLAlchemy (com trello_card_id preenchido)
            db: Sessão do banco (para carregar relacionamentos)
        
        Returns:
            True se atualizado com sucesso, False caso contrário
        
        Raises:
            Exception: Se falhar ao atualizar card
        
        Exemplo:
            ```python
            demanda.nome = "Novo nome da demanda"
            db.commit()
            
            trello_service = TrelloService()
            await trello_service.atualizar_card(demanda, db)
            ```
        """
        if not demanda.trello_card_id:
            logger.warning(f"Demanda {demanda.id} não possui trello_card_id")
            return False
        
        try:
            logger.info(f"Atualizando card {demanda.trello_card_id} para demanda {demanda.id}")
            
            # Carregar relacionamentos
            db.refresh(demanda)
            
            # Obter card
            card = self.board.get_card(demanda.trello_card_id)
            
            # Atualizar nome
            card_name = f"{demanda.nome} - {demanda.cliente.nome}"
            card.set_name(card_name)
            logger.info(f"Nome do card atualizado: {card_name}")
            
            # Atualizar descrição
            card_desc = f"""
**Secretaria:** {demanda.secretaria.nome}
**Tipo:** {demanda.tipo_demanda.nome}
**Prioridade:** {demanda.prioridade.nome}
**Prazo:** {demanda.prazo_final.strftime('%d/%m/%Y')}
**Status:** {demanda.status.value}

**Descrição:**
{demanda.descricao}

**Solicitante:** {demanda.usuario.nome_completo}

---
**ID da Demanda:** {demanda.id}
**Última atualização:** {demanda.updated_at.strftime('%d/%m/%Y %H:%M')}
            """.strip()
            
            card.set_description(card_desc)
            logger.info("Descrição do card atualizada")
            
            # Atualizar due date
            try:
                card.set_due(demanda.prazo_final)
                logger.info(f"Due date atualizado: {demanda.prazo_final}")
            except Exception as e:
                logger.warning(f"Erro ao atualizar due date: {e}")
            
            # Mover card para lista apropriada baseado no status
            try:
                lista_destino = self._obter_lista_por_status(demanda.status.value)
                if lista_destino and lista_destino.id != card.list_id:
                    card.change_list(lista_destino.id)
                    logger.info(f"Card movido para lista '{lista_destino.name}'")
            except Exception as e:
                logger.warning(f"Erro ao mover card: {e}")
            
            logger.info(f"Card atualizado com sucesso: {card.url}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao atualizar card Trello {demanda.trello_card_id}: {e}")
            raise
    
    async def adicionar_comentario(
        self,
        demanda: Demanda,
        comentario: str,
        autor: Optional[str] = None
    ) -> bool:
        """
        Adicionar comentário ao card
        
        Args:
            demanda: Objeto Demanda
            comentario: Texto do comentário
            autor: Nome do autor (opcional)
        
        Returns:
            True se adicionado com sucesso
        """
        if not demanda.trello_card_id:
            return False
        
        try:
            card = self.board.get_card(demanda.trello_card_id)
            
            # Formatar comentário com autor
            texto_final = f"**{autor}:** {comentario}" if autor else comentario
            
            card.comment(texto_final)
            logger.info(f"Comentário adicionado ao card {demanda.trello_card_id}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao adicionar comentário: {e}")
            return False
    
    def _obter_lista_por_status(self, status: str):
        """
        Obter lista do Trello baseada no status da demanda
        
        Mapeia status internos para listas do Trello.
        Personalizar conforme organização do board.
        
        Args:
            status: Status da demanda (aberta, em_andamento, concluida, cancelada)
        
        Returns:
            Objeto List do Trello ou None
        """
        try:
            # Mapeamento de status para nomes de listas
            # Ajustar conforme seu board do Trello
            mapeamento = {
                'aberta': 'Backlog',
                'em_andamento': 'Em Andamento',
                'concluida': 'Concluído',
                'cancelada': 'Cancelado'
            }
            
            lista_nome = mapeamento.get(status)
            if not lista_nome:
                return None
            
            # Buscar lista no board
            for lista in self.board.list_lists():
                if lista.name.lower() == lista_nome.lower():
                    return lista
            
            logger.warning(f"Lista '{lista_nome}' não encontrada no board")
            return None
            
        except Exception as e:
            logger.error(f"Erro ao buscar lista por status: {e}")
            return None
    
    async def arquivar_card(self, demanda: Demanda) -> bool:
        """
        Arquivar card no Trello
        
        Usado quando demanda é cancelada ou concluída.
        
        Args:
            demanda: Objeto Demanda
        
        Returns:
            True se arquivado com sucesso
        """
        if not demanda.trello_card_id:
            return False
        
        try:
            card = self.board.get_card(demanda.trello_card_id)
            card.set_closed(True)
            logger.info(f"Card {demanda.trello_card_id} arquivado")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao arquivar card: {e}")
            return False

