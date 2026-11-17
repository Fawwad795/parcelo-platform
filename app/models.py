"""ORM models: database shape only."""

from datetime import UTC, datetime

from sqlalchemy import DateTime, ForeignKey, Index, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


def utcnow() -> datetime:
    return datetime.now(UTC)


class Parcel(Base):
    __tablename__ = "parcels"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tracking_id: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    sender_name: Mapped[str] = mapped_column(String(120))
    recipient_name: Mapped[str] = mapped_column(String(120))
    origin_city: Mapped[str] = mapped_column(String(80))
    destination_city: Mapped[str] = mapped_column(String(80))
    weight_kg: Mapped[float] = mapped_column(Numeric(6, 2))
    status: Mapped[str] = mapped_column(String(32), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )

    events: Mapped[list["ParcelEvent"]] = relationship(
        back_populates="parcel", order_by="ParcelEvent.id", cascade="all, delete-orphan"
    )


class ParcelEvent(Base):
    __tablename__ = "parcel_events"
    __table_args__ = (Index("ix_parcel_events_parcel_id", "parcel_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    parcel_id: Mapped[int] = mapped_column(ForeignKey("parcels.id", ondelete="CASCADE"))
    status: Mapped[str] = mapped_column(String(32))
    location: Mapped[str] = mapped_column(String(120))
    note: Mapped[str | None] = mapped_column(String(280), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    parcel: Mapped[Parcel] = relationship(back_populates="events")
