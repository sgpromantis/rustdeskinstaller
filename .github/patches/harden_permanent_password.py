#!/usr/bin/env python3
"""Patch RustDesk 1.4.6 so a hashed custom.txt password cannot be read back.

Must run from the rustdesk source root after checkout.
"""

from __future__ import annotations

import sys
from pathlib import Path

GET_PERMANENT_PASSWORD_OLD = """    pub fn get_permanent_password() -> String {
        let mut password = CONFIG.read().unwrap().password.clone();
        if password.is_empty() {
            if let Some(v) = HARD_SETTINGS.read().unwrap().get("password") {
                password = v.to_owned();
            }
        }
        password
    }"""

GET_PERMANENT_PASSWORD_NEW = """    pub fn get_permanent_password() -> String {
        if let Some(v) = HARD_SETTINGS.read().unwrap().get("password") {
            if v.starts_with("h1:") {
                return "".to_owned();
            }
        }
        let mut password = CONFIG.read().unwrap().password.clone();
        if password.is_empty() {
            if let Some(v) = HARD_SETTINGS.read().unwrap().get("password") {
                password = v.to_owned();
            }
        }
        password
    }"""

GET_SALT_OLD = """    pub fn get_salt() -> String {
        let mut salt = CONFIG.read().unwrap().salt.clone();
        if salt.is_empty() {
            salt = Config::get_auto_password(6);
            Config::set_salt(&salt);
        }
        salt
    }"""

GET_SALT_NEW = """    pub fn get_salt() -> String {
        if let Some(v) = HARD_SETTINGS.read().unwrap().get("password") {
            if let Some(rest) = v.strip_prefix("h1:") {
                if let Some((salt, _)) = rest.split_once(':') {
                    if !salt.is_empty() {
                        return salt.to_owned();
                    }
                }
            }
        }
        let mut salt = CONFIG.read().unwrap().salt.clone();
        if salt.is_empty() {
            salt = Config::get_auto_password(6);
            Config::set_salt(&salt);
        }
        salt
    }"""

VALIDATE_ONE_OLD = """    fn validate_one_password(&self, password: String) -> bool {
        if password.len() == 0 {
            return false;
        }
        let mut hasher = Sha256::new();
        hasher.update(password);
        hasher.update(&self.hash.salt);
        let mut hasher2 = Sha256::new();
        hasher2.update(&hasher.finalize()[..]);
        hasher2.update(&self.hash.challenge);
        hasher2.finalize()[..] == self.lr.password[..]
    }"""

VALIDATE_ONE_NEW = """    fn decode_hex(s: &str) -> Option<Vec<u8>> {
        if s.len() % 2 != 0 {
            return None;
        }
        let mut out = Vec::with_capacity(s.len() / 2);
        let bytes = s.as_bytes();
        let mut i = 0;
        while i < bytes.len() {
            let hi = char::from(bytes[i]).to_digit(16)?;
            let lo = char::from(bytes[i + 1]).to_digit(16)?;
            out.push(((hi << 4) | lo) as u8);
            i += 2;
        }
        Some(out)
    }

    fn validate_hashed_permanent(&self, stored: &str) -> bool {
        let rest = match stored.strip_prefix("h1:") {
            Some(r) => r,
            None => return false,
        };
        let hash_hex = match rest.split_once(':') {
            Some((_, h)) => h,
            None => return false,
        };
        let hash_bytes = match Self::decode_hex(hash_hex) {
            Some(b) if !b.is_empty() => b,
            _ => return false,
        };
        let mut hasher2 = Sha256::new();
        hasher2.update(&hash_bytes);
        hasher2.update(&self.hash.challenge);
        hasher2.finalize()[..] == self.lr.password[..]
    }

    fn validate_one_password(&self, password: String) -> bool {
        if password.len() == 0 {
            return false;
        }
        let mut hasher = Sha256::new();
        hasher.update(password);
        hasher.update(&self.hash.salt);
        let mut hasher2 = Sha256::new();
        hasher2.update(&hasher.finalize()[..]);
        hasher2.update(&self.hash.challenge);
        hasher2.finalize()[..] == self.lr.password[..]
    }"""

VALIDATE_PASSWORD_OLD = """        if password::permanent_enabled() {
            if self.validate_one_password(Config::get_permanent_password()) {
                return true;
            }
        }
        false
    }"""

VALIDATE_PASSWORD_NEW = """        if password::permanent_enabled() {
            if let Some(v) = hbb_common::config::HARD_SETTINGS
                .read()
                .unwrap()
                .get("password")
                .cloned()
            {
                if v.starts_with("h1:") {
                    return self.validate_hashed_permanent(&v);
                }
            }
            if self.validate_one_password(Config::get_permanent_password()) {
                return true;
            }
        }
        false
    }"""


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    matches = text.count(old)
    if matches != 1:
        raise SystemExit(f"expected exactly one match in {path}, found {matches}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"patched {path}")


def main() -> int:
    root = Path(".").resolve()
    config_rs = root / "libs" / "hbb_common" / "src" / "config.rs"
    connection_rs = root / "src" / "server" / "connection.rs"
    if not config_rs.is_file() or not connection_rs.is_file():
        print("Run this script from the rustdesk source root", file=sys.stderr)
        return 1
    replace_once(config_rs, GET_PERMANENT_PASSWORD_OLD, GET_PERMANENT_PASSWORD_NEW)
    replace_once(config_rs, GET_SALT_OLD, GET_SALT_NEW)
    replace_once(connection_rs, VALIDATE_ONE_OLD, VALIDATE_ONE_NEW)
    replace_once(connection_rs, VALIDATE_PASSWORD_OLD, VALIDATE_PASSWORD_NEW)
    return 0


if __name__ == "__main__":
    sys.exit(main())
