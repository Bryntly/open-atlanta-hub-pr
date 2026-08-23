#!/usr/bin/env bash
# One quote-pipeline PR per fleet app (Highland hub + SendGrid + moocow-pg).
# ERM #425: keep CI/deploy unblockers as their own stacks. Default QUOTE_ONLY=1
# skips leftover CI/ops/alerts/docs/WIP heads so the quote PR can merge.
#
# Open leftovers this stacker will NOT fold (as of 22:26 UTC):
#   ERMT      #779 WIP, #770 Gemini CI, #773 Copilot runner
#   MOO_COW   #1549 ops-ci, #1550 alerts, #1552 warden CI
#   ERM_FORM  #233 Copilot runner, #232 Gemini CI
#   ERM       #425 agent-policy docs (stacking rule lives here)
# Set QUOTE_ONLY=0 to absorb those too. #1545/#1548/#1539/#1551 are closed.
#
# Does not POST ERM_FORM submit.php. Does not set MOOCOW_SITE_INTAKE_KEY.
# Does not remount Cloud Run secrets. Does not close absorbed PRs unless
# CLOSE_ABSORBED=1 (comments a supersede note instead).
#
# Desktop: if /Users/pacman/GITHUB_ACTUAL exists, this worktrees into
# FLEET_SRC (/tmp/fleet-src) and will REFUSE in-place checkout -B on
# those dirty trees (ERM #425). Prefer:
#   FLEET_ACTUAL=/Users/pacman/GITHUB_ACTUAL ./scripts/stack-fleet-open-prs.sh
set -euo pipefail

export HOME="${HOME:-/home/ubuntu}"
ORG="${GITHUB_ORG:-BRYNTLY-ORG}"
DEST="${FLEET_SRC:-/tmp/fleet-src}"
BRANCH="${HUB_BRANCH:-cursor/quote-pipeline-stack-610b}"
# ERMT first: already serves main; $5750 Atlanta letters are ERMT-From drain.
REPOS="${REPOS:-ERMT,ERM,LDMT,MOO_COW,ERM_FORM}"
QUOTE_ONLY="${QUOTE_ONLY:-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_HUB='245+N+Highland+Ave+NE+Atlanta+GA'

# shellcheck source=lib-fleet-actual.sh
source "${SCRIPT_DIR}/lib-fleet-actual.sh"
fleet_detect_actual
if [[ -n "${FLEET_ACTUAL:-}" ]] && fleet_dest_is_actual_inplace "${DEST}" "${FLEET_ACTUAL}"; then
  echo "REFUSE: FLEET_SRC=${DEST} is GITHUB_ACTUAL. Worktrees go in /tmp/fleet-src." >&2
  echo "  FLEET_ACTUAL=${FLEET_ACTUAL} FLEET_SRC=/tmp/fleet-src $0" >&2
  exit 2
fi

is_non_quote_pr() {
  local title="$1"
  [[ "${QUOTE_ONLY}" == "1" ]] || return 1
  case "${title}" in
    *'[WIP]'*|fix\(ci\):*|ci:*|ci\(*|'stack(ops'*|'stack(alerts'*|docs\(agents\)*|docs\(spec\)*)
      return 0
      ;;
  esac
  return 1
}

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

## Quote contract (the reason this exists)

City-string \`Atlanta, GA\` → \`Austin, TX\` must calculate **and** email at fleet **\$5,650** from 3-leg total **1864** (live ERM_FORM \`quotex.php\`). Outbox letters through 21:00 UTC still greet and body **\$5,750** because the Next/PHP pricing hub is \`2002 Reynolds Dr SW\`.

This stack changes only the **pricing** hub:

\`\`\`ts
const ATLANTA_HUB_ADDRESS = "${NEW_HUB}";
\`\`\`

Keep \`2002 Reynolds Dr SW\` / \`2002 Reynolds Drive Southwest\` as dispatch / \`isDispatchBase\` / same-trip (MOO_COW #301). Do not use ZIP 30307 (1871 / \$5750). Do not invent a third schedule. Do not align fleet down to \$5750. Do not set \`MOOCOW_SITE_INTAKE_KEY\` until city Atlanta emails \$5650.

## After merge + Cloud Run Deploy

- Customer SendGrid at the fleet amount (Atlanta **\$5650**, Asheville→Savannah **\$4350**).
- Amount-first internal SendGrid (\`\$5,650.00 - Atlanta…\` then \`Dear {name}\`). \`Bryntly+ops\` OrderDear is **not** internal.
- Next internals need baked \`quote_internal\` + \`SENDGRID_API_KEY\` + \`INTERNAL_EMAIL\` (LDMT #1103 / #1405).
- moocow-pg / central-intake id. Healthy MOO_COW write is 3 \`app.email_outbox\` rows (MOO_COW #944).
- Remount SendGrid with \`--update-secrets\` only. ERM submit-gate is still \`not_configured\`.
- Do not POST \`https://ermtform.com/submit.php\` from an unattended agent.

Deploy **ERMT first** (\`gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1\`).
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
  if ! fleet_prepare_repo "${ORG}" "${repo}" "${DEST}" "${BRANCH}"; then
    echo "FAIL prepare ${repo}" >&2
    failed=$((failed + 1))
    continue
  fi

  default="$(gh api "repos/${ORG}/${repo}" --jq .default_branch)"
  git -C "${root}" fetch origin "${default}"
  git -C "${root}" checkout -B "${BRANCH}" "origin/${default}"

  absorbed_md=""
  absorbed_nums=""
  mapfile -t prs < <(gh pr list --repo "${ORG}/${repo}" --state open --limit 50 \
    --json number,title,headRefName,url --jq 'sort_by(.number)[] | "\(.number)\t\(.headRefName)\t\(.title)\t\(.url)"')

  printf -v tab '\t'
  for row in "${prs[@]}"; do
    [[ -z "${row}" ]] && continue
    num="${row%%${tab}*}"
    rest="${row#*${tab}}"
    head="${rest%%${tab}*}"
    rest2="${rest#*${tab}}"
    title="${rest2%%${tab}*}"
    url="${rest2#*${tab}}"
    if [[ "${head}" == "${BRANCH}" ]]; then
      echo "SKIP #${num} (already ${BRANCH})"
      continue
    fi
    if is_non_quote_pr "${title}"; then
      echo "SKIP #${num} (CI/ops/docs leftover — ERM #425 keeps those separate)"
      continue
    fi
    echo "STACK #${num} ${head}  ${title}"
    if ! git -C "${root}" fetch origin "pull/${num}/head:pr-${num}"; then
      echo "FAIL fetch #${num}" >&2
      continue
    fi
    if git -C "${root}" merge --no-ff --no-edit "pr-${num}"; then
      printf -v absorbed_md '%s- [#%s](%s) %s\n' "${absorbed_md}" "${num}" "${url}" "${title}"
      absorbed_nums="${absorbed_nums} ${num}"
    else
      echo "CONFLICT #${num} — leaving it out of the stack" >&2
      git -C "${root}" merge --abort || true
    fi
  done

  if [[ -x "${SCRIPT_DIR}/rewrite-atlanta-hub.py" ]]; then
    set +e
    python3 "${SCRIPT_DIR}/rewrite-atlanta-hub.py" "${root}"
    rewrite_rc=$?
    set -e
    echo "hub rewrite exit ${rewrite_rc}"
  fi

  if [[ -n "$(git -C "${root}" status --porcelain)" ]]; then
    git -C "${root}" add -u
    git -C "${root}" commit -m "fix(quote): stack Highland hub + open PRs for ${repo}"
  fi

  ahead="$(git -C "${root}" rev-list --count "origin/${default}..HEAD" 2>/dev/null || echo 0)"
  if [[ "${ahead}" -eq 0 ]]; then
    echo "CLEAN ${repo} (no commits ahead of ${default} — not opening an empty PR)"
    continue
  fi

  git -C "${root}" push -u origin "${BRANCH}" --force-with-lease || git -C "${root}" push -u origin "${BRANCH}"

  existing="$(gh pr list --repo "${ORG}/${repo}" --head "${BRANCH}" --state open --json url --jq '.[0].url' || true)"
  if [[ -n "${existing}" && "${existing}" != "null" ]]; then
    echo "PR   ${existing}"
    url="${existing}"
  else
    url="$(gh pr create --repo "${ORG}/${repo}" --base "${default}" --head "${BRANCH}" \
      --title "fix(quote): stack Highland hub + open PRs + SendGrid/moocow-pg" \
      --body "$(pr_body_for "${repo}" "${absorbed_md}")")"
    echo "PR   ${url}"
  fi
  opened=$((opened + 1))

  if [[ -n "${absorbed_nums}" ]]; then
    for num in ${absorbed_nums}; do
      gh pr comment "${num}" --repo "${ORG}/${repo}" --body \
        "Stacked into ${url} so this repo has fewer larger PRs (Highland hub + customer/internal SendGrid + moocow-pg). Leave this one; merge the stack." \
        || true
      if [[ "${CLOSE_ABSORBED:-0}" == "1" ]]; then
        gh pr close "${num}" --repo "${ORG}/${repo}" --comment "Superseded by ${url}" || true
      fi
    done
  fi
done

echo
if [[ -x "${SCRIPT_DIR}/verify-quote-mailer-after-clone.sh" ]]; then
  echo "=== mailer / persist contract (fail-closed) ==="
  FLEET_SRC="${DEST}" bash "${SCRIPT_DIR}/verify-quote-mailer-after-clone.sh" || {
    echo "Mailer/hub contract failed in the clone tree. Stack PRs may still be open — do not merge until verify passes." >&2
    failed=$((failed + 1))
  }
fi

echo
echo "Stacked ${opened} repo PR(s). Failures: ${failed}."
echo "Merge ERMT first, then:"
echo "  gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1"
echo "Remount SendGrid with --update-secrets only if ERM submit-gate is still not_configured."
echo "Do not POST ERM_FORM submit.php. Do not set MOOCOW_SITE_INTAKE_KEY."
if [[ "${opened}" -eq 0 ]]; then
  exit 4
fi
