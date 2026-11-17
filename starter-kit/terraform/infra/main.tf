# Infra stack resources (skeleton).
#
# Target: one small server in its own network, running k3s, reachable from
# the internet on port 80 only, managed without SSH, and rebuildable from
# nothing with `terraform apply`.
#
#   internet --80--> [ security group ] --> EC2 instance (k3s, single node)
#                                              |  outbound 443 only
#                                              +--> AWS Systems Manager
#                                              +--> ghcr.io (chart and image)
#
# Work through the sections in order and `terraform plan` after each one.
# Small steps: a plan with three new resources is readable, a plan with
# thirty is not.

# -----------------------------------------------------------------------------
# 1. Network (task 3.3)
#
# Build:
#   - a VPC
#   - ONE public subnet in one availability zone
#   - an internet gateway attached to the VPC
#   - a route table with a default route (0.0.0.0/0) to the internet gateway,
#     associated with the subnet
#
# What makes a subnet "public" is that route, nothing else. Understand that
# sentence before you move on.
#
# Do NOT create a NAT gateway. It costs about 4.5 cents per hour plus data
# charges whether you use it or not, and it is the most common source of
# surprise AWS bills. A NAT gateway is for instances in PRIVATE subnets; this
# design has none.
#
# Gotcha: not every instance type is offered in every availability zone. If
# launch fails with "Unsupported" or "InsufficientInstanceCapacity", look at
# the data source aws_ec2_instance_type_offerings to choose a zone that
# offers var.instance_type instead of hard-coding one.
#
# Done when: `terraform plan` shows only these resources, and you can explain
# what would break if you deleted the route.
# -----------------------------------------------------------------------------

# TODO(3.3): VPC, subnet, internet gateway, route table, association.

# -----------------------------------------------------------------------------
# 2. Security group (task 3.3)
#
# Inbound:  TCP 80 from anywhere. Nothing else.
# Outbound: everything (the node must reach AWS, GHCR and package mirrors).
#
# Not open, on purpose:
#   22    there is no SSH. You use Session Manager, which needs NO inbound
#         port at all because the agent on the instance dials out.
#   6443  the Kubernetes API. Exposing it to the internet is how clusters get
#         found and attacked within minutes.
#
# In provider 6.x, write rules as separate aws_vpc_security_group_ingress_rule
# and aws_vpc_security_group_egress_rule resources rather than inline
# ingress/egress blocks.
#
# Honest limitation to write down in docs/infrastructure.md: the app has no
# authentication and port 80 is plain HTTP, so anyone who finds the IP can
# create parcels. That is acceptable for a short-lived demo that you destroy
# after each session, and it is one more reason to destroy it.
# -----------------------------------------------------------------------------

# TODO(3.3): security group and its rules.

# -----------------------------------------------------------------------------
# 3. Instance identity (task 3.4)
#
# The instance needs an IAM role so the Systems Manager agent can register
# it. Three pieces:
#   - a role that the EC2 service is allowed to assume
#   - the AWS managed policy AmazonSSMManagedInstanceCore attached to it
#   - an instance profile wrapping the role (EC2 attaches profiles, not roles)
#
# The instance gets NO other permissions. It does not need to call AWS for
# anything else in this project.
#
# Name these with the var.project prefix: the apply role's own permissions
# (bootstrap stack) should only allow creating roles with that prefix.
# -----------------------------------------------------------------------------

# TODO(3.4): role, policy attachment, instance profile.

# -----------------------------------------------------------------------------
# 4. Machine image (task 3.4)
#
# Never paste an AMI id from a web page: ids differ per region and go stale.
# Canonical publishes the current Ubuntu image id as a public SSM parameter:
#
#   /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id
#
# Read it with a data source. Ubuntu 24.04 images include the SSM agent.
#
# Two things to notice:
#   - the data source's `value` attribute is marked sensitive, which hides
#     the AMI id in plans; look for the attribute meant for non-secret values
#   - "current" moves whenever Canonical publishes a new image, so a later
#     plan may want to REPLACE your instance. Decide whether that is what you
#     want (always-fresh image) or not (lifecycle ignore_changes), and write
#     down the trade-off.
# -----------------------------------------------------------------------------

# TODO(3.4): data source for the AMI id.

# -----------------------------------------------------------------------------
# 5. The instance (task 3.4)
#
# Required settings, each with a reason you should be able to state:
#
#   instance type            var.instance_type
#   subnet, security group   from sections 1 and 2
#   public IP                associate one; without it the node cannot reach
#                            the internet (there is no NAT) or be reached
#   instance profile         from section 3
#   IMDSv2 only              metadata_options with http_tokens = "required";
#                            blocks a whole class of credential-theft attacks
#   root volume              gp3, 20 GB, encrypted. The default 8 GB fills up
#                            with container images within a day.
#   user data                rendered from user-data.sh.tftpl with templatefile()
#   replace on user data     user_data_replace_on_change = true, so editing
#     change                 the script rebuilds the node instead of silently
#                            doing nothing (user data runs only at first boot)
#   shutdown behaviour       what should the dead-man switch's `shutdown` do:
#                            stop the instance (disk keeps costing) or
#                            terminate it (nothing left to pay for)?
#   tags                     Name, so you can recognise it in the console;
#                            Project comes from default_tags
#
# If you ever choose a T-family type (t3.small): T3 instances default to
# "unlimited" CPU credits, which can bill extra for sustained CPU. Set
# credit_specification to "standard".
#
# Do not create an aws_key_pair and do not set key_name. No SSH keys exist in
# this project.
#
# Done when: after `terraform apply`,
#   aws ssm describe-instance-information
# lists the instance as Online within about three minutes, and
#   aws ssm start-session --target <instance-id>
# gives you a shell where `sudo k3s kubectl get nodes` shows one Ready node.
# -----------------------------------------------------------------------------

# TODO(3.4): the instance.
