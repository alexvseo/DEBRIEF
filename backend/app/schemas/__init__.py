"""
Schemas Pydantic
Exportações centralizadas
"""
from app.schemas.user import (
    UserLogin,
    UserCreate,
    UserUpdate,
    UserChangePassword,
    UserResponse,
    UserInDB,
    Token,
    TokenData,
    LoginResponse,
    TipoUsuario,
)

from app.schemas.cliente import (
    ClienteCreate,
    ClienteUpdate,
    ClienteResponse,
    ClienteResponseComplete,
)

from app.schemas.secretaria import (
    SecretariaCreate,
    SecretariaUpdate,
    SecretariaResponse,
    SecretariaResponseComplete,
)

from app.schemas.tipo_demanda import (
    TipoDemandaCreate,
    TipoDemandaUpdate,
    TipoDemandaResponse,
    TipoDemandaResponseComplete,
)

from app.schemas.prioridade import (
    PrioridadeCreate,
    PrioridadeUpdate,
    PrioridadeResponse,
    PrioridadeResponseComplete,
)

from app.schemas.demanda import (
    DemandaCreate,
    DemandaUpdate,
    DemandaFilter,
    DemandaResponse,
    DemandaDetalhada,
    DemandaListResponse,
    StatusDemanda,
    PrioridadeDemanda,
)

from app.schemas.anexo import (
    AnexoCreate,
    AnexoUpdate,
    AnexoResponse,
    AnexoResponseComplete,
)

from app.schemas.configuracao import (
    TipoConfiguracao,
    ConfiguracaoCreate,
    ConfiguracaoUpdate,
    ConfiguracaoTestarTrello,
    ConfiguracaoTestarWhatsApp,
    ConfiguracaoResponse,
    ConfiguracaoResponseSimples,
    ConfiguracaoPorTipo,
    TesteConexaoResponse,
)

__all__ = [
    # User
    "UserLogin",
    "UserCreate",
    "UserUpdate",
    "UserChangePassword",
    "UserResponse",
    "UserInDB",
    "Token",
    "TokenData",
    "LoginResponse",
    "TipoUsuario",
    # Cliente
    "ClienteCreate",
    "ClienteUpdate",
    "ClienteResponse",
    "ClienteResponseComplete",
    # Secretaria
    "SecretariaCreate",
    "SecretariaUpdate",
    "SecretariaResponse",
    "SecretariaResponseComplete",
    # Tipo Demanda
    "TipoDemandaCreate",
    "TipoDemandaUpdate",
    "TipoDemandaResponse",
    "TipoDemandaResponseComplete",
    # Prioridade
    "PrioridadeCreate",
    "PrioridadeUpdate",
    "PrioridadeResponse",
    "PrioridadeResponseComplete",
    # Demanda
    "DemandaCreate",
    "DemandaUpdate",
    "DemandaFilter",
    "DemandaResponse",
    "DemandaDetalhada",
    "DemandaListResponse",
    "StatusDemanda",
    "PrioridadeDemanda",
    # Anexo
    "AnexoCreate",
    "AnexoUpdate",
    "AnexoResponse",
    "AnexoResponseComplete",
    # Configuracao
    "TipoConfiguracao",
    "ConfiguracaoCreate",
    "ConfiguracaoUpdate",
    "ConfiguracaoTestarTrello",
    "ConfiguracaoTestarWhatsApp",
    "ConfiguracaoResponse",
    "ConfiguracaoResponseSimples",
    "ConfiguracaoPorTipo",
    "TesteConexaoResponse",
]

