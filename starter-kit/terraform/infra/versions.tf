# Infra stack: the network and the server that runs the cluster. After the
# first run, this stack is applied ONLY by the terraform.yml workflow.
#
# This file is complete except for the backend values. It pins versions and
# configures state; it creates nothing.

terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
  }

  # Remote state in the bucket created by ../bootstrap.
  #
  # Backend settings are read very early, before input variables are
  # evaluated, so they must be literal values. Two ways to supply them; pick
  # one:
  #
  #   a) write them here as literals (the bucket name contains your account
  #      id, which is not a secret, but you may prefer it out of a public repo)
  #   b) leave them out and pass them at init time ("partial configuration"):
  #        terraform init -backend-config="bucket=..." -backend-config="region=..."
  #      with the values coming from GitHub Actions variables in CI.
  #
  # TODO(3.2): bucket, key and region.
  backend "s3" {
    # bucket = "..."
    # key    = "infra/terraform.tfstate"
    # region = "..."

    # Lock the state with a lock object in the same bucket. Without locking,
    # two applies at once can corrupt state. This replaces the DynamoDB table
    # used before Terraform 1.10; DynamoDB locking is deprecated.
    use_lockfile = true

    # Ask S3 to encrypt the state and lock objects at rest.
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Stack     = "infra"
    }
  }
}
