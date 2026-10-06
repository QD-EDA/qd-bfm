import importlib.util
from pathlib import Path
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[4]
RUNNER_PATH = REPO / "dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
SPEC = importlib.util.spec_from_file_location("caliptra_top_firmware_bfm", RUNNER_PATH)
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class ProfileOverlayTest(unittest.TestCase):
    def test_replaces_only_original_axi_complex_and_adds_open_sources(self):
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
                f"+incdir+${{CALIPTRA_ROOT}}/src/integration/tb\n{original}\n{sram_export}\n"
                f"{top_sva}\n{soc_bfm}\n{top_tb}\n{generator}\n"
            )

            RUNNER.prepare_iverilog_profile(
                baseline, generated, REPO, rtl, checker_overlay, reset_overlay, jtag_overlay
            )

            content = generated.read_text()
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
