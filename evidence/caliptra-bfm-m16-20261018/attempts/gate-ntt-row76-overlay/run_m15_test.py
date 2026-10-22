#!/usr/bin/env python3
"""Run one pinned M15 YAML test and save a uniform result record."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import platform
import re
import shutil
import signal
import socket
import subprocess
import time
from pathlib import Path


CALIPTRA_PIN = "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e"
ADAMS_BRIDGE_PIN = "b77e3d899e828d626cfc2a0d26a6b5704cc121e0"
IVERILOG_PIN = "9b5fad2afb4104caa816b257d5bccc40f01b8c66"
IVERILOG_SHA256 = "6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288"
SOC_IFC_TB_PKG_SHA256 = "72f75561e1b88976ee2fe6f16de9eeac8f1f90bcace7baf7513a67ebe403feed"
BUTTERFLY_TB_SHA256 = "53c38240f13e9f353f5ae4a028d6087aa7aa15ba3fd2eb557a7505db7a899366"
PASS_MARKERS = ("* TESTCASE PASSED", "** TESTCASE PASSED")
FAIL_MARKERS = (
    "* TESTCASE FAILED", "** TESTCASE FAILED", "UVMF_SB_MISMATCH", "UVMF_SB_LEFTOVER",
    "Test failed at NTT operation", "Test failed at INTT operation",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run_git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def stop_group(process: subprocess.Popen[bytes]) -> None:
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=10)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def run_logged(command: list[str], cwd: Path, env: dict[str, str], log: Path, timeout: int) -> tuple[int, bool]:
    log.parent.mkdir(parents=True, exist_ok=True)
    resource = log.with_suffix(".resource")
    timed = ["/usr/bin/time", "-v", "-o", str(resource), *command] if platform.system() == "Linux" else command
    (log.parent / (log.stem + ".command")).write_text(json.dumps(command) + "\n")
    with log.open("wb") as output:
        process = subprocess.Popen(
            timed, cwd=cwd, env=env, stdout=output, stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        try:
            return process.wait(timeout=timeout), False
        except subprocess.TimeoutExpired:
            stop_group(process)
            return 124, True


def classify(log_text: str, return_code: int) -> tuple[str, str]:
    if any(marker in log_text for marker in FAIL_MARKERS):
        return "FAIL", "testbench reported a failure or scoreboard mismatch"
    if re.search(r"UVM_ERROR\s*:\s*[1-9]\d*|UVM_FATAL\s*:\s*[1-9]\d*", log_text):
        return "FAIL", "UVM reported one or more errors or fatals"
    if return_code != 0:
        if re.search(r"(vvp|iverilog).*(internal error|unsupported|error:)", log_text, re.I):
            return "BLOCKED", f"simulator runtime error (exit {return_code})"
        return "FAIL", f"simulation exited with status {return_code}"
    suite_errors = re.search(r"(?m)^Total tests: [1-9]\d*, Errors: ([1-9]\d*)\r?$", log_text)
    if suite_errors:
        return "FAIL", "standalone test suite reported one or more errors"
    if re.search(r"(?m)^Total tests: [1-9]\d*, Errors: 0\r?\nPASS\r?\nAll tests completed\.$", log_text):
        return "PASS", "standalone test suite reported zero errors and completed"
    if any(marker in log_text for marker in PASS_MARKERS):
        return "PASS", "testbench pass marker present; no failure marker or UVM error/fatal"
    diagnostic = first_diagnostic(log_text)
    if diagnostic != "Icarus returned nonzero without a concise diagnostic":
        return "BLOCKED", diagnostic
    return "BLOCKED", "simulation ended without a recognized test pass marker"


def first_diagnostic(log_text: str) -> str:
    for line in log_text.splitlines():
        if re.search(r"(error:|fatal:|sorry:|syntax error|could not open|No such file|include file .* not found)", line, re.I):
            return line.strip()[:500]
    return "Icarus returned nonzero without a concise diagnostic"


def stage_test_vectors(source_dir: Path, runtime: Path) -> None:
    vectors = source_dir / "test_vectors"
    if vectors.is_dir():
        shutil.copytree(vectors, runtime, dirs_exist_ok=True)


def fix_soc_ifc_dict_initializers(source_text: str) -> str:
    anchor = "[string] = {"
    if source_text.count(anchor) != 8:
        raise RuntimeError(f"expected 8 pinned SoC-IFC string maps, found {source_text.count(anchor)}")
    return source_text.replace(anchor, "[string] = '{")


def fix_butterfly_expected_vector(source_text: str) -> str:
    source = '$readmemh("kyber_stage0_out.hex", in_val);'
    if source_text.count(source) != 1:
        raise RuntimeError("expected one pinned butterfly expected-vector load into in_val")
    return source_text.replace(source, '$readmemh("kyber_stage0_out.hex", out_val);')


def prepare_m16_ahb_open_mvc_filelist(
    filelist: Path, repo: Path, output: Path, component_id: str
) -> tuple[Path, Path]:
    source_text = filelist.read_text()
    required = (
        "${QUESTA_MVC_HOME}/include/questa_mvc_svapi.svh",
        "${QUESTA_MVC_HOME}/questa_mvc_src/sv/mvc_pkg.sv",
        "${UVMF_HOME}/uvmf_base_pkg/uvmf_base_pkg.sv",
        "qvip_ahb_lite_slave_dir/uvmf/qvip_ahb_lite_slave_pkg.sv",
    )
    if any(source_text.count(marker) != 1 for marker in required):
        raise RuntimeError(f"pinned {component_id} filelist no longer has the expected MVC/UVMF/QVIP entries")

    support_filelist = repo / "dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f"
    support_sources = []
    for entry in support_filelist.read_text().splitlines():
        entry = entry.strip()
        if not entry or entry.startswith("#"):
            continue
        source = (repo / entry).resolve()
        if not source.is_file():
            raise RuntimeError(f"missing QD-BFM MVC support source: {source}")
        support_sources.append(str(source))
    for suffix in (
        "caliptra_ahb_mvc_compat_pkg.sv", "caliptra_ahb_qvip_compat_pkg.sv",
        "ahb_lite_caliptra_qvip_hdl.sv", "uvmf_base_pkg.sv",
    ):
        if not any(source.endswith(suffix) for source in support_sources):
            raise RuntimeError(f"QD-BFM MVC support filelist omits {suffix}")

    lines = source_text.splitlines()
    marker_index = next(i for i, line in enumerate(lines) if required[0] in line)
    external_paths = ("QUESTA_MVC_HOME", "UVMF_HOME", "qvip_ahb_lite_slave_dir/")
    counts = {path: sum(path in line for line in lines) for path in external_paths}
    if any(count == 0 for count in counts.values()):
        raise RuntimeError(f"expected external MVC/UVMF/QVIP paths are missing: {counts}")

    overlay_lines = []
    for i, line in enumerate(lines):
        if i == marker_index:
            overlay_lines.extend(support_sources)
        if not any(path in line for path in external_paths):
            overlay_lines.append(line)
    if any(path in line for line in overlay_lines for path in external_paths):
        raise RuntimeError("open MVC filelist still contains a removed external dependency")

    overlay_dir = output / "overlays"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    overlay = overlay_dir / f"{component_id}-ahb-open-mvc.vf"
    overlay.write_text("\n".join(overlay_lines) + "\n")
    manifest = overlay_dir / f"{component_id}-ahb-open-mvc.json"
    manifest.write_text(json.dumps({
        "source_filelist": str(filelist), "source_sha256": sha256(filelist),
        "overlay_filelist": str(overlay), "overlay_sha256": sha256(overlay),
        "support_filelist": str(support_filelist), "support_filelist_sha256": sha256(support_filelist),
        "support_sources": [{"path": source, "sha256": sha256(Path(source))} for source in support_sources],
        "removed_entry_counts": counts,
        "scope": "testbench, BFM, filelist, and setup only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return overlay, manifest


def root_for(repo_name: str, caliptra: Path) -> Path:
    return caliptra if repo_name == "caliptra" else caliptra / "submodules/adams-bridge"


def find_top(root: Path, top: str) -> Path | None:
    matches = list(root.glob(f"src/**/tb/{top}.sv"))
    return matches[0] if len(matches) == 1 else None


def main() -> int:
    repo = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=repo)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--row-id", type=int, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--timeout", type=int, default=3600)
    args = parser.parse_args()
    repo = args.repo_root.resolve()
    manifest = args.manifest.resolve()
    output = args.output_dir.resolve()
    rows = list(csv.DictReader(manifest.open(), delimiter="\t"))
    matches = [row for row in rows if int(row["row_id"]) == args.row_id]
    if len(matches) != 1:
        raise SystemExit(f"expected one row_id={args.row_id} in {manifest}")
    row = matches[0]
    output.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    deadline = started + args.timeout
    result: dict[str, object] = {
        "row_id": args.row_id, "testname": row["testname"],
        "source_repo": row["source_repo"], "source_file": row["source_file"],
        "source_pin": row["source_pin"], "source_yaml_sha256": row["source_yaml_sha256"],
        "environment_id": row["environment_id"], "runner_profile": row["runner_profile"],
        "filelist": row["filelist"], "filelist_sha256_json": row["filelist_sha256_json"],
        "run_plusargs": json.loads(row["run_plusargs_json"]),
        "host": socket.gethostname(), "platform": platform.platform(),
        "slurm_job_id": os.environ.get("SLURM_JOB_ID", "local"),
        "slurm_array_task_id": os.environ.get("SLURM_ARRAY_TASK_ID", "local"),
        "timeout_seconds": args.timeout,
    }
    try:
        caliptra = Path(os.environ.get("CALIPTRA_ROOT", "/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl")).resolve()
        root = root_for(row["source_repo"], caliptra)
        expected_pin = CALIPTRA_PIN if row["source_repo"] == "caliptra" else ADAMS_BRIDGE_PIN
        actual_pin = run_git(root, "rev-parse", "HEAD")
        if actual_pin != expected_pin or row["source_pin"] != expected_pin:
            raise RuntimeError(f"source pin mismatch: expected {expected_pin}, found {actual_pin}")
        if run_git(root, "status", "--porcelain", "--untracked-files=normal"):
            raise RuntimeError(f"refusing dirty pinned source checkout: {root}")
        yaml_path = root / row["source_file"]
        if sha256(yaml_path) != row["source_yaml_sha256"]:
            raise RuntimeError(f"source YAML hash mismatch: {yaml_path}")
        for relative, expected in json.loads(row["filelist_sha256_json"]).items():
            if sha256(root / relative) != expected:
                raise RuntimeError(f"filelist hash mismatch: {relative}")

        iverilog = Path(os.environ.get("IVERILOG_BIN", "/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog")).resolve()
        vvp = Path(os.environ.get("VVP_BIN", str(iverilog.with_name("vvp")))).resolve()
        if sha256(iverilog) != IVERILOG_SHA256:
            raise RuntimeError(f"Icarus binary hash mismatch: {sha256(iverilog)}")
        result["iverilog"] = subprocess.check_output([str(iverilog), "-V"], text=True, stderr=subprocess.STDOUT).splitlines()[0]
        result["vvp"] = subprocess.check_output([str(vvp), "-V"], text=True, stderr=subprocess.STDOUT).splitlines()[0]
        result["iverilog_source_pin"] = IVERILOG_PIN
        result["iverilog_binary_sha256"] = sha256(iverilog)
        env = os.environ.copy()
        env.update({
            "CALIPTRA_ROOT": str(caliptra),
            "CALIPTRA_PRIM_ROOT": str(caliptra / "src/caliptra_prim_generic"),
            "CALIPTRA_PRIM_MODULE_PREFIX": "caliptra_prim_generic",
            "CALIPTRA_AXI4PC_DIR": str(caliptra / "src/integration/tb"),
            "ADAMSBRIDGE_ROOT": str(caliptra / "submodules/adams-bridge"),
            "UVM_HOME": str(iverilog.parent.parent / "lib/ivl/uvm"),
            "IVERILOG_BIN": str(iverilog), "VVP_BIN": str(vvp),
            "PATH": str(iverilog.parent) + os.pathsep + env.get("PATH", ""),
        })
        env["LD_LIBRARY_PATH"] = os.pathsep.join(filter(None, [
            str(iverilog.parent.parent / "lib"), str(iverilog.parent.parent / "lib64"),
            "/usr/lib/x86_64-linux-gnu", env.get("LD_LIBRARY_PATH", ""),
        ]))
        plusargs = [arg.replace("${CALIPTRA_ROOT}", str(caliptra)).replace("${ADAMSBRIDGE_ROOT}", str(caliptra / "submodules/adams-bridge")) for arg in result["run_plusargs"]]
        if row["runner_profile"] == "compile-yaml-unresolved":
            result.update(status="BLOCKED", cause="upstream UART compile.yml has no Icarus filelist/setup")
        elif row["testname"] == "HMAC_otf_reset_test":
            script = repo / "dv/caliptra_bfm/uvmf_lite/tests/run_generated_hmac_runtime.sh"
            hmac_dir = output / "hmac"
            env.update({
                "CALIPTRA_BFM_HMAC_TESTNAME": row["testname"],
                "CALIPTRA_BFM_HMAC_SEED": str(row["selected_seed"]),
                "CALIPTRA_BFM_HMAC_RUN_DIR": str(hmac_dir),
            })
            rc, timed_out = run_logged(["/bin/sh", str(script)], repo, env, output / "runner.log", max(0, int(deadline - time.monotonic())))
            result["runner_exit"] = rc
            result["runner_timed_out"] = timed_out
            sim_log = hmac_dir / "run.log"
            log_text = sim_log.read_text(errors="replace") if sim_log.exists() else (output / "runner.log").read_text(errors="replace")
            if timed_out:
                result.update(status="TIMEOUT", cause="HMAC compile/runtime exceeded per-row timeout")
            elif rc != 0 and not sim_log.exists():
                compile_log = hmac_dir / "compile.log"
                diagnostic = first_diagnostic(compile_log.read_text(errors="replace")) if compile_log.exists() else first_diagnostic(log_text)
                result.update(status="BLOCKED", cause=diagnostic)
            else:
                status, cause = classify(log_text, rc)
                result.update(status=status, cause=cause)
            result["compile_exit"] = 0 if sim_log.exists() else (1 if (hmac_dir / "compile.log").exists() else None)
            result["sim_exit"] = rc if sim_log.exists() else None
            result["compile_log"] = str(hmac_dir / "compile.log")
            result["sim_log"] = str(sim_log)
        else:
            top_file = find_top(root, row["top"])
            if row["runner_profile"] == "m7-component" and top_file is None:
                result.update(status="BLOCKED", cause=f"no unique source testbench found for top {row['top']}")
            else:
                runtime = output / "runtime"
                source_dir = top_file.parent if top_file else Path(row["hdl_filelist"])
                if top_file:
                    shutil.copytree(source_dir, runtime, dirs_exist_ok=True)
                else:
                    runtime.mkdir(exist_ok=True)
                if row["area"] == "ntt_top":
                    stage_test_vectors(source_dir, runtime)
                filelist = root / row["filelist"]
                if row["test_kind"] == "generated-uvmf" and row["environment_id"] in (
                    "uvmf-caliptra_top", "uvmf-kv", "uvmf-mldsa", "uvmf-pv", "uvmf-soc_ifc"
                ):
                    component_id = row["environment_id"].replace("uvmf-", "")
                    filelist, overlay_manifest = prepare_m16_ahb_open_mvc_filelist(
                        filelist, repo, output, component_id
                    )
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-butterfly_top_tb":
                    source = top_file
                    if sha256(source) != BUTTERFLY_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed butterfly testbench source: {source}")
                    # The pinned testbench reads expected results back into its input array.
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(exist_ok=True)
                    overlay = overlay_dir / "butterfly_top_tb.sv"
                    overlay.write_text(fix_butterfly_expected_vector(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/ntt_top/tb/butterfly_top_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned butterfly filelist source entry changed")
                    filelist = overlay_dir / "butterfly_top_tb.overlay.vf"
                    filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "butterfly_top_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source": str(source), "source_sha256": BUTTERFLY_TB_SHA256,
                        "overlay": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(filelist), "overlay_filelist_sha256": sha256(filelist),
                        "reason": "load the existing expected-output vector into out_val rather than overwriting in_val",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    result["overlay_manifest"] = str(overlay_manifest)
                image = output / "test.vvp"
                if row["runner_profile"] == "m7-component":
                    if row["environment_id"] == "caliptra-v2-1-2-soc_ifc_tb":
                        source = caliptra / "src/soc_ifc/tb/soc_ifc_tb_pkg.sv"
                        if sha256(source) != SOC_IFC_TB_PKG_SHA256:
                            raise RuntimeError(f"refusing unreviewed SoC-IFC testbench source: {source}")
                        overlay_dir = output / "overlays"
                        overlay_dir.mkdir(exist_ok=True)
                        overlay = overlay_dir / "soc_ifc_tb_pkg.sv"
                        overlay.write_text(fix_soc_ifc_dict_initializers(source.read_text()))
                        filelist_text = filelist.read_text()
                        source_entry = "${CALIPTRA_ROOT}/src/soc_ifc/tb/soc_ifc_tb_pkg.sv"
                        if filelist_text.count(source_entry) != 1:
                            raise RuntimeError("pinned SoC-IFC filelist source entry changed")
                        filelist = overlay_dir / "soc_ifc_tb.overlay.vf"
                        filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                        overlay_manifest = overlay_dir / "manifest.json"
                        overlay_manifest.write_text(json.dumps({
                            "source": str(source), "source_sha256": SOC_IFC_TB_PKG_SHA256,
                            "overlay": str(overlay), "overlay_sha256": sha256(overlay),
                            "filelist": str(filelist), "filelist_sha256": sha256(filelist),
                            "reason": "add the SystemVerilog assignment-pattern marker to eight string-keyed testbench maps",
                            "scope": "testbench only; no RTL, firmware, or pass criteria changed",
                        }, indent=2) + "\n")
                        result["overlay_manifest"] = str(overlay_manifest)
                    command = [str(iverilog), "-g2017", "-gassertions", "-s", row["top"], "-f", str(filelist), "-o", str(image)]
                else:
                    project = (root / row["hdl_filelist"]).parents[2]
                    env["UVMF_PROJECT_DIR"] = str(project)
                    wrapper = output / "m15_uvmf_top.sv"
                    wrapper.write_text("module m15_uvmf_top; hdl_top hdl(); hvl_top hvl(); endmodule\n")
                    command = [str(iverilog), "-uvm", "-g2017", "-gassertions", "-s", "m15_uvmf_top", "-f", str(filelist)]
                    if "hdl_top.sv" not in filelist.read_text():
                        command += ["-f", str(root / row["hdl_filelist"])]
                    if "hvl_top.sv" not in filelist.read_text():
                        command += ["-f", str(root / row["hvl_filelist"])]
                    command += [str(wrapper)]
                    sim_cwd = project / "tb/testbench"
                    if sim_cwd.is_dir():
                        shutil.copytree(sim_cwd, runtime, dirs_exist_ok=True)
                compile_rc, compile_timeout = run_logged(command, runtime, env, output / "compile.log", max(0, int(deadline - time.monotonic())))
                result["compile_exit"] = compile_rc
                result["compile_timed_out"] = compile_timeout
                if compile_timeout:
                    result.update(status="TIMEOUT", cause="Icarus compile exceeded per-row timeout")
                elif compile_rc != 0:
                    compile_text = (output / "compile.log").read_text(errors="replace")
                    result.update(status="BLOCKED", cause=first_diagnostic(compile_text))
                else:
                    sim_command = [str(vvp), "-n", str(image), *plusargs]
                    sim_rc, sim_timeout = run_logged(sim_command, runtime, env, output / "sim.log", max(0, int(deadline - time.monotonic())))
                    result["sim_exit"] = sim_rc
                    result["sim_timed_out"] = sim_timeout
                    sim_text = (output / "sim.log").read_text(errors="replace")
                    if sim_timeout:
                        result.update(status="TIMEOUT", cause="VVP exceeded per-row timeout")
                    else:
                        status, cause = classify(sim_text, sim_rc)
                        result.update(status=status, cause=cause)
                    result["sim_log"] = str(output / "sim.log")
                result["compile_log"] = str(output / "compile.log")
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        result.update(status="BLOCKED", cause=str(error))

    result["elapsed_seconds"] = round(time.monotonic() - started, 3)
    (output / "result.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    (output / "result.txt").write_text(
        f"row_id={result['row_id']}\ntestname={result['testname']}\nstatus={result['status']}\ncause={result['cause']}\nelapsed_seconds={result['elapsed_seconds']}\n"
    )
    print(f"{result['status']} row={args.row_id} test={row['testname']}: {result['cause']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
