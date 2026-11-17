# Starter kit: skeletons and commented configs

Nothing in this folder runs by itself. Each file is either a **skeleton** (the
shape of the thing, with `TODO(task-number)` markers where your work goes) or a
small **commented config** you are expected to read and understand before you
use it.

Copy a file into place only when the week that needs it starts. A skeleton
copied early just gives you a red pipeline you cannot fix yet.

| File here | Copy to | When | Kind |
| --- | --- | --- | --- |
| `workflows/ci.yml` | `.github/workflows/ci.yml` | Week 1, task 1.4 | Skeleton |
| `dependabot.yml` | `.github/dependabot.yml` | Week 1, task 1.9 | Skeleton |
| `pre-commit-config.yaml` | `.pre-commit-config.yaml` | Week 1, task 1.8 | Skeleton |
| `pull_request_template.md` | `.github/pull_request_template.md` | Week 1, task 1.3 | Ready to use |
| `kind/kind-config.yaml` | `k8s/kind-config.yaml` | Week 2, task 2.1 | Commented config |
| `helm/tracker/` | `charts/tracker/` | Week 2, task 2.5 | Skeleton |
| `workflows/k8s-smoke.yml` | `.github/workflows/k8s-smoke.yml` | Week 2, task 2.7 | Skeleton |
| `terraform/bootstrap/` | `terraform/bootstrap/` | Week 3, task 3.2 | Skeleton |
| `terraform/infra/` | `terraform/infra/` | Week 3, task 3.3 | Skeleton |
| `workflows/oidc-debug.yml` | `.github/workflows/oidc-debug.yml` | Week 3, task 3.6 (delete after use) | Diagnostic, ready to use |
| `workflows/terraform.yml` | `.github/workflows/terraform.yml` | Week 3, task 3.7 | Skeleton |
| `workflows/deploy.yml` | `.github/workflows/deploy.yml` | Week 4, task 4.3 | Skeleton |
| `observability/kube-prometheus-stack-values.yaml` | `observability/` | Week 4, task 4.6 | Commented config |
| `observability/tracker-alerts.yaml` | `observability/` | Week 4, task 4.7 | Skeleton |

## How to read a skeleton

Every skeleton has the same three kinds of comment:

- **What and why**: what the block must achieve and the reason it exists.
- **`TODO(n.n)`**: your work, tagged with the task number from
  `assignment/execution-guidelines.md`. When the file is finished, no `TODO` remains.
- **Done when**: an observable check, so you know you are finished without
  asking anyone.

The one file that runs as it is, `workflows/oidc-debug.yml`, is a diagnostic:
it prints the identity your repository presents to AWS, so that you write
your trust policies from a measured value instead of a guess. It delivers
nothing and you delete it after use.

The skeletons deliberately contain no finished pipeline steps and no finished
resources. Each workflow job has one placeholder step that fails with a clear
message, so a skeleton you forgot to fill in can never look green.

## Versions

Do not copy version numbers from blog posts or from an AI answer. Use
`assignment/verified-versions.md`, which lists the versions and commit SHAs this kit
was checked against on 2026-11-12, and check for newer releases yourself when
you pin.
