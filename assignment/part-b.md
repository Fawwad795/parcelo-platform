# Parcelo Delivery Platform: Cloud Infrastructure, Deployment and Operations [Part B]

**Duration:** Weeks 3 to 5 of 5.
**Prerequisite:** Part A is merged. Specifically: the `ci` workflow publishes a **public** image tagged with the full commit SHA; the Helm chart installs on kind with one command; and the AWS preflight from Week 1 shows the **Free plan** and a **vCPU quota of 2 or more**. If the quota is not there yet, read "Plan B" in the execution guidelines (section 7) before you start Week 3.
**Money:** zero. Part B uses about 4 USD of the 100 USD in credits your AWS account came with. `assignment/cost-safety.md` is part of this brief, not an appendix to it.

## 1. The Scenario

Part A gave Parcelo a trustworthy artifact and a tested way to run it. It did nothing for the other four problems:

- **Problem 1: deploys are manual and frightening.** There is still an engineer with an SSH session and no way back.
- **Problem 4: the server is a pet.** Nobody can rebuild it.
- **Problem 5: customers discover outages first.**
- **Problem 6: nobody knows what the cloud costs.**

Part B replaces the hand-built server with infrastructure that exists only as code, replaces the SSH session with an approved, reversible pipeline, and gives the team graphs, alerts, a runbook and a cost figure.

**Two rules define this part.** Getting them right matters more than the number of tools you touch.

1. **Everything can be destroyed and rebuilt from the repository.** If a step exists only in your memory or your shell history, the server is still a pet.
2. **No long-lived credential exists anywhere.** Not on your laptop, not in GitHub's secrets, not on the server. Every identity in this system is short-lived and can do only its own job.

## 2. What "Good" Looks Like

By the end of Week 5, starting from an AWS account that holds nothing but a state bucket and three roles, you can show:

- Run one workflow, click **Approve**, and a few minutes later a server exists that is running Kubernetes. It has no SSH key and no management port open to the internet.
- Open a pull request that changes the instance type. The **plan** appears in the pull request. Nothing in AWS changes until the pull request is merged **and** you approve the apply. Reject the approval: nothing changes.
- Prove there is nothing to steal: no access key exists in the AWS account, and the repository's secrets page holds no AWS credential.
- Run the deploy workflow with a commit SHA and approve it. `GET /version` on the server's public address answers with that SHA.
- Deploy a **deliberately broken** build. The pipeline ends red, the previous version never stopped answering, and you touched nothing.
- Open Grafana and see request rate, error ratio and latency for the tracker. Raise the error rate with the chaos switch: an alert **fires**. Lower it: the alert **resolves**.
- Walk away from a running instance. After the configured time it **shuts itself down**.
- Destroy everything. The end-of-session script reports nothing left. Then rebuild from code, with a stopwatch running and **no manual step**, until the smoke test passes again.
- State what the project has cost so far, what one hour of it costs, and what it would cost per month if it ran all day.
- Follow your own runbook, cold, for three different failures.

The broken deploy, the alert and the timed rebuild are the real assignment.

## 3. Requirements

Labels as in Part A: **[MUST]**, **[SHOULD]**, **[STRETCH]**.

### 3.1 Cost Safety

- **[MUST]** The account is confirmed to be on the Free plan, with the two budgets from `assignment/cost-safety.md` in place, before any resource is created.
- **[MUST]** Every working session that touches AWS ends with the end-of-session checklist, and the cost log has a row for it.
- **[MUST]** The instance carries a **dead-man switch**: it shuts itself down a fixed time after boot, whatever you do or forget. You have seen it fire.
- **[MUST]** Terraform creates nothing that bills by the hour except one instance, its disk and its public address. No NAT gateway, no load balancer, no Elastic IP, no managed database, no managed Kubernetes.
- **[MUST]** One region, chosen once. Every resource carries a `Project` tag, applied automatically.

### 3.2 Infrastructure as Code

The first hard requirement.

- **[MUST]** Two Terraform stacks. `bootstrap` holds what must exist before a pipeline can run (state bucket, identity provider, roles) and is applied from your laptop. `infra` holds everything else and is applied **only** by the pipeline.
- **[MUST]** State is remote: an S3 bucket with versioning, encryption and all public access blocked, using the backend's native lock file. No state file, plan file or `.terraform` directory is ever committed.
- **[MUST]** The `infra` stack creates: a VPC, one public subnet, an internet gateway and route; a security group allowing inbound TCP 80 and nothing else; an instance role that can do nothing except register with Systems Manager; and one instance.
- **[MUST]** The instance: a Free Tier eligible type; the current Ubuntu 24.04 image looked up at plan time, never a pasted image id; metadata service version 2 only; an encrypted 20 GB gp3 root volume; **no key pair**.
- **[MUST]** First-boot user data installs a **pinned** k3s and a **pinned** Helm, waits for the node to be Ready, and fails loudly if anything goes wrong.
- **[MUST]** Ports 22 and 6443 are closed to the internet. You manage the node through Session Manager.
- **[MUST]** Versions are constrained (`required_version`, provider constraint) and the dependency lock file is committed. `terraform fmt -check` and `terraform validate` are clean.
- **[MUST]** Inputs are variables with descriptions; the instance type variable **rejects** any type outside the Free Tier list.
- **[MUST]** `terraform plan` on an unchanged stack reports no changes.
- **[SHOULD]** `tflint`, and a misconfiguration scan of the Terraform code that fails on HIGH findings.
- **[STRETCH]** Import a resource you created by hand into state; split the network into a reusable module.

### 3.3 Identity Without Stored Keys

The second hard requirement, and the one most tutorials get wrong for a repository created in late 2026.

- **[MUST]** **No IAM access key exists**, for any user, at any point. Your laptop authenticates with `aws login`. Pipelines authenticate with OpenID Connect (OIDC).
- **[MUST]** One OIDC identity provider for GitHub, and **three roles**, each trusted for **exactly one** token subject, matched with `StringEquals`:

  | Role | Trusted for | May do |
  | --- | --- | --- |
  | plan | pull request runs | Read. It cannot change infrastructure. |
  | apply | the `infra` environment | Change the `infra` stack. |
  | deploy | the `production` environment | Find the instance, send it a command, read the result. |

- **[MUST]** Trust policies use the subject format your repository **actually** presents. Repositories created after 15 July 2026 include numeric owner and repository ids in the subject. You print the real value before you write the policy; you do not copy one from a tutorial.
- **[MUST]** A pull request can never obtain credentials that change anything. You demonstrate the denial.
- **[MUST]** No pipeline role has `AdministratorAccess`. The apply role can create and pass IAM roles **only** under the project's name prefix, so it cannot mint itself an administrator.
- **[MUST]** The deploy role's `SendCommand` permission is restricted to instances carrying the project tag.
- **[SHOULD]** In Week 5, each role's permissions are narrowed using what it was actually observed to use.
- **[STRETCH]** A permissions boundary on roles the apply role creates.

### 3.4 The Infrastructure Pipeline

- **[MUST]** A `terraform` workflow that, on pull requests touching the infra code, formats, validates and **plans**, and shows the plan where a reviewer will see it.
- **[MUST]** On merge to `main`, it **applies**, but only after a required reviewer (you) approves in the `infra` environment.
- **[MUST]** A manual trigger offers `apply` and `destroy` through the same environment and the same approval, so tearing down is as safe and as easy as building.
- **[MUST]** Two applies can never run at once, and an apply in progress is never cancelled.
- **[MUST]** Terraform is installed at a pinned version; it is not on the runner image.
- **[MUST]** You can explain, in `docs/infrastructure.md`, how the plan you reviewed can differ from what is applied, and what would close that gap.
- **[STRETCH]** Apply the exact plan file that was reviewed.

### 3.5 Continuous Deployment

The third hard requirement.

- **[MUST]** The chart is published by CI as a versioned OCI artifact in the container registry, public, alongside the image.
- **[MUST]** A `deploy` workflow, started by hand with a **full commit SHA** as input. The input is validated, and it reaches the shell through an environment variable, never by being pasted into a script.
- **[MUST]** It runs in the `production` environment and waits for your approval.
- **[MUST]** It finds the instance **by tag**, and fails clearly if there is none or more than one.
- **[MUST]** It sends **one** command through Systems Manager that runs `helm upgrade --install` on the node with `--wait`, a `--timeout` and `--rollback-on-failure`, setting the image tag and the reported commit to the chosen SHA.
- **[MUST]** It waits for that command with its own polling loop whose deadline is **longer** than Helm's timeout, prints the command's output whatever the result, and fails the job if the command failed.
- **[MUST]** A second job checks the service **from outside**: `scripts/smoke.sh` against the public address, expecting the deployed SHA.
- **[MUST]** Deploys queue; they never overlap.
- **[MUST]** A `values-aws.yaml` for the node: a `LoadBalancer` Service on port 80, and resource settings that fit the instance.
- **[MUST]** The database password on the node is **generated at first boot**, stored only as a Kubernetes Secret, and appears in no file, no state and no log.
- **[SHOULD]** A job summary that records what was deployed, when, by which run, replacing what.
- **[SHOULD]** Deploy automatically after `ci` succeeds on `main` when an instance exists.
- **[STRETCH]** Expose the service through the Gateway API with k3s's bundled Traefik instead of a `LoadBalancer` Service.

### 3.6 Observability

Runs on your **laptop cluster**, not on AWS. The instance is too small and too short-lived to carry a monitoring stack, and the skills are identical.

- **[MUST]** The `kube-prometheus-stack` chart is installed on kind at a pinned version, using the provided values file, which you have read and can explain.
- **[MUST]** Prometheus scrapes the tracker through a `ServiceMonitor` that is part of **your** chart and switched on by a value.
- **[MUST]** A Grafana dashboard, kept **as code** in the repository, showing at least: request rate, error ratio, 95th percentile latency and pod restarts. Reinstalling Grafana brings the dashboard back with no clicking.
- **[MUST]** At least **three alert rules**, as a `PrometheusRule`: the error ratio is too high; fewer replicas are ready than desired; Prometheus has lost sight of the tracker altogether. Each has a `for` duration, a severity label, a human-readable summary and a link to the runbook section that deals with it.
- **[MUST]** One **service level objective**, written as a number over a window, with the error-ratio alert derived from it rather than guessed.
- **[MUST]** The alert drill: raise the error rate, watch the alert go pending, then firing; lower it, watch it resolve. Keep the evidence.
- **[SHOULD]** A latency alert on the 95th percentile, and a second objective for latency.
- **[SHOULD]** Recording rules, so the dashboard and the alerts share one definition of "error ratio".
- **[STRETCH]** Route alerts to a real receiver; add logs (Loki) or traces; probe the AWS endpoint from the laptop with a blackbox exporter.

### 3.7 GitOps

- **[SHOULD]** Argo CD on kind, with an Application that syncs your chart from the repository. Change a value in git and watch the cluster follow. Change the cluster by hand and watch Argo CD put it back.
- **[SHOULD]** Half a page in `docs/gitops.md` comparing the two delivery models you now have: a pipeline that **pushes** (Week 4, AWS) and a controller that **pulls** (Argo CD, kind). When would you choose each?

### 3.8 The Prove-It Drills

Each drill is a MUST. A drill counts only with dated evidence in `docs/drills.md`: what you did, what you expected, what happened, and a link or screenshot.

| # | Drill | You break | Passing looks like | Week |
| --- | --- | --- | --- | --- |
| D1 | Red build blocks merge | A unit test | The pull request cannot be merged | 1 |
| D2 | Leaked secret | Commit a fake cloud key | Blocked on your machine; when forced past, caught in the pipeline | 1 |
| D3 | Vulnerable dependency | Pin an old vulnerable package | Pipeline red at the scan; no image published | 1 |
| D4 | Failed health check | Turn on `CHAOS_FAIL_READY` in a release | New pods get no traffic; Helm rolls back; no failed requests | 2 |
| D5 | Pod loss | Delete an API pod, then the database pod | No failed requests for the first; recovers by itself after the second; data intact | 2 |
| D6 | Unapproved change | Merge an infra change and reject the approval | Nothing in AWS changes | 3 |
| D7 | Dead-man switch | Boot with a 10-minute timer and wait | The instance shuts itself down | 3 |
| D8 | Bad deploy | Deploy a build that cannot become ready | Pipeline red; previous version still serving; no manual action | 4 |
| D9 | Alert | Raise `CHAOS_ERROR_RATE` | Alert fires, then resolves when lowered | 4 |
| D10 | Rebuild from code | Destroy everything | Timed rebuild to a passing smoke test, zero manual steps | 5 |

### 3.9 Operations Documents

- **[MUST]** `docs/runbook.md`: for three failures, the symptom, how to confirm it, the exact commands to diagnose it, the fix, and how to verify the fix. At minimum: a deploy that will not go green; the service unreachable from the internet while pods look healthy; an alert that is firing.
- **[MUST]** `docs/cost-report.md`: credits used, instance hours, cost per hour, the monthly cost if always on, the largest line of the bill, and one change that would cut it.
- **[MUST]** A **traceability table** in the README: each of Parcelo's six problems, what in your repository fixes it, and the drill or evidence that proves it.

## 4. Explicitly Out of Scope

Do not build these. Several of them would also break the zero-cost rule.

- **EKS, ECS, Fargate, Lambda.** One instance, one cluster.
- **RDS, ElastiCache, or any managed database.** PostgreSQL runs in the cluster.
- **Load balancers, NAT gateways, Elastic IPs.** All bill by the hour.
- **A domain name or TLS certificates.** The service is plain HTTP on an IP address. That is a real limitation: write it down, do not solve it.
- **Secrets Manager, Parameter Store secrets, Vault.** One generated password does not justify a secrets system.
- **HCP Terraform, Terragrunt, Atlantis.** Your state lives in your own bucket and your pipeline is the automation.
- **Ansible, Packer, custom machine images.** User data does the one job.
- **More than one environment, account or region.**
- **Auto Scaling groups, multiple nodes, high availability.**
- **Database backup, replication or disaster recovery.** The data is disposable by design.
- **Exposing the Kubernetes API, or SSH, to the internet.** Not even "temporarily, to debug".
- **Paid or trial monitoring services.**
- **Running the monitoring stack or Argo CD on the EC2 instance.**

## 5. Tech Stack and Practical Rules

**Required** (versions in `assignment/verified-versions.md`)

- **Terraform** 1.15 or newer with the AWS provider 6.x; state in **S3**
- **AWS**: IAM with OIDC, VPC, EC2, Systems Manager (Session Manager and Run Command), Budgets
- **AWS CLI v2** with `aws login`; the Session Manager plugin
- **k3s** on one EC2 instance; **Helm 4** on the node
- **GitHub Actions** with **environments** and required reviewers
- **kube-prometheus-stack** (Prometheus, Alertmanager, Grafana) on kind

**Optional:** tflint, Trivy config scanning, Argo CD, the Gateway API.

**Practical rules. Read these before you create anything.**

- **Cost first.** If you do not know what a resource costs per hour, you are not ready to create it. Look it up, then write it in the pull request.
- **Print, do not guess.** The OIDC subject, the instance id, the image name: print the real value and copy it. Most lost hours in this part come from a string that was almost right.
- **Read the plan before you approve it.** The approval button is the control. Clicking it without reading the plan is the same as having no control.
- **Destroy at the end of every session.** The rebuild is five minutes, and doing it daily is what makes Drill D10 boring instead of frightening.
- **Use the documentation for the version you pinned.** Helm 4, not Helm 3. Provider 6, not provider 4. If an example uses `--atomic`, a DynamoDB lock table, an access key in GitHub secrets, or a thumbprint for the OIDC provider, it is out of date.
- **No secrets in files.** Not in `.tfvars`, not in values files, not in workflow files, not in user data. This project has exactly one secret, and it is generated on the node.

## 6. Deliverables

Added to your existing repository.

1. **`terraform/bootstrap/`** and **`terraform/infra/`**, complete, with the lock files committed and no `TODO` left.
2. **`.github/workflows/terraform.yml`** and **`.github/workflows/deploy.yml`**, complete.
3. **`charts/tracker/values-aws.yaml`**, and the chart published as an OCI artifact by CI.
4. **`observability/`**: the monitoring values, the alert rules, and the dashboard as JSON.
5. **`docs/infrastructure.md`**: a network and identity diagram; each role with its trust policy and permissions, and why; the state design; the plan-versus-apply gap; known limitations.
6. **`docs/deployment.md`**: the deploy sequence as a diagram, every identity involved, how rollback works and what it does not catch.
7. **`docs/observability.md`**: what is measured, the objective and how the number was chosen, each alert and the question it answers, dashboard screenshots.
8. **`docs/runbook.md`**, **`docs/cost-report.md`**, and **`docs/drills.md`** completed for D6 to D10.
9. **`docs/gitops.md`** if you did the Argo CD work.
10. **Updated `README.md`**: the architecture diagram, the traceability table, how to rebuild from nothing, known limitations, and what you would do with two more weeks.
11. **A demo recording**, at most 12 minutes, covering the scenarios in section 2. Record it; do not rely on the infrastructure still existing.
12. **Three merged pull requests**, one per week, each with its self-review triage table.

## 7. How You Will Assess Yourself

| Area | Weight | What to look for |
| --- | --- | --- |
| Reproducibility | 25% | Destroy and rebuild from the repository with no manual step, timed |
| Safe delivery | 25% | Approvals that really gate; a bad deploy that really rolls back; every drill evidenced |
| Security and least privilege | 20% | No stored credential; exact trust subjects; no wildcard administrator; closed ports |
| Operations | 15% | An alert derived from an objective; a runbook that works cold; an honest cost report |
| Understanding | 15% | You can answer the oral-exam questions for Weeks 3 to 5 without notes |

**Warning.** There are two ways to fail Part B outright, whatever else works:

1. **A long-lived credential or an administrator-level pipeline role.** One access key in GitHub secrets undoes the whole identity design.
2. **Anything left running, or any real charge.** The constraint was zero.

A single small server that you can destroy, rebuild, deploy to and roll back, with every identity scoped and every drill evidenced, scores far higher than an impressive platform you are afraid to touch.
