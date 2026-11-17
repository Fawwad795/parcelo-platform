"""Request and response models. ORM objects never leave the API layer."""

from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field


class ParcelStatus(StrEnum):
    CREATED = "CREATED"
    PICKED_UP = "PICKED_UP"
    IN_TRANSIT = "IN_TRANSIT"
    OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY"
    DELIVERED = "DELIVERED"
    RETURNED = "RETURNED"


class ParcelCreate(BaseModel):
    sender_name: str = Field(min_length=1, max_length=120)
    recipient_name: str = Field(min_length=1, max_length=120)
    origin_city: str = Field(min_length=1, max_length=80)
    destination_city: str = Field(min_length=1, max_length=80)
    weight_kg: float = Field(gt=0, le=1000)


class EventCreate(BaseModel):
    status: ParcelStatus
    location: str = Field(min_length=1, max_length=120)
    note: str | None = Field(default=None, max_length=280)


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    status: ParcelStatus
    location: str
    note: str | None
    created_at: datetime


class ParcelOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    tracking_id: str
    sender_name: str
    recipient_name: str
    origin_city: str
    destination_city: str
    weight_kg: float
    status: ParcelStatus
    created_at: datetime
    updated_at: datetime


class ParcelDetail(ParcelOut):
    events: list[EventOut]


class ParcelPage(BaseModel):
    items: list[ParcelOut]
    total: int
    limit: int
    offset: int


class ErrorOut(BaseModel):
    error: str
    detail: str
    request_id: str
