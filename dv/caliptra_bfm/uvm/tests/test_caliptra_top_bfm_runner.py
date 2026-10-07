import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


REPO = Path(__file__).resolve().parents[4]
RUNNER_PATH = REPO / "dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
SPEC = importlib.util.spec_from_file_location("caliptra_top_firmware_bfm", RUNNER_PATH)
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class CheckerCompileCommandTest(unittest.TestCase):
    def test_enabled_mode_adds_checker_define_but_keeps_assertions_when_disabled(self):
        enabled = RUNNER.fulltop_compile_command("iverilog", "profile.f", "sim.vvp", True)
        disabled = RUNNER.fulltop_compile_command("iverilog", "profile.f", "sim.vvp", False)
        self.assertIn("CALIPTRA_BFM_CHECKER", enabled)
        self.assertNotIn("CALIPTRA_BFM_CHECKER", disabled)
        self.assertIn("-gassertions", disabled)


class ResetInFlightTraceTest(unittest.TestCase):
    def scan(self, lines):
        with tempfile.TemporaryDirectory() as temp:
            log = Path(temp) / "sim.log"
            log.write_text("\n".join(lines) + "\n")
            return RUNNER.scan_sim_log(log)

    def test_reset_after_aw_before_b_is_in_flight(self):
        result = self.scan([
            "CALIPTRA_AXI AW count=1 addr=0 cycle=6239 pc=0000dd1a",
            "CALIPTRA_RESET_EDGE state=assert cycle=6254 pending=1 wait=3870 start=2382",
        ])
        self.assertTrue(result["reset_in_flight"])
        self.assertEqual(result["reset_assert_cycles"], [6254])
        self.assertEqual(result["outstanding_writes_at_reset"], [1])

    def test_reset_before_first_aw_is_not_in_flight(self):
        result = self.scan([
            "CALIPTRA_RESET_EDGE state=assert cycle=2896 pending=1 wait=512 start=2382",
            "CALIPTRA_AXI AW count=1 addr=0 cycle=5785 pc=0000dd1a",
        ])
        self.assertFalse(result["reset_in_flight"])
        self.assertEqual(result["reset_assert_cycles"], [2896])
        self.assertEqual(result["outstanding_writes_at_reset"], [0])

    def test_write_response_closes_the_outstanding_transfer(self):
        result = self.scan([
            "CALIPTRA_AXI AW count=1 addr=0 cycle=5785 pc=0000dd1a",
            "CALIPTRA_AXI B count=1 cycle=5817 pc=0000dd1a",
            "CALIPTRA_RESET_EDGE state=assert cycle=6000 pending=1 wait=3870 start=2382",
        ])
        self.assertFalse(result["reset_in_flight"])
        self.assertEqual(result["outstanding_writes_at_reset"], [0])


class ToolchainPrefixTest(unittest.TestCase):
    def test_accepts_absolute_prefix_with_trailing_dash(self):
        env = {"PATH": "/usr/bin"}
        prefix = RUNNER.normalize_gcc_prefix("/opt/riscv/bin/riscv64-unknown-elf-", env)
        self.assertEqual(prefix, "riscv64-unknown-elf")
        self.assertEqual(env["PATH"], f"/opt/riscv/bin{RUNNER.os.pathsep}/usr/bin")


class NativeVectorSelectionTest(unittest.TestCase):
    def test_pq_skip_keeps_only_non_pq_runtime_assets(self):
        selected = RUNNER.native_vector_outputs(skip_pq_vectors=True)
        self.assertEqual(set(selected.values()), {
            "ecc_secp384r1.exe", "doe_test_gen.py", "sha256_wntz_test_gen.py",
        })

    def test_default_keeps_all_runtime_assets(self):
        self.assertEqual(RUNNER.native_vector_outputs(skip_pq_vectors=False),
                         RUNNER.VECTOR_OUTPUTS)


class ProfileOverlayTest(unittest.TestCase):
    def test_fast_trng_profile_hash_checks_combined_top_overlay(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "rtl/src/integration/tb/caliptra_top_tb.sv"
            source.parent.mkdir(parents=True)
            source.write_text(".ListenPort     (63224)\nphysical_rng physical_rng (\n")
            rng_model = Path(temp) / "rtl/src/entropy_src/tb/physical_rng.sv"
            rng_model.parent.mkdir(parents=True)
            rng_model.write_text("module physical_rng; endmodule\n")
            output = Path(temp) / "top.sv"
            with patch.object(RUNNER, "sha256", side_effect=(
                    RUNNER.TOP_TB_SHA256, RUNNER.PHYSICAL_RNG_SHA256,
                    RUNNER.FAST_TRNG_TOP_TB_OVERLAY_SHA256)):
                RUNNER.prepare_jtag_port_overlay(Path(temp) / "rtl", output, fast_trng=True)
            overlay = output.read_text()
            self.assertTrue(overlay.startswith("`timescale 1ns/1ps\n"))
            self.assertIn(".ListenPort     (0)", overlay)
            self.assertIn("physical_rng #(.DutyCycle(50)) physical_rng (", overlay)

    def test_accelerated_rng_override_changes_only_physical_rng_instance(self):
        source = "module caliptra_top_tb;\nphysical_rng physical_rng (\n  .clk(core_clk)\n);\nendmodule\n"
        patched = RUNNER.accelerate_physical_rng_for_diagnostic(source)
        self.assertIn("physical_rng #(.DutyCycle(50)) physical_rng (", patched)
        self.assertEqual(patched.count("physical_rng #(.DutyCycle(50))"), 1)
        with self.assertRaisesRegex(ValueError, "physical_rng instance"):
            RUNNER.accelerate_physical_rng_for_diagnostic("module other; endmodule\n")

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
        top_services = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_services.sv"
        generator = "${CALIPTRA_ROOT}/src/integration/tb/dma_testcase_generator.sv"
        axi4pc = "${CALIPTRA_AXI4PC_DIR}/Axi4PC.sv"
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
            services_overlay = temp / "services.sv"
            services_overlay.write_text("module services_overlay; endmodule\n")
            baseline.write_text(
                f"+incdir+${{CALIPTRA_ROOT}}/src/integration/tb\n{original_aes_pkg}\n{original_axi_if}\n{original}\n{sram_export}\n"
                f"{top_sva}\n{soc_bfm}\n{top_tb}\n{generator}\n{top_services}\n"
                f"{axi4pc}\n"
            )

            def fake_aes_pkg_overlay(_rtl, path):
                Path(path).write_text("package aes_pkg_overlay; endpackage\n")

            def fake_axi_if_overlay(_rtl, path):
                Path(path).write_text("module axi_if_overlay; endmodule\n")

            with patch.object(RUNNER, "prepare_aes_pkg_overlay", side_effect=fake_aes_pkg_overlay), \
                    patch.object(RUNNER, "prepare_axi_if_overlay", side_effect=fake_axi_if_overlay):
                excluded_sources = RUNNER.prepare_iverilog_profile(
                    baseline, generated, REPO, rtl, checker_overlay, reset_overlay, jtag_overlay,
                    services_overlay=services_overlay,
                )
                self.assertEqual(excluded_sources, [axi4pc])
                baseline.write_text(baseline.read_text().replace(f"{axi4pc}\n", ""))
                excluded_sources = RUNNER.prepare_iverilog_profile(
                    baseline, temp / "without_axi4pc.vf", REPO, rtl,
                    checker_overlay, reset_overlay, jtag_overlay,
                    services_overlay=services_overlay,
                )
                self.assertEqual(excluded_sources, [])

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
            self.assertNotIn(axi4pc, content)
            self.assertIn(str(checker_overlay), content)
            self.assertNotIn(soc_bfm, content)
            self.assertNotIn(top_tb, content)
            self.assertIn(generator, content)
            self.assertNotIn(top_services, content)
            self.assertIn(str(services_overlay), content)
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


class FastBootDataPreloadTest(unittest.TestCase):
    def make_images(self, temp, branch="63 FA 62 00"):
        temp = Path(temp)
        program = temp / "program.hex"
        dccm = temp / "dccm.hex"
        map_file = temp / "firmware.map"
        dis_file = temp / "firmware.dis"
        program.write_text(
            "@00000040\n00 00 00 00 00 00 " + branch + "\n"
            "@00000100\n11 22 33 44 00 00 00 00\n"
        )
        dccm.write_text("@00000050\nAA BB\n")
        map_file.write_text(
            "  0x00000100 _data_lma_start = ALIGN (0x4)\n"
            "  0x00000104 _bss_lma_start = _data_lma_end\n"
            "  0x50000040 _data_vma_start = 0x50000040\n"
            "  0x00000108 _bss_lma_end = _bss_lma_start + SIZEOF (.bss)\n"
            "  0x50000044 _bss_vma_start = .\n"
            "  0x50000048 _bss_vma_end = _bss_vma_start + SIZEOF (.bss)\n"
        )
        dis_file.write_text(
            "       46: 0062fa63 bgeu t0,t1,5a <bss_cp_setup>\n"
            "0000004a <data_cp_loop>:\n"
            "0000005a <bss_cp_setup>:\n"
            "00000076 <bss_cp_loop>:\n"
            "00000086 <post_cp_loops>:\n"
        )
        return program, dccm, map_file, dis_file

    def test_preloads_data_and_patches_only_verified_startup_branch(self):
        with tempfile.TemporaryDirectory() as temp:
            program, dccm, map_file, dis_file = self.make_images(temp)
            result = RUNNER.prepare_fast_boot_data_preload(program, dccm, map_file, dis_file)
            self.assertEqual(RUNNER.read_hex_range(program.read_text(), 0x46, 0x4A),
                             bytes.fromhex("6f 00 00 04"))
            dccm_text = dccm.read_text()
            self.assertEqual(RUNNER.read_hex_range(dccm_text, 0x40, 0x44),
                             bytes.fromhex("11 22 33 44"))
            self.assertEqual(RUNNER.read_hex_range(dccm_text, 0x44, 0x48),
                             bytes.fromhex("00 00 00 00"))
            self.assertEqual(RUNNER.read_hex_range(dccm_text, 0x50, 0x52),
                             bytes.fromhex("aa bb"))
            self.assertEqual(result["data_bytes"], 4)
            self.assertEqual(result["bss_bytes"], 4)
            self.assertEqual(result["destination_offset"], "0x40")

    def test_rejects_nonzero_bss_image_without_mutating_images(self):
        with tempfile.TemporaryDirectory() as temp:
            program, dccm, map_file, dis_file = self.make_images(temp)
            program.write_text(program.read_text().replace("00 00 00 00\n", "00 00 00 01\n"))
            originals = (program.read_text(), dccm.read_text())
            with self.assertRaisesRegex(ValueError, "BSS load range is not zero-filled"):
                RUNNER.prepare_fast_boot_data_preload(program, dccm, map_file, dis_file)
            self.assertEqual((program.read_text(), dccm.read_text()), originals)

    def test_accepts_empty_bss_without_emitting_an_empty_segment(self):
        with tempfile.TemporaryDirectory() as temp:
            program, dccm, map_file, dis_file = self.make_images(temp)
            program.write_text("@00000040\n00 00 00 00 00 00 63 FA 62 00\n@00000100\n11 22 33 44\n")
            map_file.write_text(map_file.read_text().replace(
                "0x00000108 _bss_lma_end", "0x00000104 _bss_lma_end"
            ).replace(
                "0x50000048 _bss_vma_end", "0x50000044 _bss_vma_end"
            ))
            result = RUNNER.prepare_fast_boot_data_preload(program, dccm, map_file, dis_file)
            self.assertEqual(result["bss_bytes"], 0)
            self.assertNotIn("@00000044", dccm.read_text())

    def test_rejects_unrecognized_startup_without_mutating_images(self):
        with tempfile.TemporaryDirectory() as temp:
            program, dccm, map_file, dis_file = self.make_images(temp, "63 00 00 00")
            originals = (program.read_text(), dccm.read_text())
            with self.assertRaisesRegex(ValueError, "startup branch"):
                RUNNER.prepare_fast_boot_data_preload(program, dccm, map_file, dis_file)
            self.assertEqual((program.read_text(), dccm.read_text()), originals)


class DmaGeneratorOverlayTest(unittest.TestCase):
    def test_full_top_generator_uses_services_helper_scope(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "dma_testcase_generator_icarus.sv"
            with patch.object(RUNNER.subprocess, "run") as run:
                RUNNER.prepare_dma_generator_overlay(Path(temp) / "rtl", output)
            command = run.call_args.args[0]
            self.assertEqual(command[command.index("--top") + 1],
                             "caliptra_top_tb.tb_services_i")


class FirstAesCaseDiagnosticTest(unittest.TestCase):
    def test_limits_temporary_firmware_copy_to_first_dma_case(self):
        with tempfile.TemporaryDirectory() as temp:
            rtl = Path(temp) / "rtl"
            source = rtl / "src/integration/test_suites/smoke_test_dma_aes_gcm_short_1_dword"
            source.mkdir(parents=True)
            original = source / "smoke_test_dma_aes_gcm_short_1_dword.c"
            original.write_text(
                "test_config_t test_cases[] = {\n"
                "    {AES_ENC, AES_GCM, AES_256},\n"
                "    {AES_DEC, AES_GCM, AES_256},\n"
                "    {AES_ENC, AES_CBC, AES_256},\n"
                "};\n"
                "int num_tests = sizeof(test_cases) / sizeof(test_config_t);\n"
                "/* first test uses one dword */\n"
            )
            (source / "caliptra_isr.h").write_text("/* ISR declarations */\n")
            output_dir, digest = RUNNER.prepare_limited_aes_case_source(rtl, Path(temp) / "diagnostic", 1)
            patched = (output_dir / original.name).read_text()
            self.assertIn("int num_tests = 1; /* bounded AES DMA diagnostic */", patched)
            entries = [line.strip() for line in patched.splitlines()
                       if line.strip().startswith(("{AES_ENC,", "{AES_DEC,"))]
            self.assertEqual(entries, ["{AES_ENC, AES_GCM, AES_256},"])
            self.assertEqual(
                original.read_text(),
                "test_config_t test_cases[] = {\n"
                "    {AES_ENC, AES_GCM, AES_256},\n"
                "    {AES_DEC, AES_GCM, AES_256},\n"
                "    {AES_ENC, AES_CBC, AES_256},\n"
                "};\n"
                "int num_tests = sizeof(test_cases) / sizeof(test_config_t);\n"
                "/* first test uses one dword */\n",
            )
            self.assertEqual(digest, RUNNER.sha256(output_dir / original.name))
            self.assertTrue((output_dir / "caliptra_isr.h").is_file())

    def test_limits_aes_copy_to_requested_prefix_and_checks_table_bound(self):
        with tempfile.TemporaryDirectory() as temp:
            rtl = Path(temp) / "rtl"
            source = rtl / "src/integration/test_suites/smoke_test_dma_aes_gcm_short_1_dword"
            source.mkdir(parents=True)
            original = source / "smoke_test_dma_aes_gcm_short_1_dword.c"
            original.write_text(
                "test_config_t test_cases[] = {\n"
                "    {AES_ENC, AES_GCM, AES_256},\n"
                "    {AES_DEC, AES_GCM, AES_256},\n"
                "    {AES_ENC, AES_CBC, AES_256},\n"
                "};\n"
                "int num_tests = sizeof(test_cases) / sizeof(test_config_t);\n"
            )
            (source / "caliptra_isr.h").write_text("/* ISR declarations */\n")
            output_dir, _ = RUNNER.prepare_limited_aes_case_source(rtl, Path(temp) / "diagnostic", 2)
            patched = (output_dir / original.name).read_text()
            self.assertIn("int num_tests = 2; /* bounded AES DMA diagnostic */", patched)
            entries = [line.strip() for line in patched.splitlines()
                       if line.strip().startswith(("{AES_ENC,", "{AES_DEC,"))]
            self.assertEqual(entries, [
                "{AES_ENC, AES_GCM, AES_256},",
                "{AES_DEC, AES_GCM, AES_256},",
            ])
            with self.assertRaisesRegex(ValueError, "between 1 and 3"):
                RUNNER.prepare_limited_aes_case_source(rtl, Path(temp) / "too-many", 4)

    def test_limits_aes_copy_to_requested_case_window(self):
        with tempfile.TemporaryDirectory() as temp:
            rtl = Path(temp) / "rtl"
            source = rtl / "src/integration/test_suites/smoke_test_dma_aes_gcm_short_1_dword"
            source.mkdir(parents=True)
            original = source / "smoke_test_dma_aes_gcm_short_1_dword.c"
            original.write_text(
                "test_config_t test_cases[] = {\n"
                "    {AES_ENC, AES_GCM, AES_256},\n"
                "    {AES_DEC, AES_GCM, AES_256},\n"
                "    {AES_ENC, AES_CBC, AES_256},\n"
                "};\n"
                "int num_tests = sizeof(test_cases) / sizeof(test_config_t);\n"
            )
            (source / "caliptra_isr.h").write_text("/* ISR declarations */\n")
            output_dir, _ = RUNNER.prepare_limited_aes_case_source(
                rtl, Path(temp) / "diagnostic", 1, case_start=1
            )
            patched = (output_dir / original.name).read_text()
            self.assertIn("int num_tests = 1; /* bounded AES DMA diagnostic */", patched)
            entries = [line.strip() for line in patched.splitlines()
                       if line.strip().startswith(("{AES_ENC,", "{AES_DEC,"))]
            self.assertEqual(entries, ["{AES_DEC, AES_GCM, AES_256},"])
            with self.assertRaisesRegex(ValueError, "case window starting at 2"):
                RUNNER.prepare_limited_aes_case_source(
                    rtl, Path(temp) / "out-of-range", 2, case_start=2
                )

    def test_cli_exposes_multi_case_limit(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--help"],
            capture_output=True, text=True, check=True,
        )
        self.assertIn("--limit-aes-cases N", result.stdout)
        self.assertIn("--start-aes-case INDEX", result.stdout)
        self.assertIn("zero-based start index", result.stdout)

    def test_aes_case_start_requires_a_limit(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--start-aes-case", "1",
             "--output", str(Path(tempfile.gettempdir()) / "unused-caliptra-bfm-output")],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("--start-aes-case requires --limit-aes-cases", result.stderr)

    def test_aes_case_start_must_be_nonnegative(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--start-aes-case", "-1",
             "--limit-aes-cases", "1", "--case", "smoke_test_dma_aes_gcm_short_1_dword",
             "--output", str(Path(tempfile.gettempdir()) / "unused-caliptra-bfm-output")],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("--start-aes-case must be nonnegative", result.stderr)

    def test_case_limit_is_short_aes_only(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--case", "smoke_test_dma",
             "--limit-aes-cases", "2",
             "--output", str(Path(tempfile.gettempdir()) / "unused-caliptra-bfm-output")],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("AES case limits are available only for", result.stderr)

    def test_cli_exposes_pq_skip_without_limiting_firmware_to_one_case(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--help"],
            capture_output=True, text=True, check=True,
        )
        self.assertIn("--skip-pq-vector-generation", result.stdout)
        self.assertIn("keep all AES DMA cases", result.stdout)

    def test_pq_skip_is_limited_to_the_short_aes_case(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--case", "smoke_test_dma",
             "--output", str(Path(tempfile.gettempdir()) / "unused-caliptra-bfm-output"),
             "--skip-pq-vector-generation"],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("limited to smoke_test_dma_aes_gcm_short_1_dword", result.stderr)

    def test_cli_exposes_quiet_mode_without_limiting_firmware_cases(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--help"],
            capture_output=True, text=True, check=True,
        )
        self.assertIn("--quiet-firmware", result.stdout)
        self.assertIn("keep all AES DMA cases", result.stdout)

    def test_cli_exposes_axi_trace(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--help"],
            capture_output=True, text=True, check=True,
        )
        self.assertIn("--trace-axi", result.stdout)
        self.assertIn("trace CPU progress", result.stdout)
        self.assertIn("handshakes with VPI", result.stdout)

    def test_quiet_mode_is_limited_to_the_short_aes_case(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--case", "smoke_test_dma",
             "--output", str(Path(tempfile.gettempdir()) / "unused-caliptra-bfm-output"),
             "--quiet-firmware"],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("requires a supported DMA firmware case", result.stderr)

    def test_skips_only_unrelated_pq_vector_calls_when_requested(self):
        source = (
            "            ecc_testvector_generator();\n"
            "            mldsa_input_hex_gen();\n"
            "            mlkem_testvector_generator();\n"
            "            doe_testvector_generator();\n"
        )
        patched = RUNNER.skip_pq_vector_generators(source)
        self.assertIn('if (!$test$plusargs("CLP_SKIP_PQ_VECTOR_GENERATION")) begin', patched)
        self.assertIn("ecc_testvector_generator();", patched)
        self.assertIn("doe_testvector_generator();", patched)
        self.assertEqual(patched.count("mldsa_input_hex_gen();"), 1)
        self.assertEqual(patched.count("mlkem_testvector_generator();"), 1)
        with self.assertRaisesRegex(ValueError, "MLDSA/MLKEM"):
            RUNNER.skip_pq_vector_generators("no generator calls\n")

    def test_replaces_only_the_random_reset_delay_block(self):
        source = (
            "            `ifndef VERILATOR\n"
            "                std::randomize(wait_time_to_rst) with {wait_time_to_rst dist {[5:24] :/ 3, [25:99] :/ 5, [100:255] :/ 8, [256:511] :/ 5, [512:1023] :/ 1};};\n"
            "            `else\n"
            "                wait_time_to_rst = $urandom_range(5,150);\n"
            "            `endif\n"
            "            prandom_warm_rst <= 'b1;\n"
        )
        patched = RUNNER.replace_random_reset_delay(source, 512)
        self.assertIn("            wait_time_to_rst = 512;\n", patched)
        late_patched = RUNNER.replace_random_reset_delay(source, 3870)
        self.assertIn("            wait_time_to_rst = 3870;\n", late_patched)
        self.assertNotIn("std::randomize(wait_time_to_rst)", patched)
        self.assertIn("            prandom_warm_rst <= 'b1;\n", patched)
        with self.assertRaisesRegex(ValueError, "between 5 and 8191 cycles"):
            RUNNER.replace_random_reset_delay(source, 8192)
        with self.assertRaisesRegex(ValueError, "random warm-reset delay block"):
            RUNNER.replace_random_reset_delay("no reset block\n", 512)

    def test_services_overlay_combines_reset_delay_and_pq_skip(self):
        source = (
            "            mldsa_input_hex_gen();\n"
            "            mlkem_testvector_generator();\n"
            "            `ifndef VERILATOR\n"
            "                std::randomize(wait_time_to_rst) with {wait_time_to_rst dist {[5:24] :/ 3, [25:99] :/ 5, [100:255] :/ 8, [256:511] :/ 5, [512:1023] :/ 1};};\n"
            "            `else\n"
            "                wait_time_to_rst = $urandom_range(5,150);\n"
            "            `endif\n"
        )
        with tempfile.TemporaryDirectory() as temp:
            rtl = Path(temp) / "rtl"
            source_path = rtl / "src/integration/tb/caliptra_top_tb_services.sv"
            source_path.parent.mkdir(parents=True)
            source_path.write_text(source)
            output = Path(temp) / "services.sv"
            with patch.object(RUNNER, "sha256", return_value=RUNNER.TOP_SERVICES_SHA256):
                RUNNER.prepare_services_overlay(rtl, output, True, 512)
            overlay = output.read_text()
        self.assertIn('if (!$test$plusargs("CLP_SKIP_PQ_VECTOR_GENERATION")) begin', overlay)
        self.assertIn("            wait_time_to_rst = 512;\n", overlay)
        self.assertNotIn("std::randomize(wait_time_to_rst)", overlay)

    def test_cli_exposes_fixed_random_reset_delay(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--help"],
            capture_output=True, text=True, check=True,
        )
        self.assertIn("--rand-dma-reset-delay-cycles", result.stdout)
        self.assertIn("fixed 5..8191-cycle delay", result.stdout)

    def test_fixed_reset_delay_requires_the_forced_first_reset(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--case", "rand_test_dma",
             "--rand-dma-iterations", "1", "--rand-dma-reset-delay-cycles", "512",
             "--output", str(Path(tempfile.gettempdir()) / "unused-caliptra-bfm-output")],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("requires --force-first-rand-dma-reset", result.stderr)

    def test_fixed_reset_delay_requires_axi_trace(self):
        result = subprocess.run(
            ["python3", str(RUNNER_PATH), "--case", "rand_test_dma",
             "--rand-dma-iterations", "1", "--force-first-rand-dma-reset",
             "--rand-dma-reset-delay-cycles", "3870",
             "--output", str(Path(tempfile.gettempdir()) / "unused-caliptra-bfm-output")],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("requires --trace-axi", result.stderr)


if __name__ == "__main__":
    unittest.main()
