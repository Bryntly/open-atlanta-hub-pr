# Open the ERMT Highland hub PR

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` already does that. Next/outbox letters still say **$5,750** because `ATLANTA_HUB_ADDRESS` is `2002 Reynolds Dr SW`.

On any machine where `gh` can write `BRYNTLY-ORG/ERMT`:

```bash
curl -fsSL https://raw.githubusercontent.com/Bryntly/open-atlanta-hub-pr/main/desktop-open-hub-pr.sh | bash
```

That uses **your** `gh` token (not the Cloud Agent's >366-day classic PAT). It opens `cursor/atlanta-hub-highland-610b` on **ERMT, then ERM**. Keep Reynolds as dispatch. Do not use ZIP 30307. Do not POST `https://ermtform.com/submit.php`.

Then merge ERMT and:

```bash
gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1
```

Remount SendGrid with `--update-secrets` only. Amount-first internals need baked `quote_internal` + key + `INTERNAL_EMAIL`. `Bryntly+ops` OrderDear is not internal.
