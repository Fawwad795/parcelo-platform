# Parcelo tracker: developer shortcuts.
#
# A Makefile gives every common action one name that works the same on your
# laptop and in CI. Your workflows should call these targets instead of
# repeating the commands, so "it passed locally" and "it passed in CI" mean
# the same thing.
#
# Run `make` or `make help` to list the targets. Run everything inside WSL2.

SHELL := /bin/bash
.DEFAULT_GOAL := help

VENV := .venv
PY := $(VENV)/bin/python
BASE_URL ?= http://localhost:8000

.PHONY: help
help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

# --- Python environment ---------------------------------------------------------

$(VENV)/bin/activate: requirements.txt requirements-dev.txt
	python3 -m venv $(VENV)
	$(PY) -m pip install --quiet --upgrade pip
	$(PY) -m pip install --quiet -r requirements-dev.txt
	@touch $(VENV)/bin/activate

.PHONY: setup
setup: $(VENV)/bin/activate ## Create .venv and install pinned dependencies

.PHONY: lint
lint: setup ## Lint and check formatting (what CI must enforce)
	$(PY) -m ruff check .
	$(PY) -m ruff format --check .

.PHONY: fmt
fmt: setup ## Auto-format and apply safe lint fixes
	$(PY) -m ruff format .
	$(PY) -m ruff check --fix .

.PHONY: test
test: setup ## Run unit tests with coverage (no database or Docker needed)
	$(PY) -m pytest --cov --cov-report=term --cov-report=xml

.PHONY: test-integration
test-integration: setup ## Run PostgreSQL integration tests (needs `make up` first)
	set -a && source .env && set +a && \
	TEST_DATABASE_URL="postgresql+psycopg://$$POSTGRES_USER:$$POSTGRES_PASSWORD@localhost:5432/$$POSTGRES_DB" \
	$(PY) -m pytest -m integration

.PHONY: run
run: setup ## Run the API locally with auto-reload (SQLite unless DATABASE_URL is set)
	$(PY) -m alembic upgrade head
	$(PY) -m uvicorn app.main:app --reload --port 8000

# --- Docker Compose --------------------------------------------------------------

.PHONY: up
up: ## Build the image and start the stack in the background
	docker compose up --build -d

.PHONY: down
down: ## Stop the stack (keeps the database volume)
	docker compose down

.PHONY: reset
reset: ## Stop the stack and delete the database volume
	docker compose down -v

.PHONY: logs
logs: ## Follow the API logs
	docker compose logs -f api

.PHONY: smoke
smoke: ## Smoke test a running instance (override with BASE_URL=...)
	scripts/smoke.sh $(BASE_URL)

# --- Housekeeping ----------------------------------------------------------------

.PHONY: tools
tools: ## Check that the tools needed for the current week are installed
	scripts/check-tools.sh

.PHONY: clean
clean: ## Remove caches, coverage output and the virtual environment
	rm -rf $(VENV) .pytest_cache .ruff_cache .coverage coverage.xml htmlcov parcelo.db
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
