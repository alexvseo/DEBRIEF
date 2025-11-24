"""add trello fields to demandas

Revision ID: 005
Revises: 004
Create Date: 2025-11-24 01:50:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '005'
down_revision = '004'
branch_labels = None
depends_on = None


def upgrade():
    """Adicionar campos de integração com Trello na tabela demandas"""
    
    # Adicionar coluna trello_card_id
    op.add_column(
        'demandas',
        sa.Column('trello_card_id', sa.String(100), nullable=True, comment='ID do card no Trello')
    )
    
    # Adicionar coluna trello_card_url
    op.add_column(
        'demandas',
        sa.Column('trello_card_url', sa.String(500), nullable=True, comment='URL do card no Trello')
    )
    
    print("✅ Campos trello_card_id e trello_card_url adicionados à tabela demandas")


def downgrade():
    """Remover campos de integração com Trello"""
    
    op.drop_column('demandas', 'trello_card_url')
    op.drop_column('demandas', 'trello_card_id')
    
    print("✅ Campos trello_card_id e trello_card_url removidos da tabela demandas")

