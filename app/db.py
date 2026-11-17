"""Database engine and session handling."""

from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import get_settings


class Base(DeclarativeBase):
    pass


def make_engine(database_url: str) -> Engine:
    if database_url.startswith("sqlite"):
        # SQLite connections are bound to the thread that created them unless
        # told otherwise. FastAPI runs sync endpoints in a thread pool.
        return create_engine(database_url, connect_args={"check_same_thread": False})
    # pool_pre_ping tests a pooled connection before using it. Without it, the
    # first request after the database restarts fails with a stale connection.
    # You will see this matter when you kill the Postgres pod in Week 2.
    return create_engine(database_url, pool_pre_ping=True)


_engine: Engine | None = None
_session_factory: sessionmaker[Session] | None = None


def get_engine() -> Engine:
    global _engine, _session_factory
    if _engine is None:
        _engine = make_engine(get_settings().database_url)
        _session_factory = sessionmaker(bind=_engine, expire_on_commit=False)
    return _engine


def get_session() -> Iterator[Session]:
    """FastAPI dependency: one session per request, always closed."""
    get_engine()
    assert _session_factory is not None
    session = _session_factory()
    try:
        yield session
    finally:
        session.close()
