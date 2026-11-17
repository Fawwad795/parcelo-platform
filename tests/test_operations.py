"""Tests for the operational contract: health, readiness, version, metrics.

Your probes, smoke tests, dashboards and alerts all rely on this behaviour, so
it is tested as carefully as the business endpoints.
"""

import json
import logging

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.db import get_session
from app.logging_config import JsonFormatter
from app.metrics import REGISTRY
from tests.conftest import ClientFactory


def sample(name: str, labels: dict[str, str] | None = None) -> float:
    return REGISTRY.get_sample_value(name, labels or {}) or 0.0


def test_health_is_ok(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ready_when_database_answers(client: TestClient) -> None:
    response = client.get("/health/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_ready_fails_when_database_is_down(client: TestClient) -> None:
    class BrokenSession:
        def execute(self, *args: object, **kwargs: object) -> None:
            raise OperationalError("SELECT 1", {}, Exception("connection refused"))

        def close(self) -> None:
            pass

    def broken() -> object:
        yield BrokenSession()

    client.app.dependency_overrides[get_session] = broken  # type: ignore[attr-defined]
    response = client.get("/health/ready")
    assert response.status_code == 503
    assert response.json()["reason"] == "database unreachable"


def test_health_stays_ok_when_database_is_down(client: TestClient) -> None:
    """Liveness must not depend on the database (see app/api.py)."""

    def broken() -> Session:
        raise AssertionError("liveness must not open a database session")

    client.app.dependency_overrides[get_session] = broken  # type: ignore[attr-defined]
    assert client.get("/health").status_code == 200


def test_chaos_fail_ready_makes_readiness_fail_but_not_liveness(make_client: ClientFactory) -> None:
    client = make_client(CHAOS_FAIL_READY="true")
    assert client.get("/health/ready").status_code == 503
    assert client.get("/health").status_code == 200


def test_chaos_crash_on_start_fails_startup(make_client: ClientFactory) -> None:
    with pytest.raises(RuntimeError, match="CHAOS_CRASH_ON_START"):
        make_client(CHAOS_CRASH_ON_START="true")


def test_chaos_error_rate_injects_500_on_api_only(make_client: ClientFactory) -> None:
    client = make_client(CHAOS_ERROR_RATE="1.0")
    response = client.get("/api/v1/parcels")
    assert response.status_code == 500
    assert response.json()["error"] == "chaos"
    # Operational endpoints are never affected, or probes would lie.
    assert client.get("/health").status_code == 200
    assert client.get("/metrics").status_code == 200


def test_version_reports_the_injected_git_sha(make_client: ClientFactory) -> None:
    client = make_client(GIT_SHA="abc1234", APP_ENV="ci")
    body = client.get("/version").json()
    assert body["git_sha"] == "abc1234"
    assert body["environment"] == "ci"
    assert body["name"] == "parcelo-tracker"


def test_metrics_endpoint_is_prometheus_text(client: TestClient) -> None:
    response = client.get("/metrics")
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    assert "http_requests_total" in response.text
    assert "app_info" in response.text


def test_request_counter_uses_route_template_not_raw_path(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    tracking_id = client.post("/api/v1/parcels", json=parcel_payload).json()["tracking_id"]
    labels = {"method": "GET", "path": "/api/v1/parcels/{tracking_id}", "status": "200"}
    before = sample("http_requests_total", labels)
    client.get(f"/api/v1/parcels/{tracking_id}")
    assert sample("http_requests_total", labels) == before + 1
    # The raw tracking id must never appear as a label value.
    assert tracking_id not in client.get("/metrics").text


def test_unmatched_routes_share_one_label(client: TestClient) -> None:
    labels = {"method": "GET", "path": "unmatched", "status": "404"}
    before = sample("http_requests_total", labels)
    client.get("/no/such/route/1")
    client.get("/no/such/route/2")
    assert sample("http_requests_total", labels) == before + 2


def test_request_id_is_echoed_or_generated(client: TestClient) -> None:
    assert client.get("/health", headers={"X-Request-ID": "req-123"}).headers["X-Request-ID"] == (
        "req-123"
    )
    generated = client.get("/health").headers["X-Request-ID"]
    assert len(generated) == 32


def test_log_lines_are_json_with_required_fields() -> None:
    record = logging.LogRecord("parcelo", logging.INFO, __file__, 1, "hello %s", ("world",), None)
    record.status = 200
    line = json.loads(JsonFormatter().format(record))
    assert line["message"] == "hello world"
    assert line["level"] == "INFO"
    assert line["status"] == 200
    assert {"timestamp", "logger", "request_id"} <= line.keys()
