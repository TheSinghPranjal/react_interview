#!/usr/bin/env python3
"""Bump the +build number in pubspec.yaml by 1.

Writes only the version token. Fails before touching the file when the
version has no +build suffix or the build number is not a positive integer
(no leading zeros; 0 is rejected).

On success, prints GitHub Actions outputs and nothing else:

    version=1.0.0+2
    build_name=1.0.0
    build_number=2
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

PUBSPEC = Path("pubspec.yaml")
VERSION_LINE = re.compile(
    r"""(?m)^version:\s*(['"]?)([^'"#\s]+)\1\s*(?:#.*)?$"""
)
NAME_RE = re.compile(r"[0-9A-Za-z][0-9A-Za-z.\-]*")
BUILD_RE = re.compile(r"[1-9][0-9]*")


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_version(raw: str) -> tuple[str, str]:
    if raw.count("+") != 1:
        if "+" not in raw:
            fail(
                f"pubspec version {raw!r} is missing the +build part "
                "(expected a version like 1.0.0+1)"
            )
        fail(
            f"pubspec version {raw!r} must contain exactly one +build suffix"
        )
    name, build = raw.split("+", 1)
    if not NAME_RE.fullmatch(name):
        fail(f"pubspec version name {name!r} is not a plain version (version is {raw!r})")
    if not BUILD_RE.fullmatch(build):
        fail(
            f"pubspec build number {build!r} is not a positive integer "
            f"(version is {raw!r})"
        )
    return name, build


def bump_text(text: str) -> tuple[str, str, str, str]:
    matches = list(VERSION_LINE.finditer(text))
    if len(matches) != 1:
        if not matches:
            fail("pubspec.yaml has no top-level version field")
        fail("pubspec.yaml has more than one top-level version field")
    match = matches[0]
    raw = match.group(2).strip()
    name, build = parse_version(raw)
    new_build = str(int(build) + 1)
    new_version = f"{name}+{new_build}"
    updated = text[: match.start(2)] + new_version + text[match.end(2) :]
    return updated, new_version, name, new_build


def main() -> None:
    if not PUBSPEC.is_file():
        fail("pubspec.yaml not found")
    original = PUBSPEC.read_text(encoding="utf-8")
    updated, new_version, name, new_build = bump_text(original)
    if updated == original:
        fail("version bump did not change pubspec.yaml")
    PUBSPEC.write_text(updated, encoding="utf-8")
    print(f"version={new_version}")
    print(f"build_name={name}")
    print(f"build_number={new_build}")
    print(f"Bumped pubspec version to {new_version}", file=sys.stderr)


if __name__ == "__main__":
    main()
