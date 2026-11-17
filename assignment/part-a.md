# Parcelo Delivery Platform: Shipping Software Safely [Part A]

**Duration:** Weeks 1 and 2 of 5. **Type:** Individual, self-reviewed. You work in your own public repository; there is no mentor, so `assignment/self-review.md` replaces the weekly review.
**Money:** Part A costs nothing and creates nothing in the cloud. Everything runs on your laptop and on GitHub.

## 1. The Scenario

Parcelo is a courier startup that moves parcels between cities. Customers and partner shops follow each parcel through one small backend service, the **tracker**: a FastAPI application backed by PostgreSQL. Six engineers work on it. The service itself is fine. It has tests, health endpoints, metrics and structured logs.

Everything **around** the service is the problem. Parcelo is growing, and the way software reaches customers is breaking down in six ways:

1. **Deploys are manual and frightening.** One engineer connects to the server over SSH on a Friday evening, pulls the code and restarts the process. There is no way back. Last month a bad deploy took tracking offline for three hours.
2. **Nothing checks the code before it ships.** The tests exist, but nobody is required to run them. A change that broke parcel creation reached customers because it "worked on my machine".
3. **A cloud key was committed to the repository.** It sat in the history for weeks before anyone noticed. Nobody knows whether it was used.
4. **The server is a pet.** It was set up by hand two years ago by someone who has left. Nobody can say what is installed on it, and nobody could rebuild it.
5. **Customers discover outages first.** The team learns the service is down from angry messages, not from a graph or an alert.
6. **Nobody knows what the cloud costs,** or what would still be running if everyone went on holiday.

Your job in Part A: fix problems **2** and **3**, and build the two things that every later fix depends on: a **trustworthy, versioned artifact** (a container image) and a **tested way to run it** (a Helm chart, proven on a local Kubernetes cluster).

Part B then fixes problems 1, 4, 5 and 6 on real cloud infrastructure.

**You are not building the application.** It is finished and it ships in this kit. Do not add endpoints, do not refactor it, do not improve its tests. The only application file you are expected to rewrite is the `Dockerfile`, which is deliberately bad. Every hour spent on the API is an hour stolen from the assignment.

## 2. What "Good" Looks Like

By the end of Week 2, you should be able to open a terminal and a browser and show all of this, without preparing anything by hand first:

- Open a pull request with a **failing test**. The merge button is blocked. You cannot merge it even as the repository owner without deliberately bypassing a rule.
- Open a pull request with a formatting error. It fails within two minutes and the log says exactly which file.
- Merge a clean pull request. A few minutes later a container image tagged with **that commit's SHA** exists in the registry. Pull it from a logged-out shell, run it, and `GET /version` answers with the same SHA.
- Show that the image runs as a non-root user and is a fraction of the size of the one you started with.
- Pin an old, vulnerable version of a dependency in a branch. The pipeline goes **red at the scan**, names the vulnerability and never publishes the image.
- Commit a fake cloud key. Your own machine refuses the commit. Force it past the local hook, push, and the pipeline catches it instead.
- Run one command on a clean laptop cluster and watch the tracker and its database come up. The smoke test passes against `http://localhost:8080`.
- Delete the running API pod. The service keeps answering, a replacement appears within seconds, and the parcels you created are still there.
- Release a version whose **health check fails**. It never receives a single request. Helm gives up, rolls back by itself, and the old version never stopped answering.
- Break a template in the chart and open a pull request. A real Kubernetes cluster is created **inside the pipeline**, the install fails, and the pull request shows why.

The last five bullets are the real assignment. Anyone can make a pipeline go green. The skill is building one that goes red for the right reasons and leaves the running system untouched when it does.

## 3. Requirements

Requirements are labelled:

- **[MUST]** required. Missing one means Part A is incomplete.
- **[SHOULD]** expected if the week went to plan. These are the first things you drop when it does not.
- **[STRETCH]** only if you are ahead. Never at the cost of a MUST.

Hour estimates in the execution guidelines cover MUST and SHOULD items. STRETCH items are not in the budget.

### 3.1 Repository and Working Agreements

- **[MUST]** A public GitHub repository. `main` is protected by a ruleset: changes arrive only through pull requests, the `ci` checks must pass, and force pushes and branch deletion are blocked.
- **[MUST]** One branch and one pull request per week, with small commits whose messages say what changed and why.
- **[MUST]** No secret ever enters the repository: no `.env`, no token, no password, no cloud key, no Terraform state. This applies to the whole history, not only the latest commit.
- **[SHOULD]** The pull request template from the starter kit is in use, and merges are squashed so `main` reads as one line per change.
- **[STRETCH]** Signed commits; a `CODEOWNERS` file.

### 3.2 Continuous Integration

- **[MUST]** A workflow named `ci` runs on every pull request and on every push to `main`. It lints, checks formatting, and runs the unit tests with coverage.
- **[MUST]** The pipeline fails if coverage drops below **90 percent**. The threshold lives in `pyproject.toml`; you never lower it to make a build pass.
- **[MUST]** The workflow calls the same `make` targets you run locally, so "it passed on my laptop" and "it passed in CI" mean the same thing.
- **[MUST]** Jobs run on `ubuntu-24.04`, never on `ubuntu-latest`.
- **[MUST]** Dependencies are cached. A typical pull request gets its answer in **under five minutes**; record the measured time.
- **[MUST]** A newer push to the same pull request cancels the run in progress. Runs on `main` are never cancelled.
- **[MUST]** The coverage report is uploaded as an artifact and summarised in the job summary.
- **[SHOULD]** The PostgreSQL integration tests run in CI against a database service container.
- **[STRETCH]** A matrix across Python 3.12 and 3.13; a reusable workflow.

### 3.3 The Container Image

The starting `Dockerfile` works and is wrong in at least eight ways. Rewriting it is the first hard requirement.

- **[MUST]** The final image contains the application and its runtime dependencies and nothing else: no test tools, no compilers, no `.git`, no `.env`, no tests.
- **[MUST]** It runs as a **non-root user with a numeric id**. (Kubernetes cannot verify "non-root" for a user given by name; you will meet that error in Week 2 if you skip this.)
- **[MUST]** The base image is a slim variant, pinned by tag **and digest**.
- **[MUST]** Layers are ordered so that changing application code does not reinstall dependencies.
- **[MUST]** The process starts in exec form, so it receives `SIGTERM` and shuts down cleanly.
- **[MUST]** The commit SHA is passed in at build time and is what `GET /version` reports.
- **[MUST]** A `.dockerignore` keeps the build context small and secrets out of it.
- **[MUST]** `hadolint` runs in the pipeline. Any rule you ignore is ignored in a file, with a comment giving the reason.
- **[MUST]** `docker compose up` still starts the whole stack with the new image.
- **[SHOULD]** The image is at least **five times smaller** than the starting one. Record both sizes.
- **[STRETCH]** A multi-architecture build (amd64 and arm64); a distroless final stage.

### 3.4 Publishing the Image

- **[MUST]** The pipeline builds the image with Buildx and a build cache.
- **[MUST]** Pull requests **build** the image but never **push** it. Only `main` publishes.
- **[MUST]** Published images are tagged with the **full commit SHA**. A moving tag such as `main` is allowed in addition, never instead.
- **[MUST]** The image lives in the GitHub Container Registry, is linked to the repository, and is **public**, so that a cluster can pull it with no credentials.
- **[MUST]** The pipeline authenticates with the built-in `GITHUB_TOKEN`. No personal access token is created or stored.

### 3.5 Supply Chain and Secrets

The second hard requirement, and the direct answer to problem 3.

- **[MUST]** Every action is pinned to a full 40-character commit SHA, with the version as a trailing comment.
- **[MUST]** Workflows start from `permissions: {}`. Each job is then granted only what it needs, and you can say why for each permission.
- **[MUST]** The built image is scanned for known vulnerabilities. A **HIGH** or **CRITICAL** finding that has a fix available fails the pipeline **before** the image is published.
- **[MUST]** There is a written exception process: an ignore file where every entry carries a reason and a date to revisit it. An ignore with no reason is a finding in your own review.
- **[MUST]** Secrets are scanned in two places: a `pre-commit` hook on your machine, and the pipeline over the **full history**.
- **[MUST]** Dependabot is configured for GitHub Actions, Python packages and the Docker base image.
- **[SHOULD]** A software bill of materials (SBOM) is generated for each published image and kept as an artifact.
- **[SHOULD]** `actionlint` and `zizmor` check the workflows themselves in CI.
- **[SHOULD]** GitHub's own secret scanning and push protection are switched on in the repository settings.
- **[STRETCH]** Dependency review on pull requests; scan results uploaded to GitHub code scanning.

### 3.6 Kubernetes on the Laptop

- **[MUST]** A local `kind` cluster is created from the committed configuration, with the node image pinned.
- **[MUST]** The tracker runs as **two replicas** behind a Service.
- **[MUST]** PostgreSQL runs as a StatefulSet with a persistent volume. Deleting its pod does not lose data.
- **[MUST]** Non-secret settings come from a ConfigMap. The database password comes from a Secret that is created **outside git** and only referenced by name.
- **[MUST]** Database migrations run automatically before a new version serves traffic, and running them from two replicas at once does no harm.
- **[MUST]** Three probes, each using the right endpoint: startup, readiness (`/health/ready`) and liveness (`/health`). You can explain why liveness must **not** check the database.
- **[MUST]** CPU and memory requests, and a memory limit, on every container.
- **[MUST]** A restrictive security context: non-root, read-only root filesystem, no privilege escalation, all capabilities dropped, default seccomp profile.
- **[MUST]** A rolling update replaces the pods with **no failed requests**; you demonstrate it with a request loop running during the update.
- **[SHOULD]** A PodDisruptionBudget.
- **[STRETCH]** A NetworkPolicy that lets only the API reach the database (check first that your cluster's network plugin enforces policies); a HorizontalPodAutoscaler.

### 3.7 The Helm Chart

- **[MUST]** One chart, `charts/tracker`, **written by hand**. Do not start from `helm create`: it generates hundreds of lines you cannot explain.
- **[MUST]** Everything that differs between environments is a value; everything else is not. There is a `values.yaml` with safe defaults and a `values-kind.yaml` for the laptop.
- **[MUST]** The image tag and commit SHA are set at install time. The chart has no `latest` anywhere.
- **[MUST]** No secret value appears in the chart, in any values file, or in the rendered output.
- **[MUST]** `helm lint` is clean, and the rendered manifests pass schema validation (`kubeconform`).
- **[MUST]** Installing and upgrading are the same command, safe to run twice: `helm upgrade --install` with `--wait`, a `--timeout` and `--rollback-on-failure`.
- **[SHOULD]** A `NOTES.txt` that tells the person who just installed it how to reach the service; a `values.schema.json` that rejects a mistyped value.
- **[STRETCH]** Chart unit tests; `helm test` hooks.

### 3.8 Cluster Smoke Test in the Pipeline

- **[MUST]** A second workflow, `k8s-smoke`, runs on pull requests that touch the chart, the Dockerfile or the application. It creates a kind cluster on the runner, builds the image, loads it into the cluster, installs the chart and runs `scripts/smoke.sh`.
- **[MUST]** It installs **Helm 4** explicitly. The runner image ships Helm 3.
- **[MUST]** When it fails, it prints what you would need to debug it: pod status, events and logs. A red run with no diagnostics is half a pipeline.
- **[MUST]** Because it is path-filtered, it is **not** a required status check. (A required check that never runs blocks every unrelated pull request for ever.)

### 3.9 Groundwork for Part B

- **[MUST]** The AWS account is secured and inspected in Week 1 (`assignment/cost-safety.md`, section 3): MFA on, no access keys, plan checked, budget created, **vCPU quota checked and an increase requested if needed**. This is in Week 1 because a quota increase can take days and Week 3 cannot start without it.

## 4. Explicitly Out of Scope

Do not build these. They earn nothing here and they cost you the assignment.

- **Any change to the application's behaviour**: new endpoints, new tables, authentication, a UI.
- Any CI system other than GitHub Actions. No Jenkins, no GitLab CI.
- Self-hosted runners.
- Docker Swarm, Nomad, or a second container runtime.
- An ingress controller or a service mesh. A NodePort is enough on the laptop.
- Kustomize alongside Helm. One packaging tool, learned properly.
- A PostgreSQL operator, replication or backups. One StatefulSet, one replica.
- A multi-node or highly available cluster.
- Paid scanners or hosted security products, including free trials that ask for a card.
- A private registry, or any long-lived token.
- Anything in AWS beyond the account checks in 3.9.

## 5. Tech Stack

**Required** (exact versions and commit SHAs are in `assignment/verified-versions.md`)

- **Git and GitHub**: rulesets, pull requests, GitHub CLI
- **GitHub Actions** on `ubuntu-24.04` standard runners
- **Docker** with Buildx, **Docker Compose**
- **GitHub Container Registry**
- **hadolint**, **Trivy**, **gitleaks**, **pre-commit**, **Dependabot**
- **kind**, **kubectl**, **Kubernetes 1.37**
- **Helm 4**, **kubeconform**
- The provided application: Python 3.13, FastAPI, PostgreSQL 17

**Optional:** syft (SBOM), actionlint, zizmor.

The application, its tests, the compose file, the Makefile and the scripts are **provided and working**. The workflows, the chart and the manifests are **not**: `starter-kit/` holds skeletons with `TODO` markers and nothing that runs. That is the inverse of your previous assignment, and it is deliberate.

## 6. Deliverables

Everything lives in your repository.

1. **A rewritten `Dockerfile`** and a `.dockerignore`.
2. **`.github/workflows/ci.yml`** and **`.github/workflows/k8s-smoke.yml`**, complete, with no `TODO` left.
3. **`.github/dependabot.yml`** and **`.pre-commit-config.yaml`**.
4. **`charts/tracker/`**: the Helm chart, with `values.yaml` and `values-kind.yaml`.
5. **`k8s/kind-config.yaml`**, and the plain manifests you wrote before the chart, kept under `k8s/manifests/` as a record of how you got there.
6. **`README.md`**: what this is, the pipeline at a glance, how to run everything from a fresh clone, and a status badge.
7. **`docs/pipeline.md`**: a diagram of the pipeline, what each job proves, every permission and why it is there, and the exception process for scan findings.
8. **`docs/kubernetes.md`**: a diagram of the objects, the probe design, the migration approach you chose and why, and the security context with a reason for each line.
9. **`docs/drills.md`**: each drill from section 2 with the date, what you did, what happened, and a link or screenshot as evidence.
10. **`NOTES.md`**: your working log, with the AWS preflight output and the weekly review log.
11. **Two merged pull requests**, one per week, each with the self-review triage table as a comment.

## 7. How You Will Assess Yourself

Score yourself at the end of Week 2 using `assignment/self-review.md`. Be strict: the evidence either exists or it does not.

| Area | Weight | What to look for |
| --- | --- | --- |
| It works end to end | 30% | From a fresh clone, every scenario in section 2 can be reproduced |
| It fails safely | 25% | Each gate has been shown to block: tests, lint, coverage, vulnerability, secret, broken chart, failing health check |
| Security and supply chain | 15% | Pinned actions, minimal permissions, non-root image, no secret anywhere in history |
| Documentation | 15% | Someone else could run it and understand why each piece exists |
| Understanding | 15% | You can answer the oral-exam questions for Weeks 1 and 2 without notes |

**A small pipeline whose every gate you have seen fail beats a large one you have only ever seen pass.** If you must drop something, drop a STRETCH, then a SHOULD. Never a MUST. Write down what you dropped and why in `NOTES.md`.
