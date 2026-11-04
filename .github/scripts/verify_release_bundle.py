#!/usr/bin/env python3
"""Check an app bundle's version, package, and that it is not debug-signed.

Uses bundletool 1.18.3 for the manifest and keytool for the signer.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

BUNDLETOOL_VERSION = "1.18.3"


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def run_capture(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, check=False, capture_output=True, text=True)


def certificate_is_debug(text: str) -> bool:
    return "CN=Android Debug" in text


def require_bundletool(jar: Path) -> None:
    if not jar.is_file():
        fail(f"bundletool jar not found: {jar}")
    proc = run_capture(["java", "-jar", str(jar), "version"])
    if proc.returncode != 0:
        fail(f"bundletool version check failed:\n{proc.stderr.strip()}")
    got = proc.stdout.strip()
    if got != BUNDLETOOL_VERSION:
        fail(f"expected bundletool {BUNDLETOOL_VERSION}, got {got!r}")
    print(f"bundletool {got}")


def manifest_value(jar: Path, bundle: Path, xpath: str) -> str:
    proc = run_capture(
        [
            "java",
            "-jar",
            str(jar),
            "dump",
            "manifest",
            f"--bundle={bundle}",
            f"--xpath={xpath}",
        ]
    )
    if proc.returncode != 0:
        fail(
            f"bundletool dump manifest failed for {xpath}:\n"
            f"{proc.stderr.strip() or proc.stdout.strip()}"
        )
    return proc.stdout.strip().strip('"')


def signer_text(bundle: Path) -> str:
    proc = run_capture(["keytool", "-printcert", "-jarfile", str(bundle)])
    text = (proc.stdout or "") + (proc.stderr or "")
    if proc.returncode != 0:
        fail(f"keytool could not read the bundle certificate:\n{text.strip()}")
    if "Owner:" not in text:
        fail(f"bundle has no signer certificate:\n{text.strip()}")
    if certificate_is_debug(text):
        fail(f"bundle is debug-signed (CN=Android Debug):\n{text.strip()}")
    return text


def verify(
    bundle: Path,
    bundletool: Path,
    version_code: str,
    version_name: str,
    package: str,
) -> None:
    if not bundle.is_file():
        fail(f"app bundle not found: {bundle}")
    require_bundletool(bundletool)
    code = manifest_value(bundletool, bundle, "/manifest/@android:versionCode")
    name = manifest_value(bundletool, bundle, "/manifest/@android:versionName")
    got_package = manifest_value(bundletool, bundle, "/manifest/@package")
    print(f"manifest versionCode={code} versionName={name} package={got_package}")
    if code != version_code:
        fail(f"versionCode {code!r} != expected {version_code!r}")
    if name != version_name:
        fail(f"versionName {name!r} != expected {version_name!r}")
    if got_package != package:
        fail(f"package {got_package!r} != expected {package!r}")
    text = signer_text(bundle)
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith(("Owner:", "SHA1:", "SHA256:")):
            print(stripped)
    print("Bundle is release-signed and the manifest matches.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", required=True, type=Path)
    parser.add_argument("--bundletool", required=True, type=Path)
    parser.add_argument("--version-code", required=True)
    parser.add_argument("--version-name", required=True)
    parser.add_argument("--package", required=True)
    args = parser.parse_args()
    verify(
        args.bundle,
        args.bundletool,
        args.version_code,
        args.version_name,
        args.package,
    )


if __name__ == "__main__":
    main()
