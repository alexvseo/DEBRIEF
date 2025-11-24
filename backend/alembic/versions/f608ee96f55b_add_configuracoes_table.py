"""add configuracoes table

Revision ID: f608ee96f55b
Revises: 4a8a7fd18270
Create Date: 2025-11-18 22:34:19.612850

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f608ee96f55b'
down_revision: Union[str, None] = '4a8a7fd18270'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Criar tabela configuracoes
    op.create_table(
        'configuracoes',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('chave', sa.String(100), nullable=False, unique=True, index=True),
        sa.Column('valor', sa.Text(), nullable=False),
        sa.Column('tipo', sa.Enum('trello', 'whatsapp', 'sistema', 'email', name='tipoconfigurac ao'), nullable=False, index=True),
        sa.Column('descricao', sa.String(500), nullable=True),
        sa.Column('is_sensivel', sa.String(10), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    
    # Criar índices
    op.create_index('idx_configuracao_tipo', 'configuracoes', ['tipo'])
    op.create_index('idx_configuracao_chave', 'configuracoes', ['chave'])


def downgrade() -> None:
    # Remover índices
    op.drop_index('idx_configuracao_chave', 'configuracoes')
    op.drop_index('idx_configuracao_tipo', 'configuracoes')
    
    # Remover tabela
    op.drop_table('configuracoes')
    
    # Remover enum (PostgreSQL específico)
    op.execute("DROP TYPE IF EXISTS tipoconfigurac ao")
