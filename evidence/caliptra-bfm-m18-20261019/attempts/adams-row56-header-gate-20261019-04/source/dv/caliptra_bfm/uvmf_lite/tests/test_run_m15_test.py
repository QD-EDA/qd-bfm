import os
import json
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

import run_m15_test

from run_m15_test import (
    classify,
    classify_pkdecode,
    classify_skencode,
    classify_sigdecode_h,
    first_diagnostic,
    fix_butterfly_expected_vector,
    fix_compress_tb_filelist,
    fix_compress_tb_testbench,
    fix_csrng_tb_filelist,
    fix_mldsa_ahb_transfer_types,
    fix_mldsa_ahb_transfer_type_aliases,
    fix_mldsa_config_rm_access,
    fix_mldsa_environment,
    fix_mldsa_env_configuration,
    fix_mldsa_kem_fatals,
    fix_mldsa_predictor,
    fix_mldsa_reg_model_endian,
    fix_mldsa_scoreboard,
    fix_mldsa_substr,
    fix_makehint_tb,
    fix_ntt_top_masking_tb,
    fix_pkdecode_tb,
    fix_skencode_tb,
    fix_sigdecode_h_tb,
    fix_sigdecode_z_tb,
    fix_kv_factory_sequence_base,
    fix_soc_ifc_tb_pkg,
    should_drop_axi4pc_stub,
    needs_m16_open_mvc_filelist,
    needs_mldsa_reference_model,
    prepare_adams_mldsa_filelist,
    prepare_m16_mldsa_icarus_overlays,
    prepare_uart_filelist,
    rewrite_m17_aaxi_filelist,
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

    def test_sigdecode_z_overlay_fixes_only_width_and_unused_call_arguments(self):
        source = (
            "parameter MEM_ADDR_WIDTH = MLDSA_MEM_ADDR_WIDTH;\n"
            "sigdecode_z_test('h0,'h0);\n"
            "sigdecode_z_test('h40, 'h20);\n"
            'if (actual !== expected) $display("Error: Output mismatch at index %0d", i);\n'
        )
        expected = (
            "parameter MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH;\n"
            "sigdecode_z_test('h0);\n"
            "sigdecode_z_test('h20);\n"
            'if (actual !== expected) $display("Error: Output mismatch at index %0d", i);\n'
        )
        self.assertEqual(fix_sigdecode_z_tb(source), expected)

    def test_sigdecode_z_overlay_rejects_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected one"):
            fix_sigdecode_z_tb("module sigdecode_z_tb; endmodule\n")

    def test_pkdecode_overlay_only_fixes_testbench_width_and_stale_parameter(self):
        source = (
            "module pkdecode_tb import abr_params_pkg::*;\n"
            "parameter MEM_ADDR_WIDTH = MLDSA_MEM_ADDR_WIDTH,\n"
            "pkdecode #(\n"
            "    .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),\n"
            "    .MLDSA_K(MLDSA_K)\n"
            ") dut ();\n"
            "if (actual_output_mem[i] !== expected_output_mem[i]) $display(\"Error: Output mismatch\");\n"
            "pkdecode_test('h0, 'h0);\n"
            "pkdecode_test('h40, 'h20);\n"
        )
        expected = (
            "module pkdecode_tb import abr_params_pkg::*;\n"
            "parameter MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH,\n"
            "pkdecode #(\n"
            "    .MLDSA_K(MLDSA_K)\n"
            ") dut ();\n"
            "if (actual_output_mem[i] !== expected_output_mem[i]) $display(\"Error: Output mismatch\");\n"
            "pkdecode_test('h0, 'h0);\n"
            "pkdecode_test('h40, 'h0);\n"
        )
        self.assertEqual(fix_pkdecode_tb(source), expected)

    def test_pkdecode_overlay_rejects_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected one pinned PKDecode"):
            fix_pkdecode_tb("module pkdecode_tb; endmodule\n")

    def test_skencode_overlay_uses_exported_width_and_existing_dut_error_flag(self):
        source = (
            "parameter MEM_ADDR_WIDTH = MLDSA_MEM_ADDR_WIDTH,\n"
            "skencode #(\n"
            "    .clk(clk_tb),\n"
            "    .skencode_done(skencode_done_tb),\n"
            "    .skencode_error(skencode_error_tb)\n"
            ");\n"
        )
        expected = (
            "parameter MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH,\n"
            "skencode #(\n"
            "    .clk(clk_tb),\n"
            "    .skencode_done(skencode_done_tb)\n"
            ");\n\n"
            "assign skencode_error_tb = dut.error_flag;\n"
        )
        self.assertEqual(fix_skencode_tb(source), expected)

    def test_skencode_overlay_rejects_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected one pinned skencode"):
            fix_skencode_tb("module skencode_tb; endmodule\n")

    def test_skencode_completion_requires_all_comparisons_and_error_case(self):
        log = (
            "Starting skencode test\nChecking output data\nTest completed\n"
            "Starting skencode test\nChecking output data\nTest completed\n"
            "Starting skencode error test\n"
            "Starting skencode test again\nChecking output data\nTest completed\n"
            "skencode_tb.sv:337: $finish called at 14705 (1s)\n"
        )
        self.assertEqual(classify_skencode(log, 0)[0], "PASS")
        self.assertEqual(classify_skencode(log + "Error: Output mismatch at index 2\n", 0)[0], "FAIL")
        self.assertEqual(classify_skencode(log + "Error: Error flag should have been asserted\n", 0)[0], "FAIL")
        self.assertEqual(classify_skencode(log.replace("Test completed\n", "", 1), 0)[0], "BLOCKED")

    def test_sigdecode_z_completion_requires_both_clean_comparisons_and_finish(self):
        log = (
            "Checking output data\nTest completed\n"
            "Checking output data\nTest completed\n"
            "sigdecode_z_tb.sv:249: $finish called at 4605 (1s)\n"
        )
        self.assertEqual(run_m15_test.classify_sigdecode_z(log, 0)[0], "PASS")
        self.assertEqual(
            run_m15_test.classify_sigdecode_z(log + "Error: Output mismatch at index 2\n", 0)[0],
            "FAIL",
        )
        self.assertEqual(run_m15_test.classify_sigdecode_z(log.replace("Test completed\n", "", 1), 0)[0], "BLOCKED")
        self.assertEqual(run_m15_test.classify_sigdecode_z(log.replace("$finish called", "ERROR: bad"), 0)[0], "FAIL")

    def test_pkdecode_completion_requires_two_clean_comparisons_and_finish(self):
        log = (
            "Starting pkdecode test\nChecking output data\nTest completed\n"
            "Starting pkdecode test\nChecking output data\nTest completed\n"
            "pkdecode_tb.sv:251: $finish called at 5245 (1s)\n"
        )
        self.assertEqual(classify_pkdecode(log, 0)[0], "PASS")
        self.assertEqual(classify_pkdecode(log + "Error: Output mismatch at index 4\n", 0)[0], "FAIL")
        self.assertEqual(classify_pkdecode(log.replace("Test completed\n", "", 1), 0)[0], "BLOCKED")
        self.assertEqual(classify_pkdecode(log, 1)[0], "FAIL")

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

    def test_makehint_overlay_uses_the_exported_address_width(self):
        source = "import abr_params_pkg::*;\n.mem_base_addr(MLDSA_MEM_ADDR_WIDTH'(0)),\n"
        self.assertEqual(
            fix_makehint_tb(source),
            "import abr_params_pkg::*;\n.mem_base_addr(ABR_MEM_ADDR_WIDTH'(0)),\n",
        )
        with self.assertRaisesRegex(RuntimeError, "expected one"):
            fix_makehint_tb("module makehint_tb; endmodule\n")

    def test_ntt_masking_overlay_uses_context_sized_zero(self):
        source = (
            "/* task masked_bfu_1x2_test(); endtask */\n"
            "ntt_hybrid_butterfly_2x2 dut (\n"
            "    .hybrid_pw_uvw_i(),\n"
            ");\n"
            "initial begin\n"
            "    masked_uvw_i_tb = {'h0, 'h0, 'h0, 'h0, 'h0, 'h0};\n"
            "    masked_bfu_1x2_test();\n"
            "end\n"
        )
        overlay = fix_ntt_top_masking_tb(source)
        self.assertIn("/* task masked_bfu_1x2_test(); endtask */", overlay)
        self.assertIn("masked_uvw_i_tb = '0;", overlay)
        self.assertNotIn(".hybrid_pw_uvw_i(),", overlay)
        self.assertIn("    masked_hybrid_bf_2x2_test();", overlay)
        for missing in (
            "    .hybrid_pw_uvw_i(),\n",
            "    masked_bfu_1x2_test();\n",
            "masked_uvw_i_tb = {'h0, 'h0, 'h0, 'h0, 'h0, 'h0};",
        ):
            with self.subTest(missing=missing), self.assertRaises(RuntimeError):
                fix_ntt_top_masking_tb(source.replace(missing, "", 1))

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

    def test_soc_ifc_overlay_rewrites_only_pinned_assignment_patterns_and_void_returns(self):
        source = """logic [2:0] first[string] = {
word_addr_t second[string] = {
word_addr_t third[string] = {
dword_t fourth[string] = {
dword_t fifth[string] = {
dword_t sixth[string] = {
word_addr_t seventh[string] = {
dword_t eighth[string] = {
word_addr_t queue[$] = {
extern function lock_fuses();
extern function unlock_fuses();
function SocRegisters::lock_fuses();
function SocRegisters::unlock_fuses();
new_trans = {addr: addr, data: 1, tid: tid};
new_trans = {addr: addr, data: 2, tid: tid};
matched_p = {d: matched_d, v: int'(err_found == 0)};
"""
        overlaid = fix_soc_ifc_tb_pkg(source)
        self.assertEqual(overlaid.count("[string] = '{"), 8)
        self.assertIn("queue[$] = {", overlaid)
        self.assertIn("extern function void lock_fuses();", overlaid)
        self.assertIn("extern function void unlock_fuses();", overlaid)
        self.assertIn("function void SocRegisters::lock_fuses();", overlaid)
        self.assertIn("function void SocRegisters::unlock_fuses();", overlaid)
        self.assertEqual(overlaid.count("new_trans = '{addr: addr,"), 2)
        self.assertIn("matched_p = '{d: matched_d,", overlaid)

    def test_soc_ifc_overlay_rejects_a_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected 8"):
            fix_soc_ifc_tb_pkg("word_addr_t missing[string] = {\n")

    def test_soc_ifc_overlay_rejects_missing_transaction_assignment_patterns(self):
        source = "[string] = {\n" * 8 + """extern function lock_fuses();
extern function unlock_fuses();
function SocRegisters::lock_fuses();
function SocRegisters::unlock_fuses();
"""
        with self.assertRaisesRegex(RuntimeError, "expected 2 pinned SoC-IFC transaction patterns"):
            fix_soc_ifc_tb_pkg(source)

    def test_soc_ifc_intrblk_overlay_precomputes_mask_before_inline_constraint(self):
        source = """foreach (wo_regnames[i]) begin
        word_addr_t associated_addr;
        rname = wo_regnames[i];
        wrtrans.randomize() with {wrtrans.data & get_mask(rname) != 0;};
        ahb_wrdata = wrtrans.data & get_mask(rname);
      end
"""
        expected = """foreach (wo_regnames[i]) begin
        word_addr_t associated_addr;
        dword_t wr_mask;
        rname = wo_regnames[i];
        wr_mask = get_mask(rname);
        wrtrans.randomize() with {wrtrans.data & wr_mask != 0;};
        ahb_wrdata = wrtrans.data & wr_mask;
      end
"""
        self.assertEqual(run_m15_test.fix_soc_ifc_intrblk_constraint(source), expected)

    def test_soc_ifc_tb_overlay_samples_changed_signals_on_the_default_clock(self):
        source = """default clocking default_clk @(posedge clk_tb); endclocking
`include "soc_reg_intrblk_test.svh"
forever @($changed(a)) update_a();
forever @($changed(b)) update_b();
forever @($changed(c)) update_c();
forever @($changed(d)) update_d();
forever @($changed(e)) update_e();
"""
        expected = """default clocking default_clk @(posedge clk_tb); endclocking
`include "/tmp/overlays/soc_reg_intrblk_test.svh"
forever @(posedge clk_tb) if ($changed(a)) update_a();
forever @(posedge clk_tb) if ($changed(b)) update_b();
forever @(posedge clk_tb) if ($changed(c)) update_c();
forever @(posedge clk_tb) if ($changed(d)) update_d();
forever @(posedge clk_tb) if ($changed(e)) update_e();
"""
        self.assertEqual(
            run_m15_test.fix_soc_ifc_tb(source, "/tmp/overlays/soc_reg_intrblk_test.svh"),
            expected,
        )

    def test_butterfly_overlay_loads_expected_output_into_output_array(self):
        source = '$readmemh("kyber_stage0_out.hex", in_val);\n'
        self.assertEqual(
            fix_butterfly_expected_vector(source),
            '$readmemh("kyber_stage0_out.hex", out_val);\n',
        )

    def test_butterfly_overlay_rejects_a_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected one"):
            fix_butterfly_expected_vector("$readmemh(\"other.hex\", in_val);\n")

    def test_csrng_filelist_moves_ram_package_before_its_importer(self):
        package = "${CALIPTRA_ROOT}/src/caliptra_prim/rtl/caliptra_prim_ram_1p_pkg.sv\n"
        ram = "${CALIPTRA_PRIM_ROOT}/rtl/${CALIPTRA_PRIM_MODULE_PREFIX}_ram_1p.sv\n"
        incdir = "+incdir+${CALIPTRA_ROOT}/src/integration/rtl\n"
        reg_incdir = "+incdir+${CALIPTRA_ROOT}/src/integration/rtl/caliptra_reg\n"
        source = "incdirs\n" + incdir + ram + "other.sv\n" + package
        self.assertEqual(
            fix_csrng_tb_filelist(source),
            "incdirs\n" + incdir + reg_incdir + package + ram + "other.sv\n",
        )

    def test_csrng_filelist_overlay_rejects_changed_source_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected one CSRNG RAM"):
            fix_csrng_tb_filelist("no expected entries\n")

    def test_csrng_filelist_overlay_rejects_duplicate_register_include_dir(self):
        package = "${CALIPTRA_ROOT}/src/caliptra_prim/rtl/caliptra_prim_ram_1p_pkg.sv\n"
        ram = "${CALIPTRA_PRIM_ROOT}/rtl/${CALIPTRA_PRIM_MODULE_PREFIX}_ram_1p.sv\n"
        incdir = "+incdir+${CALIPTRA_ROOT}/src/integration/rtl\n"
        reg_incdir = "+incdir+${CALIPTRA_ROOT}/src/integration/rtl/caliptra_reg\n"
        source = "incdirs\n" + incdir + reg_incdir + ram + package
        with self.assertRaisesRegex(RuntimeError, "expected one CSRNG RAM"):
            fix_csrng_tb_filelist(source)


class M16OpenMvcFilelistTest(unittest.TestCase):
    def test_generated_sha512_rows_use_the_vendor_free_filelist(self):
        for environment_id in ("uvmf-sha512", "uvmf-ecc"):
            row = {"test_kind": "generated-uvmf", "environment_id": environment_id}
            self.assertTrue(needs_m16_open_mvc_filelist(row))
        row["test_kind"] = "authored-stimulus"
        self.assertFalse(needs_m16_open_mvc_filelist(row))


class M17AaxiFilelistTest(unittest.TestCase):
    def test_adds_open_avery_include_dir_only_when_requested(self):
        source = (
            "${AVERY_SIM}/src/avery_pkg.sv\n"
            "${AVERY_AXI}/src.axi/aaxi_pkg.sv\n"
            "${CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
            "verification_ip/environment_packages/soc_ifc_env_pkg/soc_ifc_env_pkg.sv\n"
        )
        include_dir = "/repo/dv/caliptra_bfm/uvm"

        with_dir = rewrite_m17_aaxi_filelist(source, [], "/tmp/soc_ifc_env_pkg.sv", include_dir=include_dir)
        without_dir = rewrite_m17_aaxi_filelist(source, [], "/tmp/soc_ifc_env_pkg.sv")

        self.assertEqual(with_dir.count(f"+incdir+{include_dir}"), 1)
        self.assertEqual(with_dir.splitlines()[0], f"+incdir+{include_dir}")
        self.assertNotIn(f"+incdir+{include_dir}", without_dir)

    def test_replaces_only_vendor_aaxi_entries_and_generated_package(self):
        source = (
            "${AVERY_SIM}/src/avery_pkg.sv\n"
            "+incdir+${AVERY_AXI}/include\n"
            "${AVERY_AXI}/src.axi/aaxi_pkg.sv\n"
            "${CALIPTRA_AXI4PC_DIR}/Axi4PC.sv\n"
            "${CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
            "verification_ip/environment_packages/soc_ifc_env_pkg/soc_ifc_env_pkg.sv\n"
        )
        support = ["/repo/dv/caliptra_bfm/uvm/caliptra_aaxi_compat_pkg.sv"]
        overlay = "/tmp/overlays/soc_ifc_env_pkg.sv"

        result = rewrite_m17_aaxi_filelist(source, support, overlay)

        self.assertNotIn("AVERY_SIM", result)
        self.assertNotIn("AVERY_AXI", result)
        self.assertEqual(result.count(support[0]), 1)
        self.assertIn("${CALIPTRA_AXI4PC_DIR}/Axi4PC.sv", result)
        self.assertIn(overlay, result)

    def test_drops_arm_axi4pc_stub_only_for_environments_without_a_reference(self):
        self.assertTrue(should_drop_axi4pc_stub("uvmf-caliptra_top"))
        self.assertTrue(should_drop_axi4pc_stub("uvmf-soc_ifc"))
        self.assertFalse(should_drop_axi4pc_stub("uvmf-pv"))


class KeyVaultFactorySequenceOverlayTest(unittest.TestCase):
    def test_retargets_only_example_sequence_to_test_top_base(self):
        source = (
            "class example_derived_test_sequence extends kv_rst_sequence_base;\n"
            "endclass\n"
            "class unrelated_reset_sequence extends kv_rst_sequence_base;\n"
            "endclass\n"
        )

        result = fix_kv_factory_sequence_base(source)

        self.assertIn(
            "class example_derived_test_sequence extends kv_bench_sequence_base;",
            result,
        )
        self.assertIn("class unrelated_reset_sequence extends kv_rst_sequence_base;", result)

    def test_rejects_changed_example_sequence_declaration(self):
        with self.assertRaisesRegex(RuntimeError, "expected one pinned KeyVault example sequence"):
            fix_kv_factory_sequence_base("class example_derived_test_sequence extends uvm_sequence;\n")

    def test_prepares_hash_guarded_sequence_and_include_overlay(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            caliptra = root / "caliptra"
            source = caliptra / "src/keyvault/uvmf_kv/uvmf_template_output/project_benches/kv/tb/sequences/src/example_derived_test_sequence.svh"
            source.parent.mkdir(parents=True)
            source.write_text("class example_derived_test_sequence extends kv_rst_sequence_base;\n")
            filelist = root / "kv-open-ahb.vf"
            filelist.write_text("/repo/caliptra_bfm_uvm.sv\n")
            output = root / "output"

            with patch.object(run_m15_test, "KV_EXAMPLE_SEQUENCE_SHA256", run_m15_test.sha256(source)):
                overlay_filelist, manifest = run_m15_test.prepare_kv_factory_overlay(filelist, caliptra, output)

            overlay = output / "overlays/kv-factory/src/example_derived_test_sequence.svh"
            self.assertEqual(overlay.read_text(), "class example_derived_test_sequence extends kv_bench_sequence_base;\n")
            self.assertEqual(overlay_filelist.read_text().splitlines()[0], f"+incdir+{output / 'overlays/kv-factory'}")
            self.assertEqual(json.loads(manifest.read_text())["scope"], "testbench and filelist only; no RTL, firmware, or pass criteria changed")


class UARTFilelistTest(unittest.TestCase):
    def test_builds_vendor_free_filelist_from_pinned_uart_compile_yml(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            config = root / "src/uart/config/compile.yml"
            config.parent.mkdir(parents=True)
            config.write_text(
                "targets:\n  rtl:\n    files:\n"
                "      - $COMPILE_ROOT/rtl/uart_reg_pkg.sv\n"
                "      - $COMPILE_ROOT/rtl/uart.sv\n"
                "  tb:\n    files:\n"
                "      - $COMPILE_ROOT/rtl/uart_reg_pkg.sv\n"
                "      - $COMPILE_ROOT/tb/uart_tb.sv\n"
            )
            prim_vf = root / "src/caliptra_prim/config/caliptra_prim.vf"
            prim_vf.parent.mkdir(parents=True)
            prim_vf.write_text("+incdir+${CALIPTRA_ROOT}/src/caliptra_prim/rtl\n")
            for source in (
                root / "src/uart/rtl/uart_reg_pkg.sv",
                root / "src/uart/rtl/uart.sv",
                root / "src/uart/tb/uart_tb.sv",
            ):
                source.parent.mkdir(parents=True, exist_ok=True)
                source.touch()
            output = root / "output"

            filelist, manifest = prepare_uart_filelist(root, output)

            text = filelist.read_text()
            self.assertTrue(text.startswith(prim_vf.read_text()))
            self.assertEqual(text.count(str(root / "src/uart/rtl/uart_reg_pkg.sv")), 1)
            self.assertIn(str(root / "src/uart/rtl/uart.sv"), text)
            self.assertIn(str(root / "src/uart/tb/uart_tb.sv"), text)
            self.assertEqual(json.loads(manifest.read_text())["scope"], "filelist/setup only")

    def test_rejects_uart_compile_yml_without_the_self_checking_tb(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "src/uart/config").mkdir(parents=True)
            (root / "src/uart/config/compile.yml").write_text(
                "- $COMPILE_ROOT/rtl/uart_reg_pkg.sv\n"
            )
            prim_vf = root / "src/caliptra_prim/config/caliptra_prim.vf"
            prim_vf.parent.mkdir(parents=True)
            prim_vf.write_text("+incdir+${CALIPTRA_ROOT}/src/caliptra_prim/rtl\n")

            with self.assertRaisesRegex(RuntimeError, "uart_tb.sv"):
                prepare_uart_filelist(root, root / "output")

    def test_drops_unused_arm_axi4pc_stub_only_when_requested(self):
        source = (
            "${AVERY_SIM}/src/avery_pkg.sv\n"
            "${AVERY_AXI}/src.axi/aaxi_pkg.sv\n"
            "${CALIPTRA_AXI4PC_DIR}/Axi4PC.sv\n"
            "${CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
            "verification_ip/environment_packages/soc_ifc_env_pkg/soc_ifc_env_pkg.sv\n"
        )

        result = rewrite_m17_aaxi_filelist(source, [], "/tmp/env.sv", drop_axi4pc=True)

        self.assertNotIn("Axi4PC.sv", result)
        with self.assertRaisesRegex(RuntimeError, "expected one unused ARM Axi4PC stub"):
            rewrite_m17_aaxi_filelist(
                source.replace("${CALIPTRA_AXI4PC_DIR}/Axi4PC.sv\n", ""),
                [],
                "/tmp/env.sv",
                drop_axi4pc=True,
            )

    def test_does_not_readd_aaxi_sources_already_in_open_ahb_filelist(self):
        shared = "/repo/dv/caliptra_bfm/uvm/axi4_caliptra_record_if.sv"
        extra = "/repo/dv/caliptra_bfm/uvm/caliptra_aaxi_uvmf_compat_pkg.sv"
        source = (
            shared + "\n"
            "${AVERY_SIM}/src/avery_pkg.sv\n"
            "${AVERY_AXI}/src.axi/aaxi_pkg.sv\n"
            "${CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
            "verification_ip/environment_packages/soc_ifc_env_pkg/soc_ifc_env_pkg.sv\n"
        )

        result = rewrite_m17_aaxi_filelist(source, [shared, extra], "/tmp/env.sv")

        self.assertEqual(result.count(shared), 1)
        self.assertEqual(result.count(extra), 1)

    def test_rejects_changed_package_or_missing_vendor_entries(self):
        with self.assertRaisesRegex(RuntimeError, "expected one pinned SoC-IFC package"):
            rewrite_m17_aaxi_filelist("${AVERY_AXI}/src.axi/aaxi_pkg.sv\n", [], "/tmp/pkg.sv")
        with self.assertRaisesRegex(RuntimeError, "expected AVERY_SIM and AVERY_AXI entries"):
            rewrite_m17_aaxi_filelist(
                "${AVERY_AXI}/src.axi/aaxi_pkg.sv\n"
                "${CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
                "verification_ip/environment_packages/soc_ifc_env_pkg/soc_ifc_env_pkg.sv\n",
                [],
                "/tmp/pkg.sv",
            )


class AdamsCompressFilelistTest(unittest.TestCase):
    def test_inserts_only_the_missing_ntt_package_before_compress_importers(self):
        source = (
            "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv\n"
            "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_reg_pkg.sv\n"
            "${ADAMSBRIDGE_ROOT}/src/compress/rtl/compress_defines_pkg.sv\n"
        )
        expected = source.replace(
            "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv\n",
            "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv\n"
            "${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_defines_pkg.sv\n",
            1,
        )
        self.assertEqual(fix_compress_tb_filelist(source), expected)

    def test_rejects_unexpected_or_duplicate_package_entries(self):
        with self.assertRaisesRegex(RuntimeError, "expected one pinned ABR params package"):
            fix_compress_tb_filelist("${ADAMSBRIDGE_ROOT}/src/abr_reg_pkg.sv\n")
        with self.assertRaisesRegex(RuntimeError, "already contains the NTT package"):
            fix_compress_tb_filelist(
                "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv\n"
                "${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_defines_pkg.sv\n"
            )

    def test_rewrites_legacy_write_ports_and_checks_the_same_compressed_values(self):
        source = """\
reg [3:0][REG_SIZE-1:0] coeff_tb, mem_wr_data_o;
compress_top dut (
    .src_base_addr(src_base_tb),
    .dest_base_addr(dest_base_tb),
    .mem_rd_req(),
    .mem_wr_req(),
    .mem_rd_data(coeff_tb),
    .mem_wr_data(mem_wr_data_o),
    .compress_done()
);
task init_sim;
    begin
        mode_tb_dut = 0;
    end
endtask
task compress_test;
    logic [3:0] d;
    logic flag;
    flag = 0;
    mode_tb_dut = mode_tb;

    fork
        begin
            // Send coefficients to the DUT
            @(posedge clk_tb);
            coeff_tb = '0;
        end
        begin
            // Wait for compress_done signal
            while (!flag) begin
                flag = 1;
            end
        end
    join
    $display("Compression done");
endtask
coeff_exp[i] = ((coeff_array[i] << d) + MLKEM_Q/2) / MLKEM_Q;
if (error_count == 0) $display("* TESTCASE PASSED");
if (error_count != 0) $display("* TESTCASE FAILED with %0d errs.", error_count);
"""
        overlay = fix_compress_tb_testbench(source)
        self.assertNotIn(".mem_wr_req(", overlay)
        self.assertNotIn(".mem_wr_data(", overlay)
        self.assertIn(".mem_rd_req(mem_rd_req_tb)", overlay)
        self.assertIn("if (mem_rd_req_tb.rd_wr_en == RW_READ)", overlay)
        self.assertIn("coeff_tb <= {", overlay)
        self.assertNotIn("// Send coefficients to the DUT", overlay)
        self.assertIn(".api_wr_data(api_wr_data_tb)", overlay)
        self.assertIn("do @(posedge clk_tb); while (!compress_done_tb);", overlay)
        self.assertNotIn("wait (compress_done_tb)", overlay)
        self.assertIn("coeff_exp[coeff_index % 256][bit_index]", overlay)
        self.assertIn("(coeff_array[i] << d) + MLKEM_Q/2", overlay)
        self.assertIn('* TESTCASE PASSED', overlay)
        self.assertIn('* TESTCASE FAILED', overlay)

    def test_rejects_a_nonpinned_compress_testbench_shape(self):
        with self.assertRaisesRegex(RuntimeError, "expected one pinned compress_tb port declaration"):
            fix_compress_tb_testbench("module compress_tb; endmodule\n")


class AdamsMldsaFilelistTest(unittest.TestCase):
    def test_maps_removed_mldsa_sources_to_pinned_abr_hierarchy(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            adamsbridge = root / "adams-bridge"
            abr_rtl = adamsbridge / "src/abr_top/rtl"
            abr_rtl.mkdir(parents=True)
            config = abr_rtl / "abr_config_defines.svh"
            params = abr_rtl / "abr_params_pkg.sv"
            config.write_text("`ifndef ABR_CFG_SV\n`define ABR_CFG_SV\n`endif\n")
            params.write_text("package abr_params_pkg; endpackage\n")
            sampler_pkg = adamsbridge / "src/abr_sampler_top/rtl/abr_sampler_pkg.sv"
            sampler_pkg.parent.mkdir(parents=True)
            sampler_pkg.write_text("package abr_sampler_pkg; endpackage\n")
            testbench = adamsbridge / "src/rej_sampler/tb/mldsa_rej_sampler_tb.sv"
            testbench.parent.mkdir(parents=True)
            testbench.write_text("module mldsa_rej_sampler_tb; import mldsa_sampler_pkg::*; endmodule\n")
            filelist = root / "mldsa_rej_sampler_tb.vf"
            filelist.write_text(
                "+incdir+${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl\n"
                "+incdir+${ADAMSBRIDGE_ROOT}/src/mldsa_sampler_top/rtl\n"
                "${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl/mldsa_config_defines.svh\n"
                "${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl/mldsa_params_pkg.sv\n"
                "${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl/mldsa_reg_pkg.sv\n"
                "${ADAMSBRIDGE_ROOT}/src/mldsa_sampler_top/rtl/mldsa_sampler_pkg.sv\n"
                "${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_piso_4.sv\n"
                "${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_piso.sv\n"
                "${ADAMSBRIDGE_ROOT}/src/rej_sampler/tb/mldsa_rej_sampler_tb.sv\n"
            )

            with patch.object(run_m15_test, "ABR_CONFIG_DEFINES_SHA256", run_m15_test.sha256(config)), patch.object(
                run_m15_test, "ABR_PARAMS_PKG_SHA256", run_m15_test.sha256(params)
            ), patch.object(run_m15_test, "ABR_SAMPLER_PKG_SHA256", run_m15_test.sha256(sampler_pkg)):
                overlay, manifest = prepare_adams_mldsa_filelist(filelist, adamsbridge, root / "output")

            text = overlay.read_text()
            self.assertIn("+incdir+" + str(root / "output/overlays/adams-mldsa"), text)
            self.assertIn("+incdir+${ADAMSBRIDGE_ROOT}/src/abr_top/rtl", text)
            self.assertIn("+incdir+${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl", text)
            self.assertIn(str(root / "output/overlays/adams-mldsa/mldsa_config_defines.svh"), text)
            self.assertIn("${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv", text)
            self.assertIn("${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl/abr_sampler_pkg.sv", text)
            self.assertNotIn("mldsa_params_pkg.sv", text)
            self.assertNotIn("mldsa_reg_pkg.sv", text)
            self.assertNotIn("mldsa_sampler_pkg.sv", text)
            self.assertNotIn("abr_piso_4.sv", text)
            self.assertIn("${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_piso.sv", text)
            self.assertEqual(
                (root / "output/overlays/adams-mldsa/tb/src/rej_sampler/tb/mldsa_rej_sampler_tb.sv").read_text(),
                "module mldsa_rej_sampler_tb; import abr_sampler_pkg::*; endmodule\n",
            )
            self.assertEqual(
                (root / "output/overlays/adams-mldsa/mldsa_config_defines.svh").read_text(),
                '`include "abr_config_defines.svh"\n',
            )
            manifest_data = json.loads(manifest.read_text())
            self.assertEqual(
                manifest_data["removed_stale_sources"],
                {"${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_piso_4.sv": "source is absent from the pinned tree and no bench instantiates abr_piso_4"},
            )
            self.assertEqual(
                manifest_data["renamed_packages"]["${ADAMSBRIDGE_ROOT}/src/mldsa_sampler_top/rtl/mldsa_sampler_pkg.sv"],
                str(sampler_pkg),
            )
            self.assertEqual(len(manifest_data["testbench_import_overlays"]), 1)
            self.assertEqual(manifest_data["scope"], "testbench and filelist only; no RTL, firmware, or pass criteria changed")


class M16MldsaOverlayTest(unittest.TestCase):
    def test_mldsa_reference_setup_selects_authored_mldsa_tests_only(self):
        self.assertTrue(needs_mldsa_reference_model({
            "environment_id": "uvmf-mldsa", "testname": "ML_DSA_randomized_verif_test"
        }))
        self.assertFalse(needs_mldsa_reference_model({
            "environment_id": "uvmf-mldsa", "testname": "ML_KEM_randomized_keygen_test"
        }))
        self.assertFalse(needs_mldsa_reference_model({
            "environment_id": "uvmf-kv", "testname": "ML_DSA_randomized_verif_test"
        }))

    def test_mldsa_native_setup_stages_the_pinned_stream_message_model(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir)
            root = base / "adams-bridge"
            source = root / "src/abr_top/uvmf/Dilithium_ref/dilithium/ref"
            (source / "test").mkdir(parents=True)
            (source / "test/test_dilithium.c").write_text("int main(void) { return 0; }\n")
            stream_source = source / "test/test_dilithium5_strm_msg"
            stream_source.write_bytes(b"pinned stream model")
            stream_source.chmod(0o755)
            repo = base / "qd-bfm"
            helpers = repo / "dv/caliptra_bfm/native_vectors"
            helpers.mkdir(parents=True)
            (helpers / "stage_mldsa.py").write_text("# stage\n")
            (helpers / "check_native_mldsa.py").write_text("# check\n")
            output = base / "output"
            output.mkdir()
            runtime = output / "runtime"
            runtime.mkdir()

            def fake_run_logged(command, cwd, env, log, timeout):
                if len(command) > 1 and command[1] == "-C":
                    (Path(command[2]) / "test/test_dilithium5").write_bytes(b"built model")
                return 0, False

            with patch.object(run_m15_test, "run_logged", side_effect=fake_run_logged):
                manifest = run_m15_test.prepare_mldsa_native_model(
                    root, repo, output, runtime, {"PATH": os.environ["PATH"]},
                    run_m15_test.time.monotonic() + 100,
                )

            self.assertEqual((runtime / "test_dilithium5").read_bytes(), b"built model")
            self.assertEqual((runtime / "test_dilithium5_strm_msg").read_bytes(), b"pinned stream model")
            self.assertTrue(os.access(runtime / "test_dilithium5_strm_msg", os.X_OK))
            manifest_data = json.loads(manifest.read_text())
            self.assertEqual(manifest_data["stream_binary_sha256"], run_m15_test.sha256(stream_source))

    def test_env_configuration_overlay_only_fixes_pinned_constructs(self):
        transfer_type = (
            "ahb_master_burst_transfer #("
            "ahb_lite_slave_0_params::AHB_NUM_MASTERS, "
            "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS, "
            "ahb_lite_slave_0_params::AHB_NUM_SLAVES, "
            "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH, "
            "ahb_lite_slave_0_params::AHB_WDATA_WIDTH, "
            "ahb_lite_slave_0_params::AHB_RDATA_WIDTH)"
        )
        source = (
            '"\\n", qvip_ahb_lite_slave_subenv_config.convert2string\n'
            "qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];\n"
            "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];\n"
            "unrelated_names = interface_names[0:0];\n"
            + f"set_monitor_item({transfer_type}::type_id::get());\n" * 2
        )
        overlaid = fix_mldsa_env_configuration(source)
        self.assertIn('qvip_ahb_lite_slave_subenv_config.convert2string()', overlaid)
        self.assertIn("qvip_ahb_lite_slave_subenv_interface_names[0] = interface_names[0];", overlaid)
        self.assertIn("qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];", overlaid)
        self.assertIn("unrelated_names = interface_names[0:0];", overlaid)
        self.assertEqual(overlaid.count("ahb_lite_slave_0_transfer_t::type_id::get()"), 2)
        self.assertNotIn("ahb_master_burst_transfer", overlaid)

    def test_mldsa_environment_uses_the_open_qvip_transfer_alias(self):
        source = (
            "typedef ahb_master_burst_transfer #(ahb_lite_slave_0_params::AHB_NUM_MASTERS, "
            "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS, ahb_lite_slave_0_params::AHB_NUM_SLAVES, "
            "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH, ahb_lite_slave_0_params::AHB_WDATA_WIDTH, "
            "ahb_lite_slave_0_params::AHB_RDATA_WIDTH) ahb_reg_transfer_t;\n"
        )
        self.assertEqual(
            fix_mldsa_environment(source),
            "typedef ahb_lite_slave_0_transfer_t ahb_reg_transfer_t;\n",
        )
        with self.assertRaisesRegex(RuntimeError, "expected 1 generated MLDSA AHB transfer type references"):
            fix_mldsa_environment("typedef unrelated_transfer ahb_reg_transfer_t;\n")

    def test_mldsa_overlays_reject_changed_or_duplicate_source_shapes(self):
        with self.assertRaisesRegex(RuntimeError, "expected one unmodified MLDSA"):
            fix_mldsa_env_configuration("qvip_ahb_lite_slave_subenv_config.convert2string()\n")
        with self.assertRaisesRegex(RuntimeError, "expected one unmodified MLDSA"):
            fix_mldsa_substr("line = line.substr(8);\nline = line.substr(8);\n")

    def test_mldsa_rm_access_and_substr_overlays_preserve_their_results(self):
        rm = fix_mldsa_config_rm_access("p_mldsa_rm = configuration.mldsa_rm;\n", "p_mldsa_rm")
        self.assertIn("mldsa_config_local = configuration;", rm)
        self.assertIn("p_mldsa_rm = mldsa_config_local.mldsa_rm;", rm)
        self.assertEqual(
            fix_mldsa_substr("        line = line.substr(8);\n"),
            '        if (line.len() <= 8) line = "";\n'
            "        else line = line.substr(8, line.len() - 1);\n",
        )

    def test_mldsa_predictor_overlay_uses_the_accepted_bfm_type(self):
        parameters = (
            "ahb_lite_slave_0_params::AHB_NUM_MASTERS,\n"
            " ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,\n"
            " ahb_lite_slave_0_params::AHB_NUM_SLAVES,\n"
            " ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,\n"
            " ahb_lite_slave_0_params::AHB_WDATA_WIDTH,\n"
            " ahb_lite_slave_0_params::AHB_RDATA_WIDTH"
        )
        transfer_type = f"ahb_master_burst_transfer #(\n{parameters})"
        source = (
            "p_mldsa_rm = configuration.mldsa_rm;\n"
            f"typedef {transfer_type} mldsa_sb_ahb_ap_output_transaction_t;\n"
            f"{transfer_type} t;\n"
            'mldsa_sb_ahb_ap_output_transaction = mldsa_sb_ahb_ap_output_transaction_t::type_id::create("mldsa_sb_ahb_ap_output_transaction");\n'
            "line = line.substr(8);\n"
        )
        overlaid = fix_mldsa_predictor(source)
        self.assertIn(
            "ahb_lite_slave_0_transfer_t "
            "mldsa_sb_ahb_ap_output_transaction_t;",
            overlaid,
        )
        self.assertIn("ahb_lite_slave_0_transfer_t t;", overlaid)
        self.assertIn('mldsa_sb_ahb_ap_output_transaction = new("mldsa_sb_ahb_ap_output_transaction");', overlaid)
        self.assertNotIn("ahb_master_burst_transfer #(", overlaid)
        self.assertNotIn("mldsa_sb_ahb_ap_output_transaction_t::type_id::create", overlaid)
        with self.assertRaisesRegex(RuntimeError, "expected 2 generated MLDSA AHB transfer types"):
            fix_mldsa_predictor(
                "p_mldsa_rm = configuration.mldsa_rm;\nline = line.substr(8);\n"
            )

    def test_mldsa_scoreboard_overlay_rewrites_all_six_ahb_transfer_types(self):
        parameters = (
            "ahb_lite_slave_0_params::AHB_NUM_MASTERS,\n"
            " ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,\n"
            " ahb_lite_slave_0_params::AHB_NUM_SLAVES,\n"
            " ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,\n"
            " ahb_lite_slave_0_params::AHB_WDATA_WIDTH,\n"
            " ahb_lite_slave_0_params::AHB_RDATA_WIDTH"
        )
        declarations = (
            ("ahb_expected_q", "       [$]"),
            ("ahb_actual_q", "       [$]"),
            ("ahb_expected_verif_q", "       [$]"),
            ("t", ""),
            ("t_exp", ""),
            ("t", ""),
        )
        source = "scbr_mldsa_rm = configuration.mldsa_rm;\n" + "".join(
            f"ahb_master_burst_transfer #(\n{parameters})     {name}{suffix};\n"
            for name, suffix in declarations
        )
        overlaid = fix_mldsa_scoreboard(source)
        alias = "ahb_lite_slave_0_transfer_t "
        for name, suffix in declarations:
            self.assertIn(f"{alias}{name}{suffix};", overlaid)
        self.assertNotIn("ahb_master_burst_transfer #(", overlaid)
        with self.assertRaisesRegex(RuntimeError, "expected 6 generated MLDSA AHB transfer types"):
            fix_mldsa_scoreboard(
                source.replace("ahb_master_burst_transfer #(\n", "unmatched_transfer #(\n", 1)
            )

    def test_mldsa_kem_fatal_overlay_adds_the_required_finish_number(self):
        source = '$fatal("Cannot open %s", fname);\n' * 6 + '$fatal(1, "already numbered");\n'
        overlaid = fix_mldsa_kem_fatals(source)
        self.assertEqual(overlaid.count('$fatal(1, "Cannot open %s", fname);'), 6)
        self.assertIn('$fatal(1, "already numbered");', overlaid)
        with self.assertRaisesRegex(RuntimeError, "expected six ML-KEM fatal calls"):
            fix_mldsa_kem_fatals(source.replace('$fatal("', '$fatal(1, "', 1))

    def test_mldsa_ral_overlay_sets_endian_only_on_the_top_level_map(self):
        map_call = 'this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);'
        source = (
            "class abr_reg__child extends uvm_reg_block;\n" + map_call + "\n"
            "endclass : abr_reg__child\n"
            "class abr_reg extends uvm_reg_block;\n" + map_call + "\n"
            "endclass : abr_reg\n"
        )
        overlaid = fix_mldsa_reg_model_endian(source)
        self.assertEqual(overlaid.count("UVM_LITTLE_ENDIAN"), 1)
        self.assertEqual(overlaid.count("UVM_NO_ENDIAN"), 1)
        self.assertIn("class abr_reg__child extends uvm_reg_block;\n" + map_call, overlaid)
        with self.assertRaisesRegex(RuntimeError, "expected one no-endian top-level abr_reg map"):
            fix_mldsa_reg_model_endian(source.replace(map_call + "\nendclass : abr_reg", "endclass : abr_reg"))

    def test_mldsa_overlay_stages_sources_and_precedes_pinned_include_dirs(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "adams-bridge"
            env_pkg = root / "src/abr_top/uvmf/uvmf_template_output/verification_ip/environment_packages/mldsa_env_pkg"
            sequences = root / "src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/sequences"
            rtl = root / "src/abr_top/rtl"
            (env_pkg / "src").mkdir(parents=True)
            (sequences / "src").mkdir(parents=True)
            rtl.mkdir(parents=True)
            transfer_type = (
                "ahb_master_burst_transfer #("
                "ahb_lite_slave_0_params::AHB_NUM_MASTERS, "
                "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS, "
                "ahb_lite_slave_0_params::AHB_NUM_SLAVES, "
                "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH, "
                "ahb_lite_slave_0_params::AHB_WDATA_WIDTH, "
                "ahb_lite_slave_0_params::AHB_RDATA_WIDTH)"
            )
            (env_pkg / "src/mldsa_env_configuration.svh").write_text(
                'qvip_ahb_lite_slave_subenv_config.convert2string\n'
                "qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];\n"
                "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];\n"
                + f"set_monitor_item({transfer_type}::type_id::get());\n" * 2
            )
            (env_pkg / "src/mldsa_environment.svh").write_text(
                f"typedef {transfer_type} ahb_reg_transfer_t;\n"
            )
            (env_pkg / "src/mldsa_predictor.svh").write_text(
                "p_mldsa_rm = configuration.mldsa_rm;\n"
                f"typedef {transfer_type} mldsa_sb_ahb_ap_output_transaction_t;\n"
                f"{transfer_type} t;\n"
                'mldsa_sb_ahb_ap_output_transaction = mldsa_sb_ahb_ap_output_transaction_t::type_id::create("mldsa_sb_ahb_ap_output_transaction");\n'
                "line = line.substr(8);\n"
            )
            (env_pkg / "src/mldsa_scoreboard.svh").write_text(
                "scbr_mldsa_rm = configuration.mldsa_rm;\n"
                + (
                    "ahb_master_burst_transfer #("
                    "ahb_lite_slave_0_params::AHB_NUM_MASTERS, "
                    "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS, "
                    "ahb_lite_slave_0_params::AHB_NUM_SLAVES, "
                    "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH, "
                    "ahb_lite_slave_0_params::AHB_WDATA_WIDTH, "
                    "ahb_lite_slave_0_params::AHB_RDATA_WIDTH) item[$];\n"
                ) * 6
            )
            (sequences / "src/mldsa_bench_sequence_base.svh").write_text(
                "line = line.substr(8);\n"
            )
            (sequences / "src/ML_KEM_base_sequence.svh").write_text(
                '$fatal("Cannot open %s", fname);\n' * 6
            )
            (rtl / "abr_reg_uvm.sv").write_text(
                "class abr_reg__child extends uvm_reg_block;\n"
                'this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);\n'
                "endclass : abr_reg__child\n"
                "class abr_reg extends uvm_reg_block;\n"
                'this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);\n'
                "endclass : abr_reg\n"
            )
            filelist = Path(temp_dir) / "mldsa.vf"
            env_marker = "+incdir+${ADAMSBRIDGE_ROOT}/src/abr_top/uvmf/uvmf_template_output/verification_ip/environment_packages/mldsa_env_pkg\n"
            sequence_marker = "+incdir+${ADAMSBRIDGE_ROOT}/src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/sequences\n"
            ral_marker = "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_reg_uvm.sv\n"
            filelist.write_text(env_marker + sequence_marker + ral_marker)

            overlay_filelist, manifest_path = prepare_m16_mldsa_icarus_overlays(
                filelist, root, Path(temp_dir) / "row"
            )

            overlay_text = overlay_filelist.read_text()
            self.assertLess(overlay_text.index("+incdir+" + str(Path(temp_dir) / "row/overlays/mldsa_icarus/mldsa_env_pkg")), overlay_text.index(env_marker))
            self.assertLess(overlay_text.index("+incdir+" + str(Path(temp_dir) / "row/overlays/mldsa_icarus/mldsa_sequences")), overlay_text.index(sequence_marker))
            overlay_files = json.loads(manifest_path.read_text())["files"]
            overlay_manifest = json.loads(manifest_path.read_text())
            self.assertEqual(overlay_manifest["compile_defines"], ["CALIPTRA_BFM_AHB_32BIT"])
            self.assertNotIn("-DCALIPTRA_BFM_AHB_32BIT", overlay_text)
            self.assertEqual(len(overlay_files), 7)
            predictor_overlay = Path(overlay_files[1]["overlay"]).read_text()
            self.assertEqual(
                predictor_overlay.count("ahb_lite_slave_0_transfer_t"),
                2,
            )
            self.assertIn('mldsa_sb_ahb_ap_output_transaction = new("mldsa_sb_ahb_ap_output_transaction");', predictor_overlay)
            configuration_overlay = Path(overlay_files[0]["overlay"]).read_text()
            self.assertEqual(configuration_overlay.count("ahb_lite_slave_0_transfer_t::type_id::get()"), 2)
            environment_overlay = Path(overlay_files[3]["overlay"]).read_text()
            self.assertIn("typedef ahb_lite_slave_0_transfer_t ahb_reg_transfer_t;", environment_overlay)
            fatal_overlay = Path(overlay_files[-2]["overlay"]).read_text()
            self.assertEqual(fatal_overlay.count('$fatal(1, "Cannot open %s", fname);'), 6)
            ral_overlay = Path(overlay_files[-1]["overlay"]).read_text()
            self.assertEqual(ral_overlay.count("UVM_LITTLE_ENDIAN"), 1)
            self.assertEqual(ral_overlay.count("UVM_NO_ENDIAN"), 1)
            scoreboard_overlay = Path(overlay_files[2]["overlay"]).read_text()
            self.assertEqual(scoreboard_overlay.count("ahb_lite_slave_0_transfer_t"), 6)
            ral_overlay_path = Path(temp_dir) / "row/overlays/mldsa_icarus/abr_top/rtl/abr_reg_uvm.sv"
            self.assertIn(str(ral_overlay_path), overlay_text)
            self.assertNotIn(ral_marker, overlay_text)


if __name__ == "__main__":
    unittest.main()
