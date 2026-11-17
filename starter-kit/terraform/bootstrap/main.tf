# Bootstrap stack resources (skeleton).
#
# Nothing below is written for you. Each section says what must exist, why,
# and what "done" looks like. Read the linked documentation for each resource
# type before you write it; the argument names matter and guessing them from
# old blog posts is the slowest way to learn Terraform.

# -----------------------------------------------------------------------------
# 1. Remote state bucket (task 3.2)
#
# Terraform state is the record of what Terraform created. Lose it and
# Terraform no longer knows your instance exists; leak it and you may leak
# whatever sensitive values it contains. So the bucket must be:
#
#   - versioned            an accidental overwrite or delete is recoverable
#   - encrypted at rest    server-side encryption with S3-managed keys is free
#   - private              all four public-access-block settings switched on
#   - hard to delete       prevent_destroy, so `terraform destroy` here fails
#                          loudly instead of deleting your state history
#
# In provider 6.x these are SEPARATE resources that each point at the bucket
# (versioning, encryption and public access block are not arguments of
# aws_s3_bucket any more).
#
# Cost: a few kilobytes of state costs well under one cent per month. This
# bucket is the one thing you do NOT tear down at the end of a session.
#
# Done when: `aws s3api get-bucket-versioning` reports Enabled, and
# `aws s3api get-public-access-block` shows all four settings true.
# -----------------------------------------------------------------------------

# TODO(3.2): state bucket and its three companion resources.

# -----------------------------------------------------------------------------
# 2. GitHub as an identity provider (task 3.6)
#
# One aws_iam_openid_connect_provider per AWS account tells IAM to trust
# tokens signed by GitHub Actions:
#
#   url             https://token.actions.githubusercontent.com
#   client_id_list  ["sts.amazonaws.com"]     (the audience)
#
# You do not need a thumbprint_list. For GitHub, AWS validates the token
# against its own trusted certificate authorities and ignores any thumbprint,
# so tutorials that tell you to compute one are out of date.
#
# The provider by itself grants nothing. Access is decided by each role's
# trust policy, below.
# -----------------------------------------------------------------------------

# TODO(3.6): the OIDC identity provider.

# -----------------------------------------------------------------------------
# 3. Roles the pipelines assume (tasks 3.6 and 4.2)
#
# Each role has two halves:
#
#   trust policy        WHO may assume it. Action sts:AssumeRoleWithWebIdentity,
#                       principal = the OIDC provider above, and CONDITIONS on
#                       the token's `aud` and `sub` claims.
#   permission policy   WHAT it may do once assumed.
#
# The `sub` condition is the security boundary. If it is too loose, any
# workflow run in your repository (including one triggered by a stranger's
# pull request) can get these credentials. Use StringEquals with the exact
# subject; avoid wildcards.
#
# Subjects for this repository (immutable format, note the @ids):
#
#   pull request runs        repo:OWNER@OWNER_ID/REPO@REPO_ID:pull_request
#   environment "infra"      repo:OWNER@OWNER_ID/REPO@REPO_ID:environment:infra
#   environment "production" repo:OWNER@OWNER_ID/REPO@REPO_ID:environment:production
#
# A job that declares `environment: infra` gets the ENVIRONMENT subject, not
# a branch subject. That is what lets a required reviewer on the environment
# act as the gate in front of the role.
#
#   Role                     Trusted subject            May do
#   -----------------------  -------------------------  ------------------------
#   <project>-tf-plan        pull_request               read-only, plus read the
#                                                       state object
#   <project>-tf-apply       environment:infra          manage this project's
#                                                       EC2, VPC, SSM and its
#                                                       own IAM roles; read and
#                                                       write state
#   <project>-deploy (4.2)   environment:production     find the instance by
#                                                       tag, send one SSM
#                                                       document to instances
#                                                       tagged Project=<project>,
#                                                       read command results
#
# Things to work out (write the answers in docs/infrastructure.md):
#
#   - `terraform plan` takes the state lock, which WRITES a .tflock object.
#     A read-only role cannot. Either let the plan role write only that one
#     object, or plan with -lock=false and accept the trade-off. Which, and
#     why?
#   - The apply role creates an IAM role for the instance and passes it to
#     EC2 (iam:PassRole). How do you allow that without letting the pipeline
#     create an administrator role for itself? (Look at restricting by role
#     name prefix, and at permissions boundaries.)
#   - AdministratorAccess on the apply role would "just work". Why is it not
#     acceptable, even in a personal account?
#
# Done when (3.6): a workflow run on a pull request can read from AWS and
# cannot change anything; a run in the `infra` environment can apply; and a
# workflow in a DIFFERENT repository, or a run without the environment, is
# denied.
# -----------------------------------------------------------------------------

# TODO(3.6): plan role and apply role, with trust and permission policies.

# TODO(4.2): deploy role.
