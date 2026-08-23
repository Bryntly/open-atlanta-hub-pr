#!/usr/bin/env bash
# Run on a machine already logged into gh as someone who can write BRYNTLY-ORG.
# Uses the Contents API (no full clone) to open cursor/atlanta-hub-highland-610b
# on ERMT first, then ERM. Does not POST ERM_FORM submit.php.
set -euo pipefail

export REPOS="${REPOS:-ERMT,ERM}"
export HUB_BRANCH="${HUB_BRANCH:-cursor/atlanta-hub-highland-610b}"
HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
SCRIPT="${HERE:+${HERE}/open-highland-hub-pr-via-api.py}"
PUBLIC_PY="https://raw.githubusercontent.com/Bryntly/open-atlanta-hub-pr/main/open-highland-hub-pr-via-api.py"

if ! command -v gh >/dev/null; then
  echo "gh is required." >&2
  exit 2
fi
if ! command -v python3 >/dev/null; then
  echo "python3 is required." >&2
  exit 2
fi

if [[ -z "${GH_TOKEN:-}${FLEET_GITHUB_TOKEN:-}" ]]; then
  if ! gh auth status -h github.com >/dev/null 2>&1; then
    echo "Run: gh auth login -h github.com -s repo,read:org,workflow" >&2
    exit 2
  fi
  GH_TOKEN="$(gh auth token)"
  export GH_TOKEN
fi

if [[ -z "${SCRIPT}" || ! -f "${SCRIPT}" ]]; then
  echo "Fetching open-highland-hub-pr-via-api.py"
  tmp="$(mktemp)"
  if ! curl -fsSL "${PUBLIC_PY}" -o "${tmp}"; then
    gh api repos/Bryntly/atlanta-hub-highland-restore/contents/scripts/open-highland-hub-pr-via-api.py \
      --jq .content | base64 --decode > "${tmp}"
  fi
  SCRIPT="${tmp}"
fi

echo "Opening Highland hub PRs for ${REPOS} (ERMT first)."
echo "City Atlanta must email \$5650 / 1864, not \$5750. Keep Reynolds as dispatch."
python3 "${SCRIPT}"
echo
echo "Next: merge the ERMT PR, then"
echo "  gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1"
echo "Then ERM. Remount SendGrid with --update-secrets only. Do not POST submit.php."
