# Research Report: Why This Kit Looks the Way It Does

**Research dates:** 11 and 12 November 2026.
**Purpose:** justify every choice in the kit with something you can check, and separate what I verified from what I am inferring.

## How to read this report

Every claim carries one of four labels.

| Label | Meaning |
| --- | --- |
| **[V] Verified** | I read the primary source (vendor documentation, the project's own repository, an official changelog) on the dates above. |
| **[R] Reported** | A secondary source says so (a blog, a news site, a community thread). I did not confirm it at a primary source. |
| **[I] Inferred** | My judgement, built on the facts around it. Argue with these. |
| **[U] Unverified** | I believe it, but I could not or did not re-check it. Treat it as a lead, not a fact. |

Nothing in this report was learned by running your AWS account or your GitHub repository. `assignment/verified-versions.md` lists what was executed.

---

## 1. What employers ask for

Two data sets that count skills across job postings, read on 12 November 2026.

| Skill | Data set A: 800+ DevOps and SRE postings, Q1 2026 | Data set B: 7,523 DevOps Engineer postings, June 2026 |
| --- | --- | --- |
| Kubernetes | 89% | 56% |
| Terraform or IaC | 81% | just under 50% |
| AWS | 74% | 54% |
| CI/CD pipelines | 73% | 67% |
| Python | 67% | 53% |
| Linux and Bash | 64% | not in the top list I retrieved |
| Docker | 62% | not in the top list I retrieved |
| Prometheus, Grafana or Datadog | 58% | not in the top list I retrieved |
| GCP | 28% | not retrieved |
| Azure | 24% | not retrieved |

- **[R]** Data set A is published by jobstrack.io and covers companies with more than 100 engineers. Data set B is published by interviewstack.io from its own job board. Both are vendors with something to sell, the samples are mostly US and remote roles, and the two sets disagree on absolute numbers by a wide margin.
- **[I]** The disagreement in numbers does not matter for this kit. The **ranking** is what both agree on: CI/CD, Kubernetes, AWS, Terraform and Python sit at the top, with AWS named roughly two to three times as often as Azure or GCP.
- **[U]** I also read a handful of DevOps postings for Islamabad and Pakistan (links in section 9). They named the same core tools, but I did not count them, so that is an impression and not data. Before Week 5, open ten current postings you would actually apply to and tally the tools yourself. Put the tally in your README: it is a better argument for your project than this report.

**What this decided [I]:** the kit spends its hours on GitHub Actions, containers, Kubernetes, Terraform, AWS and Prometheus, in that order of introduction. Python is covered by the app you already know. Everything else was cut.

---

## 2. Which cloud, at zero cost

### 2.1 AWS (chosen)

- **[V]** Accounts created on or after 15 July 2025 choose between a **Free plan** and a **Paid plan**. Both receive 100 USD of credits at sign-up and can earn up to 100 USD more by completing listed activities.
- **[V]** The Free plan lasts six months or until the credits run out, whichever comes first, and usage on it incurs no charges. When it ends the account closes; AWS keeps the content for 90 days, and upgrading within that window restores access.
- **[V]** The Paid plan does not close when credits run out. It bills the card on file at normal rates.
- **[V]** On these accounts, the Free Tier eligible EC2 instance types are `t3.micro`, `t3.small`, `t4g.micro`, `t4g.small`, `c7i-flex.large` and `m7i-flex.large`. All have 2 vCPUs.
- **[R]** New accounts are often created with an EC2 On-Demand vCPU quota of 1, which is too small to launch any of those types. Several AWS re:Post threads from 2025 and 2026 describe exactly this, with the error "You have requested more vCPU capacity than your current vCPU limit of 1 allows". Quota increases are requested through Service Quotas and are not instant.
- **[I]** That quota is the single most likely blocker in this whole assignment, and it has a waiting time. So the kit checks it in **Week 1** (task 1.2), two weeks before you need an instance.

**Why AWS [I]:** it is the cloud named most often in section 1, you already have the account, and the Free plan is the only offer I found where a mistake cannot turn into a bill.

### 2.2 The alternatives, and why each lost

| Option | What I found | Why it is not the primary |
| --- | --- | --- |
| **Azure for Students** | **[V]** 100 USD credit, 12 months, no credit card, renewable each year while you are a student. Needs academic verification. | **[I]** A strong fallback and safer than any card-backed offer. It lost on job-market share. **[U]** I could not test whether a NUST address passes Microsoft's verification. |
| **Oracle Cloud Always Free** | **[R]** The always-free Arm allowance was halved to 2 OCPUs and 12 GB from 15 June 2026, with enforcement reported for August. **[R]** Oracle's documentation says idle always-free instances may be reclaimed. | **[I]** Capacity errors and reclaimed instances are the wrong kind of lesson for a five-week plan, and Oracle barely appears in the postings. |
| **Google Cloud free trial** | **[U]** I did not re-check the current terms for this report. | Not evaluated further. GCP sits well below AWS in section 1. |
| **LocalStack (AWS emulator)** | **[V]** Since release 2026.03.0 (23 March 2026) the image needs an account and an auth token to start. A free Hobby plan exists for non-commercial use. | **[I]** An emulator would add a token to manage and remove the real lessons (IAM, quotas, cost). Not used. |
| **Local only (kind, no cloud)** | Free by construction. | **[I]** Leaves out the half of the job postings that say "AWS" and "Terraform". Kept as the laptop half of the kit instead. |

### 2.3 Open risk on the account plan

**[I]** Everything in `assignment/cost-safety.md` assumes you are on the **Free plan**. I cannot see your account. If `scripts/aws-preflight.sh` reports the Paid plan, stop and read the cost-safety document before creating anything: on the Paid plan the same mistakes cost real money once credits are gone. This is the first open decision in the kit's README.

---

## 3. Things that changed in 2026 and break older tutorials

Each of these is a place where following a well-ranked 2024 or 2025 tutorial, or an AI answer trained on one, produces a failure with an unhelpful error. They are the reason the kit pins versions and tells you to read current documentation.

### 3.1 GitHub Actions

| Change | Evidence | Effect on you |
| --- | --- | --- |
| **Immutable OIDC subject claims.** Repositories created after 15 July 2026 present a subject of the form `repo:OWNER@OWNER_ID/REPO@REPO_ID:...` instead of `repo:OWNER/REPO:...`. | **[V]** GitHub changelog, 23 April 2026; GitHub's AWS OIDC guide; the `aws-actions/configure-aws-credentials` README, which names the resulting error. | Your repository is new, so every tutorial's trust policy is wrong for it. AWS answers "Not authorized to perform sts:AssumeRoleWithWebIdentity" and says nothing more. Week 3 teaches you to print your real subject before writing the policy. |
| **`ubuntu-latest` is moving to Ubuntu 26.04** between 19 October and 19 November 2026. | **[V]** GitHub changelog, 17 September 2026, and the runner-images tracking issue. | The label changes under you mid-project. The kit uses `ubuntu-24.04` everywhere. |
| **The `ubuntu-24.04` image ships Helm 3 and no Terraform.** | **[V]** Runner image software list, version 20261101.360.1. | A Helm 4 flag fails as "unknown flag"; `terraform` is "command not found". Both are installed explicitly. |
| **Required status checks never complete for skipped workflows.** A workflow skipped by a path or branch filter leaves its required check pending for ever. | **[V]** GitHub documentation on troubleshooting required status checks. | If you mark a path-filtered workflow as required, unrelated pull requests can never merge. Require only the always-run `ci` jobs. |

### 3.2 Supply chain

- **[V]** On 19 March 2026 an attacker with stolen credentials repointed 76 of the 77 version tags of `aquasecurity/trivy-action` at malicious code (advisory GHSA-69fq-xp46-6x23, CVE-2026-33634). Workflows that referenced a tag ran the attacker's code with the workflow's secrets. Workflows pinned to a commit SHA did not.
- **[I]** This is why SHA pinning is a MUST in Week 1 and not a nice-to-have, and why the kit's first lesson about a security scanner is that the scanner itself is part of your attack surface.

### 3.3 Kubernetes and Helm

- **[V]** The `ingress-nginx` controller, used by most Kubernetes tutorials, was retired in March 2026 (Kubernetes blog, 11 November 2025). The project recommends the Gateway API.
- **[I]** The MUST path therefore uses no ingress controller at all: a plain `LoadBalancer` Service on k3s. The Gateway API is a STRETCH item.
- **[V]** Helm 4 is current (4.3.1). Its documentation lists `--rollback-on-failure` on `helm upgrade` and no longer lists `--atomic`. `--wait` now takes a strategy; a bare `--wait` selects the `watcher` strategy, and leaving the flag out means Helm waits only for hooks.
- **[V]** Helm 3 receives security patches until February 2027 (Helm blog).
- **[V]** kubectl is supported within one minor version of the API server. Keep kubectl at 1.37.x for the 1.37 clusters in this kit.
- **[V]** kind's own quick start warns that a `:latest` tag makes Kubernetes try to pull the image instead of using the one you loaded. Tag images with the commit SHA.

### 3.4 Terraform

- **[R]** Terraform has shipped under the Business Source License 1.1 since version 1.6 (August 2023); IBM completed its acquisition of HashiCorp in February 2025; OpenTofu is the MPL 2.0 fork under the Linux Foundation. On 27 October 2026 one comparison recorded OpenTofu 1.13.2 and Terraform 1.17.0.
- **[R]** Two vendor comparisons say HCP Terraform's free tier ended in March 2026. I did not confirm this with HashiCorp.
- **[V]** HashiCorp's certification page lists the Terraform Associate (004) exam as testing Terraform 1.12. **[R]** Several prep sites quote its price as 70.50 USD.
- **[V]** The S3 backend's native lock file (`use_lockfile = true`) replaces DynamoDB locking, which HashiCorp documents as deprecated. With it enabled, the role needs `s3:GetObject`, `s3:PutObject` and `s3:DeleteObject` on the `.tflock` object.
- **[I]** You chose Terraform over OpenTofu, and for a learner that is the right call: postings say "Terraform", the certification is Terraform, and for managing your own infrastructure the licence has no practical effect. What you learn transfers to OpenTofu almost one to one. The kit stores state in your own S3 bucket, so it depends on no HashiCorp service.
- **[I]** A consequence worth knowing: a plan role that is truly read-only cannot write the lock file. Week 3 makes you choose how to handle that.

### 3.5 AWS

- **[V]** `aws login` (AWS CLI 2.32.0 and newer, announced November 2025) signs you in through the browser with your console identity and gives the CLI short-lived credentials. There is a `--remote` mode for terminals without a browser. Root needs no extra permission; an IAM user needs the `SignInLocalDevelopmentAccess` managed policy. A session lasts at most 12 hours.
- **[R]** Terraform reads those credentials natively from provider 6.23.0, and for the S3 backend from Terraform 1.15.0 (two independent tested write-ups by Classmethod, 2026). **[V]** AWS documents a `credential_process` profile as the bridge for any tool that does not.
- **[I]** This is why the kit never creates an access key, and why the Terraform floor is 1.15.
- **[V]** AWS Budgets counts credits as part of cost by default (`IncludeCredit` defaults to true). **[R]** An AWS Builder Center article points out the consequence: on an account living on credits, a zero-spend budget stays silent while the credits drain.
- **[V]** Budget data is refreshed up to three times a day, typically 8 to 12 hours apart.
- **[I]** So a budget alert is a late warning, not a brake. The kit's real brake is a shutdown timer on the instance itself.
- **[V]** A public IPv4 address costs 0.005 USD per hour whether in use or idle. **[V]** The VPC pricing page shows 0.045 USD per hour for a NAT gateway (its example region is Ohio). The kit's network has no NAT gateway.
- **[V]** The Systems Manager agent is preinstalled on Canonical's Ubuntu Server images. **[V]** AWS documents restricting `ssm:SendCommand` to tagged instances with the `ssm:resourceTag/<key>` condition.
- **[V]** The AWS CLI's built-in `ssm wait command-executed` gives up after 20 attempts 5 seconds apart, about 100 seconds (botocore waiter model). A Helm deploy with a three-minute timeout outlives it.

### 3.6 Local tooling

- **[V]** Docker Desktop is free for personal use and education.
- **[V]** Docker Hub allows 100 pulls per 6 hours without logging in and 200 with a free account.
- **[V]** WSL 2 gives its virtual machine 50% of Windows memory by default: 8 GB on your laptop.
- **[I]** 8 GB is enough for kind plus the monitoring stack if nothing else heavy is running. It is the reason Prometheus and Argo CD run on the laptop and not on the EC2 instance.
- **[V]** PostgreSQL 18 container images moved the data directory. The kit pins PostgreSQL 17.

---

## 4. Architecture decisions and what they traded away

| Decision | Alternative rejected | Why | Cost of the choice |
| --- | --- | --- | --- |
| Ship a small working app; spend the hours on delivery | Reuse SmartHealth | **[I]** SmartHealth needs Temporal, Kafka, Redis and Celery running before a pipeline can even be green. You would debug infrastructure you already understand. | Your earlier project is not showcased here. A STRETCH item suggests porting the Week 1 pipeline to it. |
| One EC2 instance running k3s | EKS | **[U]** An EKS control plane bills per hour on top of its nodes (not re-checked for this report). **[V]** k3s needs 2 cores and 2 GB, which a Free Tier eligible instance provides. | You do not learn managed node groups or IAM roles for service accounts. Name this gap in interviews; do not hide it. |
| `c7i-flex.large` by default | `t3.small` | **[V]** `t3.small` is exactly k3s's stated minimum, before your workload. **[I]** The larger type costs about 6 US cents more per hour, which is noise against 100 USD of credits. | Slightly faster credit burn if you forget to destroy. |
| Deploy through Systems Manager Run Command | Open the Kubernetes API (6443) to the runner; or SSH | **[I]** No inbound port, no key to store, and the audit trail is in AWS. | The deploy step is AWS-specific, and command output is truncated at 24,000 characters. |
| Chart and image pulled from a public GHCR package | Private registry with pull secrets | **[V]** Public packages are free and pull anonymously. | Your image is public. It contains no secrets, and Week 1 makes you prove that. |
| Two Terraform stacks (`bootstrap`, `infra`) | One stack | **[I]** The pipeline cannot create the role it needs in order to run. Something must exist first. | One small stack is applied from your laptop. |
| Three IAM roles, each trusted for one subject | One role for everything | **[I]** A pull request must never be able to obtain credentials that can change infrastructure. | More trust policies to get right. That is the lesson. |
| Prometheus, Grafana and Argo CD on kind only | Run them on the EC2 instance | **[I]** They need more memory than a zero-cost instance should carry, and the skills are identical on a laptop. | No monitoring of the cloud deployment. The smoke test and Helm's readiness wait cover it. |
| Manual, approved deploys | Deploy on every merge | **[I]** The instance does not exist most of the time (you destroy it after each session), so an automatic deploy would fail most days. | Continuous deployment is a SHOULD, not the default. |

---

## 5. What was left out, on purpose

| Left out | Reason |
| --- | --- |
| EKS, ECS, RDS, load balancers, NAT gateways | Each one bills per hour. None is needed to learn the fundamentals above. |
| Jenkins, GitLab CI, CircleCI | One CI system learned properly beats three learned badly. GitHub Actions was your requirement. |
| Ansible, Packer | Cloud-init user data does the one job they would do here. |
| Service mesh, Vault, policy engines | Each is a specialism. None appears in the top ten of section 1. |
| Multi-cloud, multi-region, multi-environment | One of each, done properly. |
| Logs and tracing stacks (Loki, Tempo, OpenTelemetry) | STRETCH. Metrics and alerts first. |
| Certification prep | The kit teaches the tools. Exam prep is a separate, later decision. |

---

## 6. Time and cost model

Time. Five weeks of 20 hours of planned tasks plus 2 hours of buffer:

$$5 \times (20 + 2) = 110 \text{ hours}$$

Cost, for the default instance, with approximate us-east-1 On-Demand prices **[U]** (I could not load the live EC2 price list; check it before Week 3):

$$\underbrace{0.085}_{\text{instance}} + \underbrace{0.005}_{\text{public IPv4}} + \underbrace{0.002}_{\text{20 GB gp3 disk}} \approx 0.092 \text{ USD per hour}$$

Planned use is about 40 instance-hours across Weeks 3 to 5:

$$40 \times 0.092 \approx 3.70 \text{ USD of credits}$$

Worst realistic mistake, an instance left running for a full week with the shutdown timer broken:

$$168 \times 0.092 \approx 15.50 \text{ USD of credits}$$

**[I]** Even the worst case stays inside the 100 USD of credits, and on the Free plan the amount beyond credits is zero by definition. The plan has a wide margin, which is the point.

---

## 7. What I could not verify

Stated plainly, because you asked for it:

1. **Your AWS account.** Plan type, remaining credits, vCPU quota, whether Budgets and the Free Tier API behave as documented on it.
2. **Anything executed on GitHub, in Docker, in Kubernetes or with Terraform.** See the ledger in `assignment/verified-versions.md`.
3. **Live prices.** The instance and disk prices in section 6 are from memory of the price list, not from a page I could load. The public IPv4 price is verified.
4. **Terraform's native support for `aws login`.** Reported by two tested write-ups, not documented by HashiCorp on the pages I read. A fallback is provided.
5. **Local job market.** Impression only.
6. **Google Cloud and the GitHub Student Developer Pack.** Not re-checked; neither is used.
7. **Whether Helm 4 still silently accepts `--atomic`.** The documentation no longer lists it. Use `--rollback-on-failure` and the question never arises.

---

## 8. If you only remember five things from this report

1. Your repository is new, so its OIDC subject contains numeric ids. Print it; do not guess it.
2. Check the vCPU quota in Week 1. It has a waiting time.
3. Pin actions by SHA. The Trivy incident is the reason.
4. A budget alert arrives hours late. The shutdown timer and `terraform destroy` are the real protection.
5. The runner has Helm 3 and no Terraform. Install what you need, pinned.

---

## 9. Sources

Primary sources were read on 11 or 12 November 2026. Secondary sources are marked.

**Job market (secondary)**
- https://jobstrack.io/blog/roles/devops-sre
- https://interviewstack.io/blog/devops-engineer-skills-companies-want-2026
- https://pk.indeed.com/q-devops-engineer-jobs.html
- https://www.getpakjob.com/jobs/view/junior-devops-engineer-5
- https://www.emumba.com/careers

**AWS account, Free Tier and cost**
- https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans.html
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html
- https://aws.amazon.com/free/free-tier-faqs/
- https://aws.amazon.com/blogs/aws/aws-free-tier-update-new-customers-can-get-started-and-explore-aws-with-up-to-200-in-credits
- https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/tracking-free-tier-usage.html
- https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_budgets_CostTypes.html
- https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
- https://aws.amazon.com/vpc/pricing/
- https://builder.aws.com/content/3Kkt4kNiDSUnO3n6db2weSNubzE/the-dollar0-aws-account-in-2026-free-plan-credits-guardrails (secondary)
- https://repost.aws/questions/QU-LtNfmBZRnKT6FblHwjduA/new-aws-free-tier-account-cannot-create-tutorial-instances-or-applications-due-to-vcpu-limit-of-1 (secondary)
- https://repost.aws/questions/QUtZw68fatTCeMgiPqYfGzgw/new-aws-india-account-ec2-vcpu-quota-too-low-to-launch-even-t3-micro-how-to-increase (secondary)

**AWS access and operations**
- https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html
- https://aws.amazon.com/blogs/security/simplified-developer-access-to-aws-with-aws-login
- https://docs.aws.amazon.com/sdkref/latest/guide/feature-login-credentials.html
- https://docs.aws.amazon.com/systems-manager/latest/userguide/run-command-setting-up.html
- https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
- https://dev.classmethod.jp/en/articles/aws-login-default-profile-credential-process-error/ (secondary)
- https://dev.classmethod.jp/articles/terraform-s3-backend-aws-login/ (secondary, Japanese)

**GitHub**
- https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
- https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
- https://docs.github.com/en/actions/reference/security/oidc
- https://github.com/aws-actions/configure-aws-credentials
- https://github.blog/changelog/2026-09-17-ubuntu-26-generally-available-and-latest-migration
- https://github.com/actions/runner-images/issues/14748
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks
- https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
- https://docs.github.com/en/billing/concepts/product-billing/github-packages
- https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection
- https://docs.github.com/en/actions/concepts/security/artifact-attestations

**Supply chain**
- https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23
- https://www.aquasec.com/blog/trivy-supply-chain-attack-what-you-need-to-know/
- https://github.com/aquasecurity/trivy-action
- https://github.com/gitleaks/gitleaks-action

**Kubernetes, Helm, k3s, kind**
- https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/
- https://kubernetes.io/releases/version-skew-policy/
- https://helm.sh/docs/helm/helm_upgrade/
- https://helm.sh/blog/helm-v3-end-of-life
- https://helm.sh/docs/topics/registries/
- https://docs.k3s.io/installation/requirements
- https://docs.k3s.io/networking/networking-services
- https://kind.sigs.k8s.io/docs/user/quick-start/
- https://argo-cd.readthedocs.io/en/stable/getting_started/
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

**Terraform**
- https://developer.hashicorp.com/terraform/language/backend/s3
- https://developer.hashicorp.com/terraform/install
- https://developer.hashicorp.com/certifications/terraform-associate
- https://encore.dev/articles/opentofu-vs-terraform-2026 (secondary)
- https://scalr.com/learning-center/opentofu-vs-terraform (secondary)
- https://www.stackguardian.io/post/opentofu-vs-terraform (secondary)

**Other clouds and tools**
- https://azure.microsoft.com/en-au/free/students
- https://learn.microsoft.com/en-us/azure/education-hub/faq
- https://infoq.com/news/2026/07/oracle-cloud-free-tier-limits/ (secondary)
- https://linuxiac.com/oracle-quietly-cuts-free-tier-ampere-a1-resources-in-half/ (secondary)
- https://blog.localstack.cloud/localstack-for-aws-release-2026-03-0/
- https://docs.docker.com/subscription/desktop-license/
- https://docs.docker.com/docker-hub/usage/
- https://learn.microsoft.com/en-us/windows/wsl/wsl-config
