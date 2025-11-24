"""
Endpoints de Demandas
CRUD completo de demandas com upload de arquivos e integração Trello/WhatsApp
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query, File, UploadFile, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import json
from datetime import datetime

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_master_user
from app.models.user import User
from app.models.demanda import Demanda, StatusDemanda
from app.models.anexo import Anexo
from app.models.cliente import Cliente
from app.models.secretaria import Secretaria
from app.models.tipo_demanda import TipoDemanda
from app.models.prioridade import Prioridade
from app.schemas.demanda import (
    DemandaCreate,
    DemandaUpdate,
    DemandaResponse,
    DemandaListResponse
)
from app.services.trello import TrelloService
from app.services.whatsapp import WhatsAppService
from app.services.upload import UploadService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("", status_code=status.HTTP_201_CREATED)
async def criar_demanda(
    # Campos do formulário
    cliente_id: str = Form(...),
    secretaria_id: str = Form(...),
    nome: str = Form(...),
    tipo_demanda_id: str = Form(...),
    prioridade_id: str = Form(...),
    descricao: str = Form(...),
    prazo_final: str = Form(...),
    usuario_id: str = Form(...),
    links_referencia: Optional[str] = Form(None),
    
    # Arquivos
    files: List[UploadFile] = File(default=[]),
    
    # Dependências
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Criar nova demanda com arquivos e integração Trello/WhatsApp
    
    Args:
        cliente_id: ID do cliente
        secretaria_id: ID da secretaria
        nome: Nome da demanda
        tipo_demanda_id: ID do tipo de demanda
        prioridade_id: ID da prioridade
        descricao: Descrição detalhada
        prazo_final: Data limite (YYYY-MM-DD)
        usuario_id: ID do usuário solicitante
        links_referencia: JSON com lista de links (opcional)
        files: Lista de arquivos anexados
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        dict: Dados da demanda criada
    """
    try:
        logger.info(f"Criando demanda: {nome}")
        
        # Validar cliente
        cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
        if not cliente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cliente {cliente_id} não encontrado"
            )
        
        # Validar secretaria
        secretaria = db.query(Secretaria).filter(Secretaria.id == secretaria_id).first()
        if not secretaria:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Secretaria {secretaria_id} não encontrada"
            )
        
        # Validar tipo de demanda
        tipo_demanda = db.query(TipoDemanda).filter(TipoDemanda.id == tipo_demanda_id).first()
        if not tipo_demanda:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Tipo de demanda {tipo_demanda_id} não encontrado"
            )
        
        # Validar prioridade
        prioridade = db.query(Prioridade).filter(Prioridade.id == prioridade_id).first()
        if not prioridade:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Prioridade {prioridade_id} não encontrada"
            )
        
        # Converter prazo_final para datetime
        try:
            prazo_datetime = datetime.strptime(prazo_final, '%Y-%m-%d').date()
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Formato de data inválido. Use YYYY-MM-DD"
            )
        
        # Criar demanda
        nova_demanda = Demanda(
            cliente_id=cliente_id,
            secretaria_id=secretaria_id,
            nome=nome,
            tipo_demanda_id=tipo_demanda_id,
            prioridade_id=prioridade_id,
            descricao=descricao,
            prazo_final=prazo_datetime,
            usuario_id=usuario_id,
            links_referencia=links_referencia,
            status=StatusDemanda.ABERTA
        )
        
        db.add(nova_demanda)
        db.flush()  # Obter ID sem commit
        
        # Salvar arquivos, se houver
        upload_service = UploadService()
        anexos_criados = []
        
        for file in files:
            if file.filename:
                try:
                    # Salvar arquivo no disco
                    caminho_relativo = await upload_service.save_file(
                        file=file,
                        cliente_id=cliente_id,
                        demanda_id=nova_demanda.id
                    )
                    
                    # Criar registro de anexo
                    anexo = Anexo(
                        demanda_id=nova_demanda.id,
                        nome_arquivo=file.filename,
                        caminho=caminho_relativo,
                        tamanho=file.size or 0,
                        tipo_mime=file.content_type or 'application/octet-stream'
                    )
                    db.add(anexo)
                    anexos_criados.append(anexo)
                    logger.info(f"Anexo salvo: {file.filename}")
                    
                except Exception as e:
                    logger.error(f"Erro ao salvar arquivo {file.filename}: {e}")
                    # Continuar mesmo se falhar um arquivo
        
        # Commit após salvar anexos
        db.commit()
        db.refresh(nova_demanda)
        
        # Criar card no Trello (async, não bloqueia)
        try:
            trello_service = TrelloService(db)
            card_info = await trello_service.criar_card(nova_demanda, db)
            
            # Atualizar demanda com URL do card
            nova_demanda.trello_card_id = card_info.get('id')
            nova_demanda.trello_card_url = card_info.get('url')
            db.commit()
            
            logger.info(f"Card criado no Trello: {card_info.get('url')}")
        except Exception as e:
            logger.error(f"Erro ao criar card no Trello: {e}")
            # Não falhar a criação da demanda se Trello falhar
        
        # Enviar notificação WhatsApp (async, não bloqueia)
        try:
            whatsapp_service = WhatsAppService()
            await whatsapp_service.enviar_nova_demanda(nova_demanda, db)
            logger.info("Notificação WhatsApp enviada")
        except Exception as e:
            logger.error(f"Erro ao enviar WhatsApp: {e}")
            # Não falhar a criação da demanda se WhatsApp falhar
        
        # Retornar demanda criada
        return {
            "id": nova_demanda.id,
            "nome": nova_demanda.nome,
            "cliente_id": nova_demanda.cliente_id,
            "secretaria_id": nova_demanda.secretaria_id,
            "tipo_demanda_id": nova_demanda.tipo_demanda_id,
            "prioridade_id": nova_demanda.prioridade_id,
            "descricao": nova_demanda.descricao,
            "prazo_final": nova_demanda.prazo_final.isoformat(),
            "status": nova_demanda.status.value,
            "trello_card_url": nova_demanda.trello_card_url,
            "anexos_count": len(anexos_criados),
            "created_at": nova_demanda.created_at.isoformat(),
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar demanda: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar demanda: {str(e)}"
        )


@router.get("", response_model=List[DemandaResponse])
async def listar_demandas(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    prioridade: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Listar demandas do usuário
    
    Args:
        skip: Número de registros para pular (paginação)
        limit: Número máximo de registros
        status: Filtrar por status (opcional)
        prioridade: Filtrar por prioridade (opcional)
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        List[DemandaResponse]: Lista de demandas
    """
    # Query base
    query = db.query(Demanda)
    
    # Se não for master, filtrar apenas demandas do usuário
    if not current_user.is_master():
        query = query.filter(Demanda.usuario_id == current_user.id)
    
    # Filtros opcionais
    if status:
        query = query.filter(Demanda.status == status)
    
    if prioridade:
        query = query.filter(Demanda.prioridade == prioridade)
    
    # Ordenar por data de criação (mais recentes primeiro)
    query = query.order_by(Demanda.created_at.desc())
    
    # Paginação
    demandas = query.offset(skip).limit(limit).all()
    
    return [DemandaResponse.from_orm(d) for d in demandas]


@router.get("/{demanda_id}", response_model=DemandaResponse)
async def obter_demanda(
    demanda_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obter detalhes de uma demanda específica
    
    Args:
        demanda_id: ID da demanda
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        DemandaResponse: Dados da demanda
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    # Verificar permissão
    if not current_user.is_master() and demanda.usuario_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para ver esta demanda"
        )
    
    return DemandaResponse.from_orm(demanda)


@router.put("/{demanda_id}", response_model=DemandaResponse)
async def atualizar_demanda(
    demanda_id: str,
    demanda_data: DemandaUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Atualizar uma demanda existente
    
    Args:
        demanda_id: ID da demanda
        demanda_data: Dados para atualizar
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        DemandaResponse: Demanda atualizada
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    # Verificar permissão
    if not current_user.is_master() and demanda.usuario_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para editar esta demanda"
        )
    
    # Atualizar campos
    for field, value in demanda_data.dict(exclude_unset=True).items():
        setattr(demanda, field, value)
    
    db.commit()
    db.refresh(demanda)
    
    return DemandaResponse.from_orm(demanda)


@router.delete("/{demanda_id}", status_code=status.HTTP_204_NO_CONTENT)
async def deletar_demanda(
    demanda_id: str,
    current_user: User = Depends(get_current_master_user),  # Apenas master pode deletar
    db: Session = Depends(get_db)
):
    """
    Deletar uma demanda
    
    Args:
        demanda_id: ID da demanda
        current_user: Usuário master autenticado
        db: Sessão do banco
    """
    demanda = db.query(Demanda).filter(Demanda.id == demanda_id).first()
    
    if not demanda:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demanda não encontrada"
        )
    
    db.delete(demanda)
    db.commit()
    
    return None
