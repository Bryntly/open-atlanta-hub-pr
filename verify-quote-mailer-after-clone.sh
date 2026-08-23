#!/usr/bin/env bash
# After the fleet clone, fail loud if the customer / internal / persist
# contract is missing from source. Does not send mail. Does not POST
# ERM_FORM submit.php. Does not remount Cloud Run secrets.
#
# Proven from PR bodies (file APIs still 403 on PAT 2837364105):
# - LDMT #1405: 9-template bake from moocow-pg. Candidate chain
#   quote_internal → quote_internal_long → quote_internal_short →
#   MOOCOW:quote_internal. Live bake: LDMT/ERMT share MOOCOW:quote_internal
#   (619B); ERM uses quote_internal_long (15064B).
# - LDMT #1103: canDirectSendInternal skips the internal email_queue row
#   only when baked template + SENDGRID_API_KEY + INTERNAL_EMAIL are all
#   active. Direct-send failure must insert the legacy fallback row.
# - MOO_COW #944: healthy write is 3 app.email_outbox rows
#   (quote_customer, quote_bcc, quote_internal). ldmtqg used to persist
#   with zero emails when get_texts() was not loaded.
set -euo pipefail

DEST="${FLEET_SRC:-/tmp/fleet-src}"
missing=0

if [[ ! -d "${DEST}" ]]; then
  echo "No clone tree at ${DEST}." >&2
  exit 2
fi

echo "=== quote mailer / persist contract in ${DEST} ==="
echo "Customer letter: OrderDear {name}. Internal: amount-first then Dear {name}."
echo "Do not treat Bryntly+ops OrderDear as internals."
echo

check_file() {
  local path="$1"
  local label="$2"
  if [[ -f "${path}" ]]; then
    echo "OK   ${label}: ${path#${DEST}/}"
    return 0
  fi
  echo "MISS ${label}: ${path#${DEST}/}"
  missing=$((missing + 1))
  return 1
}

search_hits() {
  local path="$1"
  local pattern="$2"
  if command -v rg >/dev/null; then
    rg -n --no-heading -e "${pattern}" "${path}"
  else
    grep -nE "${pattern}" "${path}"
  fi
}

need_hit() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [[ ! -f "${path}" ]]; then
    return 0
  fi
  if search_hits "${path}" "${pattern}" >/dev/null; then
    echo "OK   ${label}"
    search_hits "${path}" "${pattern}" | head -8
    return 0
  fi
  echo "MISS ${label} in ${path#${DEST}/}"
  missing=$((missing + 1))
}

for repo in ERMT ERM LDMT; do
  root="${DEST}/${repo}"
  [[ -d "${root}" ]] || { echo "SKIP ${repo} (no clone)"; continue; }
  echo
  echo "--- ${repo} ---"
  if [[ -f "${root}/frontend/src/lib/quote-native.ts" || -f "${root}/frontend/lib/quote-native.ts" || -f "${root}/next-site/src/lib/quote-native.ts" || -f "${root}/next-site/src/lib/quote-native-core.ts" ]]; then
    echo "OK   quote-native (frontend/src, frontend/lib, or next-site)"
  else
    echo "MISS quote-native in ${repo}"
    missing=$((missing + 1))
  fi
  check_file "${root}/frontend/scripts/bake-email-templates.ts" "pg bake" || \
    check_file "${root}/next-site/scripts/bake-email-templates.ts" "pg bake (next-site)" || \
    check_file "${root}/frontend/scripts/ingest-email-templates.ts" "ingest trampoline"
  for bake in \
    "${root}/frontend/scripts/bake-email-templates.ts" \
    "${root}/next-site/scripts/bake-email-templates.ts"
  do
    [[ -f "${bake}" ]] || continue
    need_hit "${bake}" 'quote_internal' "bake lists quote_internal"
    need_hit "${bake}" 'quote_internal_long|quote_internal_short|MOOCOW:quote_internal' \
      "bake keeps the #1405 candidate chain"
    need_hit "${bake}" 'REQUIRED_TEMPLATES' "REQUIRED_TEMPLATES present"
  done
  mailer_hit=0
  for lib in \
    "${root}/frontend/src/lib/quote-native.ts" \
    "${root}/frontend/src/lib/quote-native-core.ts" \
    "${root}/frontend/lib/quote-native.ts" \
    "${root}/frontend/lib/quote-native-core.ts" \
    "${root}/next-site/src/lib/quote-native.ts" \
    "${root}/next-site/src/lib/quote-native-core.ts"
  do
    [[ -f "${lib}" ]] || continue
    if search_hits "${lib}" 'const[[:space:]]+ATLANTA_HUB_ADDRESS[[:space:]]*=[[:space:]]*"2002\+Reynolds' >/dev/null; then
      echo "MISS pricing hub still Reynolds in ${lib#${DEST}/}"
      missing=$((missing + 1))
    elif search_hits "${lib}" 'const[[:space:]]+ATLANTA_HUB_ADDRESS[[:space:]]*=[[:space:]]*"245\+N\+Highland' >/dev/null; then
      echo "OK   pricing hub Highland-class in ${lib#${DEST}/}"
    fi
    if search_hits "${lib}" 'canDirectSendInternal|INTERNAL_EMAIL|SENDGRID_API_KEY|quote_internal' >/dev/null; then
      echo "OK   submit path mentions internal send (#1103) in ${lib#${DEST}/}"
      mailer_hit=1
    fi
  done
  if [[ "${mailer_hit}" -eq 0 ]]; then
    echo "MISS ${repo} has no canDirectSendInternal / INTERNAL_EMAIL / quote_internal mention"
    missing=$((missing + 1))
  fi
done

if [[ -d "${DEST}/MOO_COW" ]]; then
  echo
  echo "--- MOO_COW ---"
  check_file "${DEST}/MOO_COW/lib/email/quote_placeholders.php" "get_texts helper"
  check_file "${DEST}/MOO_COW/ldmtqg/calculate.php" "ldmtqg calculator"
  check_file "${DEST}/MOO_COW/api/quote/site-submit.php" "central site-submit"
  need_hit "${DEST}/MOO_COW/lib/email/quote_placeholders.php" 'function get_texts' \
    "quote_placeholders declares get_texts (#944)"
  if [[ -f "${DEST}/MOO_COW/ldmtqg/calculate.php" ]]; then
    need_hit "${DEST}/MOO_COW/ldmtqg/calculate.php" 'quote_placeholders|get_texts' \
      "ldmtqg loads get_texts so autosubmit cannot silent-return"
  fi
  echo "Healthy generator write = 3 app.email_outbox rows: quote_customer, quote_bcc, quote_internal."
fi

if [[ -d "${DEST}/ERM_FORM" ]]; then
  echo
  echo "--- ERM_FORM ---"
  check_file "${DEST}/ERM_FORM/quotex.php" "quotex calculator"
  check_file "${DEST}/ERM_FORM/submit.php" "submit (do not POST live)"
  echo "Live quotex already prices Atlanta city-string 1864 / \$5650. Do not POST submit.php."
fi

echo
echo "=== Next-direct vs PHP drain ==="
echo "ERM submit-gate email.ok:false / not_configured means SENDGRID_API_KEY is not mounted."
echo "Remount with --update-secrets only: ./scripts/inspect-cloud-run-sendgrid.sh remount"
echo "LDMT #1103: if canDirectSendInternal is true while the key is missing, the"
echo "internal queue row is skipped and no amount-first letter lands. After clone,"
echo "canDirectSendInternal must be false unless template + key + INTERNAL_EMAIL are all present."
echo "PHP email-drainer only sends customer OrderDear unless outbox also has quote_internal."

echo
if [[ "${missing}" -gt 0 ]]; then
  echo "Mailer contract has ${missing} missing check(s). Fix in the clone tree before deploy."
  exit 4
fi
echo "Source contract checks passed. Still unproven in production: amount-first internals after 16:06, and SQL persist ids."
echo "Do not mark the five-app goal complete from this script."
