#!/usr/bin/env bash
# Reviewable Highland hub restore. Run from an already-cloned BRYNTLY-ORG/ERMT
# (or ERM). Does not download or pipe remote bash. Rewrites only
# `const ATLANTA_HUB_ADDRESS = "..."`. Leaves dispatch / isDispatchBase
# Reynolds strings alone. Does not POST submit.php.
set -euo pipefail

NEW_HUB='245+N+Highland+Ave+NE+Atlanta+GA'
OLD_HUB='2002+Reynolds+Dr+SW+Atlanta+GA'
BRANCH="${HUB_BRANCH:-cursor/atlanta-hub-highland-610b}"
ROOT="${1:-.}"

cd "${ROOT}"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Run this from a git clone (ERMT first), or pass the clone path." >&2
  exit 2
fi

here="$(pwd -P)"
if [[ "${here}" == *"/GITHUB_ACTUAL/"* && "${ALLOW_ACTUAL_INPLACE:-0}" != "1" ]]; then
  echo "REFUSE: ${here} is a GITHUB_ACTUAL checkout (ERM #425 dirty trees)." >&2
  echo "  FLEET_ACTUAL=/Users/pacman/GITHUB_ACTUAL ./scripts/stack-from-github-actual.sh" >&2
  exit 2
fi

remote_url="$(git remote get-url origin 2>/dev/null || true)"
repo_name="$(basename "${remote_url%.git}")"
echo "REPO ${repo_name}  ${remote_url}"

git fetch origin main
git checkout -B "${BRANCH}" origin/main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t files < <(git grep -l -e 'const ATLANTA_HUB_ADDRESS' -e '2002+Reynolds+Dr+SW+Atlanta+GA' -e '2002 Reynolds Dr SW' -- '*.ts' '*.tsx' '*.php' || true)
if [[ "${#files[@]}" -eq 0 ]]; then
  echo "No pricing hub literals in this clone." >&2
  exit 3
fi

changed=0
for path in "${files[@]}"; do
  echo "FILE ${path}"
  if python3 "${SCRIPT_DIR}/rewrite-atlanta-hub.py" "${path}"; then
    changed=1
  fi
done

echo "--- remaining Reynolds pricing literals (should be none) ---"
git grep -n "ATLANTA_HUB_ADDRESS = \"${OLD_HUB}\"" -- '*.ts' '*.tsx' || echo "none"
echo "--- dispatch Reynolds should still exist if this repo uses it ---"
git grep -n '2002 Reynolds\|isDispatchBase' -- '*.ts' '*.php' '*.js' || echo "no dispatch hits"

if [[ "${changed}" -eq 0 ]]; then
  echo "CLEAN already Highland-class"
  exit 0
fi

git add -u -- "${files[@]}"
git commit -m "fix(quote): price city Atlanta from Highland-class hub"

if [[ "${PUSH_ATLANTA_HUB:-1}" == "1" ]]; then
  git push -u origin "${BRANCH}"
  if command -v gh >/dev/null; then
    gh pr create --base main --head "${BRANCH}" \
      --title 'fix(quote): price city Atlanta from Highland-class hub, not Reynolds SW' \
      --body "$(cat <<'EOF'
City-string `Atlanta, GA` → `Austin, TX` must calculate and email at fleet **$5,650** from 3-leg total **1864** (live ERM_FORM quotex.php).

This changes only the pricing hub:

```ts
const ATLANTA_HUB_ADDRESS = "245+N+Highland+Ave+NE+Atlanta+GA";
```

Keep `2002 Reynolds Dr SW` as dispatch / isDispatchBase / same-trip. Do not use ZIP 30307 (1871 / $5750). Do not invent a third schedule. Do not align fleet down to $5750.

After Cloud Run Deploy on this service: customer letter $5650, amount-first internal (`$5,650.00 - Atlanta…` then `Dear {name}`), and a moocow-pg / central-intake id. `Bryntly+ops` OrderDear is not internal. Remount SendGrid with `--update-secrets` only.
EOF
)" || true
  fi
fi

echo "Next: merge ERMT, then:"
echo "  gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1"
