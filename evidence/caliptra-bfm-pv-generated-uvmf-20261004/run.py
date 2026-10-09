#!/usr/bin/env python3
"""Run Caliptra's pinned generated PCRVault UVMF test with the open AHB BFM."""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


CALIPTRA_COMMIT = "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e"
CALIPTRA_DIRTY_PATHS = (
    "src/caliptra_prim",
    "src/caliptra_prim_generic",
    "src/lc_ctrl/rtl",
    "src/entropy_src/rtl",
    "src/csrng/rtl",
    "src/edn/rtl",
    "src/libs/rtl",
    "src/integration/rtl",
    "src/pcrvault",
)
LICENSED_PATH_MARKERS = ("UVM_HOME", "QUESTA_MVC_HOME", "UVMF_HOME")
QVIP_PATH = "/src/libs/uvmf/qvip_ahb_lite_slave_dir/"


def run_git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def check_caliptra(root: Path) -> None:
    actual = run_git(root, "rev-parse", "HEAD")
    if actual != CALIPTRA_COMMIT:
        raise SystemExit(
            f"PCRVault generated UVMF run requires Caliptra commit {CALIPTRA_COMMIT}; "
            f"found {actual or 'no Git checkout'}."
        )
    dirty = run_git(root, "status", "--porcelain", "--", *CALIPTRA_DIRTY_PATHS)
    if dirty:
        raise SystemExit(
            "PCRVault generated UVMF run requires clean compiled Caliptra sources."
        )


def caliptra_filelist(root: Path, template_root: Path, overlay: Path) -> tuple[list[str], list[str], list[str]]:
    manifest = root / "src/pcrvault/uvmf_pv/config/uvmf_pv.vf"
    defines: list[str] = []
    include_dirs: list[str] = []
    sources: list[str] = []
    overlay_sources = {
        "project_benches/pv/tb/testbench/hdl_top.sv": overlay / "hdl_top.sv",
        "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_driver_bfm.sv":
            overlay / "src/pv_rst_driver_bfm.sv",
        "verification_ip/interface_packages/pv_rst_pkg/src/pv_rst_monitor_bfm.sv":
            overlay / "src/pv_rst_monitor_bfm.sv",
        "verification_ip/interface_packages/pv_read_pkg/src/pv_read_driver_bfm.sv":
            overlay / "src/pv_read_driver_bfm.sv",
        "verification_ip/interface_packages/pv_read_pkg/src/pv_read_monitor_bfm.sv":
            overlay / "src/pv_read_monitor_bfm.sv",
        "verification_ip/environment_packages/pv_env_pkg/src/pv_env_configuration.svh":
            overlay / "src/pv_env_configuration.svh",
        "verification_ip/environment_packages/pv_env_pkg/src/pv_ahb_reg_predictor.svh":
            overlay / "src/pv_ahb_reg_predictor.svh",
    }
    for raw in manifest.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        line = (
            line.replace("${CALIPTRA_ROOT}", str(root))
            .replace("${CALIPTRA_PRIM_ROOT}", str(root / "src/caliptra_prim_generic"))
            .replace("${CALIPTRA_PRIM_MODULE_PREFIX}", "caliptra_prim_generic")
        )
        if line.startswith("+define+"):
            defines.append("-D" + line.removeprefix("+define+"))
            continue
        if line.startswith("+incdir+"):
            include = line.removeprefix("+incdir+")
            if any(marker in include for marker in LICENSED_PATH_MARKERS):
                continue
            if "${" in include:
                raise SystemExit(f"unresolved include path in pinned PV file list: {include}")
            include_dirs.append("-I" + include)
            continue
        if "${" in line:
            if any(marker in line for marker in LICENSED_PATH_MARKERS):
                continue
            raise SystemExit(f"unresolved source path in pinned PV file list: {line}")
        if QVIP_PATH in line or any(marker in line for marker in LICENSED_PATH_MARKERS):
            continue
        path = Path(line)
        if path.suffix.lower() not in (".sv", ".v", ".svh"):
            continue
        if not path.is_file():
            raise SystemExit(f"missing pinned PCRVault source from file list: {path}")
        relative = path.relative_to(template_root).as_posix() if path.is_relative_to(template_root) else ""
        sources.append(str(overlay_sources.get(relative, path)))
    return defines, include_dirs, sources


def runtime_summary(output: str) -> list[str]:
    lines = output.splitlines()
    writes = sum("[SCBD_PV_WRITE]" in line and "matches expected!" in line for line in lines)
    reads = sum("[SCBD_PV_READ]" in line and "matches expected!" in line for line in lines)
    return [
        f"PV scoreboard write comparisons: {writes}",
        f"PV scoreboard read comparisons: {reads}",
        f"UVM_WARNING message count: {sum(line.startswith('UVM_WARNING /') for line in lines)}",
        *(
            line for line in lines
            if line.startswith("UVM_ERROR /")
            or line.startswith("UVM_FATAL /")
            or re.match(r"^UVM_(?:INFO|WARNING|ERROR|FATAL)\s*:", line)
            or line == "** TESTCASE PASSED"
            or "$finish called" in line
        ),
    ]


def main() -> int:
    if sys.argv[1:]:
        raise SystemExit(f"usage: {Path(sys.argv[0]).name}")
    repo_root = Path(__file__).resolve().parents[2]
    caliptra_root = Path(
        os.environ.get("CALIPTRA_ROOT", str(repo_root.parent / "caliptra-rtl"))
    ).resolve()
    check_caliptra(caliptra_root)

    template_root = caliptra_root / "src/pcrvault/uvmf_pv/uvmf_template_output"
    helper = repo_root / "docs/conformance/release_overlays/caliptra/pcrvault_generated_bfm_iverilog_overlay.py"
    bfm = repo_root / "dv/caliptra_bfm"
    output_log = Path(os.environ.get(
        "CALIPTRA_BFM_SUMMARY_LOG",
        str(Path(tempfile.gettempdir()) / "caliptra-pv-generated-uvmf-current.log"),
    )).resolve()
    iverilog = os.environ.get("IVERILOG_BIN", "iverilog")
    vvp = os.environ.get("VVP_BIN", "vvp")

    with tempfile.TemporaryDirectory(prefix="caliptra-pv-uvmf-") as temporary:
        temporary_root = Path(temporary)
        overlay = temporary_root / "overlay"
        overlay_result = subprocess.run(
            [sys.executable, str(helper), str(template_root), str(overlay)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        if overlay_result.returncode:
            raise SystemExit(overlay_result.stdout)

        defines, include_dirs, sources = caliptra_filelist(caliptra_root, template_root, overlay)
        stubs = temporary_root / "unused_external_package_stubs.sv"
        stubs.write_text(
            """package rw_txn_pkg;
endpackage
package QUESTA_MVC;
endpackage
package qvip_utils_pkg;
  import uvm_pkg::*;
  class qvip_memory_message_handler extends uvm_object;
    function new(string name = "qvip_memory_message_handler");
      super.new(name);
    endfunction
  endclass
endpackage
""",
            encoding="utf-8",
        )
        compatibility_sources = [
            bfm / "uvmf_lite/uvmf_base_pkg_hdl.sv",
            bfm / "uvmf_lite/uvmf_base_pkg.sv",
            bfm / "uvm/caliptra_ahb_mvc_compat_pkg.sv",
            bfm / "uvm/ahb_lite_caliptra_uvm_pkg.sv",
            bfm / "uvm/caliptra_ahb_qvip_compat_pkg.sv",
            bfm / "uvm/ahb_lite_caliptra_record_if.sv",
            bfm / "uvm/ahb_lite_caliptra_master_cmd_if.sv",
            bfm / "ahb_lite/ahb_lite_caliptra_master.sv",
            bfm / "ahb_lite/ahb_lite_caliptra_checker.sv",
            bfm / "ahb_lite/ahb_lite_caliptra_monitor.sv",
            bfm / "uvm/ahb_lite_caliptra_qvip_hdl.sv",
            bfm / "uvm/ahb_lite_caliptra_pin_monitor_adapter.sv",
            bfm / "uvm/ahb_lite_caliptra_uvm_master_proxy.sv",
        ]
        wrapper = temporary_root / "runtime_top.sv"
        wrapper.write_text(
            "module pv_generated_uvmf_top;\n"
            "  hdl_top hdl();\n"
            "  hvl_top hvl();\n"
            "endmodule\n",
            encoding="utf-8",
        )
        image = temporary_root / "pv-generated-uvmf.vvp"
        command = [
            iverilog,
            "-uvm",
            "-g2017",
            "-o", str(image),
            "-s", "pv_generated_uvmf_top",
            *defines,
            "-I" + str(overlay),
            *include_dirs,
            str(stubs),
            *(str(source) for source in compatibility_sources),
            *sources,
            str(wrapper),
        ]
        result = subprocess.run(
            command,
            cwd=repo_root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=240,
        )
        if result.returncode or any("error:" in line for line in result.stdout.splitlines()):
            output_log.write_text("COMPILE FAILED\n" + result.stdout, encoding="utf-8")
            print(result.stdout, end="", file=sys.stderr)
            raise SystemExit("Generated PCRVault UVMF source set failed to compile.")

        timeout = int(os.environ.get("CALIPTRA_BFM_RUNTIME_TIMEOUT_SECONDS", "180"))
        verbosity = os.environ.get("CALIPTRA_UVM_VERBOSITY", "UVM_HIGH")
        try:
            runtime = subprocess.run(
                [vvp, str(image), "+UVM_TESTNAME=pv_rand_wr_rd_test",
                 f"+UVM_VERBOSITY={verbosity}", "+UVM_NO_RELNOTES"],
                cwd=repo_root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
                timeout=timeout,
            )
        except subprocess.TimeoutExpired:
            message = f"FAIL: PCRVault runtime exceeded {timeout}s."
            output_log.write_text(message + "\n", encoding="utf-8")
            raise SystemExit(message)

        output = runtime.stdout
        trace_path = os.environ.get("CALIPTRA_UVM_TRACE_LOG")
        if trace_path:
            Path(trace_path).write_text(output, encoding="utf-8")
        summary = runtime_summary(output)
        write_compares = int(summary[0].rsplit(" ", 1)[1])
        read_compares = int(summary[1].rsplit(" ", 1)[1])
        if (
            runtime.returncode
            or re.search(r"UVM_(?:ERROR|FATAL)\s*/", output)
            or not re.search(r"^UVM_ERROR\s*:\s*0\s*$", output, re.MULTILINE)
            or not re.search(r"^UVM_FATAL\s*:\s*0\s*$", output, re.MULTILINE)
            or "** TESTCASE PASSED" not in output
            or "$finish called" not in output
            or not write_compares
            or not read_compares
        ):
            summary.insert(0, "FAIL: generated PCRVault test did not satisfy runtime gates.")
            output_log.write_text("\n".join(summary) + "\n", encoding="utf-8")
            print("\n".join(summary), file=sys.stderr)
            raise SystemExit("Generated PCRVault test did not satisfy runtime gates.")

        summary.insert(0, "PASS: generated PCRVault pv_rand_wr_rd_test ran against actual RTL.")
        output_log.write_text("\n".join(summary) + "\n", encoding="utf-8")
        print("\n".join(summary))
    return 0


def run_under_memory_guard() -> int | None:
    if os.environ.get("CALIPTRA_BFM_MEMORY_GUARD_CHILD") == "1" or "--help" in sys.argv or "-h" in sys.argv:
        return None
    repo = Path(__file__).resolve().parents[2]
    guard = repo / "scripts/run_with_memory_pressure_guard.py"
    environment = os.environ.copy()
    environment["CALIPTRA_BFM_MEMORY_GUARD_CHILD"] = "1"
    return subprocess.run(
        [sys.executable, str(guard), "--timeout-seconds", "600", "--",
         sys.executable, str(Path(__file__).resolve()), *sys.argv[1:]],
        env=environment,
        check=False,
    ).returncode


if __name__ == "__main__":
    guarded = run_under_memory_guard()
    raise SystemExit(guarded if guarded is not None else main())
