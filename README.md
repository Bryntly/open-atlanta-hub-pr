# Stack one quote-pipeline PR per fleet app

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` still does that (re-proved 22:42). 22:40 ERMT letter `1a030c885aa9f182` still says **$5,750** / 930 mi / 15 hr.

[ERM #425](https://github.com/BRYNTLY-ORG/ERM/pull/425) **merged 22:35** — keep CI/deploy leftovers as their own stacks. This kit opens **one quote-only PR per app** (Highland hub + SendGrid + moocow-pg). Still no Highland / `quote-pipeline-stack-610b` PR.

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

Keep `2002 Reynolds Dr SW` as dispatch. Do not use ZIP 30307. Do not set `MOOCOW_SITE_INTAKE_KEY`. Do not POST `https://ermtform.com/submit.php`.

Then merge **ERMT** and:

```bash
gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1
```

## Device login for the Cloud Agent

**BC25-3D72** at https://github.com/login/device (expires ~23:03 UTC). Prefer the GITHUB_ACTUAL stacker. Do not enter expired `646E-A9F3`.
