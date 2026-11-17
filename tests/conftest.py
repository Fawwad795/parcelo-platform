"""Shared fixtures.

Unit tests run against an in-memory SQLite database, so they need no network,
no Docker and no PostgreSQL. That is what lets the first CI job be fast and
dependency-free. Tests marked `integration` use a real PostgreSQL and are
skipped unless TEST_DATABASE_URL is set (see tests/test_integration_postgres.py).
"""

from collections.abc import Callable, Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.config import get_settings
from app.db import Base, get_session
from app.main import create_app

ClientFactory = Callable[..., TestClient]


@pytest.fixture
def make_client(monkeypatch: pytest.MonkeyPatch) -> Iterator[ClientFactory]:
    """Build a TestClient with optional environment overrides.

    Usage: client = make_client(CHAOS_FAIL_READY="true")
    """
    clients: list[TestClient] = []
    engines: list[Engine] = []

    def _make(**env: str) -> TestClient:
        for key, value in env.items():
            monkeypatch.setenv(key, value)
        get_settings.cache_clear()

        # StaticPool keeps one connection, so every session sees the same
        # in-memory database.
        engine = create_engine(
            "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
        )
        engines.append(engine)
        Base.metadata.create_all(engine)
        factory = sessionmaker(bind=engine, expire_on_commit=False)

        def _session() -> Iterator[Session]:
            session = factory()
            try:
                yield session
            finally:
                session.close()

        app = create_app()
        app.dependency_overrides[get_session] = _session
        client = TestClient(app)
        client.__enter__()  # runs the lifespan startup
        clients.append(client)  # only reached when startup succeeded
        return client

    yield _make

    for client in clients:
        client.__exit__(None, None, None)
    for engine in engines:
        engine.dispose()
    get_settings.cache_clear()


@pytest.fixture
def client(make_client: ClientFactory) -> TestClient:
    return make_client()


@pytest.fixture
def parcel_payload() -> dict[str, object]:
    return {
        "sender_name": "Test Sender",
        "recipient_name": "Test Recipient",
        "origin_city": "Islamabad",
        "destination_city": "Lahore",
        "weight_kg": 2.5,
    }
