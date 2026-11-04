#!/usr/bin/env python3
"""Print the Android applicationId as a GitHub Actions output."""

from __future__ import annotations

import re
import sys
from pathlib import Path

GRADLE = Path("android/app/build.gradle.kts")
APPLICATION_ID = re.compile(
    r"""(?m)^[ \t]*applicationId[ \t]*=[ \t]*(['"])([^'"]+)\1[ \t]*$"""
)


def read_application_id(text: str) -> str:
    found = APPLICATION_ID.findall(text)
    ids = [value for _quote, value in found]
    if len(ids) != 1:
        print(
            "error: expected exactly one applicationId in "
            f"{GRADLE}, found {ids or 'none'}",
            file=sys.stderr,
        )
        raise SystemExit(1)
    return ids[0]


def main() -> None:
    if not GRADLE.is_file():
        print(f"error: {GRADLE} not found", file=sys.stderr)
        raise SystemExit(1)
    package = read_application_id(GRADLE.read_text(encoding="utf-8"))
    print(f"package_name={package}")
    print(f"applicationId is {package}", file=sys.stderr)


if __name__ == "__main__":
    main()
