#!/usr/bin/env python3
"""Compile the pinned Adams Bridge generated MLDSA environment with the clean-room provider."""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile


COMMIT = "b77e3d899e828d626cfc2a0d26a6b5704cc121e0"
MEMORY_GUARD_CHILD = "CALIPTRA_BFM_MEMORY_GUARD_CHILD"


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise SystemExit(f"expected one generated-source anchor: {old!r}")
    return text.replace(old, new, 1)


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
    parser.add_argument("--edition", default=os.environ.get("SV_EDITION", "2012"))
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
        top.write_text(
            "module adams_mldsa_env_compile_top;\n"
            "  import uvm_pkg::*;\n"
            "  import mldsa_env_pkg::*;\n"
            "  mldsa_environment generated_environment;\n"
            "endmodule\n"
        )
        make_iverilog_overlay(env_root, overlay)
        command = [
            args.iverilog,
            "-uvm",
            f"-g{args.edition}",
            "-DCALIPTRA_BFM_AHB_32BIT",
            "-tnull",
            "-s",
            "adams_mldsa_env_compile_top",
            "-I",
            str(overlay),
            "-I",
            str(env_root),
            "-I",
            str(env_root / "registers"),
            "-f",
            "dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f",
            str(adams / "src/abr_top/rtl/abr_reg_uvm.sv"),
            str(env_root / "registers/mldsa_reg_model_top_pkg.sv"),
            str(env_root / "mldsa_env_pkg.sv"),
            str(top),
        ]
        subprocess.run(command, cwd=repo, check=True)
    print("PASS: pinned Adams Bridge MLDSA environment, predictor, scoreboard, and RAL package compile")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
