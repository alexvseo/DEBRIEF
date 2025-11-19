"""
API Endpoints
Importa e exporta todos os routers
"""
from app.api.endpoints import auth
from app.api.endpoints import demandas
from app.api.endpoints import clientes
from app.api.endpoints import secretarias
from app.api.endpoints import tipos_demanda
from app.api.endpoints import prioridades
from app.api.endpoints import configuracoes
from app.api.endpoints import usuarios

__all__ = [
    'auth',
    'demandas',
    'clientes',
    'secretarias',
    'tipos_demanda',
    'prioridades',
    'configuracoes',
    'usuarios',
]
