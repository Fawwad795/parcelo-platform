# Outputs of the bootstrap stack (skeleton).
#
# Outputs are how one stack hands values to the next step. The infra stack's
# backend and your workflows need three things from here. None of them is a
# secret: a role ARN identifies a role, it does not grant access to it (the
# trust policy does). Store them as repository or environment VARIABLES in
# GitHub (Settings > Secrets and variables > Actions > Variables), not as
# secrets, so they stay readable in logs when you debug.

# TODO(3.2): the state bucket name.

# TODO(3.6): the ARNs of the plan role and the apply role.

# TODO(4.2): the ARN of the deploy role.
