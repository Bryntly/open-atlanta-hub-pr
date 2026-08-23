# Stack one quote-pipeline PR per fleet app

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` still does that. 21:00 letters still say **$5,750**.

[ERM #425](https://github.com/BRYNTLY-ORG/ERM/pull/425) says keep CI/deploy leftovers as their own stacks. This kit opens **one quote-only PR per app** (Highland hub + SendGrid + moocow-pg).

## Fastest: stacker (reviewable, no remote bash)

```bash
gh repo clone Bryntly/open-atlanta-hub-pr /tmp/hub-kit && cd /tmp/hub-kit
./stack-fleet-open-prs.sh
```

Keep `2002 Reynolds Dr SW` as dispatch. Do not use ZIP 30307. Do not set `MOOCOW_SITE_INTAKE_KEY`. Do not POST `https://ermtform.com/submit.php`.

Then merge **ERMT** and:

```bash
gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1
```

## Device login for the Cloud Agent

**0A40-E94D** at https://github.com/login/device (expires ~22:30 UTC). Do not enter expired `C19C-AAF6`.
