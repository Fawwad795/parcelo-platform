# Inputs for the infra stack.

variable "aws_region" {
  description = "Region for every resource in this project."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Short name used in resource names and in the Project tag."
  type        = string
  default     = "parcelo"
}

variable "instance_type" {
  description = "EC2 instance type for the single k3s node."
  type        = string

  # Only instance types marked Free Tier eligible can be launched on the AWS
  # Free plan. For accounts created after 15 July 2025 those are:
  #
  #   type             vCPU  memory   on-demand us-east-1 (approximate; confirm
  #                                   on the EC2 pricing page before Week 3)
  #   t3.micro          2     1 GiB   too small for k3s
  #   t3.small          2     2 GiB   about $0.021 per hour; k3s's stated
  #                                   MINIMUM before any workload; expect OOM
  #   c7i-flex.large    2     4 GiB   about $0.085 per hour; comfortable for
  #                                   k3s + the app + PostgreSQL
  #   m7i-flex.large    2     8 GiB   about $0.096 per hour; needed only if
  #                                   you also run Prometheus in the cloud
  #
  # Confirm the list for your account with:
  #   aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true \
  #     --query 'InstanceTypes[].InstanceType' --output text
  default = "c7i-flex.large"

  # TODO(3.4): add a `validation` block that rejects any type outside the
  # list above, so a typo cannot launch something expensive. A plan that
  # fails is cheaper than an instance you did not mean to start.
}

variable "k3s_version" {
  description = "Exact k3s release to install. Pinned so every rebuild gives the same cluster."
  type        = string
  # Newest release on 2026-11-12. Check https://github.com/k3s-io/k3s/releases
  # before you start Week 3 and take the newest patch of this minor.
  default = "v1.37.2+k3s1"
}

variable "helm_version" {
  description = "Exact Helm release installed on the node (used by the deploy pipeline)."
  type        = string
  default     = "v4.3.1"
}

variable "auto_shutdown_minutes" {
  description = "The instance powers itself off this many minutes after boot (cost safety net)."
  type        = number
  default     = 360

  # TODO(3.4): add a validation that keeps this between 10 and 720. A dead-man
  # switch that can be set to "never" is not a dead-man switch. (The lower
  # bound of 10 exists so you can test it: drill D7 boots a node with a
  # 10-minute timer and watches it shut down.)
}

# TODO(3.3): network inputs (VPC and subnet CIDR ranges), with sensible
# defaults. Why should these be variables at all if you only ever create one
# environment?
