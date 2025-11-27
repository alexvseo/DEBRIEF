"""hardening authentication (mfa, refresh tokens, lockout)

Revision ID: 007_auth_hardening
Revises: 006_config_trello
Create Date: 2025-11-26 12:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import func


# revision identifiers, used by Alembic.
revision = '007_auth_hardening'
down_revision = '006_config_trello'
branch_labels = None
depends_on = None


def upgrade():
    """
    - Adiciona colunas de MFA e lockout na tabela users
    - Cria tabela refresh_tokens para rotação segura
    - Cria tabela login_attempts para auditoria/bloqueio
    """
    op.add_column('users', sa.Column('mfa_secret', sa.String(length=64), nullable=True))
    op.add_column('users', sa.Column('mfa_enabled', sa.Boolean(), server_default=sa.text('false'), nullable=False))
    op.add_column('users', sa.Column('failed_login_attempts', sa.Integer(), server_default='0', nullable=False))
    op.add_column('users', sa.Column('last_failed_login_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('locked_until', sa.DateTime(timezone=True), nullable=True))
    
    op.create_table(
        'refresh_tokens',
        sa.Column('id', sa.String(length=36), primary_key=True, nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=func.now(), nullable=False),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('token_hash', sa.String(length=128), nullable=False, unique=True),
        sa.Column('jti', sa.String(length=64), nullable=False, unique=True),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('revoked', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('replaced_by_token', sa.String(length=64), nullable=True),
    )
    op.create_index('ix_refresh_tokens_user_id', 'refresh_tokens', ['user_id'])
    op.create_index('ix_refresh_tokens_jti', 'refresh_tokens', ['jti'])
    
    op.create_table(
        'login_attempts',
        sa.Column('id', sa.String(length=36), primary_key=True, nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=func.now(), nullable=False),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('username', sa.String(length=100), nullable=False),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.Column('success', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('locked_out', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('reason', sa.String(length=255), nullable=True),
    )
    op.create_index('ix_login_attempts_user_id', 'login_attempts', ['user_id'])
    op.create_index('ix_login_attempts_username', 'login_attempts', ['username'])
    op.create_index('ix_login_attempts_username_created', 'login_attempts', ['username', 'created_at'])


def downgrade():
    op.drop_index('ix_login_attempts_username_created', table_name='login_attempts')
    op.drop_index('ix_login_attempts_username', table_name='login_attempts')
    op.drop_index('ix_login_attempts_user_id', table_name='login_attempts')
    op.drop_table('login_attempts')
    
    op.drop_index('ix_refresh_tokens_jti', table_name='refresh_tokens')
    op.drop_index('ix_refresh_tokens_user_id', table_name='refresh_tokens')
    op.drop_table('refresh_tokens')
    
    op.drop_column('users', 'locked_until')
    op.drop_column('users', 'last_failed_login_at')
    op.drop_column('users', 'failed_login_attempts')
    op.drop_column('users', 'mfa_enabled')
    op.drop_column('users', 'mfa_secret')

