import unittest

from normalize_lms_dccm import normalize_dccm_text


class NormalizeDccmTextTest(unittest.TestCase):
    def test_sign_extended_dccm_address_maps_to_byte_offset(self):
        source = "@FFFFFFFFB0003FF0\nAA bb 00\n"

        normalized, addresses = normalize_dccm_text(source)

        self.assertEqual(normalized, "@00003FF0\nAA bb 00\n")
        self.assertEqual(addresses, [(0xFFFFFFFFB0003FF0, 0x3FF0)])

    def test_existing_relative_address_is_unchanged(self):
        source = "@00000120\n11 22\n"

        normalized, addresses = normalize_dccm_text(source)

        self.assertEqual(normalized, source)
        self.assertEqual(addresses, [(0x120, 0x120)])

    def test_rejects_address_outside_dccm(self):
        with self.assertRaisesRegex(ValueError, "outside the 256 KiB DCCM image"):
            normalize_dccm_text("@FFFFFFFFB0040000\nAA\n")


if __name__ == "__main__":
    unittest.main()
