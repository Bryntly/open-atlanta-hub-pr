# Stack one quote-pipeline PR per fleet app

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` still does that (re-proved 23:08). Newest customer mail is still **22:45** ERM_FORM `1a030cd2e2654f25` at **$5,750** / 930 mi / 15 hr. No Highland / `quote-pipeline-stack-610b` PR yet.

[ERM #425](https://github.com/BRYNTLY-ORG/ERM/pull/425) **merged 22:35** — keep CI/deploy leftovers as their own stacks. This kit opens **one quote-only PR per app** (Highland hub + SendGrid + moocow-pg). The stacker now skips leftover `feat(fleet):` / `fix(ollama):` titles ([GITHUB_WORKFLOW_ACTUAL #413](https://github.com/BRYNTLY-ORG/GITHUB_WORKFLOW_ACTUAL/pull/413) / [#412](https://github.com/BRYNTLY-ORG/GITHUB_WORKFLOW_ACTUAL/pull/412)).

## Fastest: you already have `/Users/pacman/GITHUB_ACTUAL`

Do **not** `checkout -B` on those checkouts. Worktree:

```bash
gh repo clone Bryntly/open-atlanta-hub-pr /tmp/hub-kit && cd /tmp/hub-kit
bash ./stack-from-github-actual.sh
```

Or, if this kit is already next to the fleet:

```bash
FLEET_ACTUAL=/Users/pacman/GITHUB_ACTUAL FLEET_SRC=/tmp/fleet-src bash ./stack-fleet-open-prs.sh
```

That worktrees into `/tmp/fleet-src` and refuses in-place on GITHUB_ACTUAL.

## If you do not have GITHUB_ACTUAL

```bash
gh repo clone Bryntly/open-atlanta-hub-pr /tmp/hub-kit && cd /tmp/hub-kit
bash ./stack-fleet-open-prs.sh
```

Or (macOS):

```bash
gh api repos/Bryntly/open-atlanta-hub-pr/contents/open-highland-hub-pr-via-gh.sh --jq .content | base64 -D | bash
```

Do **not** run `python3 open-highland-hub-pr-via-api.py` from an older clone — that copy defaulted to `ERMT,ERM` only and skipped LDMT, MOO_COW, ERM_FORM, `frontend/lib`, and PHP. The copy on `main` now defaults all five apps and shares `rewrite-atlanta-hub.py`. Actions `Open Highland hub PR (Contents API)` already runs the **shell** opener (five apps). Prefer the stacker.

Keep `2002 Reynolds Dr SW` as dispatch. Do not use ZIP 30307. Do not set `MOOCOW_SITE_INTAKE_KEY`. Do not POST `https://ermtform.com/submit.php`.

Then merge **ERMT** and:

```bash
gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1
```

## Device login for the Cloud Agent

**8167-DCB9** at https://github.com/login/device (expires ~23:18 UTC). Prefer the GITHUB_ACTUAL stacker. Do not enter expired `BC25-3D72` or `646E-A9F3`.
