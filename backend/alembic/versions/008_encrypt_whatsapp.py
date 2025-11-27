"""increase whatsapp column for encryption

Revision ID: 008_encrypt_whatsapp
Revises: 007_auth_hardening
Create Date: 2025-11-26 13:00:00.000000
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '008_encrypt_whatsapp'
down_revision = '007_auth_hardening'
branch_labels = None
depends_on = None


def upgrade():
    op.alter_column('users', 'whatsapp', type_=sa.String(length=512))


def downgrade():
    op.alter_column('users', 'whatsapp', type_=sa.String(length=20))

