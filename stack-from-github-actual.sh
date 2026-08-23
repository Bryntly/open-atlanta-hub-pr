#!/usr/bin/env bash
# Desktop path for the owner who already has the fleet at
# /Users/pacman/GITHUB_ACTUAL (ERM #425 was built from that tree).
# Worktrees into /tmp/fleet-src. Does not checkout -B on GITHUB_ACTUAL.
# Quote-only (QUOTE_ONLY=1). Does not POST submit.php.
set -euo pipefail

export FLEET_ACTUAL="${FLEET_ACTUAL:-/Users/pacman/GITHUB_ACTUAL}"
export FLEET_SRC="${FLEET_SRC:-/tmp/fleet-src}"
export QUOTE_ONLY="${QUOTE_ONLY:-1}"
export REPOS="${REPOS:-ERMT,ERM,LDMT,MOO_COW,ERM_FORM}"
export HUB_BRANCH="${HUB_BRANCH:-cursor/quote-pipeline-stack-610b}"

if [[ ! -e "${FLEET_ACTUAL}/ERMT/.git" && ! -e "${FLEET_ACTUAL}/ERM/.git" ]]; then
  echo "No fleet checkout at ${FLEET_ACTUAL}." >&2
  echo "ERM #425 used /Users/pacman/GITHUB_ACTUAL. Set FLEET_ACTUAL to that tree." >&2
  exit 2
fi

if [[ "${FLEET_SRC}" == "${FLEET_ACTUAL}" ]]; then
  echo "REFUSE: FLEET_SRC must not be GITHUB_ACTUAL (would trash dirty work)." >&2
  exit 2
fi

echo "Stacking quote-only PRs from ${FLEET_ACTUAL}"
echo "Worktrees: ${FLEET_SRC}  branch: ${HUB_BRANCH}"
echo "Will not checkout -B on GITHUB_ACTUAL."
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stack-fleet-open-prs.sh"
