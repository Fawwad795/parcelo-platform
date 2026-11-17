"""Initial schema: parcels and parcel_events.

Revision ID: 0001
Revises:
Create Date: 2026-11-12
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "parcels",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tracking_id", sa.String(length=16), nullable=False),
        sa.Column("sender_name", sa.String(length=120), nullable=False),
        sa.Column("recipient_name", sa.String(length=120), nullable=False),
        sa.Column("origin_city", sa.String(length=80), nullable=False),
        sa.Column("destination_city", sa.String(length=80), nullable=False),
        sa.Column("weight_kg", sa.Numeric(6, 2), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_parcels_tracking_id", "parcels", ["tracking_id"], unique=True)
    op.create_index("ix_parcels_status", "parcels", ["status"], unique=False)

    op.create_table(
        "parcel_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "parcel_id",
            sa.Integer(),
            sa.ForeignKey("parcels.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("location", sa.String(length=120), nullable=False),
        sa.Column("note", sa.String(length=280), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_parcel_events_parcel_id", "parcel_events", ["parcel_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_parcel_events_parcel_id", table_name="parcel_events")
    op.drop_table("parcel_events")
    op.drop_index("ix_parcels_status", table_name="parcels")
    op.drop_index("ix_parcels_tracking_id", table_name="parcels")
    op.drop_table("parcels")
