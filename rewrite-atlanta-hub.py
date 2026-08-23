#!/usr/bin/env python3
"""Rewrite pricing-hub Reynolds literals to Highland-class.

Leaves dispatch / same-trip Reynolds alone:
- isDispatchBase / isSameTrip / includes() / str_contains identity checks
- "2002 Reynolds Drive Southwest" (MOO_COW #301)
"""
from __future__ import annotations

import pathlib
import re
import sys

NEW = "245+N+Highland+Ave+NE+Atlanta+GA"
OLD = "2002+Reynolds+Dr+SW+Atlanta+GA"
SPACED = "2002 Reynolds Dr SW"
HIGHLAND_SPACED = "245 N Highland Ave NE"
TS_NAMES = {"quote-native.ts", "quote-native-core.ts", "quote-pricing.ts"}
PHP_NAMES = {"calculate.php", "_pricing.php", "distance.php", "quote_helpers.php"}
KNOWN_NAMES = TS_NAMES | PHP_NAMES
HUB_CONST = re.compile(r"(const\s+ATLANTA_HUB_ADDRESS\s*=\s*)(['\"])([^'\"]+)\2")
DISPATCH = re.compile(
    r"isDispatchBase|isSameTrip|same[_-]?trip|routeAddressIdentity|Drive Southwest|includes\(|str_contains",
    re.I,
)
PRICING = re.compile(
    r"ATLANTA_HUB|HUB_ADDRESS|baseAddress|matrix|deadhead|origin|hubTo|toHub|base_to_pickup|dropoff_to_base",
    re.I,
)


def rewrite_line(line: str) -> str:
    if DISPATCH.search(line) and not PRICING.search(line):
        return line
    if OLD in line:
        return line.replace(OLD, NEW)
    if SPACED in line and "Drive Southwest" not in line:
        return line.replace(SPACED, HIGHLAND_SPACED)
    return line


def rewrite_text(text: str) -> tuple[str, list[str]]:
    notes: list[str] = []
    match = HUB_CONST.search(text)
    if match:
        current = match.group(3)
        if current != NEW:
            text = HUB_CONST.sub(rf"\1\g<2>{NEW}\2", text, count=1)
            notes.append(f"ATLANTA_HUB_ADDRESS {current!r} -> {NEW!r}")
    new_text = "\n".join(rewrite_line(line) for line in text.splitlines())
    if text.endswith("\n"):
        new_text += "\n"
    if new_text != text:
        notes.append("non-dispatch Reynolds pricing literals")
        text = new_text
    return text, notes


def rewrite_path(path: pathlib.Path, *, require_known_name: bool = True) -> bool:
    if "node_modules" in path.parts:
        return False
    if require_known_name and path.name not in KNOWN_NAMES:
        return False
    original = path.read_text()
    updated, notes = rewrite_text(original)
    if not notes:
        match = HUB_CONST.search(original)
        if match and match.group(3) == NEW:
            print(f"OK   {path} already Highland-class")
        return False
    path.write_text(updated)
    print(f"PATCH {path}: {'; '.join(notes)}")
    return True


def walk(root: pathlib.Path) -> int:
    changed = 0
    if root.is_file():
        return 1 if rewrite_path(root, require_known_name=False) else 0
    for path in root.rglob("*"):
        if path.is_file() and rewrite_path(path):
            changed += 1
    return changed


if __name__ == "__main__":
    target = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    changed = walk(target)
    print(f"patched {changed} file(s)")
    raise SystemExit(0 if changed else 4)
