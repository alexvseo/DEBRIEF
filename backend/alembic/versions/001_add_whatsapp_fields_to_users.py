"""add whatsapp fields to users

Revision ID: 001_whatsapp_users
Revises: fa226c960aba
Create Date: 2025-11-23 14:25:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '001_whatsapp_users'
down_revision: Union[str, None] = 'fa226c960aba'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Adicionar campos WhatsApp na tabela users
    op.add_column('users', sa.Column('whatsapp', sa.String(length=20), nullable=True, comment='Número WhatsApp do usuário para notificações (formato: 5511999999999)'))
    op.add_column('users', sa.Column('receber_notificacoes', sa.Boolean(), nullable=False, server_default='true', comment='Se o usuário deseja receber notificações WhatsApp'))
    
    # Criar índice para facilitar buscas por usuários que recebem notificações
    op.create_index('ix_users_receber_notificacoes', 'users', ['receber_notificacoes'], unique=False)


def downgrade() -> None:
    # Remover índice
    op.drop_index('ix_users_receber_notificacoes', table_name='users')
    
    # Remover colunas
    op.drop_column('users', 'receber_notificacoes')
    op.drop_column('users', 'whatsapp')
