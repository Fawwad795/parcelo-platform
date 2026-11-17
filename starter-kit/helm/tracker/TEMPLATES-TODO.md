# Templates to write (Week 2)

The `templates/` folder is empty on purpose. Do NOT start with `helm create`: it generates
a few hundred lines you did not write and cannot explain. Follow this order
instead.

1. **Write plain manifests first** (tasks 2.2 to 2.4), in `k8s/manifests/`,
   and get them working on kind with `kubectl apply`. You learn Kubernetes
   from manifests, not from templates.
2. **Then turn them into templates** (task 2.5): move each manifest into
   `templates/` and replace only the parts that differ between environments with values.
   Compare `helm template` output with your working manifests until they
   match.

This file sits beside `templates/`, not inside it, because Helm tries to
render every file in `templates/` as a manifest. Delete it when the chart is
complete.

## What the finished chart must render

| Template | Purpose | Task |
| --- | --- | --- |
| `_helpers.tpl` | Shared names and labels, so every object carries the same `app.kubernetes.io/*` labels and selectors can never drift | 2.5 |
| `deployment.yaml` | The API: image, env from ConfigMap and Secret, three probes, resources, security context, rolling update strategy | 2.2, 2.4, 2.6 |
| `service.yaml` | Stable name and port in front of the API pods | 2.2 |
| `configmap.yaml` | Non-secret settings | 2.2 |
| `postgres-statefulset.yaml` | PostgreSQL with a volume claim template | 2.3 |
| `postgres-service.yaml` | Stable DNS name for the database | 2.3 |
| Migration step | `alembic upgrade head` runs once, before new API pods serve traffic. Init container or Helm hook Job: choose one and justify it | 2.3 |
| `pdb.yaml` (SHOULD) | PodDisruptionBudget so a node drain cannot take every replica down | 2.6 |
| `servicemonitor.yaml` (Week 4) | Tells Prometheus to scrape `/metrics`; rendered only when enabled | 4.6 |
| `NOTES.txt` (SHOULD) | Printed after install: how to reach the service and check its version | 2.5 |

## Not in the chart

- **The database password.** Create the Secret in the cluster with
  `kubectl create secret generic ... --from-literal=...` (the value comes from
  your shell, never from a file in git). The chart only refers to the Secret
  by name. Document the command in your README.
- **The namespace.** Create it with `helm upgrade --install --create-namespace`
  or `kubectl create namespace`. A chart that creates its own namespace cannot
  be installed twice in one cluster.

## Checks before you call the chart done

```bash
helm lint charts/tracker -f charts/tracker/values-kind.yaml
helm template tracker charts/tracker -f charts/tracker/values-kind.yaml | less
helm upgrade --install tracker charts/tracker -n parcelo --create-namespace \
  -f charts/tracker/values-kind.yaml --wait --timeout 3m --rollback-on-failure
kubectl -n parcelo get all
```

`--rollback-on-failure` is the Helm 4 name. Tutorials written for Helm 3 use
`--atomic`; the Helm 4.3 documentation no longer lists that flag, so do not
rely on it. In Helm 4 a bare `--wait` also means something specific (the
`watcher` strategy): read `helm upgrade --help` once before you use it.
