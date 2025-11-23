"""merge heads

Revision ID: 33124e02e8cc
Revises: 004_notification_logs, f608ee96f55b
Create Date: 2025-11-23 18:19:34.998763

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '33124e02e8cc'
down_revision: Union[str, None] = ('004_notification_logs', 'f608ee96f55b')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
