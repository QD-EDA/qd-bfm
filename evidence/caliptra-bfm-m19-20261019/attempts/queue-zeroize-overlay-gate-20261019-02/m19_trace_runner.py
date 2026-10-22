#!/usr/bin/env python3
"""Apply an evidence-only signal trace immediately before compiling one M19 row."""

import hashlib
import json
import os
import re
import runpy
import sys
from pathlib import Path


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_sources(output: Path, mode: str, target: str, filelists: list[Path], env: dict[str, str]) -> tuple[Path, Path] | None:
    if mode == "queue":
        matches = [p for p in output.rglob(target) if p.is_file()]
        anchor = "  // Scoreboard"
        marker = "M19_QTRACE"
        block = '''  // M19-only observation of valid outputs against the zeroize/queue flush.
  integer m19_trace_queue_size;
  always @(posedge clk_tb) begin
    if (data_valid_o || zeroize) begin
      $display("M19_QTRACE PRE t=%0t valid=%b zeroize=%b count=%0d queue=%0d",
               $time, data_valid_o, zeroize, vld_coeff_ctr, expected_results.size());
      #0;
      m19_trace_queue_size = expected_results.size();
      $strobe("M19_QTRACE POST t=%0t valid=%b zeroize=%b count=%0d queue=%0d",
              $time, data_valid_o, zeroize, vld_coeff_ctr, m19_trace_queue_size);
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
            block = f'''  integer m19_trace_left = 0;
  always @(posedge clk) begin
    if ({prefix}HSEL === 1'b1 && {prefix}HTRANS[1] === 1'b1 &&
        {prefix}HWRITE === 1'b0 && {prefix}HADDR[17:0] >= 18'h000d8 &&
        {prefix}HADDR[17:0] <= 18'h00114) m19_trace_left = 6;
    if (m19_trace_left > 0) begin
      $display("M19_AHB_PIN PRE t=%0t sel=%b trans=%h addr=%h write=%b readyin=%b readyout=%b hrdata=%h",
        $time, {prefix}HSEL, {prefix}HTRANS, {prefix}HADDR, {prefix}HWRITE,
        {prefix}HREADYOUT, {prefix}HREADY, {prefix}HRDATA);
      $strobe("M19_AHB_PIN POST t=%0t sel=%b trans=%h addr=%h write=%b readyin=%b readyout=%b hrdata=%h",
        $time, {prefix}HSEL, {prefix}HTRANS, {prefix}HADDR, {prefix}HWRITE,
        {prefix}HREADYOUT, {prefix}HREADY, {prefix}HRDATA);
      m19_trace_left = m19_trace_left - 1;
    end
  end

'''
            patched = text.replace("endmodule", block + "endmodule", 1).encode()
            path.write_bytes(patched)
            selected = [(path, original, patched)]
    else:
        raise RuntimeError(f"unknown M19 trace mode: {mode}")

    filelist_record = None
    filelist_override = None
    for filelist in filelists:
        if not filelist.is_file():
            continue
        source_text = filelist.read_text()
        entries = [line for line in source_text.splitlines() if target in line and not line.lstrip().startswith(("#", "//", "+incdir+"))]
        if not entries:
            continue
        if len(entries) != 1:
            raise RuntimeError(f"expected one {target} source entry in {filelist}, found {len(entries)}")
        entry = entries[0]
        if str(output) in entry:
            filelist_record = {"source": str(filelist), "source_sha256": digest(filelist.read_bytes()), "overlay": None}
            break
        source_path_text = re.sub(r"\$\{([^}]+)\}", lambda m: env.get(m.group(1), m.group(0)), entry.strip())
        source_path = Path(source_path_text)
        candidate = next(((path, before, after) for path, before, after in selected if path.name == target), None)
        if candidate is None or not source_path.is_file() or digest(source_path.read_bytes()) != digest(candidate[1]):
            raise RuntimeError(f"cannot hash-guard the {target} filelist source in {filelist}")
        trace_file = output / "overlays" / "m19_trace" / target
        trace_file.parent.mkdir(parents=True, exist_ok=True)
        trace_file.write_bytes(candidate[2])
        overlay_filelist = trace_file.parent / "m19_trace.vf"
        if source_text.count(entry) != 1:
            raise RuntimeError(f"expected one exact {target} filelist line in {filelist}")
        overlay_text = source_text.replace(entry, str(trace_file))
        overlay_filelist.write_text(overlay_text)
        filelist_record = {
            "source": str(filelist), "source_sha256": digest(filelist.read_bytes()),
            "overlay": str(overlay_filelist), "overlay_sha256": digest(overlay_filelist.read_bytes()),
            "source_entry": entry.strip(), "overlay_source": str(trace_file),
            "overlay_source_sha256": digest(trace_file.read_bytes()),
        }
        filelist_override = (filelist, overlay_filelist)
        break
    if filelist_record is None:
        raise RuntimeError(f"no compile filelist references {target}")

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
    return filelist_override


def main() -> int:
    runner = Path(os.environ["M19_BASE_RUNNER"]).resolve()
    mode = os.environ["M19_TRACE_KIND"]
    target = os.environ["M19_TRACE_TARGET"]
    namespace = runpy.run_path(str(runner))
    original_run_logged = namespace["run_logged"]

    def traced_run_logged(command, cwd, env, log, timeout):
        if command and Path(command[0]).name == "iverilog":
            filelists = [Path(command[i + 1]) for i, token in enumerate(command[:-1]) if token == "-f"]
            override = patch_sources(log.parent, mode, target, filelists, env)
            if override:
                source_filelist, overlay_filelist = override
                command = list(command)
                for i, token in enumerate(command[:-1]):
                    if token == "-f" and Path(command[i + 1]) == source_filelist:
                        command[i + 1] = str(overlay_filelist)
                        break
        return original_run_logged(command, cwd, env, log, timeout)

    namespace["main"].__globals__["run_logged"] = traced_run_logged
    sys.argv = [str(runner), *sys.argv[1:]]
    return namespace["main"]()


if __name__ == "__main__":
    raise SystemExit(main())
