#!/usr/bin/env bash
# Check that your workstation has the tools each week needs.
#
# This script only LOOKS. It installs nothing and changes nothing. For every
# tool it prints the version it found, or what is missing and where the
# official install instructions are.
#
# Usage:
#   scripts/check-tools.sh          # check everything
#   scripts/check-tools.sh 1        # only what Week 1 needs
#   scripts/check-tools.sh 3        # everything up to and including Week 3
#
# Versions below are the releases that were current when this kit was written
# (2026-11-12, see assignment/verified-versions.md). Newer is normally fine.

set -uo pipefail

UP_TO_WEEK="${1:-5}"
missing=0
warnings=0

note() { printf '      %s\n' "$1"; }

# check WEEK NAME COMMAND INSTALL_URL
# Runs COMMAND to get a version line. Reports OK or MISSING.
check() {
  local week="$1" name="$2" cmd="$3" url="$4" binary out
  ((week > UP_TO_WEEK)) && return 0
  binary="${cmd%% *}"
  if ! command -v "$binary" >/dev/null 2>&1; then
    printf 'MISSING  %-26s (needed from Week %s)\n' "$name" "$week"
    note "install: $url"
    missing=$((missing + 1))
    return 0
  fi
  out="$(bash -c "$cmd" 2>&1 | head -n 1)"
  printf 'OK       %-26s %s\n' "$name" "$out"
}

warn() {
  printf 'WARN     %s\n' "$1"
  warnings=$((warnings + 1))
}

echo "Checking tools needed up to Week $UP_TO_WEEK"
echo

# --- Environment sanity --------------------------------------------------------
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "OK       running inside WSL2"
  case "$PWD" in
    /mnt/*)
      warn "this repo is on the Windows filesystem ($PWD)"
      note "Clone it inside WSL (for example ~/code) instead. Files under /mnt/c are"
      note "slow for Docker and Git and lose Linux permissions, which breaks scripts."
      ;;
  esac
else
  echo "NOTE     not running inside WSL2. The kit assumes WSL2 Ubuntu on Windows;"
  echo "         on native Linux or macOS the commands are the same."
fi
echo

# --- Week 1: Git, containers, Python -------------------------------------------
check 1 "git" "git --version" "https://git-scm.com/downloads/linux"
check 1 "docker" "docker --version" "https://docs.docker.com/desktop/features/wsl/"
check 1 "docker compose (v2+)" "docker compose version" "https://docs.docker.com/compose/install/"
check 1 "python3 (3.12 or 3.13)" "python3 --version" "sudo apt-get install python3 python3-venv"
check 1 "unzip" "unzip -v" "sudo apt-get install unzip"
check 1 "jq" "jq --version" "sudo apt-get install jq"
check 1 "make" "make --version" "sudo apt-get install make"
check 1 "curl" "curl --version" "sudo apt-get install curl"
check 1 "gh (GitHub CLI)" "gh --version" "https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
check 1 "aws (CLI v2.32+ for aws login)" "aws --version" "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"

if ((UP_TO_WEEK >= 1)) && command -v docker >/dev/null 2>&1; then
  if ! docker info >/dev/null 2>&1; then
    warn "docker is installed but the daemon is not reachable"
    note "Start Docker Desktop and enable WSL integration for this distro"
    note "(Settings > Resources > WSL integration), then open a new terminal."
  fi
fi

if ((UP_TO_WEEK >= 1)) && command -v python3 >/dev/null 2>&1; then
  if ! python3 -c "import ensurepip" >/dev/null 2>&1; then
    warn "python3 cannot create virtual environments (ensurepip is missing)"
    note "Ubuntu splits this into its own package: sudo apt-get install python3-venv"
  fi
  if ! python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 12) else 1)"; then
    warn "python3 is older than 3.12. The app is tested on 3.12 and 3.13 only."
  fi
fi

if ((UP_TO_WEEK >= 1)) && command -v aws >/dev/null 2>&1; then
  if aws --version 2>&1 | grep -q '^aws-cli/1\.'; then
    warn "AWS CLI v1 found. This kit needs v2 (the aws login command is v2 only)."
  fi
fi

# --- Week 2: Kubernetes --------------------------------------------------------
check 2 "kind (0.33+)" "kind version" "https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
check 2 "kubectl (1.37.x)" "kubectl version --client" "https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
check 2 "helm (4.x)" "helm version --short" "https://helm.sh/docs/intro/install/"

if ((UP_TO_WEEK >= 2)) && command -v helm >/dev/null 2>&1; then
  if helm version --short 2>/dev/null | grep -q '^v3\.'; then
    warn "Helm 3 found. This kit is written for Helm 4 (flag names differ:"
    note "--rollback-on-failure in Helm 4 replaces --atomic in Helm 3)."
  fi
fi

# --- Week 3: Infrastructure as code and AWS ------------------------------------
check 3 "terraform (1.15+)" "terraform version" "https://developer.hashicorp.com/terraform/install"
check 3 "session-manager-plugin" "session-manager-plugin --version" "https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"

# --- Optional but recommended (SHOULD items) -----------------------------------
echo
echo "Optional tools (used by SHOULD items):"
for tool in pre-commit gitleaks trivy hadolint actionlint zizmor tflint cosign; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'OK       %s\n' "$tool"
  else
    printf 'absent   %s\n' "$tool"
  fi
done

echo
if ((missing > 0)); then
  echo "$missing required tool(s) missing for Week $UP_TO_WEEK. Install them before you start the week."
  exit 1
fi
if ((warnings > 0)); then
  echo "All required tools found, with $warnings warning(s) above."
  exit 0
fi
echo "All required tools found."
