"""Tests for the business endpoints."""

from fastapi.testclient import TestClient

from app.metrics import REGISTRY


def sample(name: str, labels: dict[str, str] | None = None) -> float:
    return REGISTRY.get_sample_value(name, labels or {}) or 0.0


def create(client: TestClient, payload: dict[str, object]) -> str:
    response = client.post("/api/v1/parcels", json=payload)
    assert response.status_code == 201
    return response.json()["tracking_id"]


def move(client: TestClient, tracking_id: str, status: str) -> int:
    return client.post(
        f"/api/v1/parcels/{tracking_id}/events",
        json={"status": status, "location": "Rawalpindi hub"},
    ).status_code


def test_create_parcel_returns_tracking_id_and_created_status(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    body = client.post("/api/v1/parcels", json=parcel_payload).json()
    assert body["tracking_id"].startswith("PCL-")
    assert len(body["tracking_id"]) == 14
    assert body["status"] == "CREATED"
    assert body["weight_kg"] == 2.5


def test_create_parcel_increments_domain_counter(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    before = sample("parcels_created_total")
    create(client, parcel_payload)
    assert sample("parcels_created_total") == before + 1


def test_create_parcel_rejects_invalid_input_with_one_error_shape(client: TestClient) -> None:
    response = client.post("/api/v1/parcels", json={"sender_name": "", "weight_kg": -1})
    assert response.status_code == 422
    body = response.json()
    assert body["error"] == "validation_error"
    assert "weight_kg" in body["detail"]
    assert set(body) == {"error", "detail", "request_id"}


def test_get_parcel_includes_its_event_history(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    tracking_id = create(client, parcel_payload)
    body = client.get(f"/api/v1/parcels/{tracking_id}").json()
    assert body["tracking_id"] == tracking_id
    assert [event["status"] for event in body["events"]] == ["CREATED"]
    assert body["events"][0]["location"] == "Islamabad"


def test_get_unknown_parcel_is_404_with_error_shape(client: TestClient) -> None:
    response = client.get("/api/v1/parcels/PCL-DOESNOTEXI")
    assert response.status_code == 404
    assert response.json()["error"] == "not_found"


def test_full_delivery_flow(client: TestClient, parcel_payload: dict[str, object]) -> None:
    tracking_id = create(client, parcel_payload)
    for status in ("PICKED_UP", "IN_TRANSIT", "OUT_FOR_DELIVERY", "DELIVERED"):
        assert move(client, tracking_id, status) == 201
    body = client.get(f"/api/v1/parcels/{tracking_id}").json()
    assert body["status"] == "DELIVERED"
    assert [event["status"] for event in body["events"]] == [
        "CREATED",
        "PICKED_UP",
        "IN_TRANSIT",
        "OUT_FOR_DELIVERY",
        "DELIVERED",
    ]


def test_illegal_transition_is_409_and_changes_nothing(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    tracking_id = create(client, parcel_payload)
    before = sample("parcel_illegal_transitions_total")
    response = client.post(
        f"/api/v1/parcels/{tracking_id}/events",
        json={"status": "DELIVERED", "location": "Lahore"},
    )
    assert response.status_code == 409
    assert response.json()["error"] == "illegal_transition"
    assert sample("parcel_illegal_transitions_total") == before + 1
    body = client.get(f"/api/v1/parcels/{tracking_id}").json()
    assert body["status"] == "CREATED"
    assert len(body["events"]) == 1


def test_delivered_parcel_cannot_move_again(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    tracking_id = create(client, parcel_payload)
    for status in ("PICKED_UP", "IN_TRANSIT", "OUT_FOR_DELIVERY", "DELIVERED"):
        move(client, tracking_id, status)
    assert move(client, tracking_id, "RETURNED") == 409


def test_parcel_can_be_returned_before_delivery(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    tracking_id = create(client, parcel_payload)
    move(client, tracking_id, "PICKED_UP")
    assert move(client, tracking_id, "RETURNED") == 201


def test_transition_counter_is_labelled_by_new_status(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    tracking_id = create(client, parcel_payload)
    labels = {"to_status": "PICKED_UP"}
    before = sample("parcel_status_transitions_total", labels)
    move(client, tracking_id, "PICKED_UP")
    assert sample("parcel_status_transitions_total", labels) == before + 1


def test_event_on_unknown_parcel_is_404(client: TestClient) -> None:
    assert move(client, "PCL-DOESNOTEXI", "PICKED_UP") == 404


def test_event_with_unknown_status_is_422(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    tracking_id = create(client, parcel_payload)
    assert move(client, tracking_id, "TELEPORTED") == 422


def test_list_is_paginated_newest_first(
    client: TestClient, parcel_payload: dict[str, object]
) -> None:
    ids = [create(client, parcel_payload) for _ in range(5)]
    page = client.get("/api/v1/parcels", params={"limit": 2, "offset": 0}).json()
    assert page["total"] == 5
    assert page["limit"] == 2
    assert [item["tracking_id"] for item in page["items"]] == [ids[4], ids[3]]
    second = client.get("/api/v1/parcels", params={"limit": 2, "offset": 2}).json()
    assert [item["tracking_id"] for item in second["items"]] == [ids[2], ids[1]]


def test_list_filters_by_status(client: TestClient, parcel_payload: dict[str, object]) -> None:
    first = create(client, parcel_payload)
    create(client, parcel_payload)
    move(client, first, "PICKED_UP")
    page = client.get("/api/v1/parcels", params={"status": "PICKED_UP"}).json()
    assert page["total"] == 1
    assert page["items"][0]["tracking_id"] == first


def test_list_limit_is_capped(client: TestClient) -> None:
    assert client.get("/api/v1/parcels", params={"limit": 1000}).status_code == 422


def test_tracking_ids_are_unique(client: TestClient, parcel_payload: dict[str, object]) -> None:
    ids = {create(client, parcel_payload) for _ in range(50)}
    assert len(ids) == 50
