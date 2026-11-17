"""Runtime configuration.

Every setting comes from an environment variable. Nothing is read from a file
inside the image and nothing is hard-coded per environment. That is what lets
one image run unchanged on your laptop, in CI, in kind and on AWS: only the
environment around it changes (the "build once, deploy many" rule).
"""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

from app import __version__


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # --- Identity -----------------------------------------------------------
    app_name: str = "parcelo-tracker"
    app_version: str = __version__
    # Short commit SHA of the build. Your pipeline injects this at build or
    # deploy time. GET /version returns it, which is how you prove which build
    # is actually serving traffic after a deploy or a rollback.
    git_sha: str = "dev"
    # Free-form label: local, ci, kind, aws. Used in logs and /version only.
    app_env: str = "local"

    # --- Database -----------------------------------------------------------
    # SQLite needs no server, so the default lets the app start with zero
    # setup. Compose, kind and AWS override this with a PostgreSQL URL:
    #   postgresql+psycopg://USER:PASSWORD@HOST:5432/DBNAME
    database_url: str = "sqlite:///./parcelo.db"

    # --- Logging ------------------------------------------------------------
    log_level: str = "INFO"

    # --- Chaos switches (for the "prove it" drills) ---------------------------
    # These exist so you can break the service on purpose without editing
    # code. They are off by default and must never be on in a real deploy.
    #
    # Readiness always answers 503. The process stays alive, so a liveness
    # probe is happy while a readiness probe is not. Used in the failed
    # health check drill and the bad deploy drill.
    chaos_fail_ready: bool = False
    # The process exits with code 1 during startup. Produces CrashLoopBackOff.
    chaos_crash_on_start: bool = False
    # Fraction of /api requests (0.0 to 1.0) answered with HTTP 500. Used to
    # make an error-rate alert fire.
    chaos_error_rate: float = Field(default=0.0, ge=0.0, le=1.0)


@lru_cache
def get_settings() -> Settings:
    return Settings()
