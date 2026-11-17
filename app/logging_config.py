"""Structured JSON logging to stdout.

Containers should log to stdout and let the platform collect the stream. One
JSON object per line means `kubectl logs`, `docker compose logs` and any log
backend can filter by field instead of grepping prose.
"""

import json
import logging
import sys
from contextvars import ContextVar
from datetime import UTC, datetime

# Set per request by the middleware in app/main.py. Every log line written
# while handling a request carries the same id, so one request can be followed
# end to end.
request_id_var: ContextVar[str] = ContextVar("request_id", default="-")


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": datetime.now(UTC).isoformat(timespec="milliseconds"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": request_id_var.get(),
        }
        for key in ("method", "path", "status", "duration_ms", "tracking_id"):
            value = getattr(record, key, None)
            if value is not None:
                payload[key] = value
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload)


def configure_logging(level: str = "INFO") -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level.upper())
    # Uvicorn installs its own plain-text handlers. Remove them and let its
    # messages flow to the root handler, so every line this process writes is
    # JSON in one format.
    for name in ("uvicorn", "uvicorn.error"):
        server_logger = logging.getLogger(name)
        server_logger.handlers = []
        server_logger.propagate = True
    # Uvicorn's access log would duplicate the request line the middleware in
    # app/main.py already writes.
    logging.getLogger("uvicorn.access").disabled = True
