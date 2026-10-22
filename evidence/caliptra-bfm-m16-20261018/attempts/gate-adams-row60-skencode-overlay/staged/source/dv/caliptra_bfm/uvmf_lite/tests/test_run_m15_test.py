import os
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import run_m15_test

from run_m15_test import (
    classify,
    classify_pkdecode,
    classify_skencode,
    classify_sigdecode_h,
    first_diagnostic,
    fix_butterfly_expected_vector,
    fix_csrng_tb_filelist,
    fix_mldsa_ahb_transfer_types,
    fix_mldsa_config_rm_access,
    fix_mldsa_env_configuration,
    fix_mldsa_kem_fatals,
    fix_mldsa_predictor,
    fix_mldsa_reg_model_endian,
    fix_mldsa_scoreboard,
    fix_mldsa_substr,
    fix_pkdecode_tb,
    fix_skencode_tb,
    fix_sigdecode_h_tb,
    fix_sigdecode_z_tb,
    fix_soc_ifc_dict_initializers,
    needs_m16_open_mvc_filelist,
    prepare_m16_mldsa_icarus_overlays,
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
        row = {"test_kind": "generated-uvmf", "environment_id": "uvmf-sha512"}
        self.assertTrue(needs_m16_open_mvc_filelist(row))
        row["test_kind"] = "authored-stimulus"
        self.assertFalse(needs_m16_open_mvc_filelist(row))


class M16MldsaOverlayTest(unittest.TestCase):
    def test_env_configuration_overlay_only_fixes_pinned_constructs(self):
        source = (
            '"\\n", qvip_ahb_lite_slave_subenv_config.convert2string\n'
            "qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];\n"
            "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];\n"
            "unrelated_names = interface_names[0:0];\n"
        )
        overlaid = fix_mldsa_env_configuration(source)
        self.assertIn('qvip_ahb_lite_slave_subenv_config.convert2string()', overlaid)
        self.assertIn("qvip_ahb_lite_slave_subenv_interface_names[0] = interface_names[0];", overlaid)
        self.assertIn("qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];", overlaid)
        self.assertIn("unrelated_names = interface_names[0:0];", overlaid)

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
            "line = line.substr(8);\n"
        )
        overlaid = fix_mldsa_predictor(source)
        self.assertIn(
            "ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer "
            "mldsa_sb_ahb_ap_output_transaction_t;",
            overlaid,
        )
        self.assertIn("ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer t;", overlaid)
        self.assertNotIn("ahb_master_burst_transfer #(", overlaid)
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
        alias = "ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer "
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
            (env_pkg / "src/mldsa_env_configuration.svh").write_text(
                'qvip_ahb_lite_slave_subenv_config.convert2string\n'
                "qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];\n"
                "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];\n"
            )
            transfer_type = (
                "ahb_master_burst_transfer #("
                "ahb_lite_slave_0_params::AHB_NUM_MASTERS, "
                "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS, "
                "ahb_lite_slave_0_params::AHB_NUM_SLAVES, "
                "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH, "
                "ahb_lite_slave_0_params::AHB_WDATA_WIDTH, "
                "ahb_lite_slave_0_params::AHB_RDATA_WIDTH)"
            )
            (env_pkg / "src/mldsa_predictor.svh").write_text(
                "p_mldsa_rm = configuration.mldsa_rm;\n"
                f"typedef {transfer_type} mldsa_sb_ahb_ap_output_transaction_t;\n"
                f"{transfer_type} t;\n"
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
            self.assertEqual(len(overlay_files), 6)
            predictor_overlay = Path(overlay_files[1]["overlay"]).read_text()
            self.assertEqual(
                predictor_overlay.count("ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer"),
                2,
            )
            fatal_overlay = Path(overlay_files[-2]["overlay"]).read_text()
            self.assertEqual(fatal_overlay.count('$fatal(1, "Cannot open %s", fname);'), 6)
            ral_overlay = Path(overlay_files[-1]["overlay"]).read_text()
            self.assertEqual(ral_overlay.count("UVM_LITTLE_ENDIAN"), 1)
            self.assertEqual(ral_overlay.count("UVM_NO_ENDIAN"), 1)
            scoreboard_overlay = Path(overlay_files[2]["overlay"]).read_text()
            self.assertEqual(scoreboard_overlay.count("ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer"), 6)
            ral_overlay_path = Path(temp_dir) / "row/overlays/mldsa_icarus/abr_top/rtl/abr_reg_uvm.sv"
            self.assertIn(str(ral_overlay_path), overlay_text)
            self.assertNotIn(ral_marker, overlay_text)


if __name__ == "__main__":
    unittest.main()
