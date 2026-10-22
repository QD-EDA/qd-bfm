import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import run_m15_test

from run_m15_test import (
    classify,
    classify_sigdecode_h,
    first_diagnostic,
    fix_butterfly_expected_vector,
    fix_sigdecode_h_tb,
    fix_soc_ifc_dict_initializers,
    stage_test_vectors,
)


class ResultClassificationTest(unittest.TestCase):
    def test_stage_test_vectors_copies_contents_into_runtime_root(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            source = Path(temp_dir) / "tb"
            runtime = Path(temp_dir) / "runtime"
            (source / "test_vectors").mkdir(parents=True)
            runtime.mkdir()
            (source / "test_vectors/input.hex").write_text("1234\n")

            stage_test_vectors(source, runtime)

            self.assertEqual((runtime / "input.hex").read_text(), "1234\n")

    def test_python_alias_runs_python3_from_runtime_path(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            runtime = Path(temp_dir) / "runtime"
            runtime.mkdir()
            env = {"PATH": os.environ["PATH"]}

            run_m15_test.prepare_python_alias(runtime, env)

            self.assertEqual(env["PATH"].split(os.pathsep)[0], str(runtime))
            self.assertTrue((runtime / "python").is_symlink())
            self.assertEqual(
                (runtime / "python").resolve(),
                Path(shutil.which("python3", path=os.environ["PATH"])).resolve(),
            )
            self.assertIn("Python 3.", subprocess.check_output(
                ["python", "--version"], env=env, text=True,
            ))

    def test_only_rows_with_known_missing_includes_get_extra_include_dirs(self):
        root = Path("/pinned/adams-bridge")
        self.assertEqual(
            run_m15_test.include_dirs_for_area("norm_check", root),
            [root / "src/abr_libs/rtl"],
        )
        self.assertEqual(
            run_m15_test.include_dirs_for_area("decompose", root),
            [root / "src/abr_prim/rtl", root / "src/abr_libs/rtl"],
        )
        self.assertEqual(run_m15_test.include_dirs_for_area("sig_encode_z", root), [])

    def test_norm_check_overlay_replaces_only_the_three_undefined_width_uses(self):
        source = "src_base [MLDSA_MEM_ADDR_WIDTH];\n.ADDR_WIDTH(MLDSA_MEM_ADDR_WIDTH)\ntask arg(MLDSA_MEM_ADDR_WIDTH);\n"
        expected = source.replace("MLDSA_MEM_ADDR_WIDTH", "ABR_MEM_ADDR_WIDTH")
        self.assertEqual(run_m15_test.fix_norm_check_mem_addr_width(source), expected)

    def test_norm_check_overlay_rejects_a_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected 3"):
            run_m15_test.fix_norm_check_mem_addr_width("MLDSA_MEM_ADDR_WIDTH\n")

    def test_skdecode_overlay_fixes_width_and_odd_address_negative_case(self):
        source = (
            "reg [MLDSA_MEM_ADDR_WIDTH-1:0] dest_base_tb;\n"
            "MLDSA_MEM_ADDR_WIDTH'(0)\n"
            "        if (keymem_b_rd_req_tb.rd_wr_en == RW_READ) begin\n"
            "            keymem_b_data_tb <= s1_array_tb[keymem_b_rd_req_tb.addr];\n"
            "        end\n"
            "        if (keymem_b_rd_req_tb.rd_wr_en == RW_READ)\n"
            "            keymem_b_data_tb <= s1_array_tb[keymem_b_rd_req_tb.addr];\n"
        )
        expected = (
            "reg [ABR_MEM_ADDR_WIDTH-1:0] dest_base_tb;\n"
            "ABR_MEM_ADDR_WIDTH'(0)\n"
            "        if (keymem_b_rd_req_tb.rd_wr_en == RW_READ) begin\n"
            "            keymem_b_data_tb <= s1_array_tb[keymem_b_rd_req_tb.addr];\n"
            "        end\n"
            "        if (keymem_b_rd_req_tb.rd_wr_en == RW_READ) begin\n"
            "            if (rand_address == keymem_b_rd_req_tb.addr)\n"
            "                keymem_b_data_tb <= $urandom_range(5,7);\n"
            "            else\n"
            "                keymem_b_data_tb <= s1_array_tb[keymem_b_rd_req_tb.addr];\n"
            "        end\n"
        )
        self.assertEqual(run_m15_test.fix_skdecode_tb(source), expected)

    def test_skdecode_overlay_rejects_a_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected 2"):
            run_m15_test.fix_skdecode_tb("MLDSA_MEM_ADDR_WIDTH\n")

    def test_skdecode_overlay_rejects_a_changed_error_port_block(self):
        source = "MLDSA_MEM_ADDR_WIDTH\nMLDSA_MEM_ADDR_WIDTH\n"
        with self.assertRaisesRegex(RuntimeError, "B-port error injection block"):
            run_m15_test.fix_skdecode_tb(source)

    def test_sigdecode_h_overlay_replaces_only_its_missing_address_width(self):
        source = "logic [MLDSA_MEM_ADDR_WIDTH-1:0] dest_base_addr;\n"
        self.assertEqual(
            fix_sigdecode_h_tb(source),
            "logic [ABR_MEM_ADDR_WIDTH-1:0] dest_base_addr;\n",
        )

    def test_sigdecode_h_overlay_rejects_a_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected 1"):
            fix_sigdecode_h_tb(
                "logic [MLDSA_MEM_ADDR_WIDTH-1:0] a;\n"
                "logic [MLDSA_MEM_ADDR_WIDTH-1:0] b;\n"
            )

    def test_sigdecode_h_marker_requires_a_clean_completion(self):
        self.assertEqual(classify_sigdecode_h("Test passed\n", 0)[0], "PASS")
        self.assertEqual(classify_sigdecode_h("Test passed\nERROR: bitmap mismatch\n", 0)[0], "FAIL")
        self.assertEqual(classify_sigdecode_h("Test passed\nSigdecode error. Test failed!\n", 0)[0], "FAIL")
        self.assertEqual(classify_sigdecode_h("simulation ended\n", 0)[0], "BLOCKED")

    def test_norm_check_completion_without_errors_is_pass(self):
        log = "Norm check for z is successful\nCtrl test done\n"
        self.assertEqual(classify(log, 0)[0], "PASS")

    def test_norm_check_error_overrides_completion_marker(self):
        log = "ERROR: Expected invalid result\nCtrl test done\n"
        self.assertEqual(classify(log, 0)[0], "FAIL")

    def test_decompose_completion_requires_both_modes_to_pass(self):
        log = "Decompose success\nDecompose + usehint success\n"
        self.assertEqual(classify(log, 0)[0], "PASS")
        self.assertEqual(classify("Decompose success\n", 0)[0], "BLOCKED")

    def test_decompose_error_overrides_success_markers(self):
        log = "ERROR: r1 does not match\nDecompose success\nDecompose + usehint success\n"
        self.assertEqual(classify(log, 0)[0], "FAIL")

    def test_decompose_failure_marker_is_fail(self):
        self.assertEqual(classify("Decompose failed\n", 0)[0], "FAIL")

    def test_decompose_overlay_fixes_only_width_and_stale_port(self):
        source = """module decompose_tb;
reg [MLDSA_MEM_ADDR_WIDTH-1:0] src_base_tb, dest_base_tb;
decompose dut(
    .decompose_done(),
    .w1_encode_done()
);
endmodule
"""
        expected = source.replace("MLDSA_MEM_ADDR_WIDTH", "ABR_MEM_ADDR_WIDTH").replace(
            "    .decompose_done(),\n    .w1_encode_done()\n);",
            "    .decompose_done()\n);",
        )
        self.assertEqual(run_m15_test.fix_decompose_tb(source), expected)

    def test_decompose_overlay_rejects_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected 1"):
            run_m15_test.fix_decompose_tb("module decompose_tb;\nendmodule\n")

    def test_pass_requires_marker_and_zero_errors(self):
        self.assertEqual(classify("* TESTCASE PASSED\nUVM_ERROR :    0\nUVM_FATAL :    0", 0)[0], "PASS")

    def test_failure_marker_wins(self):
        self.assertEqual(classify("* TESTCASE FAILED", 0)[0], "FAIL")

    def test_explicit_adams_bridge_mismatch_is_fail(self):
        message = "Error: Output mismatch at index 256. Expected: 575be, Got: xxxxx"
        self.assertEqual(classify(message, 0)[0], "FAIL")
        self.assertEqual(classify("generic mismatch occurred", 0)[0], "BLOCKED")

    def test_adams_bridge_operation_failure_is_fail(self):
        for message in (
            "Test failed at NTT operation",
            "Test failed at INTT operation",
        ):
            with self.subTest(message=message):
                self.assertEqual(classify(message, 0)[0], "FAIL")

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

    def test_butterfly_overlay_loads_expected_output_into_output_array(self):
        source = '$readmemh("kyber_stage0_out.hex", in_val);\n'
        self.assertEqual(
            fix_butterfly_expected_vector(source),
            '$readmemh("kyber_stage0_out.hex", out_val);\n',
        )

    def test_butterfly_overlay_rejects_a_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected one"):
            fix_butterfly_expected_vector("$readmemh(\"other.hex\", in_val);\n")


if __name__ == "__main__":
    unittest.main()
