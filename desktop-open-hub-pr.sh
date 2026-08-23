#!/usr/bin/env bash
# Run on a machine already logged into gh as someone who can write BRYNTLY-ORG.
# Prefers the bash Contents-API opener (no python, Mac-safe base64).
# Opens cursor/atlanta-hub-highland-610b on ERMT first, then ERM.
# Does not POST ERM_FORM submit.php.
set -euo pipefail

export REPOS="${REPOS:-ERMT,ERM}"
export HUB_BRANCH="${HUB_BRANCH:-cursor/atlanta-hub-highland-610b}"
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

echo "Opening Highland hub PRs for ${REPOS} (ERMT first)."
echo "City Atlanta must email \$5650 / 1864, not \$5750. Keep Reynolds as dispatch."
bash "${BASH_SCRIPT}"
echo
echo "Next: merge the ERMT PR, then"
echo "  gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1"
echo "Then ERM. Remount SendGrid with --update-secrets only. Do not POST submit.php."
