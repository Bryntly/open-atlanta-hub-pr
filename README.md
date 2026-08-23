# Open the ERMT Highland hub PR

City-string `Atlanta, GA` → `Austin, TX` must email fleet **$5,650** from 3-leg total **1864**. Live ERM_FORM `quotex.php` already does that. 21:00 letters still say **$5,750** because `ATLANTA_HUB_ADDRESS` is `2002 Reynolds Dr SW`.

[MOO_COW #1542](https://github.com/BRYNTLY-ORG/MOO_COW/pull/1542) **merged**. Do **not** set `MOOCOW_SITE_INTAKE_KEY` until this hub is live — those generators still mail $5750.

## Fastest: fresh clone (any directory, no remote bash)

```bash
rm -rf /tmp/ermt-hub && gh repo clone BRYNTLY-ORG/ERMT /tmp/ermt-hub && cd /tmp/ermt-hub
git checkout -B cursor/atlanta-hub-highland-610b origin/main
perl -pi -e 's/const ATLANTA_HUB_ADDRESS = "[^"]*"/const ATLANTA_HUB_ADDRESS = "245+N+Highland+Ave+NE+Atlanta+GA"/' \
  $(git grep -l 'const ATLANTA_HUB_ADDRESS' -- '*.ts')
git diff -U1 -- '*.ts'
git add -u && git commit -m "fix(quote): price city Atlanta from Highland-class hub"
git push -u origin cursor/atlanta-hub-highland-610b
gh pr create --base main --title "fix(quote): price city Atlanta from Highland-class hub, not Reynolds SW"
```

Then the same with `BRYNTLY-ORG/ERM` → `/tmp/erm-hub`. Keep `2002 Reynolds Dr SW` as dispatch. Do not use ZIP 30307. Do not POST `https://ermtform.com/submit.php`.

Then merge ERMT and:

```bash
gcloud run jobs execute deploy-ermt --project eastern-royal-callcenter --region us-east1
```

## Or click Actions

[Actions → Open Highland hub PR (Contents API)](https://github.com/Bryntly/open-atlanta-hub-pr/actions) → Run workflow. Paste a 1-day PAT into **fleet_token**. Delete the PAT after the PR opens.

Remount SendGrid with `--update-secrets` only. Amount-first internals need baked `quote_internal` + key + `INTERNAL_EMAIL`. `Bryntly+ops` OrderDear is not internal.
