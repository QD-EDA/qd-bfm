#!/usr/bin/env python3
"""Rebuild and compile the pinned generated SoC-IFC host environment."""

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


COMMIT = "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e"
MEMORY_GUARD_CHILD = "CALIPTRA_BFM_MEMORY_GUARD_CHILD"


def run(*args: str) -> None:
    subprocess.run(args, check=True)


def run_under_memory_guard(repo: Path) -> int | None:
    if os.environ.get(MEMORY_GUARD_CHILD) == "1" or "--help" in sys.argv or "-h" in sys.argv:
        return None
    guard = repo / "scripts/run_with_memory_pressure_guard.py"
    default_timeout = "300" if any(
        option in sys.argv
        for option in ("--include-project-bench-packages", "--generated-environment-runtime")
    ) else "90"
    timeout = os.environ.get("CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS", default_timeout)
    command = [
        sys.executable,
        str(guard),
        "--min-free-percent",
        os.environ.get("CALIPTRA_BFM_MIN_FREE_PERCENT", "60"),
        "--timeout-seconds",
        timeout,
        "--",
        sys.executable,
        str(Path(__file__).resolve()),
        *sys.argv[1:],
    ]
    environment = os.environ.copy()
    environment[MEMORY_GUARD_CHILD] = "1"
    return subprocess.run(command, env=environment).returncode


def main() -> int:
    repo = Path(__file__).resolve().parents[2]
    guarded_result = run_under_memory_guard(repo)
    if guarded_result is not None:
        return guarded_result
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--caliptra-root", type=Path, default=repo.parent / "caliptra-rtl")
    parser.add_argument("--iverilog", default=os.environ.get("IVERILOG_BIN", "iverilog"))
    parser.add_argument(
        "--include-project-bench-packages",
        action="store_true",
        help="also compile generated soc_ifc_parameters, sequences, and tests packages",
    )
    parser.add_argument(
        "--generated-environment-runtime",
        action="store_true",
        help="run generated SoC-IFC UVMF runtime probes against the actual soc_ifc_top RTL",
    )
    parser.add_argument(
        "--generated-axi-user-init",
        action="store_true",
        help="also run Caliptra's stock 12-write AXI USER RAL sequence (runtime mode only)",
    )
    parser.add_argument(
        "--generated-axi-user-reject-probe",
        action="store_true",
        help="check an invalid mailbox AXI USER read is rejected before the generated AHB mailbox claim",
    )
    parser.add_argument(
        "--generated-ahb-ral-read",
        action="store_true",
        help="read the unlocked mailbox lock through the generated AHB RAL map (runtime mode only)",
    )
    parser.add_argument(
        "--generated-ahb-ral-dlen-write-readback",
        action="store_true",
        help="claim the mailbox, then write/read back MBOX_DLEN through generated AHB RAL (runtime mode only)",
    )
    parser.add_argument(
        "--generated-ahb-mbox-payload",
        action="store_true",
        help="send a four-word mailbox request through generated AHB RAL and check open SRAM (runtime mode only)",
    )
    parser.add_argument(
        "--open-mbox-target",
        action="store_true",
        help="attach the open mailbox SRAM model to generated hdl_top (runtime mode only)",
    )
    parser.add_argument(
        "--open-mbox-ecc-injection",
        choices=("single", "double"),
        help="inject one generated-BFM ECC fault on the first mailbox SRAM write",
    )
    parser.add_argument(
        "--trace-predictor-reset",
        action="store_true",
        help="add flushed checkpoints to the disposable predictor copy for runtime diagnosis",
    )
    args = parser.parse_args()
    if args.trace_predictor_reset and not args.generated_environment_runtime:
        parser.error("--trace-predictor-reset requires --generated-environment-runtime")
    if args.generated_axi_user_init and not args.generated_environment_runtime:
        parser.error("--generated-axi-user-init requires --generated-environment-runtime")
    if args.generated_axi_user_reject_probe and not args.generated_axi_user_init:
        parser.error("--generated-axi-user-reject-probe requires --generated-axi-user-init")
    if args.generated_axi_user_reject_probe and not args.generated_ahb_mbox_payload:
        parser.error("--generated-axi-user-reject-probe requires --generated-ahb-mbox-payload")
    if args.generated_ahb_ral_read and not args.generated_environment_runtime:
        parser.error("--generated-ahb-ral-read requires --generated-environment-runtime")
    if args.generated_ahb_ral_dlen_write_readback and not args.generated_environment_runtime:
        parser.error("--generated-ahb-ral-dlen-write-readback requires --generated-environment-runtime")
    if args.generated_ahb_mbox_payload and not args.generated_environment_runtime:
        parser.error("--generated-ahb-mbox-payload requires --generated-environment-runtime")
    if args.generated_ahb_mbox_payload and (args.generated_ahb_ral_read or args.generated_ahb_ral_dlen_write_readback):
        parser.error("--generated-ahb-mbox-payload includes its own mailbox claim and MBOX_DLEN check")
    if args.generated_environment_runtime:
        args.include_project_bench_packages = True
    if args.generated_ahb_mbox_payload:
        args.open_mbox_target = True
    if args.open_mbox_target and not args.generated_environment_runtime:
        parser.error("--open-mbox-target requires --generated-environment-runtime")
    if args.open_mbox_ecc_injection and not args.open_mbox_target:
        parser.error("--open-mbox-ecc-injection requires --open-mbox-target")
    caliptra = args.caliptra_root.resolve()
    if subprocess.check_output(["git", "-C", str(caliptra), "rev-parse", "HEAD"], text=True).strip() != COMMIT:
        raise SystemExit(f"expected clean Caliptra commit {COMMIT}")
    if subprocess.check_output(["git", "-C", str(caliptra), "status", "--porcelain"], text=True):
        raise SystemExit("refusing a modified Caliptra checkout")

    overlay_tools = repo / "docs/conformance/release_overlays/caliptra"
    package_root = caliptra / "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/interface_packages"
    env_root = caliptra / "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/environment_packages/soc_ifc_env_pkg"
    with tempfile.TemporaryDirectory(prefix="caliptra-soc-ifc-env-") as temp_name:
        temp = Path(temp_name)
        packages, rtl, env = temp / "packages", temp / "rtl", temp / "env"
        run("python3", str(overlay_tools / "soc_ifc_generated_empty_psprintf_overlay.py"), "--caliptra-root", str(caliptra), "--output", str(packages))
        run("python3", str(overlay_tools / "soc_ifc_host_coverage_wildcard_overlay.py"), "--caliptra-root", str(caliptra), "--packages", str(packages), "--rtl-output", str(rtl))
        run("python3", str(overlay_tools / "soc_ifc_generated_responder_modport_overlay.py"), "--packages", str(packages))
        run("python3", str(overlay_tools / "soc_ifc_generated_case_selector_overlay.py"), "--caliptra-root", str(caliptra), "--output", str(env))
        if args.generated_environment_runtime:
            ahb_transfer_type = re.compile(
                r"ahb_master_burst_transfer\s*#\s*\(\s*"
                r"ahb_lite_slave_0_params::AHB_NUM_MASTERS\s*,\s*"
                r"ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS\s*,\s*"
                r"ahb_lite_slave_0_params::AHB_NUM_SLAVES\s*,\s*"
                r"ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH\s*,\s*"
                r"ahb_lite_slave_0_params::AHB_WDATA_WIDTH\s*,\s*"
                r"ahb_lite_slave_0_params::AHB_RDATA_WIDTH\s*\)"
            )
            ahb_type_replacements = 0
            for original in env_root.rglob("*.svh"):
                source = env / original.relative_to(env_root)
                source_text = source.read_text() if source.exists() else original.read_text()
                source_text, replacements = ahb_transfer_type.subn(
                    "ahb_lite_slave_0_transfer_t", source_text
                )
                if replacements:
                    source.parent.mkdir(parents=True, exist_ok=True)
                    source.write_text(source_text)
                    ahb_type_replacements += replacements
            if not ahb_type_replacements:
                raise SystemExit("generated AHB transfer type was not found in the disposable environment")
            predictor = env / "src/soc_ifc_predictor.svh"
            predictor_text = predictor.read_text()
            ahb_factory_create = (
                "soc_ifc_sb_ahb_ap_output_transaction = "
                "soc_ifc_sb_ahb_ap_output_transaction_t::type_id::create("
                '"soc_ifc_sb_ahb_ap_output_transaction");'
            )
            if not predictor_text.count(ahb_factory_create):
                raise SystemExit("generated AHB predictor output construction changed unexpectedly")
            predictor.write_text(
                predictor_text.replace(
                    ahb_factory_create,
                    'soc_ifc_sb_ahb_ap_output_transaction = new("soc_ifc_sb_ahb_ap_output_transaction");',
                )
            )
            predictor_text = predictor.read_text()
            ahb_copy = "soc_ifc_sb_ahb_ap_output_transaction.copy(ahb_txn);"
            if predictor_text.count(ahb_copy) != 1:
                raise SystemExit("generated AHB predictor copy operation changed unexpectedly")
            predictor.write_text(
                predictor_text.replace(
                    ahb_copy,
                    "soc_ifc_sb_ahb_ap_output_transaction.RnW = ahb_txn.RnW;\n"
                    "    soc_ifc_sb_ahb_ap_output_transaction.address = ahb_txn.address;\n"
                    "    soc_ifc_sb_ahb_ap_output_transaction.size = ahb_txn.size;\n"
                    "    soc_ifc_sb_ahb_ap_output_transaction.data = ahb_txn.data;\n"
                    "    soc_ifc_sb_ahb_ap_output_transaction.resp = ahb_txn.resp;",
                    1,
                )
            )
            scoreboard = env / "src/soc_ifc_scoreboard.svh"
            scoreboard_text = scoreboard.read_text()
            ahb_compare = """        t_exp = ahb_expected_q.pop_front();
        txn_eq = t.compare(t_exp);"""
            if scoreboard_text.count(ahb_compare) != 1:
                raise SystemExit("generated AHB scoreboard comparison changed unexpectedly")
            scoreboard.write_text(
                scoreboard_text.replace(
                    ahb_compare,
                    "        t_exp = ahb_expected_q.pop_front();\n"
                    "        txn_eq = t.RnW == t_exp.RnW && t.address == t_exp.address && "
                    "t.size == t_exp.size && t.data.size() == t_exp.data.size() && "
                    "t.resp.size() == t_exp.resp.size();\n"
                    "        if (txn_eq) foreach (t.data[i]) txn_eq &= t.data[i] == t_exp.data[i];\n"
                    "        if (txn_eq) foreach (t.resp[i]) txn_eq &= t.resp[i] == t_exp.resp[i];",
                    1,
                )
            )
            print(
                "normalized generated AHB transfer references to the clean-room compatibility typedef "
                f"({ahb_type_replacements} replacements), direct construction, and protocol-field comparison"
            )
        if args.generated_environment_runtime:
            reset_sequence = packages / "soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_reset_sequence_base.svh"
            reset_source = reset_sequence.read_text()
            for anchor, expected_count in (
                ("      req.set_pwrgood = 1'b0;", 1),
                ("      req.set_pwrgood = 1'b1;", 2),
                ("      req.assert_rst = 1'b0;", 1),
            ):
                if reset_source.count(anchor) != expected_count:
                    raise SystemExit(
                        "reset-state adaptation refused unexpected sequence source at "
                        + repr(anchor)
                    )
                reset_source = reset_source.replace(
                    anchor,
                    "      req.security_state = 3'b111; // debug locked, production lifecycle\n"
                    + anchor,
                )
            reset_sequence.write_text(reset_source)
            print("set deterministic debug-locked production state in disposable runtime reset sequence")
            ctrl_driver_bfm = packages / "soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_driver_bfm.sv"
            driver_source = ctrl_driver_bfm.read_text()
            driver_anchor = "    security_state_o              <= initiator_struct.security_state;"
            if driver_source.count(driver_anchor) != 1:
                raise SystemExit("reset-state trace refused an unexpected control-driver source")
            driver_source = driver_source.replace(
                driver_anchor,
                driver_anchor
                + '\n    if ($test$plusargs("TRACE_CPTRA_KEY")) begin\n'
                + '      $display("CTRL_DRV_TRACE t=%0t mode=%0d input=%b output=%b bus=%b", '
                + "$time, initiator_responder, initiator_struct.security_state, security_state_o, bus.security_state);\n"
                + "      $fflush();\n"
                + "    end",
                1,
            )
            ctrl_driver_bfm.write_text(driver_source)
            status_monitor_bfm = packages / "cptra_status_pkg/src/cptra_status_monitor_bfm.sv"
            monitor_source = status_monitor_bfm.read_text()
            monitor_anchor = "    @go;\n    forever begin\n      @(posedge clk_i);"
            if monitor_source.count(monitor_anchor) != 1:
                raise SystemExit("CPTRA status trace refused an unexpected monitor source")
            status_monitor_bfm.write_text(
                monitor_source.replace(
                    monitor_anchor,
                    "    @go;\n    repeat (3) @(posedge clk_i);\n    forever begin\n      @(posedge clk_i);",
                    1,
                )
            )
            run(
                "python3",
                str(overlay_tools / "soc_ifc_generated_fw_image_runtime_guard_overlay.py"),
                "--caliptra-root",
                str(caliptra),
                "--environment-overlay",
                str(env),
                "--manifest",
                str(
                    repo
                    / "evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/fw-image-runtime-overlay-manifest.json"
                ),
            )
        aaxi_env = temp / "aaxi_env.sv"
        run("python3", str(overlay_tools / "soc_ifc_aaxi_compat_overlay.py"), "--caliptra-root", str(caliptra), "--output", str(aaxi_env))
        env_pkg = env / "soc_ifc_env_pkg.sv"
        source = env_pkg.read_text()
        aaxi_import = "  import aaxi_uvm_pkg::*;"
        open_import = "  import caliptra_aaxi_uvmf_compat_pkg::*;"
        if source.count(aaxi_import) != 1 or open_import in source:
            raise SystemExit("unexpected case-overlay AAXI import block")
        if open_import not in aaxi_env.read_text():
            raise SystemExit("hash-guarded AAXI import overlay did not produce the open import")
        env_pkg.write_text(source.replace(aaxi_import, aaxi_import + "\n" + open_import, 1))

        if args.generated_environment_runtime:
            predictor_overlay = env / "src/soc_ifc_predictor.svh"
            predictor_source = predictor_overlay.read_text()
            event_wait = "    reset_predicted.wait_trigger_data(obj_triggered);"
            latched_wait = (
                "    reset_predicted.wait_on();\n"
                "    obj_triggered = reset_predicted.get_trigger_data();"
            )
            if predictor_source.count(event_wait) != 1:
                raise SystemExit("reset-event overlay refused an unexpected predictor source")
            predictor_source = predictor_source.replace(event_wait, latched_wait, 1)
            boot_release_wait = "                    reset_predicted.wait_off();"
            clock_polled_release = (
                "                    while (reset_predicted.is_on())\n"
                "                        configuration.soc_ifc_ctrl_agent_config.wait_for_num_clocks(1);"
            )
            if predictor_source.count(boot_release_wait) != 1:
                raise SystemExit("reset-event overlay refused an unexpected boot-event release wait")
            predictor_source = predictor_source.replace(boot_release_wait, clock_polled_release, 1)
            initial_cptra_status_wait = (
                "                    // Capture is delayed from pwrgood\n"
                "                    configuration.soc_ifc_ctrl_agent_config.wait_for_num_clocks(1);"
            )
            delayed_cptra_status_wait = initial_cptra_status_wait.replace(
                "wait_for_num_clocks(1)", "wait_for_num_clocks(2)"
            )
            if predictor_source.count(initial_cptra_status_wait) != 1:
                raise SystemExit("reset-event overlay refused an unexpected initial CPTRA status wait")
            predictor_source = predictor_source.replace(
                initial_cptra_status_wait, delayed_cptra_status_wait, 1
            )
            if args.open_mbox_ecc_injection == "double":
                duplicate_ecc_status = (
                    "        cptra_error_non_fatal = 1'b1;\n"
                    "        send_soc_ifc_sts_txn = 1'b1;"
                )
                edge_only_ecc_status = (
                    "        if (!cptra_error_non_fatal) begin\n"
                    "            cptra_error_non_fatal = 1'b1;\n"
                    "            send_soc_ifc_sts_txn = 1'b1;\n"
                    "        end"
                )
                if predictor_source.count(duplicate_ecc_status) != 1:
                    raise SystemExit(
                        "double-bit ECC overlay refused an unexpected predictor source"
                    )
                predictor_source = predictor_source.replace(
                    duplicate_ecc_status, edge_only_ecc_status, 1
                )
                print(
                    "coalesced repeated double-bit ECC status predictions while the "
                    "non-fatal interrupt is already asserted"
                )
            predictor_overlay.write_text(predictor_source)
            print("applied reset-event, release, and initial-status order adaptations to disposable predictor")

        if args.trace_predictor_reset:
            predictor_overlay = env / "src/soc_ifc_predictor.svh"
            predictor_source = predictor_overlay.read_text()
            checkpoints = (
                (
                    "    `uvm_info(\"PRED_RESET\", $sformatf(\"Predicting reset of kind: %p\", kind), UVM_LOW)",
                    "    `uvm_info(\"PRED_RESET\", $sformatf(\"Predicting reset of kind: %p\", kind), UVM_LOW)\n"
                    "    $display(\"PRED_TRACE A reset entry kind=%s time=%0t\", kind, $time);\n"
                    "    $fflush();",
                ),
                (
                    "    // Track the BOOT FSM internally",
                    "    $display(\"PRED_TRACE B immediate reset branch complete time=%0t\", $time);\n"
                    "    $fflush();\n"
                    "    // Track the BOOT FSM internally",
                ),
                (
                    "    // Predict value changes due to reset",
                    "    $display(\"PRED_TRACE C boot-state setup complete time=%0t\", $time);\n"
                    "    $fflush();\n"
                    "    // Predict value changes due to reset",
                ),
                (
                    "    p_soc_ifc_rm.reset(kind);",
                    "    $display(\"PRED_TRACE D before RAL reset time=%0t\", $time);\n"
                    "    $fflush();\n"
                    "    p_soc_ifc_rm.reset(kind);\n"
                    "    $display(\"PRED_TRACE E after RAL reset time=%0t\", $time);\n"
                    "    $fflush();",
                ),
                (
                    "    // Key keeps on rolling after a SOFT reset because activity continues until NONCORE reset asserts",
                    "    $display(\"PRED_TRACE F register-busy scan complete time=%0t\", $time);\n"
                    "    $fflush();\n"
                    "    // Key keeps on rolling after a SOFT reset because activity continues until NONCORE reset asserts",
                ),
                (
                    "    end: RESET_TXN_KEY_HARD_NONCORE\nendfunction",
                    "    end: RESET_TXN_KEY_HARD_NONCORE\n"
                    "    $display(\"PRED_TRACE G reset predictor return time=%0t\", $time);\n"
                    "    $fflush();\n"
                    "endfunction",
                ),
            )
            for anchor, replacement in checkpoints:
                if predictor_source.count(anchor) != 1:
                    raise SystemExit(
                        "predictor trace refused an unexpected source copy at anchor: "
                        + anchor
                    )
                predictor_source = predictor_source.replace(anchor, replacement, 1)
            boot_wait_anchor = (
                "                    reset_predicted.wait_ptrigger_data(obj_predicted);\n"
                "                    while (reset_predicted.is_on())\n"
                "                        configuration.soc_ifc_ctrl_agent_config.wait_for_num_clocks(1);"
            )
            boot_wait_trace = (
                '                    $display("BOOT_TRACE before event wait time=%0t", $time);\n'
                + "                    reset_predicted.wait_ptrigger_data(obj_predicted);\n"
                + '                    $display("BOOT_TRACE trigger received time=%0t", $time);\n'
                + "                    while (reset_predicted.is_on())\n"
                + "                        configuration.soc_ifc_ctrl_agent_config.wait_for_num_clocks(1);"
                + '\n                    $display("BOOT_TRACE event cleared time=%0t", $time);'
            )
            if predictor_source.count(boot_wait_anchor) != 1:
                raise SystemExit("predictor trace refused an unexpected boot-event wait")
            predictor_source = predictor_source.replace(boot_wait_anchor, boot_wait_trace, 1)
            ctrl_anchor = '    `uvm_info("PRED_SOC_IFC_CTRL", "Transaction Received through soc_ifc_ctrl_agent_ae", UVM_MEDIUM)'
            ctrl_trace = (
                ctrl_anchor
                + '\n    $display("PRED_TRACE CTRL pgood=%0b rst_assert=%0b predictor_rst_asserted=%0b time=%0t", '
                + 't.set_pwrgood, t.assert_rst, soc_ifc_rst_in_asserted, $time);\n'
                + '    $fflush();'
            )
            if predictor_source.count(ctrl_anchor) != 1:
                raise SystemExit("predictor trace refused an unexpected control transaction anchor")
            predictor_source = predictor_source.replace(ctrl_anchor, ctrl_trace, 1)
            handler_anchor = '    if (!$cast(kind_predicted, obj_triggered))\n'
            handler_trace = (
                handler_anchor
                + '        `uvm_fatal("PRED_HANDLE_RESET", "Failed to retrieve triggered reset_flag")\n'
                + '    $display("PRED_TRACE HANDLE requested=%s received=%s time=%0t", '
                + 'kind, kind_predicted.get_name(), $time);\n'
                + '    $fflush();\n'
                + '    if (kind_handled != kind_predicted)'
            )
            fatal_anchor = (
                '    if (!$cast(kind_predicted, obj_triggered))\n'
                '        `uvm_fatal("PRED_HANDLE_RESET", "Failed to retrieve triggered reset_flag")\n'
                '    if (kind_handled != kind_predicted)'
            )
            if predictor_source.count(fatal_anchor) != 1:
                raise SystemExit("predictor trace refused an unexpected reset-handler anchor")
            predictor_source = predictor_source.replace(fatal_anchor, handler_trace, 1)
            predictor_overlay.write_text(predictor_source)
            environment_overlay = env / "src/soc_ifc_environment.svh"
            if not environment_overlay.exists():
                environment_overlay.parent.mkdir(parents=True, exist_ok=True)
                environment_overlay.write_text((env_root / "src/soc_ifc_environment.svh").read_text())
            environment_source = environment_overlay.read_text()
            reset_anchor = '    this.configuration.soc_ifc_ctrl_agent_config.wait_for_reset_assertion(kind);'
            reset_trace = (
                reset_anchor
                + '\n    $display("ENV_TRACE reset detected kind=%s time=%0t", kind, $time);\n'
                + '    $fflush();'
            )
            if environment_source.count(reset_anchor) != 1:
                raise SystemExit("environment trace refused an unexpected reset-detection anchor")
            environment_overlay.write_text(environment_source.replace(reset_anchor, reset_trace, 1))
            print("enabled flushed reset checkpoints in disposable predictor source")

        config = caliptra / "src/soc_ifc/uvmf_soc_ifc/config/compile.yml"
        config_docs = config.read_text().split("\n---", 1)
        first_doc = config_docs[0]
        file_lines = first_doc.split("files:", 1)[1].splitlines()
        relative_files = [line.strip()[2:] for line in file_lines if line.strip().startswith("- ${COMPILE_ROOT}/")]
        if not relative_files:
            raise SystemExit("could not read generated host package file order from compile.yml")
        compile_root = caliptra / "src/soc_ifc/uvmf_soc_ifc"
        project_bench_overlay = temp / "project_bench"
        hdl_top_source = None
        hvl_top_source = None
        if args.include_project_bench_packages:
            run(
                "python3",
                str(overlay_tools / "soc_ifc_generated_cmdline_test_overlay.py"),
                "--caliptra-root",
                str(caliptra),
                "--output",
                str(project_bench_overlay),
                "--manifest",
                str(
                    repo
                    / "evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/project-bench-overlay-manifest-20261005.json"
                ),
            )
        sources = []
        for relative in relative_files:
            original = compile_root / relative.removeprefix("${COMPILE_ROOT}/")
            if "/interface_packages/" in str(original):
                candidate = packages / original.relative_to(package_root)
            elif str(original).startswith(str(env_root) + os.sep):
                candidate = env / original.relative_to(env_root)
            else:
                candidate = original
            sources.append(candidate if candidate.is_file() else original)
        include_dirs = [packages / name for name in sorted(p.name for p in packages.iterdir())]
        include_dirs += [package_root / p.name for p in package_root.iterdir() if p.is_dir()]
        include_dirs += [env, env_root, env / "registers", env_root / "registers", rtl]
        include_dirs += [caliptra / "src/axi/rtl", caliptra / "src/soc_ifc/rtl", caliptra / "src/integration/rtl", caliptra / "src/integration/rtl/caliptra_reg", caliptra / "src/libs/rtl", caliptra / "src/libs/aaxi_uvm", caliptra / "src/keyvault/rtl", repo / "evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/include"]
        if args.include_project_bench_packages:
            if len(config_docs) < 2 or "files:" not in config_docs[1]:
                raise SystemExit("could not read generated project-bench file order from compile.yml")
            project_bench_root = caliptra / "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/project_benches/soc_ifc/tb"
            include_dirs += [
                project_bench_root,
                project_bench_root / "parameters",
                project_bench_root / "sequences",
                project_bench_root / "sequences/src",
                project_bench_root / "tests",
                project_bench_root / "tests/src",
            ]
            bench_file_lines = config_docs[1].split("files:", 1)[1].splitlines()
            bench_relative_files = [
                line.strip()[2:]
                for line in bench_file_lines
                if line.strip().startswith("- ${COMPILE_ROOT}/")
            ]
            for relative in bench_relative_files:
                original = compile_root / relative.removeprefix("${COMPILE_ROOT}/")
                if original.name == "hdl_top.sv":
                    hdl_top_source = original
                elif original.name == "hvl_top.sv":
                    hvl_top_source = original
                else:
                    overlay_candidate = project_bench_overlay / original.relative_to(project_bench_root)
                    sources.append(overlay_candidate if overlay_candidate.is_file() else original)
        runtime = args.generated_environment_runtime
        if runtime:
            if hdl_top_source is None or hvl_top_source is None:
                raise SystemExit("compile.yml does not identify generated hdl_top and hvl_top")
            generated_env_dir = repo / "evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005"
            hdl_top_overlay = temp / "hdl_top.sv"
            prepare_overlay_args = [
                "python3",
                str(repo / "evidence/caliptra-bfm-soc-ifc-axi-target-20261004/prepare_overlay.py"),
                "--caliptra-root",
                str(caliptra),
                "--output",
                str(hdl_top_overlay),
            ]
            if args.open_mbox_target:
                prepare_overlay_args.append("--open-mbox-target")
            run(*prepare_overlay_args)
            if " " in str(caliptra):
                raise SystemExit("Caliptra path cannot contain spaces in an Icarus filelist")
            sha512_ral_overlay = temp / "sha512_acc_csr_uvm.sv"
            run(
                "python3",
                str(overlay_tools / "soc_ifc_sha512_ral_little_endian_overlay.py"),
                "--caliptra-root",
                str(caliptra),
                "--output",
                str(sha512_ral_overlay),
                "--manifest",
                str(
                    repo
                    / "evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/sha512-ral-endian-overlay-manifest.json"
                ),
            )
            caliptra_prim_root = Path(
                os.environ.get("CALIPTRA_PRIM_ROOT", str(caliptra / "src/caliptra_prim_generic"))
            ).resolve()
            caliptra_prim_prefix = os.environ.get(
                "CALIPTRA_PRIM_MODULE_PREFIX", "caliptra_prim_generic"
            )
            rtl_filelist = temp / "soc_ifc_top.f"
            rtl_filelist_source = (
                caliptra / "src/soc_ifc/config/soc_ifc_top.vf"
            ).read_text()
            rtl_filelist_source = rtl_filelist_source.replace(
                "${CALIPTRA_ROOT}", str(caliptra)
            ).replace("${CALIPTRA_PRIM_ROOT}", str(caliptra_prim_root))
            rtl_filelist_source = rtl_filelist_source.replace(
                "${CALIPTRA_PRIM_MODULE_PREFIX}", caliptra_prim_prefix
            )
            soc_ifc_top = caliptra / "src/soc_ifc/rtl/soc_ifc_top.sv"
            soc_ifc_top_overlay = temp / "soc_ifc_top.sv"
            soc_ifc_top_source = soc_ifc_top.read_text()
            var_state_port = "input var security_state_t security_state,"
            if soc_ifc_top_source.count(var_state_port) != 1:
                raise SystemExit("security-state port overlay refused unexpected RTL source")
            soc_ifc_top_overlay.write_text(
                soc_ifc_top_source.replace(
                    var_state_port, "input security_state_t security_state,", 1
                )
            )
            if rtl_filelist_source.count(str(soc_ifc_top)) != 1:
                raise SystemExit("security-state port overlay did not find its RTL filelist entry")
            rtl_filelist.write_text(
                rtl_filelist_source.replace(str(soc_ifc_top), str(soc_ifc_top_overlay), 1)
            )
            print("adapted the disposable RTL security-state input port for Icarus net propagation")
            runtime_support = [
                caliptra / "src/axi/rtl/axi_dma_reg_uvm.sv",
                caliptra / "src/soc_ifc/rtl/mbox_csr_uvm.sv",
                sha512_ral_overlay,
                caliptra / "src/soc_ifc/rtl/soc_ifc_reg_uvm.sv",
            ]
            runtime_sources = [
                repo / "dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv",
                hdl_top_overlay,
                repo / "evidence/caliptra-bfm-soc-ifc-generated-hdl-20261004/hdl_stubs.sv",
                generated_env_dir / "generated_env_probe_pkg.sv",
                generated_env_dir / "generated_env_probe_top.sv",
            ]
            top = generated_env_dir / "generated_env_probe_top.sv"
            top_name = "caliptra_soc_ifc_generated_env_top"
            image = temp / "soc_ifc_generated_env_runtime.vvp"
            if args.open_mbox_target:
                runtime_sources.insert(
                    0,
                    repo / "dv/caliptra_bfm/mailbox/caliptra_mbox_sram_subordinate.sv",
                )
        else:
            runtime_support = []
            runtime_sources = []
            top = repo / "evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/hostpkg_compile_top.sv"
            top_name = "hostpkg_compile_top"
            image = temp / "soc_ifc_env_compile.vvp"
        if runtime and args.open_mbox_target:
            mbox_driver_overlay = temp / "mbox_sram_driver_bfm_open_target.sv"
            mbox_driver_indices = [
                i for i, source in enumerate(sources)
                if source.name == "mbox_sram_driver_bfm.sv"
            ]
            if len(mbox_driver_indices) != 1:
                raise SystemExit(
                    "generated mailbox driver source was not found exactly once in the runtime filelist"
                )
            mbox_driver_source = sources[mbox_driver_indices[0]]
            run(
                "python3",
                str(overlay_tools / "soc_ifc_generated_mbox_driver_release_overlay.py"),
                "--caliptra-root",
                str(caliptra),
                "--input",
                str(mbox_driver_source),
                "--output",
                str(mbox_driver_overlay),
            )
            sources[mbox_driver_indices[0]] = mbox_driver_overlay
        support = [
            caliptra / "src/axi/rtl/axi_pkg.sv",
            caliptra / "src/soc_ifc/rtl/soc_ifc_pkg.sv",
            caliptra / "src/soc_ifc/rtl/mbox_pkg.sv",
            caliptra / "src/soc_ifc/rtl/mbox_csr_pkg.sv",
            caliptra / "src/soc_ifc/rtl/sha512_acc_csr_pkg.sv",
            caliptra / "src/soc_ifc/rtl/soc_ifc_reg_pkg.sv",
            caliptra / "src/axi/rtl/axi_dma_reg_pkg.sv",
            caliptra / "src/keyvault/rtl/kv_defines_pkg.sv",
            caliptra / "src/axi/rtl/axi_dma_reg_uvm.sv",
            caliptra / "src/soc_ifc/rtl/mbox_csr_uvm.sv",
            caliptra / "src/soc_ifc/rtl/sha512_acc_csr_uvm.sv",
            caliptra / "src/soc_ifc/rtl/soc_ifc_reg_uvm.sv",
        ]
        bfm_filelist = repo / "dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f"
        bfm_sources = [repo / line.strip() for line in bfm_filelist.read_text().splitlines() if line.strip() and not line.lstrip().startswith("#")]
        command = [args.iverilog, "-g2012", "-uvm", "-DXCELIUM", "-DCLP_OBF_KEY_DWORDS=8", "-DCLP_OBF_FE_DWORDS=8", "-DCLP_OBF_UDS_DWORDS=16", "-s", top_name, "-o", str(image)]
        if runtime and args.open_mbox_target:
            command.append("-DCALIPTRA_BFM_OPEN_MBOX_TARGET")
        command += [f"-I{path}" for path in include_dirs]
        if runtime:
            command += ["-f", str(rtl_filelist)]
            command += [str(path) for path in runtime_support]
        else:
            command += [str(path) for path in support]
        command += [str(path) for path in bfm_sources]
        if args.include_project_bench_packages:
            command += [str(repo / "evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/generated_test_dependency_stubs.sv")]
        command += [str(path) for path in sources]
        if runtime:
            command += [str(path) for path in runtime_sources]
        else:
            command += [str(top)]
        compile_result = subprocess.run(command, cwd=repo)
        if compile_result.returncode != 0 or not runtime:
            return compile_result.returncode

        iverilog_path = Path(args.iverilog)
        vvp = os.environ.get(
            "VVP_BIN",
            str(iverilog_path.with_name("vvp")) if iverilog_path.parent != Path(".") else "vvp",
        )
        simulation_log = Path(
            os.environ.get(
                "CALIPTRA_BFM_RUNTIME_LOG",
                str(
                    repo
                    / "evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/"
                    "generated-env-runtime-vvp.log"
                ),
            )
        )
        if not simulation_log.is_absolute():
            simulation_log = repo / simulation_log
        progress_log = os.environ.get("CALIPTRA_BFM_RUNTIME_HEARTBEAT_LOG")
        progress_args = [f"+SOC_IFC_PROGRESS_LOG={progress_log}"] if progress_log else []
        ecc_args = []
        if args.open_mbox_ecc_injection:
            ecc_args = [f"+CALIPTRA_MBOX_ECC_{args.open_mbox_ecc_injection.upper()}"]
        axi_user_init_args = ["+CALIPTRA_GENERATED_AXI_USER_INIT"] if args.generated_axi_user_init else []
        axi_user_reject_args = ["+CALIPTRA_GENERATED_AXI_USER_REJECT"] if args.generated_axi_user_reject_probe else []
        ahb_ral_read_args = ["+CALIPTRA_GENERATED_AHB_RAL_READ"] if args.generated_ahb_ral_read else []
        ahb_ral_dlen_args = ["+CALIPTRA_GENERATED_AHB_RAL_DLEN_WRITE_READBACK"] if args.generated_ahb_ral_dlen_write_readback else []
        ahb_mbox_payload_args = ["+CALIPTRA_GENERATED_AHB_MBOX_PAYLOAD"] if args.generated_ahb_mbox_payload else []
        simulation_log.parent.mkdir(parents=True, exist_ok=True)
        with simulation_log.open("w") as log:
            simulation = subprocess.run(
                [
                    vvp,
                    "-i",
                    str(image),
                    "+UVM_TESTNAME=caliptra_soc_ifc_generated_env_probe_test",
                    "+uvm_set_action=*,UVM/FLD/GET_MIRRORED_VAL/VOL,UVM_WARNING,UVM_NO_ACTION",
                    *( ["+TRACE_CPTRA_KEY"] if args.trace_predictor_reset else [] ),
                    *progress_args,
                    *ecc_args,
                    *axi_user_init_args,
                    *axi_user_reject_args,
                    *ahb_ral_read_args,
                    *ahb_ral_dlen_args,
                    *ahb_mbox_payload_args,
                ],
                cwd=repo,
                stdout=log,
                stderr=subprocess.STDOUT,
            )
        saw_pass = False
        saw_uvm_error = False
        scoreboard_result = None
        with simulation_log.open() as log:
            for line in log:
                sys.stdout.write(line)
                saw_pass |= "PASS: generated SoC-IFC bench sequence" in line
                saw_uvm_error |= bool(re.match(r"^UVM_(?:ERROR|FATAL)\s*:\s*[1-9]", line))
                match = re.search(
                    r"SCOREBOARD_RESULTS:\s+PREDICTED_TRANSACTIONS=(\d+)\s+MATCHES=(\d+)\s+"
                    r"MISMATCHES=(\d+)\s+NO_COMPARISON_TXN=(\d+)\s+MULTIPLE_MISSED_TXN=(\d+)",
                    line,
                )
                if match:
                    scoreboard_result = tuple(int(value) for value in match.groups())
        sys.stdout.flush()
        if simulation.returncode != 0 or not saw_pass:
            return simulation.returncode or 1
        if saw_uvm_error:
            return 1
        if scoreboard_result is None:
            print("ERROR: generated runtime did not report SoC-IFC scoreboard results", file=sys.stderr)
            return 1
        predicted, matches, mismatches, no_comparison, missed = scoreboard_result
        if matches < 1 or predicted != matches or mismatches or no_comparison or missed:
            print(
                "ERROR: generated SoC-IFC scoreboard failed its match gate: "
                f"predicted={predicted} matches={matches} mismatches={mismatches} "
                f"no_comparison={no_comparison} missed={missed}",
                file=sys.stderr,
            )
            return 1
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
