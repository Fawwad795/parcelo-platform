"""Integration tests against a real PostgreSQL.

Skipped unless TEST_DATABASE_URL is set, for example:

    TEST_DATABASE_URL=postgresql+psycopg://parcelo:parcelo@localhost:5432/parcelo \
        pytest -m integration

SQLite and PostgreSQL differ (types, constraints, transactions). Unit tests on
SQLite are fast; these prove the app and its migrations work on the database
you actually deploy. Wiring a PostgreSQL service container into CI so this
file runs on every pull request is a SHOULD item in Week 1.

WARNING: these tests drop and recreate the schema in the target database.
Point TEST_DATABASE_URL at a throwaway database only.
"""

import os
from collections.abc import Iterator

import pytest
from alembic import command
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import Session, sessionmaker

from app.config import get_settings
from app.db import get_session
from app.main import create_app
from tests.test_migrations import alembic_config

TEST_DATABASE_URL = os.environ.get("TEST_DATABASE_URL")

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not TEST_DATABASE_URL, reason="TEST_DATABASE_URL is not set"),
]


@pytest.fixture
def pg_client() -> Iterator[TestClient]:
    assert TEST_DATABASE_URL
    config = alembic_config(TEST_DATABASE_URL)
    engine = create_engine(TEST_DATABASE_URL)
    with engine.begin() as connection:
        connection.execute(text("DROP TABLE IF EXISTS parcel_events, parcels, alembic_version"))
    command.upgrade(config, "head")

    factory = sessionmaker(bind=engine, expire_on_commit=False)

    def _session() -> Iterator[Session]:
        session = factory()
        try:
            yield session
        finally:
            session.close()

    get_settings.cache_clear()
    app = create_app()
    app.dependency_overrides[get_session] = _session
    with TestClient(app) as client:
        yield client
    engine.dispose()


def test_migrations_create_expected_tables_on_postgres(pg_client: TestClient) -> None:
    assert TEST_DATABASE_URL
    engine = create_engine(TEST_DATABASE_URL)
    tables = set(inspect(engine).get_table_names())
    engine.dispose()
    assert {"parcels", "parcel_events", "alembic_version"} <= tables


def test_readiness_and_round_trip_on_postgres(pg_client: TestClient) -> None:
    assert pg_client.get("/health/ready").status_code == 200
    created = pg_client.post(
        "/api/v1/parcels",
        json={
            "sender_name": "Integration Sender",
            "recipient_name": "Integration Recipient",
            "origin_city": "Karachi",
            "destination_city": "Peshawar",
            "weight_kg": 12.75,
        },
    )
    assert created.status_code == 201
    tracking_id = created.json()["tracking_id"]

    moved = pg_client.post(
        f"/api/v1/parcels/{tracking_id}/events",
        json={"status": "PICKED_UP", "location": "Karachi hub", "note": "collected"},
    )
    assert moved.status_code == 201

    body = pg_client.get(f"/api/v1/parcels/{tracking_id}").json()
    assert body["status"] == "PICKED_UP"
    assert body["weight_kg"] == 12.75
    assert [event["status"] for event in body["events"]] == ["CREATED", "PICKED_UP"]
