#!/usr/bin/env bash
# Open Highland hub PRs with `gh api` only (no python, no full clone).
# Run on a machine already logged into gh as someone who can write BRYNTLY-ORG.
# Default: all five quote apps. Rewrites `const ATLANTA_HUB_ADDRESS`
# and calculate.php Matrix origins. Leaves dispatch / isDispatchBase
# Reynolds strings alone.
# Does not POST ERM_FORM submit.php. Does not remount Cloud Run secrets.
set -euo pipefail

ORG="${GITHUB_ORG:-BRYNTLY-ORG}"
BRANCH="${HUB_BRANCH:-cursor/quote-pipeline-stack-610b}"
REPOS="${REPOS:-ERMT,ERM,LDMT,MOO_COW,ERM_FORM}"
NEW_HUB='245+N+Highland+Ave+NE+Atlanta+GA'

PATHS=(
  frontend/src/lib/quote-native.ts
  frontend/src/lib/quote-native-core.ts
  frontend/lib/quote-native.ts
  frontend/lib/quote-native-core.ts
  next-site/src/lib/quote-native.ts
  next-site/src/lib/quote-native-core.ts
  src/lib/quote-native.ts
  src/lib/quote-native-core.ts
  calculate.php
  ldmtqg/calculate.php
  ermqg/calculate.php
  ermtqg/calculate.php
  api/booking/_pricing.php
)

b64decode() {
  if [[ "$(uname -s)" == Darwin ]]; then
    base64 -D
  else
    base64 -d
  fi
}

b64encode() {
  if [[ "$(uname -s)" == Darwin ]]; then
    base64 | tr -d '\n'
  else
    base64 -w0 2>/dev/null || base64 | tr -d '\n'
  fi
}

if ! command -v gh >/dev/null; then
  echo "gh is required." >&2
  exit 2
fi
if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "Run: gh auth login -h github.com -s repo,read:org,workflow" >&2
  exit 2
fi

patched_any=0

ensure_branch() {
  local repo="$1"
  local default sha
  default="$(gh api "repos/${ORG}/${repo}" --jq .default_branch)"
  sha="$(gh api "repos/${ORG}/${repo}/git/ref/heads/${default}" --jq .object.sha)"
  if gh api "repos/${ORG}/${repo}/git/ref/heads/${BRANCH}" --jq .object.sha >/dev/null 2>&1; then
    echo "OK   ${repo} branch ${BRANCH} exists"
    return 0
  fi
  gh api --method POST "repos/${ORG}/${repo}/git/refs" \
    -f ref="refs/heads/${BRANCH}" \
    -f sha="${sha}" >/dev/null
  echo "NEW  ${repo} branch ${BRANCH} from ${default} ${sha:0:12}"
}

patch_file() {
  local repo="$1" path="$2"
  local sha text current updated encoded
  if ! sha="$(gh api "repos/${ORG}/${repo}/contents/${path}?ref=${BRANCH}" --jq .sha 2>/dev/null)"; then
    echo "SKIP ${repo}/${path} (missing)"
    return 1
  fi
  text="$(gh api "repos/${ORG}/${repo}/contents/${path}?ref=${BRANCH}" --jq .content | tr -d '\n' | b64decode)"
  updated="${text}"
  if printf '%s' "${text}" | grep -q 'const ATLANTA_HUB_ADDRESS'; then
    current="$(printf '%s' "${text}" | sed -n 's/.*const ATLANTA_HUB_ADDRESS = "\([^"]*\)".*/\1/p' | head -1)"
    if [[ "${current}" == "${NEW_HUB}" ]]; then
      echo "OK   ${repo}/${path} already Highland-class"
    else
      updated="$(printf '%s' "${text}" | sed "s/const ATLANTA_HUB_ADDRESS = \"[^\"]*\"/const ATLANTA_HUB_ADDRESS = \"${NEW_HUB}\"/")"
    fi
  elif ! printf '%s' "${text}" | grep -q '2002+Reynolds+Dr+SW+Atlanta+GA\|2002 Reynolds Dr SW'; then
    echo "SKIP ${repo}/${path} (no pricing hub literal)"
    return 1
  fi
  updated="$(printf '%s' "${updated}" | perl -pe '
    next if /isDispatchBase|isSameTrip|Drive Southwest|includes\(|str_contains/;
    s/2002\+Reynolds\+Dr\+SW\+Atlanta\+GA/245+N+Highland+Ave+NE+Atlanta+GA/g;
    s/2002 Reynolds Dr SW/245 N Highland Ave NE/g;
  ')"
  if [[ "${updated}" == "${text}" ]]; then
    echo "OK   ${repo}/${path} already Highland-class"
    return 1
  fi
  current="${current:-Reynolds}"
  encoded="$(printf '%s' "${updated}" | b64encode)"
  gh api --method PUT "repos/${ORG}/${repo}/contents/${path}" \
    -f message='fix(quote): price city Atlanta from Highland-class hub' \
    -f content="${encoded}" \
    -f sha="${sha}" \
    -f branch="${BRANCH}" >/dev/null
  echo "PATCH ${repo}/${path}: ${current} -> ${NEW_HUB}"
  return 0
}

ensure_pr() {
  local repo="$1"
  local existing url base
  existing="$(gh api "repos/${ORG}/${repo}/pulls?head=${ORG}:${BRANCH}&state=open" --jq '.[0].html_url' 2>/dev/null || true)"
  if [[ -n "${existing}" && "${existing}" != "null" ]]; then
    echo "PR   ${existing}"
    return 0
  fi
  base="$(gh api "repos/${ORG}/${repo}" --jq .default_branch)"
  url="$(gh api --method POST "repos/${ORG}/${repo}/pulls" \
    -f title='fix(quote): price city Atlanta from Highland-class hub, not Reynolds SW' \
    -f head="${BRANCH}" \
    -f base="${base}" \
    -f body="$(cat <<'EOF'
City-string `Atlanta, GA` → `Austin, TX` must calculate and email at fleet **$5,650** from 3-leg total **1864** (live ERM_FORM quotex.php).

This changes only the pricing hub:

```ts
const ATLANTA_HUB_ADDRESS = "245+N+Highland+Ave+NE+Atlanta+GA";
```

Keep `2002 Reynolds Dr SW` as dispatch / isDispatchBase / same-trip. Do not use ZIP 30307 (1871 / $5750). Do not invent a third schedule. Do not align fleet down to $5750.

After Cloud Run Deploy on this service: customer letter $5650, amount-first internal (`$5,650.00 - Atlanta…` then `Dear {name}`), and a moocow-pg / central-intake id. `Bryntly+ops` OrderDear is not internal. Remount SendGrid with `--update-secrets` only.
EOF
)" --jq .html_url)"
  echo "PR   ${url}"
}

MAILER_PATHS=(
  frontend/src/lib/quote-native.ts
  frontend/src/lib/quote-native-core.ts
  frontend/lib/quote-native.ts
  frontend/lib/quote-native-core.ts
  next-site/src/lib/quote-native.ts
  next-site/src/lib/quote-native-core.ts
  frontend/scripts/bake-email-templates.ts
  next-site/scripts/bake-email-templates.ts
  lib/email/quote_placeholders.php
  ldmtqg/calculate.php
  ermqg/calculate.php
  ermtqg/calculate.php
  calculate.php
  api/quote/site-submit.php
)

report_mailer() {
  local repo="$1"
  local path text hits n found_any=0
  echo "--- ${repo} mailer/persist contract ---"
  for path in "${MAILER_PATHS[@]}"; do
    if ! text="$(gh api "repos/${ORG}/${repo}/contents/${path}?ref=main" --jq .content 2>/dev/null | tr -d '\n' | b64decode)"; then
      continue
    fi
    found_any=1
    hits=""
    for n in canDirectSendInternal INTERNAL_EMAIL SENDGRID_API_KEY quote_internal quote_internal_long MOOCOW:quote_internal get_texts quote_customer quote_bcc; do
      if printf '%s' "${text}" | grep -Fq "${n}"; then
        hits="${hits} ${n}"
      fi
    done
    echo "READ ${repo}/${path} (${#text} bytes) hits=${hits:- none}"
    if printf '%s' "${text}" | grep -Fq 'canDirectSendInternal'; then
      echo "NOTE canDirectSendInternal must stay false unless baked quote_internal + SENDGRID_API_KEY + INTERNAL_EMAIL are all active."
    fi
    if printf '%s' "${text}" | grep -Fq 'function get_texts'; then
      echo "NOTE healthy MOO_COW write is 3 app.email_outbox rows: quote_customer, quote_bcc, quote_internal."
    fi
  done
  if [[ "${found_any}" -eq 0 ]]; then
    echo "SKIP ${repo} mailer files not on main (or token cannot read them)"
  fi
}

IFS=',' read -r -a repo_list <<<"${REPOS}"
for repo in "${repo_list[@]}"; do
  repo="$(echo "${repo}" | tr -d ' ')"
  [[ -z "${repo}" ]] && continue
  echo "=== ${ORG}/${repo} ==="
  if ! ensure_branch "${repo}"; then
    echo "FAIL ${repo} branch" >&2
    continue
  fi
  changed=0
  for path in "${PATHS[@]}"; do
    if patch_file "${repo}" "${path}"; then
      changed=1
      patched_any=1
    fi
  done
  if [[ "${changed}" -eq 1 ]]; then
    ensure_pr "${repo}"
  else
    echo "CLEAN ${repo} (no hub rewrite)"
  fi
  report_mailer "${repo}" || true
done

if [[ "${patched_any}" -eq 0 ]]; then
  echo "No files patched. Token may lack Contents, or the hub constant was renamed." >&2
  exit 4
fi

echo "Hub PR opened. Amount-first internals and moocow-pg ids are still unproven after 16:06."
echo "Next: merge ERMT, then:"
echo "  gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1"
echo "Do not POST ERM_FORM submit.php. Remount SendGrid with --update-secrets only."
