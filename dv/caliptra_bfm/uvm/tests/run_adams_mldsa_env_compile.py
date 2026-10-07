#!/usr/bin/env python3
"""Compile the pinned Adams Bridge generated MLDSA environment with the clean-room provider."""

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


COMMIT = "b77e3d899e828d626cfc2a0d26a6b5704cc121e0"
MEMORY_GUARD_CHILD = "CALIPTRA_BFM_MEMORY_GUARD_CHILD"


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise SystemExit(f"expected one generated-source anchor: {old!r}")
    return text.replace(old, new, 1)


def use_generated_transfer_alias(path: Path, expected_matches: int) -> None:
    pattern = re.compile(
        r"ahb_master_burst_transfer\s*#\(\s*"
        r"ahb_lite_slave_0_params::AHB_NUM_MASTERS,\s*"
        r"ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,\s*"
        r"ahb_lite_slave_0_params::AHB_NUM_SLAVES,\s*"
        r"ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,\s*"
        r"ahb_lite_slave_0_params::AHB_WDATA_WIDTH,\s*"
        r"ahb_lite_slave_0_params::AHB_RDATA_WIDTH\s*\)"
    )
    text, count = pattern.subn(
        "qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_transfer_t",
        path.read_text(),
    )
    if count != expected_matches:
        raise SystemExit(f"unexpected generated transfer type layout in {path.name}: {count}")
    path.write_text(text)


def make_iverilog_overlay(source: Path, overlay: Path) -> None:
    (overlay / "src").mkdir(parents=True)

    path = source / "src/mldsa_env_configuration.svh"
    text = path.read_text()
    text = replace_once(
        text,
        "qvip_ahb_lite_slave_subenv_config.convert2string",
        "qvip_ahb_lite_slave_subenv_config.convert2string()",
    )
    text = replace_once(
        text,
        "qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];",
        "qvip_ahb_lite_slave_subenv_interface_names[0] = interface_names[0];",
    )
    text = replace_once(
        text,
        "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];",
        "qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];",
    )
    (overlay / "src/mldsa_env_configuration.svh").write_text(text)

    path = source / "src/mldsa_predictor.svh"
    text = replace_once(
        path.read_text(),
        "  CONFIG_T configuration;",
        "  CONFIG_T configuration;\n  mldsa_env_configuration mldsa_env_cfg;",
    )
    text = replace_once(
        text,
        "    p_mldsa_rm = configuration.mldsa_rm;",
        '    if (!$cast(mldsa_env_cfg, configuration)) `uvm_fatal("MLDSA_CFG", "Wrong generated environment configuration type")\n'
        "    p_mldsa_rm = mldsa_env_cfg.mldsa_rm;",
    )
    text = replace_once(
        text,
        "line = line.substr(8);",
        'line = (line.len() > 8) ? line.substr(8, line.len()-1) : "";',
    )
    text = replace_once(
        text,
        'mldsa_sb_ahb_ap_output_transaction = mldsa_sb_ahb_ap_output_transaction_t::type_id::create("mldsa_sb_ahb_ap_output_transaction");',
        'mldsa_sb_ahb_ap_output_transaction = new("mldsa_sb_ahb_ap_output_transaction");',
    )
    (overlay / "src/mldsa_predictor.svh").write_text(text)

    path = source / "src/mldsa_scoreboard.svh"
    text = replace_once(
        path.read_text(),
        "  CONFIG_T configuration;",
        "  CONFIG_T configuration;\n  mldsa_env_configuration mldsa_env_cfg;",
    )
    text = replace_once(
        text,
        "    scbr_mldsa_rm = configuration.mldsa_rm;",
        '    if (!$cast(mldsa_env_cfg, configuration)) `uvm_fatal("MLDSA_CFG", "Wrong generated environment configuration type")\n'
        "    scbr_mldsa_rm = mldsa_env_cfg.mldsa_rm;",
    )
    (overlay / "src/mldsa_scoreboard.svh").write_text(text)
    use_generated_transfer_alias(overlay / "src/mldsa_predictor.svh", 4)
    use_generated_transfer_alias(overlay / "src/mldsa_scoreboard.svh", 9)


def run_under_memory_guard(repo: Path) -> int | None:
    if os.environ.get(MEMORY_GUARD_CHILD) == "1" or "--help" in sys.argv or "-h" in sys.argv:
        return None
    command = [
        sys.executable,
        str(repo / "scripts/run_with_memory_pressure_guard.py"),
        "--timeout-seconds",
        os.environ.get(
            "CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS",
            "600" if "--actual-keygen-smoke" in sys.argv else "300",
        ),
        "--",
        sys.executable,
        str(Path(__file__).resolve()),
        *sys.argv[1:],
    ]
    environment = os.environ.copy()
    environment[MEMORY_GUARD_CHILD] = "1"
    return subprocess.run(command, env=environment).returncode


def main() -> int:
    repo = Path(__file__).resolve().parents[4]
    guarded_result = run_under_memory_guard(repo)
    if guarded_result is not None:
        return guarded_result

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--adamsbridge-root",
        type=Path,
        default=repo.parent / "caliptra-rtl/submodules/adams-bridge",
    )
    parser.add_argument("--iverilog", default=os.environ.get("IVERILOG_BIN", "iverilog"))
    parser.add_argument("--vvp", default=os.environ.get("VVP_BIN", "vvp"))
    parser.add_argument("--edition", default=os.environ.get("SV_EDITION", "2012"))
    parser.add_argument(
        "--actual-rtl-smoke",
        action="store_true",
        help="run a generated-environment version read against the pinned abr_top RTL",
    )
    parser.add_argument(
        "--actual-keygen-smoke",
        action="store_true",
        help="run generated-RAL MLDSA keygen and score PK/SK readback against abr_top",
    )
    parser.add_argument(
        "--compile-only",
        action="store_true",
        help="compile the selected actual-RTL harness without starting VVP",
    )
    args = parser.parse_args()
    actual_rtl = args.actual_rtl_smoke or args.actual_keygen_smoke
    if args.compile_only and not actual_rtl:
        parser.error("--compile-only requires --actual-rtl-smoke or --actual-keygen-smoke")

    adams = args.adamsbridge_root.resolve()
    if subprocess.check_output(["git", "-C", str(adams), "rev-parse", "HEAD"], text=True).strip() != COMMIT:
        raise SystemExit(f"expected clean Adams Bridge commit {COMMIT}")
    if subprocess.check_output(["git", "-C", str(adams), "status", "--porcelain"], text=True):
        raise SystemExit("refusing a modified Adams Bridge checkout")

    env_root = adams / "src/abr_top/uvmf/uvmf_template_output/verification_ip/environment_packages/mldsa_env_pkg"
    with tempfile.TemporaryDirectory(prefix="caliptra-adams-mldsa-env-") as temp_name:
        temp = Path(temp_name)
        overlay = temp / "overlay"
        top = temp / "compile_top.sv"
        top_name = "adams_mldsa_env_compile_top"
        runtime = temp / "runtime"
        runtime.mkdir()
        expected_pass = "PASS: generated MLDSA environment RAL-wrote seed and read abr_top version through 32-bit AHB"
        if args.actual_keygen_smoke and not args.compile_only:
            ref_source = adams / "src/abr_top/uvmf/Dilithium_ref/dilithium/ref"
            ref_copy = temp / "dilithium-ref"
            shutil.copytree(ref_source, ref_copy)
            helper = ref_copy / "test/test_dilithium5"
            helper.unlink(missing_ok=True)
            compiler = shutil.which("clang") or shutil.which("cc")
            if compiler is None or shutil.which("make") is None:
                raise SystemExit("actual MLDSA keygen requires make and clang or cc")
            subprocess.run(
                [
                    sys.executable,
                    str(repo / "dv/caliptra_bfm/native_vectors/stage_mldsa.py"),
                    str(ref_source / "test/test_dilithium.c"),
                    str(ref_copy / "test/test_dilithium.c"),
                ],
                check=True,
            )
            subprocess.run(
                ["make", "-C", str(ref_copy), f"CC={compiler}", "test/test_dilithium5"],
                check=True,
            )
            shutil.copy2(helper, runtime / "test_dilithium5")
            expected_pass = (
                "PASS: generated MLDSA keygen completed on abr_top; "
                "public/private key readbacks matched the generated predictor"
            )
        if actual_rtl:
            top_name = "adams_mldsa_runtime_top"
            keygen_body = (
                "      uvm_reg_data_t hw_status, public_word, private_word; int keygen_done, progress_fd;\n"
                "      bit saw_busy;\n"
                "      uvm_reg_data_t seed_words[8] = '{32'h03020100, 32'h07060504, 32'h0b0a0908, 32'h0f0e0d0c, "
                "32'h13121110, 32'h17161514, 32'h1b1a1918, 32'h1f1e1d1c};\n"
                "      if (!uvm_config_db#(virtual adams_mldsa_busy_if)::get(this, \"\", \"busy_if\", busy_if))\n"
                "        `uvm_fatal(\"MLDSA_BUSY_IF\", \"missing abr_top busy signal interface\")\n"
                "      phase.raise_objection(this);\n"
                "      foreach (seed_words[i]) begin\n"
                "        configuration.mldsa_rm.MLDSA_SEED[i].write(status, seed_words[i], UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "        if (status != UVM_IS_OK) `uvm_fatal(\"MLDSA_SEED\", \"generated RAL seed write failed\")\n"
                "      end\n"
                "      configuration.mldsa_rm.MLDSA_CTRL.write(status, 32'h1, UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "      if (status != UVM_IS_OK) `uvm_fatal(\"MLDSA_CTRL\", \"generated RAL keygen command failed\")\n"
                "      progress_fd = $fopen(\"./keygen_progress.log\", \"w\");\n"
                "      if (progress_fd == 0) `uvm_fatal(\"MLDSA_PROGRESS\", \"cannot create keygen progress log\")\n"
                "      $fdisplay(progress_fd, \"keygen busy trace start\"); $fflush(progress_fd);\n"
                "      keygen_done = 0;\n"
                "      saw_busy = 0;\n"
                "      // ponytail: 500000-cycle watchdog; measure and tune if this RTL profile changes.\n"
                "      for (int cycle = 0; cycle < 500000; cycle++) begin\n"
                "        #10ns;\n"
                "        if (busy_if.busy) saw_busy = 1;\n"
                "        if ((cycle % 10000) == 0) begin\n"
                "          $fdisplay(progress_fd, \"cycle=%0d busy=%b saw_busy=%b\", cycle, busy_if.busy, saw_busy);\n"
                "          $fflush(progress_fd);\n"
                "        end\n"
                "        if (saw_busy && !busy_if.busy) begin keygen_done = 1; break; end\n"
                "      end\n"
                "      $fdisplay(progress_fd, \"keygen_done=%0d\", keygen_done); $fflush(progress_fd); $fclose(progress_fd);\n"
                "      if (!keygen_done) `uvm_fatal(\"MLDSA_KEYGEN\", \"abr_top keygen exceeded the 500000-cycle limit\")\n"
                "      configuration.mldsa_rm.MLDSA_STATUS.read(status, hw_status, UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "      if (status != UVM_IS_OK || !hw_status[0] || !hw_status[1] || hw_status[3])\n"
                "        `uvm_fatal(\"MLDSA_STATUS\", \"abr_top keygen status is not ready/valid or reports an error\")\n"
                "      configuration.mldsa_rm.MLDSA_PUBKEY.m_mem.read(status, 0, public_word, UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "      if (status != UVM_IS_OK) `uvm_fatal(\"MLDSA_PUBKEY\", \"generated RAL public-key read failed\")\n"
                "      configuration.mldsa_rm.MLDSA_PRIVKEY_OUT.m_mem.read(status, 0, private_word, UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "      if (status != UVM_IS_OK) `uvm_fatal(\"MLDSA_PRIVKEY\", \"generated RAL private-key read failed\")\n"
                "      #1;\n"
                "      if (environment.mldsa_sb.mismatch_count != 0 || environment.mldsa_sb.match_count != 2)\n"
                "        `uvm_fatal(\"MLDSA_SCOREBOARD\", \"generated predictor did not match both key readbacks\")\n"
                f"      $display(\"{expected_pass}\");\n"
                "      phase.drop_objection(this);\n"
            )
            smoke_body = (
                keygen_body
                if args.actual_keygen_smoke
                else "      phase.raise_objection(this);\n"
                "      configuration.mldsa_rm.MLDSA_SEED[0].write(status, 32'h1a2b3c4d, UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "      if (status != UVM_IS_OK) `uvm_fatal(\"MLDSA_RAL_WRITE\", \"generated RAL seed write failed\")\n"
                "      configuration.mldsa_rm.MLDSA_VERSION[0].read(status, version, UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "      if (status != UVM_IS_OK || version[31:0] != 32'h302e322e)\n"
                "        `uvm_fatal(\"MLDSA_RAL_READ\", \"generated RAL version read failed\")\n"
                "      #1;\n"
                "      if (environment.mldsa_sb.mismatch_count != 0)\n"
                "        `uvm_fatal(\"MLDSA_SCOREBOARD\", \"generated scoreboard reported a mismatch\")\n"
                f"      $display(\"{expected_pass}\");\n"
                "      phase.drop_objection(this);\n"
            )
            runtime_source = (
                "`timescale 1ns/1ps\n"
                "interface adams_mldsa_busy_if; logic busy; endinterface\n"
                "package adams_mldsa_runtime_smoke_pkg;\n"
                "  import uvm_pkg::*;\n"
                "  import uvmf_base_pkg::*;\n"
                "  import mldsa_env_pkg::*;\n"
                "  `include \"uvm_macros.svh\"\n"
                "  class adams_mldsa_runtime_smoke_test extends uvm_test;\n"
                "    `uvm_component_utils(adams_mldsa_runtime_smoke_test)\n"
                "    mldsa_env_configuration configuration;\n"
                "    mldsa_environment environment;\n"
                "    virtual adams_mldsa_busy_if busy_if;\n"
                "    function new(string name, uvm_component parent); super.new(name, parent); endfunction\n"
                "    function void build_phase(uvm_phase phase);\n"
                "      string interface_names[1]; uvmf_active_passive_t activity[1];\n"
                "      super.build_phase(phase);\n"
                "      configuration = mldsa_env_configuration::type_id::create(\"configuration\");\n"
                "      interface_names[0] = \"uvm_test_top.environment.qvip_ahb_lite_slave_subenv.ahb_lite_slave_0\";\n"
                "      activity[0] = ACTIVE;\n"
                "      configuration.initialize(NA, \"uvm_test_top.environment\", interface_names, null, activity);\n"
                "      environment = mldsa_environment::type_id::create(\"environment\", this);\n"
                "      environment.set_config(configuration);\n"
                "    endfunction\n"
                "    task run_phase(uvm_phase phase);\n"
                "      uvm_status_e status; uvm_reg_data_t version;\n"
            ) + smoke_body + (
                "    endtask\n"
                "  endclass\n"
                "endpackage\n"
                "module adams_mldsa_runtime_top;\n"
                "  import uvm_pkg::*;\n"
                "  import adams_mldsa_runtime_smoke_pkg::*;\n"
                "  hdl_top generated_hdl_top();\n"
                "  adams_mldsa_busy_if mldsa_busy_if();\n"
                "  assign mldsa_busy_if.busy = generated_hdl_top.dut.busy_o;\n"
                "  initial begin\n"
                "    uvm_config_db#(virtual adams_mldsa_busy_if)::set(null, \"uvm_test_top\", \"busy_if\", mldsa_busy_if);\n"
                "    #1; run_test(\"adams_mldsa_runtime_smoke_test\");\n"
                "  end\n"
                "endmodule\n"
            )
            top.write_text(runtime_source)
        else:
            top.write_text(
                "module adams_mldsa_env_compile_top;\n"
                "  import uvm_pkg::*;\n"
                "  import mldsa_env_pkg::*;\n"
                "  mldsa_environment generated_environment;\n"
                "endmodule\n"
            )
        make_iverilog_overlay(env_root, overlay)
        if actual_rtl:
            abr_reg_source = adams / "src/abr_top/rtl/abr_reg_uvm.sv"
            abr_reg_text = abr_reg_source.read_text()
            if abr_reg_text.count("UVM_NO_ENDIAN") != 10:
                raise SystemExit("unexpected generated Adams Bridge RAL map layout")
            (overlay / "abr_reg_uvm.sv").write_text(
                abr_reg_text.replace("UVM_NO_ENDIAN", "UVM_LITTLE_ENDIAN")
            )
        binary = temp / "adams_mldsa_runtime.vvp"
        output_option = ["-tnull"] if args.compile_only or not actual_rtl else ["-o", str(binary)]
        command = [
            args.iverilog,
            "-uvm",
            f"-g{args.edition}",
            "-DCALIPTRA_BFM_AHB_32BIT",
            *output_option,
            "-s",
            top_name,
            "-I",
            str(overlay),
            "-I",
            str(env_root),
            "-I",
            str(env_root / "registers"),
            "-f",
            "dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f",
        ]
        environment = os.environ.copy()
        environment["ADAMSBRIDGE_ROOT"] = str(adams)
        if actual_rtl:
            command.extend(
                [
                    "-f",
                    str(adams / "src/abr_top/config/abr_top.vf"),
                ]
            )
        command.extend(
            [
                str(overlay / "abr_reg_uvm.sv") if actual_rtl else str(adams / "src/abr_top/rtl/abr_reg_uvm.sv"),
                str(env_root / "registers/mldsa_reg_model_top_pkg.sv"),
                str(env_root / "mldsa_env_pkg.sv"),
            ]
        )
        if actual_rtl:
            command.extend(
                [
                    str(adams / "src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/parameters/mldsa_parameters_pkg.sv"),
                    str(adams / "src/abr_top/coverage/abr_top_cov_if.sv"),
                    str(adams / "src/abr_top/coverage/abr_top_cov_bind.sv"),
                    str(adams / "src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/testbench/hdl_top.sv"),
                    str(top),
                ]
            )
        else:
            command.append(str(top))
        subprocess.run(command, cwd=repo, env=environment, check=True)
        if actual_rtl and not args.compile_only:
            result = subprocess.run(
                [args.vvp, str(binary)],
                cwd=runtime,
                capture_output=True,
                text=True,
            )
            print(result.stdout, end="")
            print(result.stderr, end="", file=sys.stderr)
            if (
                result.returncode != 0
                or expected_pass not in result.stdout
                or re.search(r"UVM_(ERROR|FATAL) :\s*[1-9]", result.stdout)
            ):
                return result.returncode or 1
            if args.actual_keygen_smoke and not (runtime / "keygen.log").is_file():
                raise SystemExit("MLDSA predictor did not invoke the native keygen helper")
    if args.compile_only:
        print("PASS: generated Adams Bridge actual-RTL harness compiles")
    elif not actual_rtl:
        print("PASS: pinned Adams Bridge MLDSA environment, predictor, scoreboard, and RAL package compile")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
