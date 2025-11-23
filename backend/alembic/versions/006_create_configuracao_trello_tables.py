"""create configuracao trello tables

Revision ID: 006_config_trello
Revises: 005_links_ref
Create Date: 2025-11-23 14:35:00.000000

Cria tabelas para configuração do Trello:
- configuracoes_trello: Credenciais e configuração do board/lista
- etiquetas_trello_cliente: Vinculação de etiquetas Trello a clientes
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


# revision identifiers, used by Alembic.
revision = '006_config_trello'
down_revision = '005_links_ref'
branch_labels = None
depends_on = None


def upgrade():
    """
    Cria tabelas de configuração do Trello
    """
    
    # ===== TABELA: configuracoes_trello =====
    op.create_table(
        'configuracoes_trello',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        
        # Credenciais Trello
        sa.Column('api_key', sa.String(100), nullable=False, comment='API Key do Trello'),
        sa.Column('token', sa.String(255), nullable=False, comment='Token de autenticação do Trello'),
        
        # Board e Lista
        sa.Column('board_id', sa.String(100), nullable=False, comment='ID do Board no Trello'),
        sa.Column('board_nome', sa.String(200), nullable=True, comment='Nome do Board (cache)'),
        sa.Column('lista_id', sa.String(100), nullable=False, comment='ID da Lista no Trello'),
        sa.Column('lista_nome', sa.String(200), nullable=True, comment='Nome da Lista (cache)'),
        
        # Status
        sa.Column('ativo', sa.Boolean(), nullable=False, server_default='true', comment='Se está ativo (apenas uma por vez)'),
        
        # Metadados
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.func.now(), onupdate=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
    )
    
    # Índice para buscar configuração ativa
    op.create_index('idx_config_trello_ativo', 'configuracoes_trello', ['ativo'])
    
    
    # ===== TABELA: etiquetas_trello_cliente =====
    op.create_table(
        'etiquetas_trello_cliente',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        
        # Relacionamento com cliente
        sa.Column('cliente_id', sa.String(36), nullable=False, comment='ID do cliente'),
        
        # Dados da etiqueta Trello
        sa.Column('etiqueta_trello_id', sa.String(100), nullable=False, comment='ID da label no Trello'),
        sa.Column('etiqueta_nome', sa.String(100), nullable=False, comment='Nome da etiqueta'),
        sa.Column('etiqueta_cor', sa.String(20), nullable=False, comment='Cor da etiqueta (ex: green, red)'),
        
        # Status
        sa.Column('ativo', sa.Boolean(), nullable=False, server_default='true', comment='Se está ativo'),
        
        # Metadados
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.func.now(), onupdate=sa.func.now()),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        
        # Foreign Key
        sa.ForeignKeyConstraint(['cliente_id'], ['clientes.id'], ondelete='CASCADE'),
    )
    
    # Índices
    op.create_index('idx_etiqueta_cliente', 'etiquetas_trello_cliente', ['cliente_id'])
    op.create_index('idx_etiqueta_ativo', 'etiquetas_trello_cliente', ['ativo'])


def downgrade():
    """
    Remove tabelas de configuração do Trello
    """
    op.drop_table('etiquetas_trello_cliente')
    op.drop_table('configuracoes_trello')

