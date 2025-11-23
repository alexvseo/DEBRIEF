"""create notification_logs table

Revision ID: 004_notification_logs
Revises: 003_templates_msg
Create Date: 2025-11-23 14:28:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '004_notification_logs'
down_revision: Union[str, None] = '003_templates_msg'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Criar tabela de logs de notificações
    op.create_table('notification_logs',
        sa.Column('id', sa.String(length=36), nullable=False, comment='Identificador único universal (UUID v4)'),
        sa.Column('user_id', sa.String(length=36), nullable=True, comment='ID do usuário que recebeu a notificação'),
        sa.Column('demanda_id', sa.String(length=36), nullable=True, comment='ID da demanda relacionada'),
        sa.Column('tipo_evento', sa.String(length=50), nullable=False, comment='Tipo de evento notificado'),
        sa.Column('whatsapp_destino', sa.String(length=20), nullable=False, comment='Número WhatsApp de destino'),
        sa.Column('mensagem_enviada', sa.Text(), nullable=False, comment='Conteúdo da mensagem enviada'),
        sa.Column('status', sa.String(length=20), nullable=False, comment='Status do envio: enviada, falha, pendente'),
        sa.Column('erro', sa.Text(), nullable=True, comment='Mensagem de erro caso tenha falhado'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False, comment='Data e hora de criação do registro'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['demanda_id'], ['demandas.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Criar índices para consultas eficientes
    op.create_index(op.f('ix_notification_logs_id'), 'notification_logs', ['id'], unique=False)
    op.create_index('ix_notification_logs_user_id', 'notification_logs', ['user_id'], unique=False)
    op.create_index('ix_notification_logs_demanda_id', 'notification_logs', ['demanda_id'], unique=False)
    op.create_index('ix_notification_logs_status', 'notification_logs', ['status'], unique=False)
    op.create_index('ix_notification_logs_tipo_evento', 'notification_logs', ['tipo_evento'], unique=False)
    op.create_index('ix_notification_logs_created_at', 'notification_logs', ['created_at'], unique=False)


def downgrade() -> None:
    # Remover índices
    op.drop_index('ix_notification_logs_created_at', table_name='notification_logs')
    op.drop_index('ix_notification_logs_tipo_evento', table_name='notification_logs')
    op.drop_index('ix_notification_logs_status', table_name='notification_logs')
    op.drop_index('ix_notification_logs_demanda_id', table_name='notification_logs')
    op.drop_index('ix_notification_logs_user_id', table_name='notification_logs')
    op.drop_index(op.f('ix_notification_logs_id'), table_name='notification_logs')
    
    # Remover tabela
    op.drop_table('notification_logs')
