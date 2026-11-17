"""Prometheus metrics.

Two families:

* HTTP metrics (count and latency per route). These give you the RED view of
  the service: Rate, Errors, Duration. Your Week 4 dashboard and alert are
  built on them.
* Domain metrics (parcels created, status transitions). These answer business
  questions that HTTP metrics cannot.

Label rule: labels must have few possible values. The path label is the route
TEMPLATE (/api/v1/parcels/{tracking_id}), never the raw URL, otherwise every
tracking id would create a new time series and Prometheus would drown.
"""

from prometheus_client import CollectorRegistry, Counter, Gauge, Histogram

# A dedicated registry (instead of the global default) keeps tests isolated
# and makes it explicit which metrics this service exposes.
REGISTRY = CollectorRegistry()

HTTP_REQUESTS = Counter(
    "http_requests_total",
    "HTTP requests handled, by method, route template and status code.",
    ["method", "path", "status"],
    registry=REGISTRY,
)

HTTP_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds, by method and route template.",
    ["method", "path"],
    # Buckets sized for a small JSON API: most requests are a few ms.
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
    registry=REGISTRY,
)

PARCELS_CREATED = Counter(
    "parcels_created_total",
    "Parcels registered.",
    registry=REGISTRY,
)

STATUS_TRANSITIONS = Counter(
    "parcel_status_transitions_total",
    "Parcel status changes, by new status.",
    ["to_status"],
    registry=REGISTRY,
)

ILLEGAL_TRANSITIONS = Counter(
    "parcel_illegal_transitions_total",
    "Status changes rejected because the transition is not allowed.",
    registry=REGISTRY,
)

# Value is always 1. The labels carry the information, so a dashboard can show
# which build each pod is running and you can watch a rollout move across pods.
APP_INFO = Gauge(
    "app_info",
    "Build information for the running process.",
    ["version", "git_sha", "environment"],
    registry=REGISTRY,
)
