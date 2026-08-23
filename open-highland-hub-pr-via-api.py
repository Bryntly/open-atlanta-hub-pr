#!/usr/bin/env python3
"""Open Highland hub PRs via the GitHub Contents API (no full clone).

Needs GH_TOKEN with Contents + Pull requests on each BRYNTLY-ORG repo.
Rewrites only `const ATLANTA_HUB_ADDRESS = "..."` in quote-native.ts copies.
Leaves dispatch / isDispatchBase Reynolds strings alone.
Does not POST ERM_FORM submit.php. Does not remount Cloud Run secrets.
"""
from __future__ import annotations

import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request

ORG = os.environ.get("GITHUB_ORG", "BRYNTLY-ORG")
BRANCH = os.environ.get("HUB_BRANCH", "cursor/atlanta-hub-highland-610b")
REPOS = [r.strip() for r in os.environ.get("REPOS", "ERMT,ERM").split(",") if r.strip()]
NEW_HUB = "245+N+Highland+Ave+NE+Atlanta+GA"
PAT = re.compile(r"(const\s+ATLANTA_HUB_ADDRESS\s*=\s*)(['\"])([^'\"]+)\2")
TOKEN = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or os.environ.get("FLEET_GITHUB_TOKEN")
PATHS = [
    "frontend/src/lib/quote-native.ts",
    "next-site/src/lib/quote-native.ts",
]
MAILER_PATHS = [
    "frontend/src/lib/quote-native.ts",
    "next-site/src/lib/quote-native.ts",
    "frontend/scripts/bake-email-templates.ts",
    "frontend/scripts/ingest-email-templates.ts",
    "lib/email/quote_placeholders.php",
    "ldmtqg/calculate.php",
    "api/quote/site-submit.php",
]
MAILER_NEEDLES = (
    "canDirectSendInternal",
    "INTERNAL_EMAIL",
    "SENDGRID_API_KEY",
    "quote_internal",
    "quote_internal_long",
    "MOOCOW:quote_internal",
    "function get_texts",
    "quote_customer",
    "quote_bcc",
)


def api(method: str, path: str, body: dict | None = None):
    if not TOKEN:
        raise SystemExit("GH_TOKEN / FLEET_GITHUB_TOKEN is required")
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        f"https://api.github.com{path}",
        data=data,
        method=method,
        headers={
            "authorization": f"Bearer {TOKEN}",
            "accept": "application/vnd.github+json",
            "x-github-api-version": "2022-11-28",
            "user-agent": "atlanta-hub-highland-restore",
            **({"content-type": "application/json"} if data else {}),
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=45) as res:
            raw = res.read()
            return res.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as err:
        detail = err.read().decode("utf-8", "replace")
        raise RuntimeError(f"{method} {path} -> {err.code}: {detail[:500]}") from err


def ensure_branch(repo: str) -> None:
    _, repo_info = api("GET", f"/repos/{ORG}/{repo}")
    default = repo_info["default_branch"]
    _, ref = api("GET", f"/repos/{ORG}/{repo}/git/ref/heads/{default}")
    sha = ref["object"]["sha"]
    try:
        api("GET", f"/repos/{ORG}/{repo}/git/ref/heads/{BRANCH}")
        print(f"OK   {repo} branch {BRANCH} exists")
        return
    except RuntimeError as err:
        if "404" not in str(err):
            raise
    api("POST", f"/repos/{ORG}/{repo}/git/refs", {"ref": f"refs/heads/{BRANCH}", "sha": sha})
    print(f"NEW  {repo} branch {BRANCH} from {default} {sha[:12]}")


def patch_file(repo: str, path: str) -> bool:
    try:
        _, info = api("GET", f"/repos/{ORG}/{repo}/contents/{path}?ref={BRANCH}")
    except RuntimeError as err:
        if "404" in str(err):
            print(f"SKIP {repo}/{path} (missing)")
            return False
        raise
    text = base64.b64decode(info["content"]).decode()
    match = PAT.search(text)
    if not match:
        print(f"SKIP {repo}/{path} (no ATLANTA_HUB_ADDRESS)")
        return False
    current = match.group(3)
    if current == NEW_HUB:
        print(f"OK   {repo}/{path} already Highland-class")
        return False
    updated = PAT.sub(rf"\1\g<2>{NEW_HUB}\2", text, count=1)
    api(
        "PUT",
        f"/repos/{ORG}/{repo}/contents/{path}",
        {
            "message": "fix(quote): price city Atlanta from Highland-class hub",
            "content": base64.b64encode(updated.encode()).decode(),
            "sha": info["sha"],
            "branch": BRANCH,
        },
    )
    print(f"PATCH {repo}/{path}: {current!r} -> {NEW_HUB!r}")
    return True


def ensure_pr(repo: str) -> None:
    _, pulls = api(
        "GET",
        f"/repos/{ORG}/{repo}/pulls?head={ORG}:{BRANCH}&state=open",
    )
    if pulls:
        print(f"PR   {pulls[0]['html_url']}")
        return
    body = """City-string `Atlanta, GA` → `Austin, TX` must calculate and email at fleet **$5,650** from 3-leg total **1864** (live ERM_FORM quotex.php).

This changes only the pricing hub:

```ts
const ATLANTA_HUB_ADDRESS = \"245+N+Highland+Ave+NE+Atlanta+GA\";
```

Keep `2002 Reynolds Dr SW` as dispatch / isDispatchBase / same-trip. Do not use ZIP 30307 (1871 / $5750). Do not invent a third schedule. Do not align fleet down to $5750.

After Cloud Run Deploy on this service: customer letter $5650, amount-first internal (`$5,650.00 - Atlanta…` then `Dear {name}`), and a moocow-pg / central-intake id. `Bryntly+ops` OrderDear is not internal. Remount SendGrid with `--update-secrets` only.
"""
    _, pr = api(
        "POST",
        f"/repos/{ORG}/{repo}/pulls",
        {
            "title": "fix(quote): price city Atlanta from Highland-class hub, not Reynolds SW",
            "head": BRANCH,
            "base": "main",
            "body": body,
        },
    )
    print(f"PR   {pr.get('html_url')}")


def report_mailer(repo: str) -> None:
    """Read-only contract report (LDMT #1103 / #1405, MOO_COW #944)."""
    print(f"--- {repo} mailer/persist contract ---")
    found_any = False
    for path in MAILER_PATHS:
        try:
            _, info = api("GET", f"/repos/{ORG}/{repo}/contents/{path}?ref=main")
        except RuntimeError as err:
            if "404" in str(err):
                continue
            print(f"FAIL {repo}/{path}: {err}", file=sys.stderr)
            continue
        if not info.get("content"):
            print(f"SKIP {repo}/{path} (empty content field)")
            continue
        text = base64.b64decode(info["content"]).decode()
        hits = [needle for needle in MAILER_NEEDLES if needle in text]
        found_any = True
        print(f"READ {repo}/{path} ({len(text)} bytes) hits={hits or 'none'}")
        if path.endswith("quote-native.ts") and "canDirectSendInternal" in text:
            print(
                "NOTE canDirectSendInternal must stay false unless baked "
                "quote_internal + SENDGRID_API_KEY + INTERNAL_EMAIL are all active. "
                "If it is true while ERM submit-gate is not_configured, internals vanish."
            )
        if "function get_texts" in text:
            print("NOTE healthy MOO_COW write is 3 app.email_outbox rows: quote_customer, quote_bcc, quote_internal.")
    if not found_any:
        print(f"SKIP {repo} mailer files not on main (or token cannot read them)")


def main() -> int:
    patched_any = False
    for repo in REPOS:
        print(f"=== {ORG}/{repo} ===")
        try:
            ensure_branch(repo)
        except RuntimeError as err:
            print(f"FAIL {repo} branch: {err}", file=sys.stderr)
            continue
        changed = False
        for path in PATHS:
            try:
                changed = patch_file(repo, path) or changed
            except RuntimeError as err:
                print(f"FAIL {repo}/{path}: {err}", file=sys.stderr)
        if changed:
            patched_any = True
            try:
                ensure_pr(repo)
            except RuntimeError as err:
                print(f"FAIL {repo} PR: {err}", file=sys.stderr)
        else:
            print(f"CLEAN {repo} (no hub rewrite)")
        try:
            report_mailer(repo)
        except RuntimeError as err:
            print(f"FAIL {repo} mailer report: {err}", file=sys.stderr)
    if not patched_any:
        print("No files patched. Token may lack Contents, or the hub constant was renamed.")
        return 4
    print("Hub PR opened. Amount-first internals and moocow-pg ids are still unproven after 16:06.")
    print("Do not POST ERM_FORM submit.php. Remount SendGrid with --update-secrets only.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
