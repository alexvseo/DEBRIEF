"""
Modelo de Refresh Tokens
Armazena tokens de atualização emitidos para usuários (com rotação e revogação)
"""
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class RefreshToken(BaseModel):
    """
    Persistência de refresh tokens emitidos para usuários.
    Permite rotação segura e revogação imediata em caso de comprometimento.
    """
    __tablename__ = "refresh_tokens"
    
    user_id = Column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID do usuário dono do token"
    )
    
    token_hash = Column(
        String(128),
        nullable=False,
        unique=True,
        comment="Hash SHA-256 do refresh token"
    )
    
    jti = Column(
        String(64),
        nullable=False,
        unique=True,
        index=True,
        comment="Identificador único do token (JWT ID)"
    )
    
    expires_at = Column(
        DateTime(timezone=True),
        nullable=False,
        comment="Data de expiração do token"
    )
    
    revoked = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Indica se o token foi revogado"
    )
    
    replaced_by_token = Column(
        String(64),
        nullable=True,
        comment="JTI do token que substituiu este (rotação)"
    )
    
    user = relationship(
        "User",
        back_populates="refresh_tokens",
        lazy="joined"
    )
    
    __table_args__ = (
        Index('idx_refresh_token_user_id', 'user_id'),
    )

