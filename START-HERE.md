# Parcelo DevOps and Cloud Assignment: Start Here

A five-week, hands-on DevOps and Cloud assignment for one person, built to fit **22 hours a week** and to cost **nothing**.

You are handed a small, finished, tested backend service. You build everything around it: the pipeline that checks it, the image that packages it, the cluster that runs it, the cloud infrastructure underneath, the deployment that ships it and can take it back, and the monitoring that tells you when it is unwell.

This kit was put together and checked on **12 November 2026**. Tools in this field move fast; `assignment/verified-versions.md` says exactly what was checked and how to check again.

## Three things to do before anything else

1. **Confirm your AWS account is on the Free plan.** On that plan nothing can be charged to your card. Everything about cost in this kit assumes it. (`assignment/cost-safety.md`, section 2.)
2. **Check your EC2 vCPU quota this week, not in Week 3.** New accounts are often limited to 1 vCPU, every usable instance type needs 2, and raising the limit can take days. (`assignment/cost-safety.md`, section 3.4.)
3. **Accept the two rules of the house.** Nothing paid, ever. No secret in any file, ever.

## Reading order

| Order | Read | Time | Why |
| --- | --- | --- | --- |
| 1 | This file | 5 min | The map |
| 2 | `assignment/execution-guidelines.md`, sections 1 to 4 | 25 min | What the assignment is for, the ground rules, Day 1 setup |
| 3 | `assignment/part-a.md` | 20 min | The brief for Weeks 1 and 2 |
| 4 | `assignment/cost-safety.md` | 15 min | Before you touch AWS, even to look |
| 5 | Day 1: `assignment/execution-guidelines.md`, section 4 | 2 h | The app running in your own repository |
| Later | `assignment/part-b.md` | 25 min | Before Week 3 |
| Each week | `assignment/self-review.md` | 90 min | Your replacement for a mentor review |
| Whenever a claim surprises you | `assignment/research-report.md` | | Why each choice was made, with sources |

`assignment/execution-guidelines.md` is the document you keep open all five weeks.

## The five weeks

| Week | You build | You prove |
| --- | --- | --- |
| 1 | A GitHub Actions pipeline; a hardened container image, published by commit | A failing test, a leaked secret and a vulnerable dependency each stop the pipeline |
| 2 | A hand-written Helm chart running on local Kubernetes | A release with a failing health check gets no traffic and rolls back |
| 3 | A cloud server defined entirely in Terraform, with no keys and no SSH | An unapproved change does nothing; the server shuts itself down if forgotten |
| 4 | An approved deployment pipeline; dashboards and alerts | A bad deploy rolls back by itself; an alert fires and resolves |
| 5 | Nothing new | Everything is destroyed and rebuilt from the repository, timed |

## What is in the box

```text
parcelo-devops-kit/
|-- START-HERE.md                 this file
|-- NOTES.md                      your working log, with the tracking tables ready to fill in
|
|-- assignment/                   the brief (read-only; you do not edit these)
|   |-- execution-guidelines.md   MAIN DOCUMENT: weekly tasks, guidance, Definition of Done
|   |-- part-a.md                 brief for Weeks 1 and 2
|   |-- part-b.md                 brief for Weeks 3 to 5
|   |-- cost-safety.md            budgets, free limits, end-of-session teardown checklist
|   |-- self-review.md            weekly checklists, AI review prompt, oral-exam questions
|   |-- verified-versions.md      versions, commit SHAs, and what was and was not verified
|   `-- research-report.md        why each choice was made, verified versus inferred, sources
|
|-- app/                          PROVIDED AND WORKING: the tracker service (FastAPI)
|-- migrations/                   Alembic migration
|-- tests/                        31 unit tests, 2 PostgreSQL integration tests
|-- Dockerfile                    works, and is deliberately bad: you rewrite it in Week 1
|-- docker-compose.yml            the app and PostgreSQL for local use, heavily commented
|-- Makefile                      make setup / lint / test / up / smoke
|-- pyproject.toml, requirements.txt, requirements-dev.txt, alembic.ini
|-- .env.example, .gitignore, .gitattributes
|
|-- scripts/
|   |-- smoke.sh                  end-to-end check of a running instance; used in every week
|   |-- check-tools.sh            are the tools for this week installed?
|   |-- aws-preflight.sh          read-only look at your AWS account: plan, credits, quota
|   `-- end-of-session.sh         read-only list of anything in AWS still costing credits
|
`-- starter-kit/                  SKELETONS: structure and TODO markers, nothing that runs
    |-- README.md                 what to copy where, and when
    |-- workflows/
    |   |-- ci.yml                Week 1
    |   |-- k8s-smoke.yml         Week 2
    |   |-- terraform.yml         Week 3
    |   |-- deploy.yml            Week 4
    |   `-- oidc-debug.yml        the one ready-to-run file: a diagnostic you use once
    |-- dependabot.yml, pre-commit-config.yaml, pull_request_template.md
    |-- kind/kind-config.yaml     local cluster definition, commented
    |-- helm/tracker/             chart skeleton and the list of templates to write
    |-- terraform/bootstrap/      state bucket, identity provider, roles
    |-- terraform/infra/          network, instance, first-boot script
    `-- observability/            monitoring values (working, commented) and alert skeleton
```

## What you are given, and what you build

| Given, working | You build |
| --- | --- |
| The application, its tests, health endpoints, metrics, structured logs | Four GitHub Actions workflows |
| Three "chaos" switches for breaking it on purpose | A production-grade Dockerfile |
| Docker Compose, Makefile, smoke test | A Helm chart, written by hand |
| Read-only AWS safety scripts | Two Terraform stacks and three IAM roles |
| Commented skeletons with `TODO(task)` markers | Dashboards, alert rules, a runbook, a cost report |
| The monitoring stack's values file | Ten drills with evidence |

This is your previous assignment turned inside out. There the infrastructure was provided and you wrote the application. Here the application is provided and you write the infrastructure. The skeletons contain **no finished pipeline and no finished infrastructure**, on purpose: each workflow job is a placeholder that fails until you replace it, so a skeleton you forgot can never look green.

## What it uses, and what it costs

| Layer | Tool | Cost |
| --- | --- | --- |
| Source, CI/CD, registry | GitHub public repository, Actions, Container Registry | Free for public repositories |
| Containers | Docker, Buildx, Compose | Free |
| Kubernetes | kind on the laptop; k3s on one cloud instance | Free |
| Packaging | Helm 4 | Free |
| Infrastructure as code | Terraform, state in your own S3 bucket | Free |
| Cloud | AWS Free plan: one small EC2 instance, only while you work | About 4 USD of your 100 USD credits in total |
| Identity | GitHub OIDC to AWS; `aws login` on the laptop | Free, and no stored keys |
| Security | Trivy, gitleaks, hadolint, Dependabot | Free |
| Observability | Prometheus, Alertmanager, Grafana, on the laptop | Free |

Deliberately left out: EKS, RDS, load balancers, NAT gateways, Jenkins, Ansible, service meshes, Vault, multiple clouds. The research report explains each.

## What was verified, and what was not

Said plainly, because it decides how much you should trust each part.

**Run and passing:** the application and its tests on Python 3.12 and 3.13 (31 passed, 2 skipped; 33 passed against a real PostgreSQL), linting, coverage of 94 percent, migrations, the smoke script, the Compose file's structure, every YAML file, all workflow skeletons (actionlint, schema, zizmor), all shell scripts (shellcheck), Terraform syntax, every diagram, and the links in the learning resources (two exceptions are noted there).

**Not run by anyone yet:** building the Docker image, any GitHub Actions run, kind, Helm, kubectl, the monitoring stack, `terraform validate` or `plan`, and every call to AWS. The reasons and what to do if one fails are in `assignment/verified-versions.md`, section 7.

So the application is solid ground. Everything you build on top of it you will be the first to run, which is rather the point of the assignment, and which is why the guidance tells you to print values and read errors instead of trusting anyone's snippet, including this kit's.

## Open decisions

These are yours to make. Each has a default so that none of them blocks you.

| # | Decision | Default in the kit | Decide by |
| --- | --- | --- | --- |
| 1 | Is the AWS account on the Free plan? If it is on the Paid plan, do you proceed with stricter discipline? | Assumes Free | Week 1, task 1.2 |
| 2 | vCPU quota below 2: wait, switch region, or fall back to Azure for Students | Request an increase to 2 at once | Week 1, task 1.2 |
| 3 | Region | `us-east-1` | Before Week 3 |
| 4 | Instance type | `c7i-flex.large` (roomy); `t3.small` is cheaper and is k3s's bare minimum | Week 3, task 3.4 |
| 5 | Sign in to AWS as an IAM user or as root | A personal IAM user with MFA | Week 1, task 1.2 |
| 6 | Your AWS account id will be visible in a public repository | Accept it (it is an identifier, not a credential), or move it to repository variables | Week 3, task 3.2 |
| 7 | How database migrations run in Kubernetes | Your choice: init container or Helm hook | Week 2, task 2.3 |
| 8 | How the read-only plan role copes with the state lock file | Your choice: allow the lock object, or plan without locking | Week 3, task 3.6 |
| 9 | What the dead-man switch does to a forgotten instance: stop or terminate | Your choice, with the cost of each explained | Week 3, task 3.4 |
| 10 | Argo CD (SHOULD, 2.5 hours) | Do it only if Week 4 is on schedule | Start of Week 4 |
| 11 | Keep `assignment/` and `starter-kit/` in the finished public repository? | Keep `assignment/`, delete `starter-kit/` once nothing is left to copy | Week 5 |

## When this file has done its job

In task 1.11 you write your own `README.md`: your project, in your words. That file becomes the front door of the repository. Keep this one or delete it, as you prefer; everything it says is also in `assignment/`.

Now open `assignment/execution-guidelines.md`.
