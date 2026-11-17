"""The migrations and the ORM models must describe the same schema.

Tests create tables straight from the models (fast). Real deployments create
them by running Alembic migrations. If the two ever drift apart, tests pass
while production breaks. This test fails the build the moment that happens.
"""

from pathlib import Path

from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.config import Config
from alembic.migration import MigrationContext
from sqlalchemy import create_engine, inspect

from app.db import Base

ROOT = Path(__file__).resolve().parent.parent


def alembic_config(database_url: str) -> Config:
    config = Config(str(ROOT / "alembic.ini"))
    config.set_main_option("script_location", str(ROOT / "migrations"))
    config.set_main_option("sqlalchemy.url", database_url)
    return config


def test_upgrade_head_matches_models(tmp_path: Path) -> None:
    url = f"sqlite:///{tmp_path / 'migrated.db'}"
    command.upgrade(alembic_config(url), "head")

    engine = create_engine(url)
    with engine.connect() as connection:
        differences = compare_metadata(MigrationContext.configure(connection), Base.metadata)
    engine.dispose()
    assert differences == [], f"models and migrations have drifted: {differences}"


def test_downgrade_to_base_removes_everything(tmp_path: Path) -> None:
    url = f"sqlite:///{tmp_path / 'migrated.db'}"
    config = alembic_config(url)
    command.upgrade(config, "head")
    command.downgrade(config, "base")
    engine = create_engine(url)
    tables = set(inspect(engine).get_table_names())
    engine.dispose()
    assert tables == {"alembic_version"}
