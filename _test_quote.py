import importlib.util
import subprocess
import sys
import tempfile
from pathlib import Path

src = Path(r"C:\Users\SebastianGorr\rustdesk-build-tools\rustdesk")
raw = subprocess.check_output(["git", "show", "HEAD:src/platform/windows.rs"], cwd=src)
tmp = Path(tempfile.gettempdir()) / "windows_quote_test.rs"
tmp.write_bytes(raw)
spec = importlib.util.spec_from_file_location("q", r".github\patches\quote_windows_reg.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
sys.argv = ["q", str(tmp)]
print("rc", mod.main())
text = tmp.read_text(encoding="utf-8")
print("quoted_share", r'reg add \"{}\" /f /v share_rdp' in text)
print("quoted_hkcr", r'reg add \"HKEY_CLASSES_ROOT\\.{ext}\" /f' in text)
print("quoted_subkey", r'reg add \"{subkey}\" /f' in text)
broken = [
    ln
    for ln in text.splitlines()
    if ('reg add "{' in ln) or ('reg add "HKEY' in ln) or ('reg delete "{' in ln)
]
print("broken", len(broken))
for ln in broken[:8]:
    print(ln.strip()[:140])
