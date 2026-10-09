#!/usr/bin/env python3
"""Elaborate the pinned generated KeyVault HDL top with the open AHB BFM."""

from __future__ import annotations

import os
import re
import shlex
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
    "src/keyvault",
    "src/libs/rtl",
    "src/integration/rtl/caliptra_reg",
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
            f"KeyVault generated HDL evidence requires Caliptra commit {CALIPTRA_COMMIT}; "
            f"found {actual or 'no Git checkout'}."
        )
    dirty = run_git(root, "status", "--porcelain", "--", *CALIPTRA_DIRTY_PATHS)
    if dirty:
        raise SystemExit(
            "KeyVault generated HDL evidence requires clean compiled Caliptra source and include inputs."
        )


def caliptra_filelist(
    root: Path, template_root: Path, overlay: Path, *, runtime: bool = False
) -> tuple[list[str], list[str], list[str]]:
    manifest = root / "src/keyvault/uvmf_kv/config/uvmf_kv.vf"
    defines: list[str] = []
    include_dirs: list[str] = []
    sources: list[str] = []
    overlay_sources = {
        "project_benches/kv/tb/testbench/hdl_top.sv": overlay / "hdl_top.sv",
        "verification_ip/interface_packages/kv_rst_pkg/kv_rst_pkg.sv": overlay / "kv_rst_pkg.sv",
        "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_driver_bfm.sv":
            overlay / "src/kv_rst_driver_bfm.sv",
        "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_monitor_bfm.sv":
            overlay / "src/kv_rst_monitor_bfm.sv",
        "verification_ip/interface_packages/kv_write_pkg/kv_write_pkg.sv":
            overlay / "kv_write_pkg.sv",
        "verification_ip/interface_packages/kv_read_pkg/src/kv_read_monitor_bfm.sv":
            overlay / "src/kv_read_monitor_bfm.sv",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_ahb_sequence.svh":
            overlay / "src/kv_ahb_sequence.svh",
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
                raise SystemExit(f"unresolved include path in pinned KeyVault file list: {include}")
            include_dirs.append("-I" + include)
            continue
        if "${" in line:
            if any(marker in line for marker in LICENSED_PATH_MARKERS):
                continue
            raise SystemExit(f"unresolved source path in pinned KeyVault file list: {line}")
        if QVIP_PATH in line or any(marker in line for marker in LICENSED_PATH_MARKERS):
            continue
        if not runtime and "/environment_packages/" in line and not line.endswith(
            "/registers/kv_reg_adapter_functions_pkg.sv"
        ):
            continue
        if not runtime and "/project_benches/" in line and not line.endswith(
            ("/project_benches/kv/tb/parameters/kv_parameters_pkg.sv",
             "/project_benches/kv/tb/testbench/hdl_top.sv")
        ):
            continue
        path = Path(line)
        if path.suffix.lower() not in (".sv", ".v"):
            continue
        if not path.is_file():
            raise SystemExit(f"missing pinned KeyVault source from file list: {path}")
        relative = path.relative_to(template_root).as_posix() if path.is_relative_to(template_root) else ""
        source = overlay_sources.get(relative, path)
        sources.append(str(source))
    return defines, include_dirs, sources


def runtime_summary(output: str) -> list[str]:
    lines = output.splitlines()
    summary = [
        f"UVM_WARNING message count: {sum(line.startswith('UVM_WARNING /') for line in lines)}",
    ]
    summary.extend(
        line for line in lines
        if line.startswith("UVM_ERROR /")
        or line.startswith("UVM_FATAL /")
        or re.match(r"^UVM_(?:INFO|WARNING|ERROR|FATAL)\s*:", line)
        or line == "** TESTCASE PASSED"
        or line == "PASS: generated KeyVault four-beat AHB read prediction"
        or "$finish called" in line
    )
    return summary


def main() -> int:
    runtime_2023 = sys.argv[1:] == ["--runtime-2023"]
    burst_smoke = sys.argv[1:] == ["--runtime-ahb-burst-smoke"]
    runtime = sys.argv[1:] in (
        ["--runtime"], ["--diagnose"], ["--runtime-2023"], ["--runtime-ahb-burst-smoke"]
    )
    runtime_edition = "2023" if runtime_2023 else "2017"
    diagnostic = sys.argv[1:] == ["--diagnose"]
    if sys.argv[1:] not in (
        [], ["--runtime"], ["--runtime-2023"], ["--diagnose"],
        ["--runtime-ahb-burst-smoke"],
    ):
        raise SystemExit(
            f"usage: {Path(sys.argv[0]).name} "
            "[--runtime|--runtime-2023|--diagnose|--runtime-ahb-burst-smoke]"
        )
    repo_root = Path(__file__).resolve().parents[2]
    caliptra_root = Path(
        os.environ.get("CALIPTRA_ROOT", str(repo_root.parent / "caliptra-rtl"))
    ).resolve()
    check_caliptra(caliptra_root)

    template_root = caliptra_root / "src/keyvault/uvmf_kv/uvmf_template_output"
    helper = repo_root / "docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py"
    bfm = repo_root / "dv/caliptra_bfm"
    output_log = Path(__file__).with_name(
        "ahb-burst-smoke-runtime.log" if burst_smoke else
        "diagnose-runtime.log" if diagnostic else
        "verify-runtime-2023.log" if runtime_2023 else
        "verify-runtime.log" if runtime else "verify.log"
    )
    iverilog = os.environ.get("IVERILOG_BIN", "iverilog")

    run_lines: list[str] = []
    with tempfile.TemporaryDirectory(prefix="caliptra-keyvault-hdl-") as temporary:
        temporary_root = Path(temporary)
        overlay = temporary_root / "overlay"
        overlay_command = [sys.executable, str(helper), str(template_root), str(overlay)]
        if diagnostic:
            overlay_command.append("--diagnose")
        if burst_smoke:
            overlay_command.append("--ahb-burst-smoke")
        overlay_result = subprocess.run(
            overlay_command,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        if overlay_result.returncode:
            raise SystemExit(overlay_result.stdout)

        defines, include_dirs, sources = caliptra_filelist(
            caliptra_root, template_root, overlay, runtime=runtime
        )
        external_stubs = temporary_root / "external_package_stubs.sv"
        external_stubs.write_text(
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
        editions = (runtime_edition,) if runtime else ("2017", "2023")
        wrapper = temporary_root / "runtime_top.sv"
        image = temporary_root / "keyvault-generated-uvmf.vvp"
        if runtime:
            wrapper.write_text(
                "module keyvault_generated_uvmf_top;\n"
                "  hdl_top hdl();\n"
                "  hvl_top hvl();\n"
                "endmodule\n",
                encoding="utf-8",
            )

        for edition in editions:
            target = (
                ["-o", str(image), "-s", "keyvault_generated_uvmf_top"]
                if runtime else ["-tnull", "-s", "hdl_top"]
            )
            command = [
                iverilog,
                "-uvm",
                f"-g{edition}",
                *target,
                *defines,
                "-I" + str(overlay),
                *include_dirs,
                str(external_stubs),
                *(str(source) for source in compatibility_sources),
                *sources,
                *([str(wrapper)] if runtime else []),
            ]
            result = subprocess.run(
                command,
                cwd=repo_root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
                timeout=180,
            )
            errors = [line for line in result.stdout.splitlines() if "error:" in line]
            if result.returncode or errors:
                output_log.write_text(
                    "\n".join(run_lines + [f"FAIL: IEEE {edition}", result.stdout]),
                    encoding="utf-8",
                )
                print(result.stdout, end="", file=sys.stderr)
                raise SystemExit(f"Generated KeyVault hdl_top failed under IEEE {edition}.")
            warning_count = sum("warning:" in line for line in result.stdout.splitlines())
            compile_warning_count = warning_count
            if not runtime:
                run_lines.append(
                    f"PASS: actual generated KeyVault hdl_top elaborated with open AHB replacement "
                    f"under IEEE {edition} ({warning_count} warnings)."
                )
            else:
                run_lines.append(
                    f"PASS: generated KeyVault runtime image compiled under IEEE {runtime_edition} "
                    f"({compile_warning_count} compile warnings)."
                )

        if runtime:
            vvp = os.environ.get("VVP_BIN", "vvp")
            runtime_timeout = int(os.environ.get("CALIPTRA_BFM_RUNTIME_TIMEOUT_SECONDS", "180"))
            runtime_args = [vvp, str(image), "+UVM_TESTNAME=kv_rand_wr_rd_test",
                            f"+UVM_VERBOSITY={os.environ.get('CALIPTRA_UVM_VERBOSITY', 'UVM_NONE')}",
                            "+UVM_NO_RELNOTES",
                            *( ["+KV_PIN_TRACE"] if diagnostic else []),
                            *( ["+KV_AHB_BURST_SMOKE"] if burst_smoke else []),
                            *shlex.split(os.environ.get("CALIPTRA_UVM_PLUSARGS", ""))]
            try:
                result = subprocess.run(
                    runtime_args,
                    cwd=repo_root,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                    timeout=runtime_timeout,
                )
            except subprocess.TimeoutExpired:
                message = (
                    f"FAIL: generated KeyVault runtime exceeded {runtime_timeout}s "
                    f"under IEEE {runtime_edition}."
                )
                output_log.write_text("\n".join(run_lines + [message]) + "\n", encoding="utf-8")
                print(message, file=sys.stderr)
                raise SystemExit(message)
            runtime_output = result.stdout
            trace_path = os.environ.get("CALIPTRA_UVM_TRACE_LOG")
            if trace_path:
                Path(trace_path).write_text(runtime_output, encoding="utf-8")
            if diagnostic:
                if result.returncode or "$finish called" not in runtime_output:
                    failure_summary = [
                        "FAIL: KeyVault diagnostic replay did not terminate normally.",
                        *runtime_summary(runtime_output),
                    ]
                    output_log.write_text("\n".join(run_lines + failure_summary) + "\n", encoding="utf-8")
                    print("\n".join(failure_summary), file=sys.stderr)
                    raise SystemExit("KeyVault diagnostic replay did not terminate normally.")
                error_count = sum(
                    line.startswith("UVM_ERROR /") for line in runtime_output.splitlines()
                )
                run_lines.append(
                    f"DIAGNOSTIC COMPLETE: normal simulation termination; {error_count} UVM errors retained."
                )
                run_lines.extend(
                    line for line in runtime_output.splitlines()
                    if line.startswith("KV_PIN_") or "[KV_PIN_TRACE]" in line
                    or line == "** TESTCASE PASSED" or "$finish called" in line
                )
                output_log.write_text("\n".join(run_lines) + "\n", encoding="utf-8")
                print("\n".join(run_lines))
                return 0
            if (
                result.returncode
                or re.search(r"UVM_(?:ERROR|FATAL)\s*/", runtime_output)
                or not re.search(r"^UVM_ERROR\s*:\s*0\s*$", runtime_output, re.MULTILINE)
                or not re.search(r"^UVM_FATAL\s*:\s*0\s*$", runtime_output, re.MULTILINE)
                or "** TESTCASE PASSED" not in runtime_output
                or "$finish called" not in runtime_output
                or (burst_smoke and
                    "PASS: generated KeyVault four-beat AHB read prediction" not in runtime_output)
            ):
                failure_summary = [
                    "FAIL: actual generated KeyVault kv_rand_wr_rd_test did not pass runtime gates.",
                    *runtime_summary(runtime_output),
                ]
                output_log.write_text(
                    "\n".join(run_lines + failure_summary) + "\n",
                    encoding="utf-8",
                )
                print("\n".join(failure_summary), file=sys.stderr)
                raise SystemExit("Generated KeyVault kv_rand_wr_rd_test did not pass runtime gates.")
            runtime_warning_count = sum(
                line.startswith("UVM_WARNING /") for line in runtime_output.splitlines()
            )
            run_lines.append(
                "PASS: actual generated KeyVault kv_rand_wr_rd_test ran with open AHB replacement "
                f"under IEEE {runtime_edition} ({runtime_warning_count} runtime warnings)."
            )
            run_lines.extend(runtime_summary(runtime_output))

    output_log.write_text("\n".join(run_lines) + "\n", encoding="utf-8")
    print("\n".join(run_lines))
    return 0




def run_under_memory_guard() -> int | None:
    if os.environ.get("CALIPTRA_BFM_MEMORY_GUARD_CHILD") == "1" or "--help" in sys.argv or "-h" in sys.argv:
        return None
    repo = Path(__file__).resolve().parents[2]
    guard = repo / "scripts/run_with_memory_pressure_guard.py"
    environment = os.environ.copy()
    environment["CALIPTRA_BFM_MEMORY_GUARD_CHILD"] = "1"
    command = [
        sys.executable,
        str(guard),
        "--timeout-seconds",
        "600",
        "--",
        sys.executable,
        str(Path(__file__).resolve()),
        *sys.argv[1:],
    ]
    return subprocess.run(command, env=environment).returncode


if __name__ == "__main__":
    guarded_result = run_under_memory_guard()
    if guarded_result is not None:
        raise SystemExit(guarded_result)
    raise SystemExit(main())
