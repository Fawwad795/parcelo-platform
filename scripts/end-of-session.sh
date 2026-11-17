#!/usr/bin/env bash
# End-of-session cost check: list everything in the account that still costs
# credits, so you never walk away from a running bill.
#
# Run it as the LAST thing in every session that touched AWS, after
# `terraform destroy`. A clean result means there is nothing left to pay for
# in the regions checked. It reads only; it deletes nothing. If it finds
# something, you remove it (preferably with Terraform, so state stays true).
#
# Usage:
#   scripts/end-of-session.sh                       # checks AWS_REGION or us-east-1
#   REGIONS="us-east-1 ap-south-1" scripts/end-of-session.sh
#
# What it looks for, and why each one costs money even when "nothing is running":
#   EC2 instances      running instances bill per second; STOPPED instances
#                      still bill for their disks
#   EBS volumes        billed per GB-month whether attached or not
#   EBS snapshots      billed per GB-month
#   Elastic IPs        every public IPv4 address bills per hour, used or idle
#   NAT gateways       bill per hour plus per GB; the classic surprise bill
#   Load balancers     bill per hour
#   EKS clusters       the control plane bills per hour
#   RDS instances      bill per hour, and storage bills even when stopped

set -uo pipefail

REGIONS="${REGIONS:-${AWS_REGION:-us-east-1}}"
found=0

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Cannot call AWS. Run 'aws login' first." >&2
  exit 2
fi

# report REGION LABEL RESULT: print resources if RESULT is not empty.
report() {
  local region="$1" label="$2" result="$3"
  if [[ -n "$result" && "$result" != "None" ]]; then
    printf 'FOUND  [%s] %s\n' "$region" "$label"
    printf '%s\n' "$result" | sed 's/^/         /'
    found=$((found + 1))
  fi
}

for region in $REGIONS; do
  echo "Checking $region ..."

  # The backticks in --query are JMESPath literal syntax, not shell.
  # shellcheck disable=SC2016
  report "$region" "EC2 instances (not terminated)" "$(aws ec2 describe-instances --region "$region" \
    --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`]|[0].Value]' \
    --output text 2>/dev/null)"

  report "$region" "EBS volumes" "$(aws ec2 describe-volumes --region "$region" \
    --query 'Volumes[].[VolumeId,Size,State]' --output text 2>/dev/null)"

  report "$region" "EBS snapshots owned by this account" "$(aws ec2 describe-snapshots --region "$region" \
    --owner-ids self --query 'Snapshots[].[SnapshotId,VolumeSize,StartTime]' --output text 2>/dev/null)"

  report "$region" "Elastic IP addresses" "$(aws ec2 describe-addresses --region "$region" \
    --query 'Addresses[].[PublicIp,AllocationId,AssociationId]' --output text 2>/dev/null)"

  report "$region" "NAT gateways" "$(aws ec2 describe-nat-gateways --region "$region" \
    --filter Name=state,Values=pending,available \
    --query 'NatGateways[].[NatGatewayId,State]' --output text 2>/dev/null)"

  report "$region" "Load balancers" "$(aws elbv2 describe-load-balancers --region "$region" \
    --query 'LoadBalancers[].[LoadBalancerName,Type,State.Code]' --output text 2>/dev/null)"

  report "$region" "EKS clusters" "$(aws eks list-clusters --region "$region" \
    --query 'clusters[]' --output text 2>/dev/null)"

  report "$region" "RDS instances" "$(aws rds describe-db-instances --region "$region" \
    --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' \
    --output text 2>/dev/null)"
done

echo
# Remaining credits, so you can log the number in NOTES.md after each session.
aws freetier get-account-plan-state \
  --query '{plan: accountPlanType, credits_left: accountPlanRemainingCredits.amount, plan_ends: accountPlanExpirationDate}' \
  --output table 2>/dev/null || echo "(could not read remaining credits; check the Billing console)"

echo
if ((found > 0)); then
  echo "$found kind(s) of billable resource still exist. Remove them before you stop for the day."
  echo "Expected leftovers: the Terraform state bucket (S3) is not listed here and costs"
  echo "well under one cent per month, so it stays."
  exit 1
fi
echo "Nothing billable found in: $REGIONS"
echo "Note: this checks only the regions listed. If you ever worked in another region, check it too."
