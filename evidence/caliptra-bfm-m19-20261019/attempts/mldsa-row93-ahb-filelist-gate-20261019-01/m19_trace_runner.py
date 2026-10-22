#!/usr/bin/env python3
"""Apply an evidence-only signal trace immediately before compiling one M19 row."""

import hashlib
import json
import os
import sys
from pathlib import Path


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_sources(output: Path, mode: str, target: str) -> None:
    filelist_record = None
    if mode == "queue":
        matches = [p for p in output.rglob(target) if p.is_file()]
        anchor = "  // Scoreboard"
        marker = "M19_QTRACE"
        block = '''  // M19-only observation of valid outputs against the zeroize/queue flush.
  always @(posedge clk_tb) begin
    if (data_valid_o || zeroize) begin
      $display("M19_QTRACE PRE t=%0t valid=%b zeroize=%b count=%0d queue=%0d",
               $time, data_valid_o, zeroize, vld_coeff_ctr, expected_results.size());
      $strobe("M19_QTRACE POST t=%0t valid=%b zeroize=%b count=%0d queue=%0d",
              $time, data_valid_o, zeroize, vld_coeff_ctr, expected_results.size());
    end
  end

'''
        required = ("data_valid_o", "zeroize", "vld_coeff_ctr", "expected_results")
        selected = []
        for path in matches:
            original = path.read_bytes()
            text = original.decode()
            if marker in text:
                selected.append((path, original, original))
                continue
            if any(name not in text for name in required) or text.count(anchor) != 1:
                continue
            patched = text.replace(anchor, block + anchor, 1).encode()
            path.write_bytes(patched)
            selected.append((path, original, patched))
        if not selected:
            raise RuntimeError(f"no {target} in {output} matched the queue-trace anchors")
    elif mode == "ahb":
        candidates = [p for p in output.rglob(target) if p.is_file()]
        prefix = "uvm_test_top_environment_qvip_ahb_lite_slave_subenv_qvip_hdl.ahb_lite_slave_0_"
        required = (prefix + "HADDR", prefix + "HRDATA", prefix + "HREADY")
        matches = []
        for path in candidates:
            original = path.read_bytes()
            text = original.decode()
            if all(name in text for name in required):
                matches.append((path, original, text))
        if len(matches) != 1:
            raise RuntimeError(f"expected one AHB hdl_top in {output}, found {len(matches)}")
        path, original, text = matches[0]
        marker = "M19_AHB_PIN"
        if marker in text:
            selected = [(path, original, original)]
        else:
            if text.count("endmodule") != 1:
                raise RuntimeError(f"expected one endmodule in {path}")
            block = f'''  always @(posedge clk) begin
    $display("M19_AHB_PIN PRE t=%0t sel=%b trans=%h addr=%h write=%b readyin=%b readyout=%b hrdata=%h",
      $time, {prefix}HSEL, {prefix}HTRANS, {prefix}HADDR, {prefix}HWRITE,
      {prefix}HREADYOUT, {prefix}HREADY, {prefix}HRDATA);
    $strobe("M19_AHB_PIN POST t=%0t sel=%b trans=%h addr=%h write=%b readyin=%b readyout=%b hrdata=%h",
      $time, {prefix}HSEL, {prefix}HTRANS, {prefix}HADDR, {prefix}HWRITE,
      {prefix}HREADYOUT, {prefix}HREADY, {prefix}HRDATA);
  end

'''
            patched = text.replace("endmodule", block + "endmodule", 1).encode()
            path.write_bytes(patched)
            selected = [(path, original, patched)]
        filelist = output / "overlays/mldsa-ahb-open-mvc-icarus.vf"
        original_filelist = filelist.read_bytes()
        old_entry = "${ADAMSBRIDGE_ROOT}/src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/testbench/hdl_top.sv"
        runtime_entry = str(path.resolve())
        text = original_filelist.decode()
        if text.count(old_entry) != 1 or runtime_entry in text:
            raise RuntimeError(f"expected exactly one shared hdl_top entry in {filelist}")
        rewritten_filelist = text.replace(old_entry, runtime_entry, 1).encode()
        filelist.write_bytes(rewritten_filelist)
        check = filelist.read_text()
        if check.count(runtime_entry) != 1 or old_entry in check:
            raise RuntimeError(f"filelist did not select the instrumented hdl_top: {filelist}")
        filelist_record = {
            "path": str(filelist),
            "source_sha256": digest(original_filelist),
            "trace_sha256": digest(rewritten_filelist),
            "replaced_entries": 1,
            "runtime_entry": runtime_entry,
        }
    else:
        raise RuntimeError(f"unknown M19 trace mode: {mode}")

    manifest = {
        "mode": mode,
        "target": target,
        "files": [
            {"path": str(path), "source_sha256": digest(before), "trace_sha256": digest(after)}
            for path, before, after in selected
        ],
        "filelist": filelist_record,
        "scope": "testbench observation only; no RTL, firmware, expected values, or pass criteria changed",
    }
    (output / "m19_trace_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def main() -> int:
    runner = Path(os.environ["M19_BASE_RUNNER"]).resolve()
    mode = os.environ["M19_TRACE_KIND"]
    target = os.environ["M19_TRACE_TARGET"]
    namespace = {
        "__name__": "m19_base_runner",
        "__file__": str(runner),
        "__package__": None,
    }
    exec(compile(runner.read_bytes(), str(runner), "exec"), namespace)
    original_run_logged = namespace["run_logged"]

    def traced_run_logged(command, cwd, env, log, timeout):
        if command and Path(command[0]).name == "iverilog":
            patch_sources(log.parent, mode, target)
        return original_run_logged(command, cwd, env, log, timeout)

    namespace["run_logged"] = traced_run_logged
    sys.argv = [str(runner), *sys.argv[1:]]
    return namespace["main"]()


if __name__ == "__main__":
    raise SystemExit(main())
