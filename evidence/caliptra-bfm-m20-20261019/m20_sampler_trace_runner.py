#!/usr/bin/env python3
"""Add an observation-only trace to the pinned ABR controller before one row compiles."""

import hashlib
import json
import os
import sys
from pathlib import Path


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_control(source: Path, filelist: Path, output: Path) -> dict:
    original = source.read_bytes()
    text = original.decode()
    marker = "M20_VERIFY_TRACE"
    if marker in text or text.count("endmodule") != 1:
        raise RuntimeError("unexpected abr_ctrl.sv shape or duplicate trace")
    block = '''  // M20_VERIFY_TRACE: observation only; no control or data assignment changed.
  integer m20_ctrl_trace_cycle;
  initial m20_ctrl_trace_cycle = 0;
  always @(posedge clk) begin
    m20_ctrl_trace_cycle = m20_ctrl_trace_cycle + 1;
    $display("M20_VERIFY_TRACE PRE cycle=%0d t=%0t proc=%b verify=%b set=%b clear=%b dv=%b dest=%h data0=%08h state=%h write0=%b clear0=%b reg0=%08h",
      m20_ctrl_trace_cycle, $time, mldsa_verifying_process, verify_valid, set_verify_valid, clear_verify_valid, sampler_state_dv_i,
      abr_instr.operand3, sampler_state_data_i[0][31:0], sampler_state_data_i[0][511:0],
      abr_reg_hwif_in.MLDSA_VERIFY_RES[0].VERIFY_RES.we,
      abr_reg_hwif_in.MLDSA_VERIFY_RES[0].VERIFY_RES.hwclr,
      abr_reg_hwif_out.MLDSA_VERIFY_RES[0].VERIFY_RES.value);
    $strobe("M20_VERIFY_TRACE POST cycle=%0d t=%0t proc=%b verify=%b set=%b clear=%b dv=%b dest=%h data0=%08h write0=%b clear0=%b reg0=%08h",
      m20_ctrl_trace_cycle, $time, mldsa_verifying_process, verify_valid, set_verify_valid, clear_verify_valid, sampler_state_dv_i,
      abr_instr.operand3, sampler_state_data_i[0][31:0],
      abr_reg_hwif_in.MLDSA_VERIFY_RES[0].VERIFY_RES.we,
      abr_reg_hwif_in.MLDSA_VERIFY_RES[0].VERIFY_RES.hwclr,
      abr_reg_hwif_out.MLDSA_VERIFY_RES[0].VERIFY_RES.value);
  end
'''
    patched = text.replace("endmodule", block + "endmodule", 1).encode()
    overlay = output / "overlays/m20-internal-trace/abr_ctrl.sv"
    overlay.parent.mkdir(parents=True, exist_ok=True)
    overlay.write_bytes(patched)

    old_entry = "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_ctrl.sv"
    original_filelist = filelist.read_bytes()
    fl_text = original_filelist.decode()
    if fl_text.count(old_entry) != 1:
        raise RuntimeError(f"expected one abr_ctrl.sv source entry in {filelist}")
    updated_filelist = fl_text.replace(old_entry, str(overlay.resolve()), 1).encode()
    filelist.write_bytes(updated_filelist)
    manifest = {
        "source": str(source), "source_sha256": sha256(original),
        "instrumented_overlay": str(overlay), "overlay_sha256": sha256(patched),
        "filelist": str(filelist), "filelist_sha256_before": sha256(original_filelist),
        "filelist_sha256_after": sha256(updated_filelist), "replaced_source_entries": 1,
        "scope": "diagnostic observation only; no RTL logic, firmware, stimulus, expected values, or pass criteria changed",
    }
    (output / "m20-internal-trace-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def patch_sampler(source: Path, filelist: Path, output: Path) -> dict:
    original = source.read_bytes()
    text = original.decode()
    marker = "M20_SAMPLER_TRACE"
    if marker in text or text.count("endmodule") != 1:
        raise RuntimeError("unexpected abr_sampler_top.sv shape or duplicate trace")
    block = '''  // M20_SAMPLER_TRACE: boundary observation only; no sampler logic changed.
  integer m20_sampler_trace_cycle;
  initial m20_sampler_trace_cycle = 0;
  always @(posedge clk) begin
    m20_sampler_trace_cycle = m20_sampler_trace_cycle + 1;
    $display("M20_SAMPLER_TRACE cycle=%0d mode=%0d sha3_start=%b msg_start=%b msg_valid=%b msg_rdy=%b msg_strobe=%h msg_data0=%h sampler_start=%b busy=%b sampler_ps=%0d sha3_process=%b sha3_run=%b sha3_fsm=%0d sha3_squeezing=%b sha3_dv=%b state_dv_o=%b state_any=%b state0=%08h",
      m20_sampler_trace_cycle, sampler_mode_i, sha3_start_i, msg_start_i, msg_valid_i, msg_rdy_o,
      msg_strobe_i, msg_data_i[0][31:0], sampler_start_i, sampler_busy_o, sampler_fsm_ps,
      sha3_process, sha3_run, sha3_fsm, sha3_squeezing, sha3_state_dv, sampler_state_dv_o,
      |sha3_state[0], sha3_state[0][31:0]);
  end
'''
    patched = text.replace("endmodule", block + "endmodule", 1).encode()
    overlay = output / "overlays/m20-internal-trace/abr_sampler_top.sv"
    overlay.parent.mkdir(parents=True, exist_ok=True)
    overlay.write_bytes(patched)

    old_entry = "${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl/abr_sampler_top.sv"
    original_filelist = filelist.read_bytes()
    fl_text = original_filelist.decode()
    if fl_text.count(old_entry) != 1:
        raise RuntimeError(f"expected one abr_sampler_top.sv source entry in {filelist}")
    updated_filelist = fl_text.replace(old_entry, str(overlay.resolve()), 1).encode()
    filelist.write_bytes(updated_filelist)
    manifest = {
        "source": str(source), "source_sha256": sha256(original),
        "instrumented_overlay": str(overlay), "overlay_sha256": sha256(patched),
        "filelist": str(filelist), "filelist_sha256_before": sha256(original_filelist),
        "filelist_sha256_after": sha256(updated_filelist), "replaced_source_entries": 1,
        "scope": "sampler/SHA3 boundary observation only; no RTL logic or test behavior changed",
    }
    (output / "m20-sampler-trace-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def self_check() -> None:
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        source = root / "abr_ctrl.sv"
        sampler = root / "abr_sampler_top.sv"
        filelist = root / "test.vf"
        output = root / "out"
        source.write_text("module abr_ctrl;\nendmodule\n")
        sampler.write_text("module abr_sampler_top;\nendmodule\n")
        filelist.write_text(
            "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_ctrl.sv\n"
            "${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl/abr_sampler_top.sv\n"
        )
        manifest = patch_control(source, filelist, output)
        sampler_manifest = patch_sampler(sampler, filelist, output)
        assert manifest["replaced_source_entries"] == sampler_manifest["replaced_source_entries"] == 1
        entries = filelist.read_text().splitlines()
        traced_control = Path(entries[0]).read_text()
        traced_sampler = Path(entries[1]).read_text()
        assert "M20_VERIFY_TRACE" in traced_control and "cycle=%0d" in traced_control
        assert '$display("M20_VERIFY_TRACE PRE' in traced_control
        assert '$strobe("M20_VERIFY_TRACE POST' in traced_control
        assert "M20_SAMPLER_TRACE" in traced_sampler and "cycle=%0d" in traced_sampler
        assert '$display("M20_SAMPLER_TRACE' in traced_sampler
        assert "endmodule" in traced_control and "endmodule" in traced_sampler


def main() -> int:
    if sys.argv[1:] == ["--self-check"]:
        self_check()
        print("internal trace overlay self-check passed")
        return 0

    runner = Path(os.environ["M20_BASE_RUNNER"]).resolve()
    caliptra = Path(os.environ["CALIPTRA_ROOT"]).resolve()
    control = caliptra / "submodules/adams-bridge/src/abr_top/rtl/abr_ctrl.sv"
    sampler = caliptra / "submodules/adams-bridge/src/abr_sampler_top/rtl/abr_sampler_top.sv"
    namespace = {"__name__": "m20_base_runner", "__file__": str(runner), "__package__": None}
    exec(compile(runner.read_bytes(), str(runner), "exec"), namespace)
    original_run_logged = namespace["run_logged"]
    installed = False

    def traced_run_logged(command, cwd, env, log, timeout):
        nonlocal installed
        if command and Path(command[0]).name == "iverilog" and not installed:
            filelist = Path(command[command.index("-f") + 1])
            manifest = {
                "abr_ctrl": patch_control(control, filelist, log.parent),
                "abr_sampler_top": patch_sampler(sampler, filelist, log.parent),
            }
            installed = True
            print("M20 sampler-boundary trace installed: " + json.dumps(manifest, sort_keys=True))
        return original_run_logged(command, cwd, env, log, timeout)

    namespace["run_logged"] = traced_run_logged
    sys.argv = [str(runner), *sys.argv[1:]]
    result = namespace["main"]()
    if not installed:
        raise RuntimeError("runner completed without intercepting an Icarus compile")
    return result


if __name__ == "__main__":
    raise SystemExit(main())
