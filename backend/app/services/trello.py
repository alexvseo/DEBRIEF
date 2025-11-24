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
        trello_service = TrelloService(db)
        card = await trello_service.criar_card(demanda)
        print(f"Card criado: {card['url']}")
        ```
    """
    
    def __init__(self, db: Session = None):
        """
        Inicializar cliente Trello
        
        Conecta com a API do Trello usando credenciais do banco de dados
        (tabela configuracoes_trello) e carrega o board e lista configurados.
        
        Args:
            db: Sessão do banco (obrigatório para carregar configuração)
        
        Raises:
            Exception: Se credenciais inválidas, board não encontrado ou config não existe
        """
        if db is None:
            raise Exception("TrelloService requer sessão do banco (db)")
        
        try:
            # Carregar configuração ativa do banco
            from app.models.configuracao_trello import ConfiguracaoTrello
            
            config = ConfiguracaoTrello.get_ativa(db)
            
            if not config:
                raise Exception("Trello não configurado. Configure em Configurações Master.")
            
            # Inicializar cliente Trello
            self.client = TrelloClient(
                api_key=config.api_key,
                api_secret=config.token
            )
            
            # Obter board e lista
            self.board = self.client.get_board(config.board_id)
            self.list = self.board.get_list(config.lista_id)
            
            # Armazenar sessão do banco
            self.db = db
            
            logger.info(f"TrelloService inicializado - Board: {config.board_nome}, Lista: {config.lista_nome}")
            
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
            trello_service = TrelloService(db)
            card_info = await trello_service.criar_card(demanda)
            demanda.trello_card_id = card_info['id']
            demanda.trello_card_url = card_info['url']
            db.commit()
            ```
        """
        try:
            # Carregar relacionamentos necessários
            self.db.refresh(demanda)
            
            # ========== CONSTRUIR TÍTULO DO CARD ==========
            # Formato: NOME DO CLIENTE - SECRETARIA - NOME DA DEMANDA
            card_name = f"{demanda.cliente.nome} - {demanda.secretaria.nome} - {demanda.nome}"
            
            # ========== CONSTRUIR DESCRIÇÃO DO CARD ==========
            card_desc_parts = []
            
            # Nome do Cliente
            card_desc_parts.append(f"**NOME DO CLIENTE:** {demanda.cliente.nome}")
            card_desc_parts.append("")
            
            # Secretaria
            card_desc_parts.append(f"**SECRETARIA:** {demanda.secretaria.nome}")
            card_desc_parts.append("")
            
            # Tipo da Demanda
            card_desc_parts.append(f"**TIPO DA DEMANDA:** {demanda.tipo_demanda.nome}")
            card_desc_parts.append("")
            
            # Título da Demanda
            card_desc_parts.append(f"**TÍTULO DA DEMANDA:** {demanda.nome}")
            card_desc_parts.append("")
            
            # Prioridade
            card_desc_parts.append(f"**PRIORIDADE:** {demanda.prioridade.nome}")
            card_desc_parts.append("")
            
            # Prazo Final
            if demanda.prazo_final:
                card_desc_parts.append(f"**PRAZO FINAL:** {demanda.prazo_final.strftime('%d/%m/%Y')}")
            else:
                card_desc_parts.append("**PRAZO FINAL:** Não definido")
            card_desc_parts.append("")
            
            # Descrição da Demanda
            card_desc_parts.append("**DESCRIÇÃO DA DEMANDA:**")
            card_desc_parts.append(demanda.descricao)
            card_desc_parts.append("")
            
            # Links de referência (se houver)
            if demanda.links_referencia:
                import json
                try:
                    links = json.loads(demanda.links_referencia) if isinstance(demanda.links_referencia, str) else demanda.links_referencia
                    if links and len(links) > 0:
                        card_desc_parts.append("**LINKS DE REFERÊNCIA:**")
                        for link in links:
                            if isinstance(link, dict) and 'url' in link:
                                titulo = link.get('titulo', 'Link')
                                url = link.get('url', '')
                                if url:
                                    card_desc_parts.append(f"- {titulo}: {url}")
                                else:
                                    card_desc_parts.append(f"- {titulo}")
                            elif isinstance(link, str):
                                card_desc_parts.append(f"- {link}")
                        card_desc_parts.append("")
                except Exception as e:
                    logger.warning(f"Erro ao processar links de referência: {e}")
            
            # Informações complementares
            card_desc_parts.append("---")
            card_desc_parts.append(f"**Solicitante:** {demanda.usuario.nome_completo} ({demanda.usuario.email})")
            card_desc_parts.append(f"**ID da Demanda:** {demanda.id}")
            card_desc_parts.append(f"**Status:** {demanda.status.value}")
            
            # Juntar tudo
            card_desc = "\n".join(card_desc_parts)
            
            logger.info(f"Criando card no Trello para demanda {demanda.id}")
            
            # ========== CRIAR CARD ==========
            card = self.list.add_card(
                name=card_name,
                desc=card_desc,
                position='top'  # Adicionar no topo da lista
            )
            
            # ========== APLICAR ETIQUETA DO CLIENTE ==========
            from app.models.etiqueta_trello_cliente import EtiquetaTrelloCliente
            
            etiqueta_cliente = EtiquetaTrelloCliente.get_by_cliente(self.db, demanda.cliente_id)
            
            if etiqueta_cliente and etiqueta_cliente.ativo:
                try:
                    # Buscar label no board pelo ID
                    for label in self.board.get_labels():
                        if label.id == etiqueta_cliente.etiqueta_trello_id:
                            card.add_label(label)
                            logger.info(f"Etiqueta '{etiqueta_cliente.etiqueta_nome}' aplicada ao card")
                            break
                except Exception as e:
                    logger.warning(f"Erro ao aplicar etiqueta do cliente: {e}")
            else:
                logger.warning(f"Cliente {demanda.cliente.nome} sem etiqueta configurada")
            
            # ========== LABEL DE PRIORIDADE (OPCIONAL) ==========
            try:
                prioridade_nome = demanda.prioridade.nome
                for label in self.board.get_labels():
                    if label.name and label.name.lower() == prioridade_nome.lower():
                        card.add_label(label)
                        logger.info(f"Label '{prioridade_nome}' adicionado ao card")
                        break
            except Exception as e:
                logger.warning(f"Não foi possível adicionar label de prioridade: {e}")
            
            # ========== MEMBER (CLIENTE - OPCIONAL) ==========
            if demanda.cliente.trello_member_id:
                try:
                    card.add_member(demanda.cliente.trello_member_id)
                    logger.info(f"Membro {demanda.cliente.trello_member_id} atribuído ao card")
                except Exception as e:
                    logger.warning(f"Não foi possível adicionar membro: {e}")
            
            # ========== ANEXAR IMAGENS ==========
            if demanda.anexos:
                for anexo in demanda.anexos:
                    try:
                        # Construir URL pública do anexo
                        anexo_url = f"{settings.FRONTEND_URL}/uploads/{anexo.caminho}"
                        card.attach(url=anexo_url, name=anexo.nome_arquivo)
                        logger.info(f"Anexo '{anexo.nome_arquivo}' adicionado ao card")
                    except Exception as e:
                        logger.warning(f"Erro ao anexar arquivo '{anexo.nome_arquivo}': {e}")
            
            # ========== DEFINIR DUE DATE (PRAZO) ==========
            if demanda.prazo_final:
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

