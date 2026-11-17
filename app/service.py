"""Business rules. No HTTP here, no SQL strings: just what a parcel may do."""

import secrets

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.metrics import ILLEGAL_TRANSITIONS, PARCELS_CREATED, STATUS_TRANSITIONS
from app.models import Parcel, ParcelEvent
from app.schemas import EventCreate, ParcelCreate, ParcelStatus

# The only legal moves. Anything else is rejected with 409.
ALLOWED_TRANSITIONS: dict[ParcelStatus, set[ParcelStatus]] = {
    ParcelStatus.CREATED: {ParcelStatus.PICKED_UP, ParcelStatus.RETURNED},
    ParcelStatus.PICKED_UP: {ParcelStatus.IN_TRANSIT, ParcelStatus.RETURNED},
    ParcelStatus.IN_TRANSIT: {ParcelStatus.OUT_FOR_DELIVERY, ParcelStatus.RETURNED},
    ParcelStatus.OUT_FOR_DELIVERY: {ParcelStatus.DELIVERED, ParcelStatus.RETURNED},
    ParcelStatus.DELIVERED: set(),
    ParcelStatus.RETURNED: set(),
}

# Unambiguous characters only: no 0/O or 1/I, so a tracking id survives being
# read out over the phone.
_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"


class ParcelNotFound(Exception):
    pass


class IllegalTransition(Exception):
    def __init__(self, current: str, requested: str) -> None:
        super().__init__(f"cannot move a parcel from {current} to {requested}")
        self.current = current
        self.requested = requested


def new_tracking_id() -> str:
    return "PCL-" + "".join(secrets.choice(_ALPHABET) for _ in range(10))


def create_parcel(session: Session, data: ParcelCreate) -> Parcel:
    parcel = Parcel(
        tracking_id=new_tracking_id(),
        sender_name=data.sender_name,
        recipient_name=data.recipient_name,
        origin_city=data.origin_city,
        destination_city=data.destination_city,
        weight_kg=data.weight_kg,
        status=ParcelStatus.CREATED.value,
    )
    parcel.events.append(
        ParcelEvent(status=ParcelStatus.CREATED.value, location=data.origin_city, note="Registered")
    )
    session.add(parcel)
    session.commit()
    PARCELS_CREATED.inc()
    return parcel


def get_parcel(session: Session, tracking_id: str) -> Parcel:
    parcel = session.scalar(select(Parcel).where(Parcel.tracking_id == tracking_id))
    if parcel is None:
        raise ParcelNotFound(tracking_id)
    return parcel


def list_parcels(
    session: Session, status: ParcelStatus | None, limit: int, offset: int
) -> tuple[list[Parcel], int]:
    query = select(Parcel)
    count_query = select(func.count()).select_from(Parcel)
    if status is not None:
        query = query.where(Parcel.status == status.value)
        count_query = count_query.where(Parcel.status == status.value)
    total = session.scalar(count_query) or 0
    items = session.scalars(query.order_by(Parcel.id.desc()).limit(limit).offset(offset)).all()
    return list(items), total


def add_event(session: Session, tracking_id: str, data: EventCreate) -> Parcel:
    parcel = get_parcel(session, tracking_id)
    current = ParcelStatus(parcel.status)
    if data.status not in ALLOWED_TRANSITIONS[current]:
        ILLEGAL_TRANSITIONS.inc()
        raise IllegalTransition(current.value, data.status.value)
    parcel.status = data.status.value
    parcel.events.append(
        ParcelEvent(status=data.status.value, location=data.location, note=data.note)
    )
    session.commit()
    STATUS_TRANSITIONS.labels(to_status=data.status.value).inc()
    return parcel
