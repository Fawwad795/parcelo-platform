# Inputs for the bootstrap stack.
#
# Pass values on the command line or in a terraform.tfvars file. That file is
# ignored by git (see .gitignore): it will contain your account-specific ids,
# and a public repository does not need them.

variable "aws_region" {
  description = "Region for every resource in this project. Pick one and never mix."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Short name used in resource names and in the Project tag."
  type        = string
  default     = "parcelo"
}

variable "github_owner" {
  description = "GitHub user or organisation that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "Repository name, without the owner."
  type        = string
}

# Repositories created after 15 July 2026 put numeric, immutable ids into the
# OIDC subject claim:  repo:OWNER@OWNER_ID/REPO@REPO_ID:...
# Read both ids with:
#   gh api repos/OWNER/REPO --jq '{repo_id: .id, owner_id: .owner.id}'
# or print the exact prefix GitHub will send with:
#   gh api repos/OWNER/REPO/actions/oidc/customization/sub

variable "github_owner_id" {
  description = "Numeric id of the GitHub owner (immutable OIDC subject format)."
  type        = string
}

variable "github_repo_id" {
  description = "Numeric id of the GitHub repository (immutable OIDC subject format)."
  type        = string
}

# TODO(3.2): the state bucket name. S3 bucket names are global across ALL AWS
# accounts, so "parcelo-tfstate" is certainly taken. Build a unique name, for
# example by including your account id. Should this be a variable, or a local
# computed from `data "aws_caller_identity"`? Decide and say why.
