import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


REPO = Path(__file__).resolve().parents[4]
RUNNER_PATH = REPO / "dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
SPEC = importlib.util.spec_from_file_location("caliptra_top_firmware_bfm", RUNNER_PATH)
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class ProfileOverlayTest(unittest.TestCase):
    def test_lists_short_dma_aes_gcm_firmware_case(self):
        self.assertIn("smoke_test_dma_aes_gcm_short_1_dword", RUNNER.CASE_NAMES)

    def test_rewrites_only_aes_mul2_partial_result_writes(self):
        source = (
            "function automatic logic [7:0] aes_mul2(logic [7:0] in);\n"
            "  logic [7:0] out;\n"
            "  out[7] = in[6];\n"
            "  out[6] = in[5];\n"
            "  out[5] = in[4];\n"
            "  out[4] = in[3] ^ in[7];\n"
            "  out[3] = in[2] ^ in[7];\n"
            "  out[2] = in[1];\n"
            "  out[1] = in[0] ^ in[7];\n"
            "  out[0] = in[7];\n"
            "  return out;\n"
            "endfunction\n"
        )
        patched = RUNNER.replace_aes_mul2_partial_writes(source)
        self.assertIn("out = {in[6:0], 1'b0} ^ (in[7] ? 8'h1b : 8'h00);", patched)
        self.assertNotIn("out[7] =", patched)
        with self.assertRaisesRegex(ValueError, "AES mul2 partial-write block"):
            RUNNER.replace_aes_mul2_partial_writes("function automatic logic [7:0] other(); endfunction\n")

    def test_replaces_only_original_axi_complex_and_adds_open_sources(self):
        original_aes_pkg = "${CALIPTRA_ROOT}/src/aes/rtl/aes_pkg.sv"
        original_axi_if = "${CALIPTRA_ROOT}/src/axi/rtl/axi_if.sv"
        original = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_axi_complex.sv"
        sram_export = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_veer_sram_export.sv"
        top_sva = "${CALIPTRA_ROOT}/src/integration/asserts/caliptra_top_sva.sv"
        soc_bfm = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_soc_bfm.sv"
        top_tb = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb.sv"
        generator = "${CALIPTRA_ROOT}/src/integration/tb/dma_testcase_generator.sv"
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            baseline = temp / "base.vf"
            generated = temp / "open.vf"
            rtl = temp / "rtl"
            sram_path = rtl / "src/integration/tb/caliptra_veer_sram_export.sv"
            sram_path.parent.mkdir(parents=True)
            sram_path.write_text(
                "module caliptra_veer_sram_export;\n"
                "int ii,jj,kk,ll;\n"
                "localparam DCCM_INDEX_DEPTH = 1;\n"
                ".Q({el2_mem_export.iccm_bank_ecc[i][pt.ICCM_ECC_WIDTH-1:0],"
                "el2_mem_export.iccm_bank_dout[i][31:0]})\n"
                ".Q   ({el2_mem_export.dccm_bank_ecc[i][pt.DCCM_ECC_WIDTH-1:0],"
                "el2_mem_export.dccm_bank_dout[i][pt.DCCM_DATA_WIDTH-1:0]})\n"
            )
            checker_overlay = temp / "checker.sv"
            checker_overlay.write_text("module checker_overlay; endmodule\n")
            reset_overlay = temp / "reset.sv"
            reset_overlay.write_text("module reset_overlay; endmodule\n")
            jtag_overlay = temp / "jtag.sv"
            jtag_overlay.write_text("module jtag_overlay; endmodule\n")
            baseline.write_text(
                f"+incdir+${{CALIPTRA_ROOT}}/src/integration/tb\n{original_aes_pkg}\n{original_axi_if}\n{original}\n{sram_export}\n"
                f"{top_sva}\n{soc_bfm}\n{top_tb}\n{generator}\n"
            )

            def fake_aes_pkg_overlay(_rtl, path):
                Path(path).write_text("package aes_pkg_overlay; endpackage\n")

            def fake_axi_if_overlay(_rtl, path):
                Path(path).write_text("module axi_if_overlay; endmodule\n")

            with patch.object(RUNNER, "prepare_aes_pkg_overlay", side_effect=fake_aes_pkg_overlay), \
                    patch.object(RUNNER, "prepare_axi_if_overlay", side_effect=fake_axi_if_overlay):
                RUNNER.prepare_iverilog_profile(
                    baseline, generated, REPO, rtl, checker_overlay, reset_overlay, jtag_overlay
                )

            content = generated.read_text()
            self.assertNotIn(original_aes_pkg, content)
            self.assertIn(str(temp / "aes_pkg_icarus.sv"), content)
            self.assertNotIn(original_axi_if, content)
            self.assertIn(str(temp / "axi_if_icarus.sv"), content)
            self.assertNotIn(original, content)
            self.assertIn(str(REPO / "dv/caliptra_bfm/axi/caliptra_top_tb_axi_complex_bfm.sv"), content)
            self.assertIn(str(REPO / "dv/caliptra_bfm/axi/axi4_caliptra_dma_subordinate.sv"), content)
            self.assertNotIn(sram_export, content)
            self.assertNotIn(top_sva, content)
            self.assertIn(str(checker_overlay), content)
            self.assertNotIn(soc_bfm, content)
            self.assertNotIn(top_tb, content)
            self.assertIn(generator, content)
            self.assertIn("+incdir+${CALIPTRA_ROOT}/src/integration/tb", content)
            overlay = (temp / "caliptra_veer_sram_export_icarus.sv").read_text()
            self.assertIn("dccm_bank_ecc_icarus[i]", overlay)
            self.assertIn("iccm_bank_ecc_icarus[i]", overlay)
            self.assertNotIn("el2_mem_export.dccm_bank_ecc[i]", overlay)

    def test_rejects_ambiguous_profile(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            baseline = temp / "base.vf"
            baseline.write_text("no AXI complex here\n")
            checker_overlay = temp / "checker.sv"
            with self.assertRaisesRegex(ValueError, "exactly one"):
                RUNNER.prepare_iverilog_profile(
                    baseline, temp / "open.vf", REPO, temp / "rtl", checker_overlay,
                    temp / "reset.sv", temp / "jtag.sv"
                )

    def test_allocates_response_user_array_before_read_beat_writes(self):
        source = "            data = new[len+1];\n            resp = new[len+1];\n"
        patched = RUNNER.allocate_axi_read_resp_user(source)
        self.assertIn("            resp_user = new[len+1];\n", patched)
        self.assertEqual(patched.count("resp_user = new[len+1];"), 1)
        with self.assertRaisesRegex(ValueError, "response-array allocation"):
            RUNNER.allocate_axi_read_resp_user("no allocation sequence\n")

    def test_removes_checker_print_without_removing_failure_result(self):
        source = ('if (bad) begin\n  $display("SVA ERROR: KV[%0d][%0d] debug flush failed. Expected: %h, Got: %h, SelValue: %0d", actual, expected);\n'
                  "  return 1'b0;\nend\n")
        overlay, count = RUNNER.remove_sva_debug_print(
            source, RUNNER.SVA_DIAGNOSTICS_TO_REMOVE[0]
        )
        self.assertEqual(count, 1)
        self.assertNotIn("SVA ERROR", overlay)
        self.assertIn("return 1'b0;", overlay)


if __name__ == "__main__":
    unittest.main()
