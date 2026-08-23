#!/usr/bin/env python3
"""Fail-closed LDMT #1103 internal-send gate in cloned quote-native files.

canDirectSendInternal must skip the internal email_queue row only when the
baked template AND SENDGRID_API_KEY AND INTERNAL_EMAIL are all active.
If the function is true while Cloud Run has no key (ERM submit-gate
not_configured), amount-first internals vanish.

Inserts request-time env guards at the top of canDirectSendInternal.
Leaves the function alone when those checks are already present.
Does not send mail. Does not POST submit.php.
"""
from __future__ import annotations

import pathlib
import re
import sys

TS_NAMES = {"quote-native.ts", "quote-native-core.ts"}
RET = r"(?:\s*:\s*[^{=]+)?"
FUNC_HEAD = re.compile(
    rf"(export\s+)?(async\s+)?function\s+canDirectSendInternal\s*\([^)]*\){RET}\s*\{{"
    rf"|const\s+canDirectSendInternal\s*=\s*(async\s*)?\([^)]*\){RET}\s*=>\s*\{{"
    rf"|(?:export\s+)?const\s+canDirectSendInternal\s*=\s*(async\s+)?function\s*\([^)]*\){RET}\s*\{{",
    re.M,
)
KEY_GUARD = 'if (!(process.env.SENDGRID_API_KEY || "").trim()) return false;'
EMAIL_GUARD = 'if (!(process.env.INTERNAL_EMAIL || "").trim()) return false;'
GUARD_BLOCK = f"\n  {KEY_GUARD}\n  {EMAIL_GUARD}"


def already_gated(body: str) -> bool:
    return "SENDGRID_API_KEY" in body and "INTERNAL_EMAIL" in body


def patch_text(text: str) -> tuple[str, int]:
    patched = 0
    out = text
    for match in reversed(list(FUNC_HEAD.finditer(text))):
        start = match.end()
        window = out[start : start + 1200]
        if already_gated(window):
            continue
        out = out[:start] + GUARD_BLOCK + out[start:]
        patched += 1
    return out, patched


def rewrite_file(path: pathlib.Path) -> int:
    if path.name not in TS_NAMES:
        return 0
    original = path.read_text()
    if "canDirectSendInternal" not in original:
        return 0
    updated, count = patch_text(original)
    if count == 0 or updated == original:
        return 0
    path.write_text(updated)
    print(f"PATCH {path}: canDirectSendInternal now fail-closes without SENDGRID_API_KEY / INTERNAL_EMAIL")
    return count


def walk(root: pathlib.Path) -> int:
    changed = 0
    if root.is_file():
        return rewrite_file(root)
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if "node_modules" in path.parts or ".git" in path.parts:
            continue
        changed += rewrite_file(path)
    return changed


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: rewrite-quote-mailer.py <clone-root-or-file>", file=sys.stderr)
        return 2
    target = pathlib.Path(argv[1])
    if not target.exists():
        print(f"missing {target}", file=sys.stderr)
        return 2
    changed = walk(target)
    if changed:
        print(f"patched {changed} canDirectSendInternal site(s)")
        return 0
    print("no canDirectSendInternal gate inserted (already present or not in tree)")
    return 4


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
