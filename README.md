# Open the ERMT Highland hub PR

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` already does that. Next/outbox letters still say **$5,750** because `ATLANTA_HUB_ADDRESS` is `2002 Reynolds Dr SW` (including ERMT #772 `quote-native-core.ts`).

Copilot on this repo ([PR #1](https://github.com/Bryntly/open-atlanta-hub-pr/pull/1)) failed in 13 seconds. Do not wait on Copilot. [MOO_COW #1542](https://github.com/BRYNTLY-ORG/MOO_COW/pull/1542) is generator smoke, not this hub change.

## Fastest: Desktop curl

On any machine where `gh` can write `BRYNTLY-ORG/ERMT`:

```bash
curl -fsSL https://raw.githubusercontent.com/Bryntly/open-atlanta-hub-pr/main/desktop-open-hub-pr.sh | bash
```

That uses **your** `gh` token (not the Cloud Agent's >366-day classic PAT). It opens `cursor/atlanta-hub-highland-610b` on **ERMT, then ERM**, rewriting `ATLANTA_HUB_ADDRESS` in `quote-native.ts` **and** `quote-native-core.ts`. Keep Reynolds as dispatch. Do not use ZIP 30307. Do not POST `https://ermtform.com/submit.php`.

Then merge ERMT and:

```bash
gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1
```

## Or click Actions

[Actions → Open Highland hub PR (Contents API)](https://github.com/Bryntly/open-atlanta-hub-pr/actions) → Run workflow. Paste a 1-day PAT into **fleet_token** (Contents + Pull requests on `BRYNTLY-ORG/ERMT` and `ERM`). No repo secret required. Delete the PAT after the PR opens.

Remount SendGrid with `--update-secrets` only. Amount-first internals need baked `quote_internal` + key + `INTERNAL_EMAIL`. `Bryntly+ops` OrderDear is not internal.
