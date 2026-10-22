import unittest

from run_m15_test import classify, first_diagnostic, fix_soc_ifc_dict_initializers


class ResultClassificationTest(unittest.TestCase):
    def test_pass_requires_marker_and_zero_errors(self):
        self.assertEqual(classify("* TESTCASE PASSED\nUVM_ERROR :    0\nUVM_FATAL :    0", 0)[0], "PASS")

    def test_failure_marker_wins(self):
        self.assertEqual(classify("* TESTCASE FAILED", 0)[0], "FAIL")

    def test_missing_pass_marker_is_blocked(self):
        self.assertEqual(classify("simulation ended", 0)[0], "BLOCKED")

    def test_standalone_suite_success_summary_is_pass(self):
        log = "Total tests: 5, Errors: 0\nPASS\nAll tests completed."
        self.assertEqual(classify(log, 0)[0], "PASS")

    def test_standalone_suite_error_summary_is_failure(self):
        log = "Total tests: 5, Errors: 1\nPASS\nAll tests completed."
        self.assertEqual(classify(log, 0)[0], "FAIL")

    def test_pass_word_without_exact_summary_is_not_a_pass(self):
        self.assertEqual(classify("some PASS text", 0)[0], "BLOCKED")

    def test_runtime_diagnostic_is_preserved(self):
        message = "ERROR: testbench: Cannot open input.hex for reading"
        self.assertEqual(classify(message, 0), ("BLOCKED", message))

    def test_nonzero_runtime_is_failure(self):
        self.assertEqual(classify("", 3)[0], "FAIL")

    def test_icarus_sorry_diagnostic_is_preserved(self):
        message = "file.sv:9: sorry: Nested member path not yet supported"
        self.assertEqual(first_diagnostic(message), message)

    def test_missing_include_diagnostic_is_preserved(self):
        message = "file.sv:9: Include file abr_sva.svh not found"
        self.assertEqual(first_diagnostic(message), message)

    def test_soc_ifc_overlay_uses_assignment_patterns_only_for_string_maps(self):
        source = """logic [2:0] first[string] = {
word_addr_t second[string] = {
word_addr_t third[string] = {
dword_t fourth[string] = {
dword_t fifth[string] = {
dword_t sixth[string] = {
word_addr_t seventh[string] = {
dword_t eighth[string] = {
word_addr_t queue[$] = {
"""
        overlaid = fix_soc_ifc_dict_initializers(source)
        self.assertEqual(overlaid.count("[string] = '{"), 8)
        self.assertIn("queue[$] = {", overlaid)

    def test_soc_ifc_overlay_rejects_a_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected 8"):
            fix_soc_ifc_dict_initializers("word_addr_t missing[string] = {\n")


if __name__ == "__main__":
    unittest.main()
