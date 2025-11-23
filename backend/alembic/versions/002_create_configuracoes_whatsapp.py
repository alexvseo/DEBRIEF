"""create configuracoes_whatsapp table

Revision ID: 002_config_whatsapp
Revises: 001_whatsapp_users
Create Date: 2025-11-23 14:26:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '002_config_whatsapp'
down_revision: Union[str, None] = '001_whatsapp_users'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Criar tabela de configurações WhatsApp
    op.create_table('configuracoes_whatsapp',
        sa.Column('id', sa.String(length=36), nullable=False, comment='Identificador único universal (UUID v4)'),
        sa.Column('numero_remetente', sa.String(length=20), nullable=False, comment='Número WhatsApp Business remetente (formato: 5511999999999)'),
        sa.Column('instancia_wpp', sa.String(length=100), nullable=False, comment='Nome da instância WPP Connect'),
        sa.Column('ativo', sa.Boolean(), nullable=False, server_default='true', comment='Se esta configuração está ativa'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False, comment='Data e hora de criação do registro'),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False, comment='Data e hora da última atualização'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Criar índices
    op.create_index(op.f('ix_configuracoes_whatsapp_id'), 'configuracoes_whatsapp', ['id'], unique=False)
    op.create_index('ix_configuracoes_whatsapp_ativo', 'configuracoes_whatsapp', ['ativo'], unique=False)


def downgrade() -> None:
    # Remover índices
    op.drop_index('ix_configuracoes_whatsapp_ativo', table_name='configuracoes_whatsapp')
    op.drop_index(op.f('ix_configuracoes_whatsapp_id'), table_name='configuracoes_whatsapp')
    
    # Remover tabela
    op.drop_table('configuracoes_whatsapp')
