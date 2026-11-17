# Outputs of the infra stack (skeleton).
#
# The instance is destroyed and recreated often, so its id and IP change.
# Nothing downstream may hard-code them. Humans read these outputs with
# `terraform output`; the deploy pipeline finds the instance by TAG instead,
# so it keeps working after every rebuild.

# TODO(3.4): instance_id.

# TODO(3.4): public_ip, and a ready-to-click URL for the service.

# TODO(3.5): a ready-to-paste Session Manager command, for example
#   aws ssm start-session --target <id> --region <region>
# Small conveniences like this are what make infrastructure pleasant to
# operate at two in the morning.
