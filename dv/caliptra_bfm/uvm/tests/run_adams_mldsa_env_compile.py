#!/usr/bin/env python3
"""Compile the pinned Adams Bridge generated MLDSA environment with the clean-room provider."""

import argparse
import os
from pathlib import Path
import re
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
        "--min-free-percent",
        os.environ.get("CALIPTRA_BFM_MIN_FREE_PERCENT", "60"),
        "--timeout-seconds",
        os.environ.get("CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS", "300"),
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
    args = parser.parse_args()

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
        if args.actual_rtl_smoke:
            top_name = "adams_mldsa_runtime_top"
            top.write_text(
                "`timescale 1ns/1ps\n"
                "package adams_mldsa_runtime_smoke_pkg;\n"
                "  import uvm_pkg::*;\n"
                "  import uvmf_base_pkg::*;\n"
                "  import mvc_pkg::*;\n"
                "  import mgc_ahb_v2_0_pkg::*;\n"
                "  import ahb_lite_caliptra_uvm_pkg::*;\n"
                "  import mldsa_env_pkg::*;\n"
                "  `include \"uvm_macros.svh\"\n"
                "  class adams_mldsa_version_read_sequence extends uvm_sequence #(mvc_sequence_item_base);\n"
                "    `uvm_object_utils(adams_mldsa_version_read_sequence)\n"
                "    function new(string name = \"adams_mldsa_version_read_sequence\"); super.new(name); endfunction\n"
                "    task body();\n"
                "      ahb_lite_caliptra_mvc_transfer req = new(\"read_mldsa_version\");\n"
                "      start_item(req); req.RnW = AHB_READ; req.address = 32'h8;\n"
                "      req.size = AHB_MVC_WORD_SIZE; req.data.push_back(0); finish_item(req);\n"
                "      if (req.resp.size() != 1 || req.resp[0] != AHB_OKAY || req.data[0] != 32'h302e322e)\n"
                "        `uvm_fatal(\"MLDSA_AHB_READ\", \"generated 32-bit AHB version read failed\")\n"
                "      `uvm_info(\"MLDSA_AHB_READ\", $sformatf(\"version response %08h\", req.data[0]), UVM_LOW)\n"
                "    endtask\n"
                "  endclass\n"
                "  class adams_mldsa_runtime_smoke_test extends uvm_test;\n"
                "    `uvm_component_utils(adams_mldsa_runtime_smoke_test)\n"
                "    mldsa_env_configuration configuration;\n"
                "    mldsa_environment environment;\n"
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
                "      uvm_status_e seed_write_status;\n"
                "      adams_mldsa_version_read_sequence read_seq;\n"
                "      phase.raise_objection(this);\n"
                "      configuration.mldsa_rm.MLDSA_SEED[0].write(seed_write_status, 32'h1a2b3c4d, UVM_FRONTDOOR, configuration.mldsa_rm.default_map);\n"
                "      if (seed_write_status != UVM_IS_OK) `uvm_fatal(\"MLDSA_RAL_WRITE\", \"generated RAL seed write failed\")\n"
                "      read_seq = adams_mldsa_version_read_sequence::type_id::create(\"read_seq\");\n"
                "      read_seq.start(environment.qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.m_sequencer);\n"
                "      #1;\n"
                "      if (environment.mldsa_sb.mismatch_count != 0)\n"
                "        `uvm_fatal(\"MLDSA_SCOREBOARD\", \"generated scoreboard reported a mismatch\")\n"
                "      $display(\"PASS: generated MLDSA environment RAL-wrote seed and read abr_top version through 32-bit AHB\");\n"
                "      phase.drop_objection(this);\n"
                "    endtask\n"
                "  endclass\n"
                "endpackage\n"
                "module adams_mldsa_runtime_top;\n"
                "  import uvm_pkg::*;\n"
                "  import adams_mldsa_runtime_smoke_pkg::*;\n"
                "  hdl_top generated_hdl_top();\n"
                "  initial begin #1; run_test(\"adams_mldsa_runtime_smoke_test\"); end\n"
                "endmodule\n"
            )
        else:
            top.write_text(
                "module adams_mldsa_env_compile_top;\n"
                "  import uvm_pkg::*;\n"
                "  import mldsa_env_pkg::*;\n"
                "  mldsa_environment generated_environment;\n"
                "endmodule\n"
            )
        make_iverilog_overlay(env_root, overlay)
        if args.actual_rtl_smoke:
            abr_reg_source = adams / "src/abr_top/rtl/abr_reg_uvm.sv"
            abr_reg_text = abr_reg_source.read_text()
            if abr_reg_text.count("UVM_NO_ENDIAN") != 10:
                raise SystemExit("unexpected generated Adams Bridge RAL map layout")
            (overlay / "abr_reg_uvm.sv").write_text(
                abr_reg_text.replace("UVM_NO_ENDIAN", "UVM_LITTLE_ENDIAN")
            )
        binary = temp / "adams_mldsa_runtime.vvp"
        output_option = ["-o", str(binary)] if args.actual_rtl_smoke else ["-tnull"]
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
        if args.actual_rtl_smoke:
            command.extend(
                [
                    "-f",
                    str(adams / "src/abr_top/config/abr_top.vf"),
                ]
            )
        command.extend(
            [
                str(overlay / "abr_reg_uvm.sv") if args.actual_rtl_smoke else str(adams / "src/abr_top/rtl/abr_reg_uvm.sv"),
                str(env_root / "registers/mldsa_reg_model_top_pkg.sv"),
                str(env_root / "mldsa_env_pkg.sv"),
            ]
        )
        if args.actual_rtl_smoke:
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
        if args.actual_rtl_smoke:
            result = subprocess.run(
                [args.vvp, str(binary)],
                cwd=repo,
                capture_output=True,
                text=True,
            )
            print(result.stdout, end="")
            print(result.stderr, end="", file=sys.stderr)
            if (
                result.returncode != 0
                or "PASS: generated MLDSA environment RAL-wrote seed and read abr_top version through 32-bit AHB" not in result.stdout
                or re.search(r"UVM_(ERROR|FATAL) :\s*[1-9]", result.stdout)
            ):
                return result.returncode or 1
    if not args.actual_rtl_smoke:
        print("PASS: pinned Adams Bridge MLDSA environment, predictor, scoreboard, and RAL package compile")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
