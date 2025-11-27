"""
Registro de tentativas de login
Ajuda a detectar abuso e aplicar bloqueios temporários
"""
from sqlalchemy import Column, String, Boolean, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class LoginAttempt(BaseModel):
    """
    Armazena cada tentativa de login (sucesso ou falha)
    """
    __tablename__ = "login_attempts"
    
    user_id = Column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
        comment="Usuário associado (se existir)"
    )
    
    username = Column(
        String(100),
        nullable=False,
        index=True,
        comment="Username/email informado na tentativa"
    )
    
    ip_address = Column(
        String(45),
        nullable=True,
        comment="IP do cliente (IPv4/IPv6)"
    )
    
    success = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Indica se a tentativa foi bem sucedida"
    )
    
    locked_out = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Se a tentativa foi bloqueada por lockout"
    )
    
    reason = Column(
        String(255),
        nullable=True,
        comment="Descrição resumida (ex: senha inválida, mfa ausente)"
    )
    
    user = relationship(
        "User",
        back_populates="login_attempts",
        lazy="joined"
    )
    
    __table_args__ = (
        Index('idx_login_attempt_username_created', 'username', 'created_at'),
    )

