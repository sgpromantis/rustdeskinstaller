#!/usr/bin/env python3
"""Build custom.txt JSON without embedding a recoverable permanent password.

The host is patched at build time (harden_permanent_password.py) so that
password values of the form h1:<salt>:<sha256(password||salt) hex> are
verified without storing plaintext in the installer or the installed app.
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import secrets
import sys
from pathlib import Path
from typing import Any, Dict, Optional

H1_PREFIX = "h1:"
ENV_PATH = Path(__file__).resolve().parent / ".env"


def load_dotenv(path: Optional[Path] = None) -> None:
    env_path = Path(path) if path else ENV_PATH
    if not env_path.is_file():
        return
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and not os.environ.get(key):
            os.environ[key] = value


load_dotenv()


def hash_permanent_password(password: str, salt: Optional[str] = None) -> str:
    if not password:
        return ""
    if password.startswith(H1_PREFIX):
        return password
    if not salt:
        salt = os.environ.get("PERMANENT_PASSWORD_SALT") or secrets.token_hex(16)
    digest = hashlib.sha256(password.encode("utf-8") + salt.encode("utf-8")).hexdigest()
    return f"{H1_PREFIX}{salt}:{digest}"


def apply_password_lock(custom: Dict[str, Any], password: str) -> Dict[str, Any]:
    hashed = hash_permanent_password(password)
    if hashed:
        custom["password"] = hashed
        custom["disable-change-permanent-password"] = "Y"
        custom["hide-security-settings"] = "Y"
        custom["locked-verification-method"] = "Y"
        custom["approve-mode"] = "password"
        defaults = custom.setdefault("default-settings", {})
        defaults["allow-remote-config-modification"] = "N"
        defaults["verification-method"] = "use-permanent-password"
        defaults["approve-mode"] = "password"
        overrides = custom.setdefault("override-settings", {})
        overrides["allow-remote-config-modification"] = "N"
        overrides["verification-method"] = "use-permanent-password"
        overrides["approve-mode"] = "password"
    return custom


def build_promantis_custom(password: str) -> Dict[str, Any]:
    custom: Dict[str, Any] = {
        "app-name": "Promantis Remote",
        "enable-lan-discovery": "Y",
        "direct-server": "N",
        "allow-auto-disconnect": "Y",
        "approve-mode": "password",
        "default-settings": {
            "access-mode": "full",
            "enable-keyboard": "Y",
            "enable-clipboard": "Y",
            "enable-file-transfer": "Y",
            "enable-audio": "Y",
            "enable-tunnel": "Y",
            "enable-remote-restart": "Y",
            "enable-record-session": "N",
            "enable-block-input": "N",
            "allow-remote-config-modification": "N",
        },
    }
    return apply_password_lock(custom, password)


def custom_to_base64(custom: Dict[str, Any]) -> str:
    payload = json.dumps(custom, separators=(",", ":")).encode("ascii")
    return base64.b64encode(payload).decode("ascii")


def main() -> int:
    password = os.environ.get("PERMANENT_PASSWORD", "")
    if not password:
        print("PERMANENT_PASSWORD is not set", file=sys.stderr)
        return 1
    print(custom_to_base64(build_promantis_custom(password)), end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
