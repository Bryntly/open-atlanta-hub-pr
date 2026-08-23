#!/usr/bin/env bash
# Fold every open PR on the five quote apps into ONE larger PR per repo,
# then apply the Highland pricing hub + mailer/persist contract.
# Fewer PRs, not more.
#
# Absorbs (as of 21:59 UTC):
#   ERMT      #779 (quality WIP) + #770 (Gemini CI) + #773 (Copilot runner)
#   MOO_COW   #1548 (CI) + #1545 (ops) + #1539 (alerts draft)
#   ERM_FORM  #233 (Copilot runner) + #232 (Gemini CI)
#   ERM/LDMT  no open PRs — still opens the hub + SendGrid + moocow-pg stack
#
# Does not POST ERM_FORM submit.php. Does not set MOOCOW_SITE_INTAKE_KEY.
set -euo pipefail

export HOME="${HOME:-/home/ubuntu}"
ORG="${GITHUB_ORG:-BRYNTLY-ORG}"
DEST="${FLEET_SRC:-/tmp/fleet-src}"
BRANCH="${HUB_BRANCH:-cursor/quote-pipeline-stack-610b}"
REPOS="${REPOS:-ERMT,ERM,LDMT,MOO_COW,ERM_FORM}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_HUB='245+N+Highland+Ave+NE+Atlanta+GA'

if ! command -v gh >/dev/null; then
  echo "gh is required." >&2
  exit 2
fi
if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "Run: gh auth login -h github.com -s repo,read:org,workflow" >&2
  exit 2
fi
gh auth setup-git >/dev/null

pr_body_for() {
  local repo="$1" absorbed="$2"
  cat <<EOF
## Stack (fewer larger PRs)

One quote-pipeline PR for **${repo}** instead of another micro-PR.

Absorbed open PRs:
${absorbed:-*(none open — this is the hub + mailer + persist stack)*}

## Quote contract

City-string \`Atlanta, GA\` → \`Austin, TX\` must calculate **and** email at fleet **\$5,650** from 3-leg total **1864**.

```ts
const ATLANTA_HUB_ADDRESS = "${NEW_HUB}";
```

Keep Reynolds as dispatch / isDispatchBase. Do not use ZIP 30307. Do not set MOOCOW_SITE_INTAKE_KEY.

Deploy **ERMT first** (`gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1`).
EOF
}

mkdir -p "${DEST}"
opened=0
failed=0
IFS=',' read -r -a repo_list <<<"${REPOS}"
for repo in "${repo_list[@]}"; do
  repo="$(echo "${repo}" | tr -d ' ')"
  [[ -z "${repo}" ]] && continue
  echo "=== ${ORG}/${repo} ==="
  root="${DEST}/${repo}"
  if [[ ! -d "${root}/.git" ]]; then
    if ! gh repo clone "${ORG}/${repo}" "${root}"; then
      echo "FAIL clone ${repo}" >&2
      failed=$((failed + 1))
      continue
    fi
  else
    git -C "${root}" fetch origin --prune
  fi
  default="$(gh api "repos/${ORG}/${repo}" --jq .default_branch)"
  git -C "${root}" fetch origin "${default}"
  git -C "${root}" checkout -B "${BRANCH}" "origin/${default}"
  absorbed_md=""
  absorbed_nums=""
  mapfile -t prs < <(gh pr list --repo "${ORG}/${repo}" --state open --limit 50 --json number,title,headRefName,url --jq 'sort_by(.number)[] | "\(.number)\t\(.headRefName)\t\(.title)\t\(.url)"')
  for row in "${prs[@]}"; do
    [[ -z "${row}" ]] && continue
    num="${row%%$'\t'*}"
    rest="${row#*$'\t'}"
    head="${rest%%$'\t'*}"
    rest2="${rest#*$'\t'}"
    title="${rest2%%$'\t'*}"
    url="${rest2#*$'\t'}"
    if [[ "${head}" == "${BRANCH}" ]]; then
      echo "SKIP #${num} (already ${BRANCH})"
      continue
    fi
    echo "STACK #${num} ${head}  ${title}"
    if ! git -C "${root}" fetch origin "pull/${num}/head:pr-${num}"; then
      echo "FAIL fetch #${num}" >&2
      continue
    fi
    if git -C "${root}" merge --no-ff --no-edit "pr-${num}"; then
      absorbed_md="${absorbed_md}- [#${num}](${url}) ${title}"$'\n'
      absorbed_nums="${absorbed_nums} ${num}"
    else
      echo "CONFLICT #${num} — leaving it out of the stack" >&2
      git -C "${root}" merge --abort || true
    fi
  done
  if [[ -f "${SCRIPT_DIR}/rewrite-atlanta-hub.py" ]]; then
    python3 "${SCRIPT_DIR}/rewrite-atlanta-hub.py" "${root}" || true
  fi
  if [[ -n "$(git -C "${root}" status --porcelain)" ]]; then
    git -C "${root}" add -u
    git -C "${root}" commit -m "fix(quote): stack Highland hub + open PRs for ${repo}"
  fi
  git -C "${root}" push -u origin "${BRANCH}" --force-with-lease || git -C "${root}" push -u origin "${BRANCH}"
  existing="$(gh pr list --repo "${ORG}/${repo}" --head "${BRANCH}" --state open --json url --jq '.[0].url' || true)"
  if [[ -n "${existing}" && "${existing}" != "null" ]]; then
    echo "PR   ${existing}"
    url="${existing}"
  else
    url="$(gh pr create --repo "${ORG}/${repo}" --base "${default}" --head "${BRANCH}" --title "fix(quote): stack Highland hub + open PRs + SendGrid/moocow-pg" --body "$(pr_body_for "${repo}" "${absorbed_md}")")"
    echo "PR   ${url}"
  fi
  opened=$((opened + 1))
  if [[ -n "${absorbed_nums}" ]]; then
    for num in ${absorbed_nums}; do
      gh pr comment "${num}" --repo "${ORG}/${repo}" --body "Stacked into ${url} so this repo has fewer larger PRs. Merge the stack." || true
    done
  fi
done
echo "Stacked ${opened} repo PR(s). Failures: ${failed}."
echo "Merge ERMT first. Do not POST submit.php. Do not set MOOCOW_SITE_INTAKE_KEY."
[[ "${opened}" -gt 0 ]] || exit 4
