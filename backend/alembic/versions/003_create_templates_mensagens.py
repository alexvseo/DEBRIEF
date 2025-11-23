"""create templates_mensagens table

Revision ID: 003_templates_msg
Revises: 002_config_whatsapp
Create Date: 2025-11-23 14:27:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '003_templates_msg'
down_revision: Union[str, None] = '002_config_whatsapp'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Criar tabela de templates de mensagens
    op.create_table('templates_mensagens',
        sa.Column('id', sa.String(length=36), nullable=False, comment='Identificador único universal (UUID v4)'),
        sa.Column('tipo_evento', sa.String(length=50), nullable=False, comment='Tipo de evento: nova_demanda, demanda_alterada, demanda_deletada, etc'),
        sa.Column('titulo', sa.String(length=100), nullable=False, comment='Título descritivo do template'),
        sa.Column('template', sa.Text(), nullable=False, comment='Template da mensagem com variáveis: {cliente_nome}, {demanda_titulo}, etc'),
        sa.Column('ativo', sa.Boolean(), nullable=False, server_default='true', comment='Se este template está ativo'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False, comment='Data e hora de criação do registro'),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False, comment='Data e hora da última atualização'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Criar índices
    op.create_index(op.f('ix_templates_mensagens_id'), 'templates_mensagens', ['id'], unique=False)
    op.create_index('ix_templates_mensagens_tipo_evento', 'templates_mensagens', ['tipo_evento'], unique=False)
    op.create_index('ix_templates_mensagens_ativo', 'templates_mensagens', ['ativo'], unique=False)
    
    # Inserir templates padrão
    op.execute("""
        INSERT INTO templates_mensagens (id, tipo_evento, titulo, template, ativo) VALUES
        (
            'tpl-nova-demanda-001',
            'nova_demanda',
            'Nova Demanda Criada',
            '🆕 *Nova Demanda Criada*

📋 *Título*: {demanda_titulo}
🏢 *Cliente*: {cliente_nome}
⚡ *Prioridade*: {prioridade}
📅 *Data*: {demanda_data}

👤 *Responsável*: {usuario_responsavel}

_Sistema DeBrief_',
            true
        ),
        (
            'tpl-demanda-alterada-001',
            'demanda_alterada',
            'Demanda Atualizada',
            '✏️ *Demanda Atualizada*

📋 *#{demanda_numero}* - {demanda_titulo}
🏢 *Cliente*: {cliente_nome}

🔄 *Status*: {demanda_status}
⚡ *Prioridade*: {prioridade}

_Atualizado em {data_atual} às {hora_atual}_',
            true
        ),
        (
            'tpl-demanda-deletada-001',
            'demanda_deletada',
            'Demanda Removida',
            '🗑️ *Demanda Removida*

📋 *#{demanda_numero}* - {demanda_titulo}
🏢 *Cliente*: {cliente_nome}

❌ Esta demanda foi removida do sistema.

_Sistema DeBrief_',
            true
        )
    """)


def downgrade() -> None:
    # Remover índices
    op.drop_index('ix_templates_mensagens_ativo', table_name='templates_mensagens')
    op.drop_index('ix_templates_mensagens_tipo_evento', table_name='templates_mensagens')
    op.drop_index(op.f('ix_templates_mensagens_id'), table_name='templates_mensagens')
    
    # Remover tabela
    op.drop_table('templates_mensagens')
