"""add links_referencia to demandas

Revision ID: 005_links_ref
Revises: 33124e02e8cc
Create Date: 2025-11-23 14:30:00.000000

Adiciona campo links_referencia na tabela demandas
para permitir que usuários incluam links de referência
nas demandas (ex: links de documentos, sites, etc)
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '005_links_ref'
down_revision = '33124e02e8cc'
branch_labels = None
depends_on = None


def upgrade():
    """
    Adiciona coluna links_referencia na tabela demandas
    """
    # Adicionar coluna links_referencia (JSON para armazenar array de links)
    op.add_column(
        'demandas',
        sa.Column(
            'links_referencia',
            sa.Text(),
            nullable=True,
            comment='Links de referência da demanda (JSON array)'
        )
    )


def downgrade():
    """
    Remove coluna links_referencia da tabela demandas
    """
    op.drop_column('demandas', 'links_referencia')

