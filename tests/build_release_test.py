#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Release labels must not change the bootloader's fixed-width product identity."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from build import release_metadata


class ReleaseLabels(unittest.TestCase):
    def test_legacy_labels_remain_compatible(self):
        self.assertEqual(release_metadata("0.9"), ("FM-1_909", "0.9 BETA", "felucca-0.9.fwsc"))
        self.assertEqual(release_metadata("0.9-beta"),
                         ("FM-1_909", "0.9-BETA", "felucca-0.9-beta.fwsc"))

    def test_patch_label_keeps_family_identity(self):
        self.assertEqual(release_metadata("2.8.4-scale1"),
                         ("FM-1_928", "2.8.4-SCALE1 BETA", "felucca-2.8.4-scale1.fwsc"))
        self.assertEqual(release_metadata("2.8.12")[0], release_metadata("2.8")[0])

    def test_rejects_invalid_identity_and_path_components(self):
        for value in ("12.8", "2.18", "2", "2.8.4.1", "2.8/../x", "2.8-scale/1", "2.8-", "2.8\n"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                release_metadata(value)


if __name__ == "__main__":
    unittest.main()
