#!/usr/bin/env python3
"""Add observation-only status snapshots to the staged row31 testbench."""

import hashlib
import json
import os
import runpy
import sys
from pathlib import Path


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def trace_source(text: str) -> str:
    target = '"SHA_ACC_INTR_BRF_ERROR_INTERNAL_INTR_R"'
    ahb = "        wrtrans.update(addr, 32'hffff_ffff, tid);\n        write_reg_trans(SET_AHB, wrtrans); // This should clear the register to all 0's\n        repeat (10) @(posedge clk_tb);"
    if text.count(ahb) != 1:
        raise RuntimeError(f"expected one row31 AHB status-write anchor, found {text.count(ahb)}")
    traced_ahb = f'''        if (rname == {target}) $display("M19_STATUS PRE_AHB=%b", error_internal_intr_r);
        wrtrans.update(addr, 32'hffff_ffff, tid);
        write_reg_trans(SET_AHB, wrtrans); // This should clear the register to all 0's
        repeat (10) @(posedge clk_tb);
        if (rname == {target}) $display("M19_STATUS PRE_AXI=%b", error_internal_intr_r);'''
    text = text.replace(ahb, traced_ahb, 1)
    sample = "              @(posedge clk_tb);\n              case (rname)"
    if text.count(sample) != 1:
        raise RuntimeError(f"expected one row31 assertion-sample anchor, found {text.count(sample)}")
    traced_sample = f'''              @(posedge clk_tb);
              if (rname == {target}) $display("M19_STATUS ASSERT_SAMPLE=%b", error_internal_intr_r);
              case (rname)'''
    return text.replace(sample, traced_sample, 1)


def self_check() -> None:
    source = '''        wrtrans.update(addr, 32'hffff_ffff, tid);
        write_reg_trans(SET_AHB, wrtrans); // This should clear the register to all 0's
        repeat (10) @(posedge clk_tb);
              @(posedge clk_tb);
              case (rname)'''
    patched = trace_source(source)
    assert patched.count("M19_STATUS PRE_AHB") == 1
    assert patched.count("M19_STATUS PRE_AXI") == 1
    assert patched.count("M19_STATUS ASSERT_SAMPLE") == 1


def main() -> int:
    self_check()
    runner = Path(os.environ["M19_BASE_RUNNER"]).resolve()
    namespace = runpy.run_path(str(runner))
    original_run_logged = namespace["run_logged"]

    def traced_run_logged(command, cwd, env, log, timeout):
        if command and Path(command[0]).name == "iverilog":
            output = log.parent
            source = output / "runtime" / "sha_acc_intrblk_test.svh"
            if not source.is_file():
                raise RuntimeError(f"missing staged row31 testbench {source}")
            original = source.read_bytes()
            patched = trace_source(original.decode()).encode()
            source.write_bytes(patched)
            (output / "m19_row31_trace_manifest.json").write_text(json.dumps({
                "source": str(source),
                "source_sha256": digest(original),
                "trace_sha256": digest(patched),
                "observations": ["status before AHB status write", "status before AXI write", "status at each assertion sample"],
                "scope": "observation-only testbench trace; no functional logic or pass criteria changed",
            }, indent=2) + "\n")
        return original_run_logged(command, cwd, env, log, timeout)

    namespace["main"].__globals__["run_logged"] = traced_run_logged
    sys.argv = [str(runner), *sys.argv[1:]]
    return namespace["main"]()


if __name__ == "__main__":
    raise SystemExit(main())
