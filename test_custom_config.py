#!/usr/bin/env python3
import base64
import hashlib
import json
import unittest

from custom_config import (
    H1_PREFIX,
    apply_password_lock,
    custom_to_base64,
    hash_permanent_password,
)


class HashPermanentPasswordTests(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(hash_permanent_password(""), "")

    def test_already_hashed(self):
        existing = "h1:abc:def"
        self.assertEqual(hash_permanent_password(existing), existing)

    def test_format_and_digest(self):
        hashed = hash_permanent_password("secret", salt="aabb")
        self.assertTrue(hashed.startswith(H1_PREFIX))
        salt, digest = hashed[len(H1_PREFIX) :].split(":", 1)
        self.assertEqual(salt, "aabb")
        expected = hashlib.sha256(b"secret" + b"aabb").hexdigest()
        self.assertEqual(digest, expected)
        self.assertNotIn("secret", hashed)

    def test_apply_lock_strips_plaintext(self):
        custom = apply_password_lock({"approve-mode": "password"}, "secret")
        self.assertTrue(custom["password"].startswith(H1_PREFIX))
        self.assertNotEqual(custom["password"], "secret")
        self.assertEqual(custom["disable-change-permanent-password"], "Y")
        self.assertEqual(custom["hide-security-settings"], "Y")
        self.assertEqual(custom["default-settings"]["allow-remote-config-modification"], "N")
        self.assertEqual(custom["override-settings"]["verification-method"], "use-permanent-password")
        self.assertEqual(custom["override-settings"]["approve-mode"], "password")
        decoded = json.loads(base64.b64decode(custom_to_base64(custom)))
        self.assertNotIn("secret", json.dumps(decoded))


if __name__ == "__main__":
    unittest.main()
