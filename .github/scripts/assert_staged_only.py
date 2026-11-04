#!/usr/bin/env python3
"""Fail unless the git index contains exactly the given paths, in order.

The version-bump commit must stage only pubspec.yaml. Call this after
`git add -- pubspec.yaml` and before `git commit`.
"""

from __future__ import annotations

import subprocess
import sys


def staged_paths() -> list[str]:
    out = subprocess.check_output(["git", "diff", "--cached", "--name-only", "-z"])
    return [part.decode() for part in out.split(b"\0") if part]


def main() -> None:
    expected = sys.argv[1:] or ["pubspec.yaml"]
    found = staged_paths()
    if found != expected:
        shown = "\n".join(found) if found else "<nothing>"
        print(
            "error: commit must stage ONLY "
            + " ".join(expected)
            + f"; staged:\n{shown}",
            file=sys.stderr,
        )
        raise SystemExit(1)
    print("Staged only: " + " ".join(found))


if __name__ == "__main__":
    main()
