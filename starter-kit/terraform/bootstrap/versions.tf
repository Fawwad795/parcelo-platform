# Bootstrap stack: the few things that must exist BEFORE a pipeline can run
# Terraform at all. You apply this stack from your laptop (after `aws login`),
# rarely, and by hand. Everything else lives in ../infra and is applied only
# by the pipeline.
#
# Why two stacks: the pipeline needs a state bucket and an IAM role to assume
# before it can do anything. Something has to create those first. That
# chicken-and-egg step is what "bootstrap" means, and keeping it small and
# separate means a mistake in day-to-day infrastructure can never delete the
# state bucket or lock you out of your own pipeline.
#
# This file is complete. It pins versions; it creates nothing.

terraform {
  # Terraform 1.15 or newer reads `aws login` credentials directly, and
  # 1.10 or newer supports S3-native state locking (`use_lockfile`), which
  # replaces the DynamoDB lock table that older tutorials create.
  # Newest release on 2026-11-12: Terraform 1.17.2 (the kit author could not
  # run Terraform; see assignment/verified-versions.md for what was and was not run).
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # "~> 6.70" allows 6.70 and any later 6.x, never 7.0. A new major
      # version can change resource behaviour; you upgrade majors on purpose,
      # in a pull request, not by accident on a Tuesday.
      # Newest release on 2026-11-12: provider 6.73.0.
      version = "~> 6.70"
    }
  }

  # TODO(3.2): this stack starts with LOCAL state (a terraform.tfstate file
  # next to this code, ignored by git). Once the bucket below exists, add an
  # `backend "s3"` block here and run `terraform init -migrate-state` so the
  # bootstrap state is not stored only on your laptop. Use a different `key`
  # from the infra stack.
}

provider "aws" {
  region = var.aws_region

  # Every resource this provider creates gets these tags automatically. Tags
  # are how you (and scripts/end-of-session.sh, and IAM conditions in Week 4)
  # tell which resources belong to this project.
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}
