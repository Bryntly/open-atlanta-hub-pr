#!/usr/bin/env bash
# Run on a machine already logged into gh as someone who can write BRYNTLY-ORG.
# Prefers the bash Contents-API opener (no python, Mac-safe base64).
# Opens cursor/atlanta-hub-highland-610b on ERMT first, then ERM and MOO_COW.
# Does not POST ERM_FORM submit.php.
set -euo pipefail

# One PR per fleet app. Do not shrink this to a hub-only ERMT/ERM pair.
export REPOS="${REPOS:-ERMT,ERM,LDMT,MOO_COW,ERM_FORM}"
export HUB_BRANCH="${HUB_BRANCH:-cursor/quote-pipeline-stack-610b}"
# Prefer the owner's existing GITHUB_ACTUAL trees via worktrees.
if [[ -z "${FLEET_ACTUAL:-}" && -e /Users/pacman/GITHUB_ACTUAL/ERMT/.git ]]; then
  export FLEET_ACTUAL=/Users/pacman/GITHUB_ACTUAL
  export FLEET_SRC="${FLEET_SRC:-/tmp/fleet-src}"
  echo "Using ${FLEET_ACTUAL} via worktrees at ${FLEET_SRC} (will not checkout -B in-place)."
fi
HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
BASH_SCRIPT="${HERE:+${HERE}/open-highland-hub-pr-via-gh.sh}"
PUBLIC_BASH="https://raw.githubusercontent.com/Bryntly/open-atlanta-hub-pr/main/open-highland-hub-pr-via-gh.sh"

if ! command -v gh >/dev/null; then
  echo "gh is required." >&2
  exit 2
fi
if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "Run: gh auth login -h github.com -s repo,read:org,workflow" >&2
  exit 2
fi

if [[ -z "${BASH_SCRIPT}" || ! -f "${BASH_SCRIPT}" ]]; then
  echo "Fetching open-highland-hub-pr-via-gh.sh"
  tmp="$(mktemp)"
  if ! curl -fsSL "${PUBLIC_BASH}" -o "${tmp}"; then
    gh api repos/Bryntly/atlanta-hub-highland-restore/contents/scripts/open-highland-hub-pr-via-gh.sh \
      --jq .content | tr -d '\n' | {
      if [[ "$(uname -s)" == Darwin ]]; then base64 -D; else base64 -d; fi
    } > "${tmp}"
  fi
  BASH_SCRIPT="${tmp}"
  chmod +x "${BASH_SCRIPT}"
fi

STACK_SCRIPT="${HERE:+${HERE}/stack-fleet-open-prs.sh}"
if [[ -n "${STACK_SCRIPT}" && -f "${STACK_SCRIPT}" ]]; then
  echo "Stacking open PRs + Highland hub into ONE PR per fleet app."
  echo "City Atlanta must email \$5650 / 1864, not \$5750. Keep Reynolds as dispatch."
  bash "${STACK_SCRIPT}"
else
  echo "Opening Highland hub PRs for ${REPOS} (ERMT first)."
  echo "City Atlanta must email \$5650 / 1864, not \$5750. Keep Reynolds as dispatch."
  bash "${BASH_SCRIPT}"
fi
echo
echo "Next: merge the ERMT PR, then"
echo "  gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1"
echo "Then ERM. Remount SendGrid with --update-secrets only. Do not POST submit.php."
