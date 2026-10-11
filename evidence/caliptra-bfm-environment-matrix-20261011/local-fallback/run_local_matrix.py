#!/usr/bin/env python3
"""Run the pinned environment matrix sequentially on the local Mac."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
TASKS = HERE / "tasks.tsv"
RTL = Path("/tmp/a2-env-c339/runtime/caliptra-rtl")
IVL = Path("/tmp/a2-caliptra-unit-20261011/toolchain/bin/iverilog")
VVP = Path("/tmp/a2-caliptra-unit-20261011/toolchain/bin/vvp")
TIMEOUT = 6900


def run_stage(command, cwd, env, log_path, deadline):
    start = time.monotonic()
    with log_path.open("wb") as log:
        proc = subprocess.Popen(command, cwd=cwd, env=env, stdout=log,
                                stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = proc.wait(timeout=max(0, deadline - time.monotonic()))
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGTERM)
            try:
                proc.wait(timeout=30)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
            code = 124
    return code, round(time.monotonic() - start, 2)


def main():
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    assert IVL.is_file() and VVP.is_file(), "pinned Icarus c339 must be built first"
    assert RTL.is_dir(), "pinned Caliptra source snapshot missing"
    rows = [line.rstrip("\n").split("\t") for line in TASKS.read_text().splitlines()]
    assert all(len(row) == 4 for row in rows), "malformed task manifest"
    done = 0
    for env_id, top, source_repo, filelist in rows:
        out = HERE / "local-mac" / "tasks" / env_id
        result_file = out / "result.json"
        if result_file.exists():
            continue
        root = RTL if source_repo == "caliptra_v2.1.2" else RTL / "submodules/adams-bridge"
        vf = root / filelist
        candidates = list(root.glob(f"src/**/tb/{top}.sv"))
        if not candidates:
            candidates = list(root.glob(f"src/**/{top}.sv"))
        out.mkdir(parents=True, exist_ok=True)
        if not vf.is_file():
            result_file.write_text(json.dumps({"environment_id": env_id, "top": top,
                "runner_exit": 2, "error": f"filelist missing: {vf}"}, indent=2) + "\n")
            continue
        cwd = candidates[0].parent if len(candidates) == 1 else vf.parent
        env = os.environ.copy()
        env.update(CALIPTRA_ROOT=str(RTL),
                   CALIPTRA_PRIM_ROOT=str(RTL / "src/caliptra_prim_generic"),
                   CALIPTRA_PRIM_MODULE_PREFIX="caliptra_prim_generic",
                   CALIPTRA_AXI4PC_DIR=str(RTL / "src/integration/tb"),
                   ADAMSBRIDGE_ROOT=str(RTL / "submodules/adams-bridge"),
                   PATH=f"{IVL.parent}:{env.get('PATH', '')}")
        binary = out / f"{top}.vvp"
        deadline = time.monotonic() + TIMEOUT
        compile_exit, compile_seconds = run_stage(
            ["/usr/bin/time", "-l", str(IVL), "-g2017", "-gassertions", "-s", top,
             "-f", str(vf), "-o", str(binary)], cwd, env, out / "compile.log", deadline)
        sim_exit, sim_seconds = None, None
        if compile_exit == 0:
            sim_exit, sim_seconds = run_stage(
                ["/usr/bin/time", "-l", str(VVP), "-n", str(binary)],
                cwd, env, out / "sim.log", deadline)
        data = {"environment_id": env_id, "top": top, "source_repo": source_repo,
                "filelist": filelist, "working_directory": str(cwd),
                "compile_exit": compile_exit, "compile_seconds": compile_seconds,
                "sim_exit": sim_exit, "sim_seconds": sim_seconds,
                "classification": "PASS" if compile_exit == 0 and sim_exit == 0 else "UNCLASSIFIED"}
        result_file.write_text(json.dumps(data, indent=2) + "\n")
        print(json.dumps(data), flush=True)
        done += 1
        if limit and done >= limit:
            break


if __name__ == "__main__":
    main()
