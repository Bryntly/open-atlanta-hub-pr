# Stack one quote-pipeline PR per fleet app

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` still does that. 21:00 letters still say **$5,750**.

[ERM #425](https://github.com/BRYNTLY-ORG/ERM/pull/425) says keep CI/deploy leftovers as their own stacks. This kit opens **one quote-only PR per app** (Highland hub + SendGrid + moocow-pg). It does **not** fold MOO_COW #1549/#1550, ERMT #779/#770/#773, ERM_FORM #232/#233, or ERM #425.

Contents-API / `gh` openers now also rewrite `frontend/lib/quote-native.ts` (ERM #316). A `frontend/src/lib`-only apply would have left ERM at $5750.

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

## Or one Contents-API command (hub only)

```bash
gh api repos/Bryntly/open-atlanta-hub-pr/contents/open-highland-hub-pr-via-gh.sh --jq .content | base64 -D | bash
```

## Device login for the Cloud Agent

**C19C-AAF6** at https://github.com/login/device (expires ~22:14 UTC). Do not enter expired `1F75-95C5`.
