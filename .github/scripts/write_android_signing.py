#!/usr/bin/env python3
"""Restore the upload keystore and write android/key.properties.

Reads KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD from
the environment. Does not print secret values.

The keystore is written to android/app/keystore/upload-keystore.jks.
storeFile in android/key.properties is an absolute path, which is what
android/app/build.gradle.kts passes to file().
"""

from __future__ import annotations

import base64
import os
import re
import subprocess
import sys
from pathlib import Path

KEYSTORE_RELATIVE = Path("android/app/keystore/upload-keystore.jks")
PROPERTIES_RELATIVE = Path("android/key.properties")
REQUIRED_ENV = (
    "KEYSTORE_BASE64",
    "KEYSTORE_PASSWORD",
    "KEY_ALIAS",
    "KEY_PASSWORD",
)


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def java_properties_escape(value: str) -> str:
    """Escape a value for java.util.Properties.load."""
    out: list[str] = []
    for char in value:
        code = ord(char)
        if char == "\\":
            out.append("\\\\")
        elif char == "\n":
            out.append("\\n")
        elif char == "\r":
            out.append("\\r")
        elif char == "\t":
            out.append("\\t")
        elif char in " #!=:":
            out.append("\\" + char)
        elif code < 0x20 or code > 0x7E:
            out.append(f"\\u{code:04x}")
        else:
            out.append(char)
    return "".join(out)


def decode_keystore(encoded: str) -> bytes:
    compact = re.sub(r"\s+", "", encoded)
    if not compact:
        fail("KEYSTORE_BASE64 is empty")
    try:
        raw = base64.b64decode(compact, validate=True)
    except Exception:
        fail("KEYSTORE_BASE64 is not valid base64")
    if not raw:
        fail("KEYSTORE_BASE64 decoded to an empty keystore")
    return raw


def env_value(name: str) -> str:
    value = os.environ.get(name, "")
    if not value.strip():
        fail(f"{name} is empty")
    return value


def redact(text: str, secrets: list[str]) -> str:
    redacted = text
    for secret in secrets:
        if secret:
            redacted = redacted.replace(secret, "***")
    return redacted


def write_signing() -> Path:
    for name in REQUIRED_ENV:
        env_value(name)
    store_password = os.environ["KEYSTORE_PASSWORD"]
    key_password = os.environ["KEY_PASSWORD"]
    alias = os.environ["KEY_ALIAS"]
    raw = decode_keystore(os.environ["KEYSTORE_BASE64"])

    keystore_path = KEYSTORE_RELATIVE.resolve()
    if not keystore_path.is_absolute():
        fail(f"keystore path {keystore_path} is not absolute")
    keystore_path.parent.mkdir(parents=True, exist_ok=True)
    keystore_path.write_bytes(raw)

    listed = subprocess.run(
        [
            "keytool",
            "-list",
            "-keystore",
            str(keystore_path),
            "-storepass",
            store_password,
            "-alias",
            alias,
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if listed.returncode != 0:
        keystore_path.unlink(missing_ok=True)
        detail = redact((listed.stderr or listed.stdout or "").strip(), [store_password, key_password])
        fail(
            "decoded keystore could not be read with KEYSTORE_PASSWORD and "
            f"KEY_ALIAS.{(' ' + detail) if detail else ''}"
        )

    store_file = str(keystore_path)
    if not Path(store_file).is_absolute():
        keystore_path.unlink(missing_ok=True)
        fail("storeFile is not absolute")

    properties = "\n".join(
        [
            f"storePassword={java_properties_escape(store_password)}",
            f"keyPassword={java_properties_escape(key_password)}",
            f"keyAlias={java_properties_escape(alias)}",
            f"storeFile={java_properties_escape(store_file)}",
            "",
        ]
    )
    PROPERTIES_RELATIVE.write_text(properties, encoding="latin-1")
    print(f"Wrote {keystore_path} ({len(raw)} bytes)")
    print(f"Wrote {PROPERTIES_RELATIVE.resolve()} with absolute storeFile")
    return keystore_path


def main() -> None:
    write_signing()


if __name__ == "__main__":
    main()
