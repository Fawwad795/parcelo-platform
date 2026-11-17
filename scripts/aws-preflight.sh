#!/usr/bin/env bash
# AWS preflight: read-only checks that catch account problems BEFORE Week 3.
#
# Run this in Week 1 (task 1.2), not on the first day of Week 3. Two of the
# things it checks can take hours or days to fix (a quota increase, an
# account still being verified), and you do not want to discover them when
# you are ready to run `terraform apply`.
#
# It reads account state only. It creates nothing, changes nothing and costs
# nothing.
#
# Usage:
#   aws login                      # once per session, opens a browser
#   scripts/aws-preflight.sh       # uses AWS_REGION, default us-east-1
#   AWS_REGION=ap-south-1 scripts/aws-preflight.sh
#
# Requires AWS CLI v2.32 or newer.

set -uo pipefail

REGION="${AWS_REGION:-us-east-1}"
problems=0

ok() { printf 'OK    %s\n' "$1"; }
bad() {
  printf 'FIX   %s\n' "$1"
  problems=$((problems + 1))
}
info() { printf '      %s\n' "$1"; }

echo "AWS preflight for region $REGION"
echo

# --- 1. Who am I? -----------------------------------------------------------
if ! identity="$(aws sts get-caller-identity --output json 2>&1)"; then
  bad "cannot call AWS. Run 'aws login' first."
  info "$identity"
  exit 1
fi
arn="$(printf '%s' "$identity" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Arn"])')"
account="$(printf '%s' "$identity" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Account"])')"
ok "authenticated as $arn"
if [[ "$arn" == *":root" ]]; then
  bad "you are using the ROOT user for daily work"
  info "Root can do anything, including closing the account. Create an IAM user"
  info "with MFA for everyday use and keep root for billing tasks only."
  info "See assignment/cost-safety.md, section 2."
fi

# --- 2. Which plan is the account on, and how much credit is left? -----------
# On the FREE plan the account cannot be charged: it closes when credits run
# out or after six months. On the PAID plan your card IS charged once credits
# are used up. Knowing which one you are on is the single most important
# cost-safety fact in this assignment.
if plan="$(aws freetier get-account-plan-state --output json 2>&1)"; then
  printf '%s' "$plan" | python3 -c '
import json, sys
p = json.load(sys.stdin)
plan_type = p.get("accountPlanType", "?")
status = p.get("accountPlanStatus", "?")
credits = p.get("accountPlanRemainingCredits") or {}
amount = credits.get("amount", "?")
unit = credits.get("unit", "")
expires = p.get("accountPlanExpirationDate", "n/a")
print(f"OK    account plan: {plan_type} ({status}), credits left: {amount} {unit}, plan ends: {expires}")
if plan_type == "PAID":
    print("NOTE  PAID plan: your card is charged after credits run out. The budget alerts")
    print("      and the end-of-session teardown in assignment/cost-safety.md are not optional.")
'
else
  bad "could not read the account plan (freetier:GetAccountPlanState)"
  info "Check it in the console: Billing and Cost Management home page."
  info "$plan"
fi

# --- 3. Can this account launch a 2 vCPU instance? ----------------------------
# New accounts sometimes start with a Standard On-Demand vCPU quota below 2.
# Every Free Tier eligible instance type has 2 vCPUs, so with a quota of 1
# nothing launches and Terraform fails with VcpuLimitExceeded.
quota="$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A \
  --region "$REGION" --query 'Quota.Value' --output text 2>/dev/null || echo unknown)"
case "$quota" in
  unknown | None | "")
    bad "could not read the EC2 vCPU quota in $REGION"
    info "Check Service Quotas > Amazon EC2 > Running On-Demand Standard instances."
    ;;
  *)
    if python3 -c "import sys; sys.exit(0 if float('$quota') >= 2 else 1)"; then
      ok "EC2 Standard On-Demand vCPU quota in $REGION: $quota (need at least 2)"
    else
      bad "EC2 Standard On-Demand vCPU quota in $REGION is $quota; you need at least 2"
      info "Request an increase now (it can take a day or more):"
      info "  aws service-quotas request-service-quota-increase --service-code ec2 \\"
      info "    --quota-code L-1216C47A --desired-value 4 --region $REGION"
    fi
    ;;
esac

# --- 4. Which instance types may this account use for free-tier credits? ------
types="$(aws ec2 describe-instance-types --region "$REGION" \
  --filters Name=free-tier-eligible,Values=true \
  --query 'InstanceTypes[].InstanceType' --output text 2>/dev/null | tr '\t' ' ')"
if [[ -n "$types" ]]; then
  ok "Free Tier eligible instance types in $REGION: $types"
else
  bad "could not list Free Tier eligible instance types in $REGION"
fi

# --- 5. Is there a budget, so you hear about spending? ------------------------
# The backticks are JMESPath literal syntax, not shell command substitution.
# shellcheck disable=SC2016
budget_count="$(aws budgets describe-budgets --account-id "$account" \
  --query 'length(Budgets || `[]`)' --output text 2>/dev/null || echo unknown)"
case "$budget_count" in
  unknown) bad "could not list budgets (budgets:ViewBudget). Check Billing > Budgets." ;;
  0)
    bad "no AWS Budget exists"
    info "Create one that EXCLUDES credits, or it stays silent while credits drain."
    info "See assignment/cost-safety.md, section 3."
    ;;
  *) ok "$budget_count budget(s) exist (confirm at least one excludes credits)" ;;
esac

echo
if ((problems > 0)); then
  echo "$problems item(s) to fix. Fix them now; some take days to resolve."
  exit 1
fi
echo "Preflight passed. This account is ready for Week 3."
