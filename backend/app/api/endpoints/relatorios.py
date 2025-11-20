"""
Endpoints de Relatórios
Geração de relatórios em PDF e Excel
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import FileResponse, StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import Optional, List
from datetime import datetime, date
from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_master_user
from app.models.user import User
from app.models.demanda import Demanda, StatusDemanda
from app.models.cliente import Cliente
from app.models.secretaria import Secretaria
from app.models.tipo_demanda import TipoDemanda
from app.models.prioridade import Prioridade
import io
import json

router = APIRouter()


@router.get("/demandas/estatisticas")
async def get_demandas_estatisticas(
    cliente_id: Optional[str] = Query(None, description="Filtrar por cliente"),
    secretaria_id: Optional[str] = Query(None, description="Filtrar por secretaria"),
    tipo_demanda_id: Optional[str] = Query(None, description="Filtrar por tipo"),
    data_inicio: Optional[str] = Query(None, description="Data início (YYYY-MM-DD)"),
    data_fim: Optional[str] = Query(None, description="Data fim (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Obter estatísticas detalhadas de demandas
    
    Args:
        cliente_id: Filtrar por cliente (opcional)
        secretaria_id: Filtrar por secretaria (opcional)
        tipo_demanda_id: Filtrar por tipo (opcional)
        data_inicio: Data início (opcional)
        data_fim: Data fim (opcional)
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        dict: Estatísticas detalhadas
    """
    # Query base
    query = db.query(Demanda)
    
    # Se não for master, filtrar apenas demandas do usuário
    if not current_user.is_master():
        query = query.filter(Demanda.usuario_id == current_user.id)
    
    # Filtros opcionais
    if cliente_id:
        query = query.join(Secretaria).filter(Secretaria.cliente_id == cliente_id)
    
    if secretaria_id:
        query = query.filter(Demanda.secretaria_id == secretaria_id)
    
    if tipo_demanda_id:
        query = query.filter(Demanda.tipo_demanda_id == tipo_demanda_id)
    
    if data_inicio:
        try:
            data_ini = datetime.strptime(data_inicio, "%Y-%m-%d").date()
            query = query.filter(Demanda.created_at >= data_ini)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Formato de data_inicio inválido. Use YYYY-MM-DD"
            )
    
    if data_fim:
        try:
            data_f = datetime.strptime(data_fim, "%Y-%m-%d").date()
            query = query.filter(Demanda.created_at <= data_f)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Formato de data_fim inválido. Use YYYY-MM-DD"
            )
    
    # Estatísticas gerais
    total = query.count()
    
    # Por status
    stats_status = {}
    for status_enum in StatusDemanda:
        count = query.filter(Demanda.status == status_enum).count()
        stats_status[status_enum.value] = count
    
    # Por prioridade
    stats_prioridade = {}
    prioridades = db.query(Prioridade).all()
    for prioridade in prioridades:
        count = query.filter(Demanda.prioridade_id == prioridade.id).count()
        stats_prioridade[prioridade.nome] = count
    
    # Por tipo de demanda
    stats_tipo = {}
    tipos = db.query(TipoDemanda).all()
    for tipo in tipos:
        count = query.filter(Demanda.tipo_demanda_id == tipo.id).count()
        stats_tipo[tipo.nome] = count
    
    # Atrasadas
    hoje = date.today()
    atrasadas = query.filter(
        Demanda.prazo_final < hoje,
        Demanda.status.in_([StatusDemanda.ABERTA, StatusDemanda.EM_ANDAMENTO])
    ).count()
    
    # Por mês (últimos 12 meses)
    stats_mes = {}
    for i in range(12):
        mes_data = date.today().replace(day=1)
        # Subtrair i meses
        for _ in range(i):
            if mes_data.month == 1:
                mes_data = mes_data.replace(year=mes_data.year - 1, month=12)
            else:
                mes_data = mes_data.replace(month=mes_data.month - 1)
        
        mes_str = mes_data.strftime("%Y-%m")
        count = query.filter(
            func.date_trunc('month', Demanda.created_at) == mes_data
        ).count()
        stats_mes[mes_str] = count
    
    return {
        "total": total,
        "por_status": stats_status,
        "por_prioridade": stats_prioridade,
        "por_tipo": stats_tipo,
        "atrasadas": atrasadas,
        "por_mes": stats_mes,
        "filtros": {
            "cliente_id": cliente_id,
            "secretaria_id": secretaria_id,
            "tipo_demanda_id": tipo_demanda_id,
            "data_inicio": data_inicio,
            "data_fim": data_fim
        }
    }


@router.get("/pdf")
async def gerar_relatorio_pdf(
    cliente_id: Optional[str] = Query(None),
    secretaria_id: Optional[str] = Query(None),
    tipo_demanda_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    data_inicio: Optional[str] = Query(None),
    data_fim: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Gerar relatório em PDF
    
    Retorna um arquivo PDF com as demandas filtradas.
    Por enquanto retorna JSON (implementação futura com ReportLab).
    
    Args:
        cliente_id: Filtrar por cliente
        secretaria_id: Filtrar por secretaria
        tipo_demanda_id: Filtrar por tipo
        status: Filtrar por status
        data_inicio: Data início
        data_fim: Data fim
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        StreamingResponse: Arquivo PDF
    """
    # TODO: Implementar geração de PDF com ReportLab
    # Por enquanto, retornar JSON como placeholder
    
    query = db.query(Demanda)
    
    if not current_user.is_master():
        query = query.filter(Demanda.usuario_id == current_user.id)
    
    # Aplicar filtros
    if cliente_id:
        query = query.join(Secretaria).filter(Secretaria.cliente_id == cliente_id)
    if secretaria_id:
        query = query.filter(Demanda.secretaria_id == secretaria_id)
    if tipo_demanda_id:
        query = query.filter(Demanda.tipo_demanda_id == tipo_demanda_id)
    if status:
        query = query.filter(Demanda.status == status)
    if data_inicio:
        try:
            data_ini = datetime.strptime(data_inicio, "%Y-%m-%d").date()
            query = query.filter(Demanda.created_at >= data_ini)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Formato de data_inicio inválido"
            )
    if data_fim:
        try:
            data_f = datetime.strptime(data_fim, "%Y-%m-%d").date()
            query = query.filter(Demanda.created_at <= data_f)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Formato de data_fim inválido"
            )
    
    demandas = query.all()
    
    # Por enquanto, retornar JSON
    # TODO: Implementar geração de PDF real
    dados = {
        "total": len(demandas),
        "demandas": [d.to_dict() for d in demandas],
        "gerado_em": datetime.now().isoformat(),
        "usuario": current_user.username
    }
    
    return {
        "message": "Geração de PDF ainda não implementada. Use /api/relatorios/excel ou aguarde implementação.",
        "dados": dados
    }


@router.get("/excel")
async def gerar_relatorio_excel(
    cliente_id: Optional[str] = Query(None),
    secretaria_id: Optional[str] = Query(None),
    tipo_demanda_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    data_inicio: Optional[str] = Query(None),
    data_fim: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Gerar relatório em Excel
    
    Retorna um arquivo Excel com as demandas filtradas.
    Por enquanto retorna JSON (implementação futura com openpyxl).
    
    Args:
        cliente_id: Filtrar por cliente
        secretaria_id: Filtrar por secretaria
        tipo_demanda_id: Filtrar por tipo
        status: Filtrar por status
        data_inicio: Data início
        data_fim: Data fim
        current_user: Usuário autenticado
        db: Sessão do banco
        
    Returns:
        StreamingResponse: Arquivo Excel
    """
    # TODO: Implementar geração de Excel com openpyxl
    # Por enquanto, retornar JSON como placeholder
    
    query = db.query(Demanda)
    
    if not current_user.is_master():
        query = query.filter(Demanda.usuario_id == current_user.id)
    
    # Aplicar filtros (mesmo código do PDF)
    if cliente_id:
        query = query.join(Secretaria).filter(Secretaria.cliente_id == cliente_id)
    if secretaria_id:
        query = query.filter(Demanda.secretaria_id == secretaria_id)
    if tipo_demanda_id:
        query = query.filter(Demanda.tipo_demanda_id == tipo_demanda_id)
    if status:
        query = query.filter(Demanda.status == status)
    if data_inicio:
        try:
            data_ini = datetime.strptime(data_inicio, "%Y-%m-%d").date()
            query = query.filter(Demanda.created_at >= data_ini)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Formato de data_inicio inválido"
            )
    if data_fim:
        try:
            data_f = datetime.strptime(data_fim, "%Y-%m-%d").date()
            query = query.filter(Demanda.created_at <= data_f)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Formato de data_fim inválido"
            )
    
    demandas = query.all()
    
    # Por enquanto, retornar JSON
    # TODO: Implementar geração de Excel real
    dados = {
        "total": len(demandas),
        "demandas": [d.to_dict() for d in demandas],
        "gerado_em": datetime.now().isoformat(),
        "usuario": current_user.username
    }
    
    return {
        "message": "Geração de Excel ainda não implementada. Aguarde implementação com openpyxl.",
        "dados": dados
    }

