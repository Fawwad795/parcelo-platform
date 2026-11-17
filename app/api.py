"""HTTP routes. Parse input, call the service layer, shape the response."""

import logging
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response, status
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from sqlalchemy import text
from sqlalchemy.orm import Session

from app import service
from app.config import Settings, get_settings
from app.db import get_session
from app.metrics import REGISTRY
from app.schemas import (
    EventCreate,
    ParcelCreate,
    ParcelDetail,
    ParcelOut,
    ParcelPage,
    ParcelStatus,
)

log = logging.getLogger("parcelo.api")

SessionDep = Annotated[Session, Depends(get_session)]
SettingsDep = Annotated[Settings, Depends(get_settings)]

# --- Operational endpoints ---------------------------------------------------
# These are the contract between this service and the platform that runs it.
# Probes, load balancers, Prometheus and your smoke tests all depend on them.
ops = APIRouter(tags=["operations"])


@ops.get("/health")
def health() -> dict[str, str]:
    """Liveness: is the process able to answer at all?

    Deliberately checks nothing else. If liveness depended on the database, a
    database outage would make Kubernetes restart every healthy app pod, which
    turns one problem into two.
    """
    return {"status": "ok"}


@ops.get("/health/ready")
def ready(session: SessionDep, settings: SettingsDep, response: Response) -> dict[str, str]:
    """Readiness: should this instance receive traffic right now?

    Checks the dependencies a request needs (here, the database). A failing
    readiness check removes the pod from the Service endpoints without
    restarting it.
    """
    if settings.chaos_fail_ready:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "not ready", "reason": "CHAOS_FAIL_READY is set"}
    try:
        session.execute(text("SELECT 1"))
    except Exception:
        log.exception("readiness check failed: database unreachable")
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "not ready", "reason": "database unreachable"}
    return {"status": "ready"}


@ops.get("/version")
def version(settings: SettingsDep) -> dict[str, str]:
    """Which build is this? Compare git_sha with the commit you deployed."""
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "git_sha": settings.git_sha,
        "environment": settings.app_env,
    }


@ops.get("/metrics", include_in_schema=False)
def metrics() -> Response:
    return Response(generate_latest(REGISTRY), media_type=CONTENT_TYPE_LATEST)


# --- Business endpoints ------------------------------------------------------
api = APIRouter(prefix="/api/v1", tags=["parcels"])


@api.post("/parcels", response_model=ParcelOut, status_code=status.HTTP_201_CREATED)
def create_parcel(data: ParcelCreate, session: SessionDep) -> ParcelOut:
    parcel = service.create_parcel(session, data)
    log.info("parcel created", extra={"tracking_id": parcel.tracking_id})
    return ParcelOut.model_validate(parcel)


@api.get("/parcels", response_model=ParcelPage)
def list_parcels(
    session: SessionDep,
    status_filter: Annotated[ParcelStatus | None, Query(alias="status")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> ParcelPage:
    items, total = service.list_parcels(session, status_filter, limit, offset)
    return ParcelPage(
        items=[ParcelOut.model_validate(p) for p in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@api.get("/parcels/{tracking_id}", response_model=ParcelDetail)
def get_parcel(tracking_id: str, session: SessionDep) -> ParcelDetail:
    return ParcelDetail.model_validate(service.get_parcel(session, tracking_id))


@api.post(
    "/parcels/{tracking_id}/events",
    response_model=ParcelDetail,
    status_code=status.HTTP_201_CREATED,
)
def add_event(tracking_id: str, data: EventCreate, session: SessionDep) -> ParcelDetail:
    parcel = service.add_event(session, tracking_id, data)
    log.info("parcel status changed", extra={"tracking_id": tracking_id})
    return ParcelDetail.model_validate(parcel)
