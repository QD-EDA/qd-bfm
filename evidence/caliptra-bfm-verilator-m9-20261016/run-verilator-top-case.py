#!/usr/bin/env python3
import argparse
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import time
import traceback
from datetime import datetime, timezone
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--rtl", type=Path, required=True)
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--case", required=True)
    parser.add_argument("--case-yaml", type=Path)
    parser.add_argument("--timeout", type=int, required=True)
    parser.add_argument("--c339-outcome", required=True)
    parser.add_argument("--c339-mcycle", required=True)
    parser.add_argument("--c339-elapsed", required=True)
    parser.add_argument("--keep-firmware-images", action="store_true")
    args = parser.parse_args()

    source = args.source.resolve()
    rtl = args.rtl.resolve()
    model = args.model.resolve()
    output = args.output.resolve()
    if output.exists():
        raise SystemExit(f"output already exists: {output}")
    output.mkdir(parents=True)
    work = output / ".work"
    work.mkdir()
    runner_path = source / "dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
    spec = importlib.util.spec_from_file_location("caliptra_runner", runner_path)
    runner = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = runner
    spec.loader.exec_module(runner)

    result = {
        "host": os.uname().nodename,
        "case": args.case,
        "timeout_s": args.timeout,
        "c339_outcome": args.c339_outcome,
        "c339_mcycle": args.c339_mcycle,
        "c339_elapsed_s": args.c339_elapsed,
        "model_sha256": runner.sha256(model),
        "started_at": datetime.now(timezone.utc).isoformat(),
    }
    outcome = "HARNESS_ERROR"
    started = time.monotonic()
    try:
        env = os.environ.copy()
        env.update(
            CALIPTRA_ROOT=str(rtl),
            CALIPTRA_PRIM_ROOT=str(rtl / "src/caliptra_prim_generic"),
            CALIPTRA_PRIM_MODULE_PREFIX="caliptra_prim_generic",
            CALIPTRA_AXI4PC_DIR=str(rtl / "src/integration/tb"),
        )
        gcc_prefix = runner.normalize_gcc_prefix(env["CALIPTRA_GCC_PREFIX"], env)
        runner.preflight_riscv_toolchain(gcc_prefix, env, work, output / "toolchain-preflight.log")
        case_yaml, seed, plusargs, yaml_testname = runner.load_case(rtl, args.case, args.case_yaml)
        if args.case_yaml is None and yaml_testname != args.case:
            raise RuntimeError(f"YAML testname mismatch: {yaml_testname}")
        result.update(
            case_yaml=str(case_yaml.relative_to(rtl)),
            case_yaml_sha256=runner.sha256(case_yaml),
            seed=seed,
            plusargs=plusargs,
        )

        vector_files, vector_hashes, vector_commands, vector_tools = runner.prepare_native_vectors(
            rtl, work, env
        )
        result["native_vector_commands"] = vector_commands
        test_output = work / args.case
        test_output.mkdir()
        firmware_command = [
            "make", "-f", str(rtl / "tools/scripts/Makefile"), f"TESTNAME={args.case}",
            f"GCC_PREFIX={gcc_prefix}", "CALIPTRA_INTERNAL_TRNG=1",
            f"PLAYBOOK_RANDOM_SEED={seed}", "BUILD_CFLAGS=-std=gnu11 -O2", "program.hex",
        ]
        firmware_exit = runner.run_logged(
            firmware_command, test_output, env, test_output / "firmware.log"
        )
        result["firmware_command"] = firmware_command
        result["firmware_exit"] = firmware_exit
        images = ("program.hex", "dccm.hex", "iccm.hex", "mailbox.hex")
        missing = [name for name in images if not (test_output / name).is_file()]
        if firmware_exit or missing or (test_output / "program.hex").stat().st_size == 0:
            outcome = "FIRMWARE_BUILD_FAIL"
            result["missing_images"] = missing
        else:
            result["firmware_image_sha256"] = {
                name: runner.sha256(test_output / name) for name in images
            }
            if args.keep_firmware_images:
                image_output = output / "firmware-images"
                image_output.mkdir()
                for name in images:
                    shutil.copy2(test_output / name, image_output / name)
            result["native_vector_sha256"] = runner.stage_native_vectors(
                test_output, vector_files, vector_hashes, vector_tools, env
            )
            sim_command = [str(model), "+CLP_REGRESSION", *plusargs]
            result["simulation_command"] = sim_command
            sim_log = output / "sim.log"
            sim_resource = output / "sim.resource"
            sim_started = time.monotonic()
            with sim_log.open("wb") as log:
                sim_exit = subprocess.run([
                    "/usr/bin/time", "-v", "-o", str(sim_resource),
                    "timeout", "--signal=TERM", "--kill-after=30s", str(args.timeout),
                    *sim_command,
                ], cwd=test_output, env=env, stdout=log, stderr=subprocess.STDOUT).returncode
            sim_elapsed = time.monotonic() - sim_started
            scan = runner.scan_sim_log(sim_log)
            result["sim_exit"] = sim_exit
            result["sim_elapsed_s"] = round(sim_elapsed, 3)
            result["sim_scan"] = scan
            if sim_exit == 124:
                outcome = "TIMEOUT"
            elif (sim_exit == 0 and scan["passed"] == 1 and scan["failed"] == 0
                  and scan["bad"] == 0 and scan["jtag_errors"] == 0
                  and scan["finish"] is not None):
                outcome = "PASS"
            else:
                outcome = "FAIL"
    except Exception:
        result["error"] = traceback.format_exc()
    finally:
        result["outcome"] = outcome
        result["elapsed_s"] = round(time.monotonic() - started, 3)
        result["completed_at"] = datetime.now(timezone.utc).isoformat()
        if work.exists():
            firmware_log = work / args.case / "firmware.log"
            if firmware_log.is_file():
                shutil.copy2(firmware_log, output / "firmware.log")
            native_logs = work / "native_vectors"
            if native_logs.is_dir():
                copies = output / "native-vector-logs"
                copies.mkdir(exist_ok=True)
                for path in native_logs.glob("step_*.log"):
                    shutil.copy2(path, copies / path.name)
        (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        if outcome in ("PASS", "FAIL", "TIMEOUT"):
            shutil.rmtree(work, ignore_errors=True)
    return 0 if outcome in ("PASS", "FAIL", "TIMEOUT") else 1


if __name__ == "__main__":
    raise SystemExit(main())
