"""Application factory, middleware and error handling."""

import logging
import random
import time
import uuid
from collections.abc import AsyncIterator, Awaitable, Callable
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api import api, ops
from app.config import get_settings
from app.logging_config import configure_logging, request_id_var
from app.metrics import APP_INFO, HTTP_DURATION, HTTP_REQUESTS
from app.service import IllegalTransition, ParcelNotFound

log = logging.getLogger("parcelo")


def _error(status_code: int, error: str, detail: str) -> JSONResponse:
    """One error shape for every failure, so clients parse a single format."""
    return JSONResponse(
        status_code=status_code,
        content={"error": error, "detail": detail, "request_id": request_id_var.get()},
    )


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    if settings.chaos_crash_on_start:
        # An exception during startup makes the server log "Application
        # startup failed" and exit with a non-zero code, which is exactly what
        # a broken release looks like to Docker and Kubernetes.
        log.error("CHAOS_CRASH_ON_START is set: refusing to start")
        raise RuntimeError("CHAOS_CRASH_ON_START is set")
    APP_INFO.labels(
        version=settings.app_version, git_sha=settings.git_sha, environment=settings.app_env
    ).set(1)
    log.info(
        "startup complete: %s %s (%s)", settings.app_name, settings.app_version, settings.git_sha
    )
    yield
    # Reached on SIGTERM when the server shuts down gracefully. If this line
    # never appears in your pod logs during a rollout, the process is not
    # receiving the signal (see the Dockerfile task in Week 1).
    log.info("shutdown complete")


def create_app() -> FastAPI:
    settings = get_settings()
    # Configured here (at import time) rather than in the lifespan so that the
    # server's own startup lines are already JSON.
    configure_logging(settings.log_level)
    app = FastAPI(title="Parcelo Tracker API", version=settings.app_version, lifespan=lifespan)

    @app.middleware("http")
    async def observe(
        request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
        token = request_id_var.set(request_id)
        started = time.perf_counter()
        status_code = 500
        try:
            if (
                settings.chaos_error_rate > 0
                and request.url.path.startswith("/api/")
                and random.random() < settings.chaos_error_rate
            ):
                response: Response = _error(500, "chaos", "CHAOS_ERROR_RATE injected this failure")
            else:
                response = await call_next(request)
            status_code = response.status_code
            response.headers["X-Request-ID"] = request_id
            return response
        finally:
            duration = time.perf_counter() - started
            # The route TEMPLATE, not the raw URL (see app/metrics.py).
            route = request.scope.get("route")
            path = getattr(route, "path", "unmatched")
            HTTP_REQUESTS.labels(request.method, path, str(status_code)).inc()
            HTTP_DURATION.labels(request.method, path).observe(duration)
            # Probe and scrape traffic would bury real requests in the logs.
            if path not in ("/health", "/health/ready", "/metrics"):
                log.info(
                    "request handled",
                    extra={
                        "method": request.method,
                        "path": path,
                        "status": status_code,
                        "duration_ms": round(duration * 1000, 2),
                    },
                )
            request_id_var.reset(token)

    @app.exception_handler(ParcelNotFound)
    async def not_found(request: Request, exc: ParcelNotFound) -> JSONResponse:
        return _error(404, "not_found", f"no parcel with tracking id {exc}")

    @app.exception_handler(IllegalTransition)
    async def illegal_transition(request: Request, exc: IllegalTransition) -> JSONResponse:
        return _error(409, "illegal_transition", str(exc))

    @app.exception_handler(RequestValidationError)
    async def validation(request: Request, exc: RequestValidationError) -> JSONResponse:
        problems = "; ".join(
            f"{'.'.join(str(part) for part in err['loc'])}: {err['msg']}" for err in exc.errors()
        )
        return _error(422, "validation_error", problems)

    @app.exception_handler(StarletteHTTPException)
    async def http_error(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        return _error(exc.status_code, "http_error", str(exc.detail))

    @app.exception_handler(Exception)
    async def unhandled(request: Request, exc: Exception) -> JSONResponse:
        # Log the stack trace for operators. Never send it to the client.
        log.exception("unhandled error")
        return _error(500, "internal_error", "an unexpected error occurred")

    app.include_router(ops)
    app.include_router(api)
    return app


app = create_app()
