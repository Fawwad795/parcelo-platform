# Verified Versions and What Was Actually Checked

**Checked on:** 2026-11-12. Everything here goes stale. Re-check before you pin (section 6 shows how).

This file exists because most DevOps tutorials on the internet are one or two major versions behind, and an AI assistant will happily hand you a version number from its training data. When a guide, a blog post or an AI answer disagrees with this file, trust neither: look the version up yourself.

## 1. How to read this file

Three levels of confidence are used, and they are not the same thing:

| Label | Meaning |
| --- | --- |
| **Ran** | I executed it in a sandbox and saw it pass. |
| **Resolved** | I looked the version or commit up at its source on the date above (`git ls-remote` against the real repository, PyPI, or the official documentation page). The thing exists. I did not run it. |
| **Not run** | I could not execute it at all. You are the first person to run it. |

Section 7 lists exactly what falls in each bucket. Read it before Week 1.

## 2. GitHub Actions, pinned by commit SHA

Pin every third-party action to a full commit SHA and keep the tag as a comment. A tag is a movable label that the owner of the action (or an attacker who steals their credentials) can point at different code tomorrow; a SHA cannot change.

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

This is not theoretical. In March 2026 the release tags of `aquasecurity/trivy-action` were repointed at malicious code for several hours (see the research report, section 3.2). Workflows that pinned a SHA were not affected.

All SHAs below were **resolved** with `git ls-remote` on 2026-11-12. None of these actions was executed by me.

| Action | Tag | Commit SHA | Used in |
| --- | --- | --- | --- |
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` | every workflow |
| `actions/setup-python` | v7.1.0 | `6d4fd22b20465ccc0f7354476588e8df7c9ca0e0` | Week 1 |
| `actions/upload-artifact` | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` | Week 1 |
| `actions/cache` | v6.1.0 | `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` | Week 1 (only if you cache by hand) |
| `docker/setup-buildx-action` | v4.4.1 | `f87e5991a6d7451dcb8d9637bfbc97413f497069` | Week 1 |
| `docker/login-action` | v4.8.0 | `8aa5831fb8d48d8f76594c7ddde61ae58019f550` | Week 1 |
| `docker/metadata-action` | v6.2.0 | `dc802804100637a589fabce1cb79ff13a1411302` | Week 1 |
| `docker/build-push-action` | v7.4.0 | `c3c9e263c25d99ce0380d002d59b67737d91b0dc` | Week 1 |
| `hadolint/hadolint-action` | v3.5.0 | `06be81baf89a55ffd0e24b8f04a4185738dd3387` | Week 1 |
| `aquasecurity/trivy-action` | v0.36.0 | `ed142fd0673e97e23eac54620cfb913e5ce36c25` | Week 1, Week 3 |
| `aquasecurity/setup-trivy` | v0.3.1 | `81e514348e19b6112ce2a7e3ecbafe19c1e1f567` | optional |
| `gitleaks/gitleaks-action` | v3.0.0 | `e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e` | Week 1 |
| `anchore/sbom-action` | v0.24.3 | `66cbf4bc1f1c0d2edc94016e65bc221b6bb0ad6c` | Week 1 (SHOULD) |
| `zizmorcore/zizmor-action` | v0.8.1 | `45d7276c9ca790aabd705e31ca99c6185c3e76dd` | Week 1 (SHOULD) |
| `actions/dependency-review-action` | v5.0.0 | `a1d282b36b6f3519aa1f3fc636f609c47dddb294` | Week 1 (STRETCH) |
| `azure/setup-helm` | v5.1.0 | `2f5e7bc67f1f9972ab16657bb795f36d8f04de0e` | Week 2, Week 4 |
| `helm/kind-action` | v1.15.2 | `ea822c7bf1874f08e5a491df991c228edffc3376` | Week 2 |
| `aws-actions/configure-aws-credentials` | v6.3.0 | `e1253824e5c10ff9df46874f81ed3ec929e19cfd` | Week 3, Week 4 |
| `hashicorp/setup-terraform` | v4.0.1 | `dfe3c3f87815947d99a8997f908cb6525fc44e9e` | Week 3 |
| `terraform-linters/setup-tflint` | v6.3.2 | `6ffdbaa3be476b3431f7275c26966ef32ff60337` | Week 3 (SHOULD) |
| `actions/attest-build-provenance` | v4.2.2 | `4d101475d8b20a2381f78447822ac1eab6504dd8` | Week 5 (SHOULD) |
| `sigstore/cosign-installer` | v4.1.3 | `756fe2d284c7292c4e9b62c8a28f1e5629c59532` | Week 5 (STRETCH) |

Notes that save time:

- `gitleaks/gitleaks-action` needs no licence key on a personal account (its README says the key is required for organisations only). It needs `fetch-depth: 0` on checkout to scan history.
- `docker/metadata-action` lowercases the image name for you. Nothing else does. See the uppercase-owner trap in the execution guidelines, Week 1.
- `aquasecurity/trivy-action` caches the vulnerability database by default. Leave that on; the README recommends it to avoid registry rate limits.

## 3. Tools

**Resolved** on 2026-11-12 as the newest release of each project. Newer patch releases are normally fine. A newer **major** version is a decision, not an accident.

| Tool | Version | Where it runs | First needed |
| --- | --- | --- | --- |
| Docker Compose | v5.x | laptop | Day 1 |
| Python | 3.13 in the container and CI; 3.12 or 3.13 on the laptop | all | Day 1 |
| GitHub CLI (`gh`) | 2.x | laptop | Day 1 |
| AWS CLI | 2.40.1 (must be 2.32.0 or newer for `aws login`) | laptop | Week 1 |
| Trivy | v0.76.2 | CI (and laptop, optional) | Week 1 |
| gitleaks | v8.30.1 | CI and pre-commit | Week 1 |
| hadolint | v2.15.1 | CI | Week 1 |
| actionlint | v1.7.12 | laptop, CI (SHOULD) | Week 1 |
| zizmor | 1.32.0 | laptop, CI (SHOULD) | Week 1 |
| syft | v1.57.1 | CI (SHOULD) | Week 1 |
| kind | v0.33.0 | laptop, CI | Week 2 |
| Kubernetes | v1.37.x (kind node image v1.37.0) | laptop, CI | Week 2 |
| kubectl | v1.37.x | laptop | Week 2 |
| Helm | v4.3.1 | laptop, CI, the EC2 instance | Week 2 |
| kubeconform | v0.8.0 | CI | Week 2 |
| Terraform | v1.17.2 (must be 1.15.0 or newer) | laptop, CI | Week 3 |
| Terraform AWS provider | v6.73.0 (must be 6.23.0 or newer) | laptop, CI | Week 3 |
| tflint | v0.66.0 | CI (SHOULD) | Week 3 |
| k3s | v1.37.2+k3s1 | the EC2 instance | Week 3 |
| Session Manager plugin | current | laptop | Week 3 |
| kube-prometheus-stack chart | 93.2.2 | kind | Week 4 |
| Prometheus | v3.16.0 (bundled by the chart) | kind | Week 4 |
| Argo CD | v3.6.1 | kind (SHOULD) | Week 4 |
| Gateway API | v1.7.0 | k3s (STRETCH) | Week 4 |
| cosign | v3.1.4 | CI (STRETCH) | Week 5 |

Small discrepancy, recorded so it does not confuse you: the `hashicorp/terraform` repository had a `v1.17.2` tag on 2026-11-12, while the official install page still showed 1.17.1 that day. Either is fine. The floor that matters is 1.15.0.

The kind node image is pinned by digest in `starter-kit/kind/kind-config.yaml`:

```text
kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5
```

That digest was copied from the kind v0.33.0 release documentation. I could not pull the image to confirm it (container registries are blocked in my sandbox). If `kind create cluster` reports a digest mismatch, take the digest from the kind release notes for the version you installed.

## 4. Application dependencies

**Ran**: installed from the pinned files into clean virtual environments on Python 3.12.3 and 3.13, `pip check` clean, tests green.

| File | Package | Version |
| --- | --- | --- |
| `requirements.txt` | fastapi | 0.162.4 |
| | uvicorn[standard] | 0.54.0 |
| | sqlalchemy | 2.1.8 |
| | psycopg[binary] | 3.3.8 |
| | alembic | 1.20.1 |
| | pydantic-settings | 2.16.2 |
| | prometheus-client | 0.26.0 |
| `requirements-dev.txt` | pytest | 9.2.0 |
| | pytest-cov | 7.1.0 |
| | httpx2 | 2.16.0 |
| | ruff | 0.17.4 |

`httpx2`, not `httpx`: Starlette 1.x deprecates plain `httpx` for its test client and asks for `httpx2`. If a tutorial tells you to `pip install httpx` for FastAPI tests, it predates that change.

Container images referenced by the kit:

| Image | Why this tag |
| --- | --- |
| `postgres:17-alpine` | PostgreSQL 18 images moved the data directory, which breaks the `/var/lib/postgresql/data` mount every older tutorial uses. 17 keeps the well-known path. Upgrading to 18 is a STRETCH exercise. |
| `python:3.13` (in the starting `Dockerfile`) | Deliberately bad. Choosing a slim base and pinning it by digest is part of task 1.6. |

## 5. What is on the GitHub runner, and what is not

You will use `runs-on: ubuntu-24.04`, never `ubuntu-latest`. GitHub is moving the `ubuntu-latest` label to Ubuntu 26.04 between 19 October and 19 November 2026, so a workflow that says `ubuntu-latest` changes operating system underneath you in the middle of this project.

Contents of the `ubuntu-24.04` image (version 20261101.360.1), read from the runner-images repository on 2026-11-12:

| Tool | On the image | What that means for you |
| --- | --- | --- |
| Docker | 28.0.4, Buildx 0.38.1 | Ready to use |
| Python | 3.12.3 | Not 3.13. Use `actions/setup-python` |
| kind | 0.33.0 | Present; `helm/kind-action` still gives you a pinned version |
| kubectl | 1.37.2 | Ready to use |
| **Helm** | **3.22.1** | **Not Helm 4.** `--rollback-on-failure` does not exist in Helm 3. Install Helm 4 with `azure/setup-helm` |
| **Terraform** | **absent** | Install with `hashicorp/setup-terraform` |
| AWS CLI | 2.39.3, with the Session Manager plugin | Ready to use |
| GitHub CLI | 2.103.3 | Ready to use |
| jq, curl, git | present | Ready to use |

The two bold rows are the ones that produce confusing failures: a Helm flag that "does not exist", and `terraform: command not found`.

## 6. How to re-check a version yourself

Do this whenever you pin something, and once more in Week 5.

```bash
# Newest tags of an action, newest last
git ls-remote --tags --sort=v:refname https://github.com/actions/checkout 'v7*' | tail -n 4

# The commit a tag points at. For annotated tags, use the line ending in ^{}
git ls-remote https://github.com/actions/checkout 'refs/tags/v7.0.1*'

# Newest release of a tool
gh release view --repo hashicorp/terraform --json tagName,publishedAt

# Newest version of a Python package
python3 -m pip index versions fastapi 2>/dev/null | head -n 1
```

Once Dependabot is configured (task 1.9) it opens pull requests that move the SHA and update the version comment for you. Your job becomes reading the release notes before you merge, which is the point.

## 7. Verification ledger

### Ran, and passed

| What | How |
| --- | --- |
| Sample app unit tests | 31 passed, 2 skipped (the PostgreSQL tests skip without a database), on Python 3.12.3 and 3.13 |
| Sample app against a real database | 33 passed against PostgreSQL 16 (the kit uses 17; see below) |
| Coverage | 94 percent, threshold 90 |
| Lint and format | `ruff check` and `ruff format --check` clean |
| Clean install | fresh virtual environment from the pinned requirement files, `pip check` clean |
| Migrations | `alembic upgrade head` and `downgrade base` on SQLite and PostgreSQL |
| Smoke script | `scripts/smoke.sh` passes against a running server, and fails correctly when given a wrong expected commit SHA |
| Graceful shutdown | SIGTERM logs "shutdown complete" before exit |
| Chaos switches | `CHAOS_FAIL_READY` returns 503 on `/health/ready`; `CHAOS_CRASH_ON_START` makes uvicorn exit non-zero; `CHAOS_ERROR_RATE` injects 500s on `/api/` only |
| Compose file | `docker compose config` valid (structure and variable interpolation only) |
| YAML | `yamllint` clean on the compose file and every starter-kit YAML |
| Workflow skeletons | `actionlint` clean, JSON-schema valid, `zizmor` reports no findings |
| Dependabot skeleton | JSON-schema valid |
| Shell scripts | `shellcheck` clean, `bash -n` clean |
| Terraform skeletons | HCL syntax parses (`python-hcl2`). Syntax only: see below |
| Dockerfile | `hadolint` reports the problems the Dockerfile is meant to have |
| AWS CLI request shapes | The Budgets, Systems Manager, Service Quotas and Free Tier calls used in the docs and scripts validate against the official API models (botocore 1.44.1). No real call was made |
| Links | Every link in the learning-resources appendix was fetched on 2026-11-12, with two exceptions listed in that appendix |
| Diagrams | All Mermaid diagrams in `assignment/` parse with the Mermaid 11 parser |
| OIDC diagnostic | The token-decoding logic in `starter-kit/workflows/oidc-debug.yml` was tested against synthetic tokens for every padding case. The workflow itself has never run on GitHub |

### Not run: you are the first

| What | Why | Risk | What to do if it fails |
| --- | --- | --- | --- |
| Building the Docker image, `docker compose up` | No Docker daemon in my sandbox | Low. The app runs with the same command the image uses | Read the build error; the Dockerfile is yours to fix in task 1.6 anyway |
| PostgreSQL 17 specifically | Only PostgreSQL 16 binaries were available | Low. The app uses nothing version-specific | Run `make test-integration` on Day 1 |
| Any GitHub Actions run | No GitHub API access | Medium. Action inputs change between major versions | Read each action's README at the pinned tag, not at `main` |
| kind, kubectl, Helm | Binaries could not be downloaded | Medium | `starter-kit/kind/kind-config.yaml` follows the documented v1alpha4 format; check the digest note above |
| kube-prometheus-stack install | Needs a cluster | Medium. The values file was written against the chart's own `values.yaml` at 93.2.2, but never installed | `helm template` it first and read the error |
| `terraform validate`, `plan`, `apply` | No Terraform binary | Medium. The skeletons contain no resources, only version pins and comments, so there is little to be wrong | `terraform init` on Day 1 of Week 3 proves the pins |
| Any real AWS call | No AWS account | Medium. `scripts/aws-preflight.sh` and `scripts/end-of-session.sh` are linted and their API shapes validated, but never executed against AWS | Run `scripts/aws-preflight.sh` in task 1.2; if a query prints nothing, check it in the console and note it |
| `aws login` with Terraform | No AWS account | Medium. Native support is reported by two independent write-ups (Terraform 1.15+, provider 6.23+), not by HashiCorp documentation | The fallback in the execution guidelines, Week 3, works with any version |
| gitleaks and Trivy scans | Binaries could not be downloaded | Low | First CI run shows it |
| Windows and WSL2 behaviour | Sandbox is plain Linux | Low to medium. File permissions and line endings are the usual culprits; `.gitattributes` forces LF | Keep the repository inside the WSL filesystem, never under `/mnt/c` |

If something in the second table bites you, write it in `NOTES.md` with the exact error. That note is worth more than the hour it cost.
