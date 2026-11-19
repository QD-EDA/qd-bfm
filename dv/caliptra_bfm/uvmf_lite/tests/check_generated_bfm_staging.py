#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Stage the generated BFMs of each M15 UVMF environment from its real filelists.

Runs the same filelist preparation as run_m15_test.py against the pinned
Caliptra checkout in CALIPTRA_ROOT, then prints one line per environment. The
filelists name ${UVM_HOME}/src/uvm_pkg.sv, so UVM_HOME (or --uvm-src) must be set. With
--slang and --uvm-src it also lints the unstaged and staged sources and counts
IEEE 1800-2023 25.9 virtual-interface errors and writes through input ports.
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

import run_m15_test as m15

ENVIRONMENTS = {
    "uvmf-kv": ("src/keyvault/uvmf_kv", "kv"),
    "uvmf-pv": ("src/pcrvault/uvmf_pv", "pv"),
    "uvmf-soc_ifc": ("src/soc_ifc/uvmf_soc_ifc", "soc_ifc"),
    "uvmf-caliptra_top": ("src/integration/uvmf_caliptra_top", "caliptra_top"),
    "uvmf-sha512": ("src/sha512/uvmf_sha512", "SHA512"),
    "uvmf-ecc": ("src/ecc/uvmf_ecc", "ECC"),
}


def prepare(environment_id, caliptra, repo, output):
    area, _ = ENVIRONMENTS[environment_id]
    component = environment_id.replace("uvmf-", "")
    filelist = caliptra / area / "config" / f"uvmf_{component}.vf"
    filelist, _ = m15.prepare_m16_ahb_open_mvc_filelist(filelist, repo, output, component)
    if environment_id == "uvmf-kv":
        filelist, _ = m15.prepare_kv_factory_overlay(filelist, caliptra, output)
        filelist, _ = m15.prepare_kv_generated_bfm_overlay(filelist, caliptra, repo, output)
    if environment_id in ("uvmf-caliptra_top", "uvmf-soc_ifc"):
        filelist, _ = m15.prepare_m17_aaxi_open_filelist(
            filelist, caliptra, repo, output, drop_axi4pc=m15.should_drop_axi4pc_stub(environment_id))
        filelist, _ = m15.prepare_soc_ifc_generated_case_filelist(filelist, caliptra, repo, output)
        filelist, _ = m15.prepare_soc_ifc_wildcard_coverage_overlay(filelist, caliptra, output)
    return filelist


def lint(slang, uvm_src, filelist, env, log):
    command = [slang, "--single-unit", "--timescale", "1ns/1ps", "--error-limit=0",
               "-DUVM_NO_DPI", "-DUVM_NUM_LINES=8", "-I", str(uvm_src), str(uvm_src / "uvm_pkg.sv"),
               "--top", "hdl_top", "-f", str(filelist)]
    completed = subprocess.run(command, env=env, capture_output=True, text=True, timeout=1800)
    log.write_text(completed.stdout + completed.stderr)
    errors = [line for line in log.read_text().splitlines() if " error: " in line]
    interface = sum("virtual interface" in line for line in errors)
    modport = sum("cannot assign to input port" in line for line in errors)
    return interface, modport, len(errors) - interface - modport


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--slang", help="slang binary; lint only when given")
    parser.add_argument("--uvm-src", type=Path, help="UVM library src directory, for --slang")
    args = parser.parse_args()
    if bool(args.slang) != bool(args.uvm_src):
        parser.error("--slang and --uvm-src go together")
    repo = Path(__file__).resolve().parents[4]
    try:
        caliptra = Path(m15.required_environment("CALIPTRA_ROOT", "the pinned Caliptra checkout")).resolve()
        uvm_home = str(args.uvm_src.parent) if args.uvm_src else m15.required_environment(
            "UVM_HOME", "a UVM library root, or pass --uvm-src")
    except m15.ConfigurationError as error:
        print(error, file=sys.stderr)
        return 2
    env = dict(os.environ, CALIPTRA_ROOT=str(caliptra),
               CALIPTRA_PRIM_ROOT=str(caliptra / "src/caliptra_prim_generic"),
               CALIPTRA_PRIM_MODULE_PREFIX="caliptra_prim_generic",
               CALIPTRA_AXI4PC_DIR=str(caliptra / "src/integration/tb"),
               ADAMSBRIDGE_ROOT=str(caliptra / "submodules/adams-bridge"), UVM_HOME=uvm_home)
    failed = False
    for environment_id, (area, bench) in ENVIRONMENTS.items():
        output = args.output_dir.resolve() / environment_id
        output.mkdir(parents=True, exist_ok=True)
        testbench = caliptra / area / "uvmf_template_output/project_benches" / bench / "tb/testbench"
        env["UVMF_PROJECT_DIR"] = str(testbench.parents[1])
        try:
            filelist = prepare(environment_id, caliptra, repo, output)
            staged = m15.prepare_generated_bfm_pins(
                filelist, repo, env, output,
                (testbench / "top_filelist_hdl.f", testbench / "top_filelist_hvl.f"))
        except (OSError, RuntimeError, ValueError) as error:
            failed = True
            print(f"{environment_id}: STAGING FAILED: {error}")
            continue
        staged_bfms = sorted(path.stem for path in (output / "pins").glob("*_bfm.sv"))
        top = (output / "pins/hdl_top.sv").read_text()
        instances = len(re.findall(r"\(\n    \.qd_", top))
        nested = sum(bool(re.match(r"\s*-[fF]\s", line)) for line in staged.read_text().splitlines())
        line = (f"{environment_id}: staged {len(staged_bfms)} BFMs, rewired {instances} hdl_top instances, "
                f"nested -f entries {nested}")
        if args.slang:
            before = lint(args.slang, args.uvm_src, filelist, env, output / "unstaged.log")
            after = lint(args.slang, args.uvm_src, staged, env, output / "staged.log")
            line += (f"; slang 25.9 errors {before[0]} -> {after[0]}, input-port writes "
                     f"{before[1]} -> {after[1]}, other errors {before[2]} -> {after[2]}")
            failed |= after[0] > 0 or after[1] > 0
        print(line)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
