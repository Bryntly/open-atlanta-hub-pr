# Stack one quote-pipeline PR per fleet app

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` still does that. 21:00 letters still say **$5,750**.

Do **not** open another hub-only micro-PR. Stack every open fleet PR plus the Highland hub into **one** PR per app.

## Fastest: stacker (reviewable, no remote bash)

On a machine already logged into `gh` with org write:

```bash
gh repo clone Bryntly/open-atlanta-hub-pr /tmp/hub-kit && cd /tmp/hub-kit
./stack-fleet-open-prs.sh
```

That absorbs:

- ERMT #779 #770 #773
- MOO_COW #1548 #1545 #1539
- ERM_FORM #233 #232
- ERM / LDMT (no open PRs — still opens the hub + SendGrid + moocow-pg stack)

Keep `2002 Reynolds Dr SW` as dispatch. Do not use ZIP 30307. Do not set `MOOCOW_SITE_INTAKE_KEY`. Do not POST `https://ermtform.com/submit.php`.

Then merge **ERMT** and:

```bash
gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1
```

## Or one Contents-API command (hub only, no PR absorb)

```bash
gh api repos/Bryntly/open-atlanta-hub-pr/contents/open-highland-hub-pr-via-gh.sh --jq .content | base64 -D | bash
```

## Device login for the Cloud Agent

**C19C-AAF6** at https://github.com/login/device (expires ~22:14 UTC). Do not enter expired `1F75-95C5`.

Remount SendGrid with `--update-secrets` only. Amount-first internals need baked `quote_internal` + key + `INTERNAL_EMAIL`. `Bryntly+ops` OrderDear is not internal.
