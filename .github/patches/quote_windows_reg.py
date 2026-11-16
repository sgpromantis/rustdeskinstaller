"""Quote registry paths in rustdesk src/platform/windows.rs.

Needed when the app name contains a space (e.g. Promantis Remote).
Uses exact string replacements so Git Bash/PowerShell sed cannot mangle Rust strings.
Idempotent.
"""
from pathlib import Path
import sys

REPLACEMENTS = [
    (
        r"reg add HKEY_CLASSES_ROOT\\.{ext}\\shell\\open\\command /f",
        r'reg add \"HKEY_CLASSES_ROOT\\.{ext}\\shell\\open\\command\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\.{ext}\\shell\\open\\command",
        r'reg add \"HKEY_CLASSES_ROOT\\.{ext}\\shell\\open\\command\"',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\.{ext}\\shell\\open /f",
        r'reg add \"HKEY_CLASSES_ROOT\\.{ext}\\shell\\open\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\.{ext}\\shell /f",
        r'reg add \"HKEY_CLASSES_ROOT\\.{ext}\\shell\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\.{ext}\\DefaultIcon /f",
        r'reg add \"HKEY_CLASSES_ROOT\\.{ext}\\DefaultIcon\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\.{ext} /f",
        r'reg add \"HKEY_CLASSES_ROOT\\.{ext}\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\{ext}\\shell\\open\\command /f",
        r'reg add \"HKEY_CLASSES_ROOT\\{ext}\\shell\\open\\command\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\{ext}\\shell\\open /f",
        r'reg add \"HKEY_CLASSES_ROOT\\{ext}\\shell\\open\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\{ext}\\shell /f",
        r'reg add \"HKEY_CLASSES_ROOT\\{ext}\\shell\" /f',
    ),
    (
        r"reg add HKEY_CLASSES_ROOT\\{ext} /f",
        r'reg add \"HKEY_CLASSES_ROOT\\{ext}\" /f',
    ),
    (
        r"reg delete HKEY_CLASSES_ROOT\\.{ext} /f",
        r'reg delete \"HKEY_CLASSES_ROOT\\.{ext}\" /f',
    ),
    (
        r"reg delete HKEY_CLASSES_ROOT\\{ext} /f",
        r'reg delete \"HKEY_CLASSES_ROOT\\{ext}\" /f',
    ),
    (r"reg add {}", r'reg add \"{}\"'),
    (r"reg delete {subkey}", r'reg delete \"{subkey}\"'),
    (r"reg add {subkey}", r'reg add \"{subkey}\"'),
]


def main() -> int:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "src/platform/windows.rs")
    if not path.exists():
        print(f"skip missing {path}")
        return 0
    text = path.read_text(encoding="utf-8")
    if r'reg add \"{}\"' in text:
        print(f"already quoted {path}")
        return 0
    original = text
    for old, new in REPLACEMENTS:
        text = text.replace(old, new)
    if text == original:
        print(f"no registry strings matched in {path}", file=sys.stderr)
        return 1
    path.write_text(text, encoding="utf-8")
    print(f"quoted registry paths in {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
