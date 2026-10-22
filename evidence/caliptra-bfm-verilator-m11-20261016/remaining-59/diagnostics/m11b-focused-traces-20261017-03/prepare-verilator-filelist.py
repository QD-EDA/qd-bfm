#!/usr/bin/env python3
import hashlib
import importlib.util
import sys
from pathlib import Path

TOP_TB_SHA256 = "c212c32da99e90cd3991da65e653998cac3e945d7479abfd640b9d82f47659f9"
TOP_TB_JTAG_OVERLAY_SHA256 = "6b3d6eeb6bbb3acddcc6045b86c9cc6c6ca3934164f29564485a9a3d2fc4d02a"

rtl, repo, output = map(Path, sys.argv[1:])
base = rtl / "src/integration/config/caliptra_top_tb.vf"
original = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_axi_complex.sv"
top_tb_original = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb.sv"
checker_original = "${CALIPTRA_ROOT}/src/integration/asserts/caliptra_top_sva.sv"
lines = base.read_text().splitlines()
if lines.count(original) != 1:
    raise SystemExit(f"expected one upstream AXI complex BFM entry in {base}")
if lines.count(top_tb_original) != 1:
    raise SystemExit(f"expected one upstream top testbench entry in {base}")
if lines.count(checker_original) != 1:
    raise SystemExit(f"expected one upstream Caliptra SVA checker entry in {base}")
lines.remove(original)

axi_assertion_sources = {
    "src/axi/rtl/axi_sub_rd.sv": ("bc1b1f63c5db4fb9d717d9532a27a1967a896290704153615b8ff57e0bbdb5be", 2),
    "src/axi/rtl/axi_sub_wr.sv": ("33cbdd398ffe6a16e5687cd7c60fa4dab96b0ea6a5516790ef61f3404cb2c07f", 3),
}
axi_overlay_paths = {}
for rel_path, (expected_sha, expected_count) in axi_assertion_sources.items():
    source_path = rtl / rel_path
    source_bytes = source_path.read_bytes()
    source_sha = hashlib.sha256(source_bytes).hexdigest()
    if source_sha != expected_sha:
        raise SystemExit(f"Caliptra source hash mismatch for {source_path}: {source_sha}")
    old = b"eventually [0:5] not(rst_n)"
    new = b"##[0:5] !rst_n"
    if source_bytes.count(old) != expected_count:
        raise SystemExit(f"expected {expected_count} bounded eventually assertions in {source_path}")
    overlay_bytes = source_bytes.replace(old, new)
    overlay_path = output.parent.parent / "rtl" / rel_path
    overlay_path.parent.mkdir(parents=True, exist_ok=True)
    overlay_path.write_bytes(overlay_bytes)
    axi_overlay_paths[rel_path] = overlay_path

    upstream_entry = f"${{CALIPTRA_ROOT}}/{rel_path}"
    if lines.count(upstream_entry) != 1:
        raise SystemExit(f"expected one upstream filelist entry: {upstream_entry}")
    lines = [str(overlay_path) if line == upstream_entry else line for line in lines]

replacement = repo / "dv/caliptra_bfm/axi/caliptra_top_tb_axi_complex_bfm.sv"
sources = []
for line in (repo / "dv/caliptra_bfm/caliptra_bfm.f").read_text().splitlines():
    line = line.strip()
    if line and not line.startswith("#"):
        source = repo / line
        if not source.is_file():
            raise SystemExit(f"missing QD-BFM source: {source}")
        sources.append(source)
if not replacement.is_file() or "module caliptra_top_tb_axi_complex" not in replacement.read_text():
    raise SystemExit(f"invalid QD-BFM replacement module: {replacement}")

top_tb_source = rtl / "src/integration/tb/caliptra_top_tb.sv"
top_tb_bytes = top_tb_source.read_bytes()
if hashlib.sha256(top_tb_bytes).hexdigest() != TOP_TB_SHA256:
    raise SystemExit(f"Caliptra top testbench source hash mismatch: {top_tb_source}")
before = b".ListenPort     (63224)"
if top_tb_bytes.count(before) != 1:
    raise SystemExit("expected exactly one JTAG DPI listen port")
top_tb_text = b"`timescale 1ns/1ps\n" + top_tb_bytes.replace(before, b".ListenPort     (0)", 1)
top_tb_overlay = output.parent.parent / "tb/caliptra_top_tb.sv"
top_tb_overlay.parent.mkdir(parents=True, exist_ok=True)
top_tb_overlay.write_bytes(top_tb_text)
if hashlib.sha256(top_tb_text).hexdigest() != TOP_TB_JTAG_OVERLAY_SHA256:
    raise SystemExit("Caliptra top testbench overlay hash mismatch")
lines = [str(top_tb_overlay) if line == top_tb_original else line for line in lines]

runner_path = repo / "dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
spec = importlib.util.spec_from_file_location("caliptra_runner", runner_path)
runner = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = runner
spec.loader.exec_module(runner)
checker_overlay = output.parent.parent / "asserts/caliptra_top_sva.sv"
checker_overlay.parent.mkdir(parents=True, exist_ok=True)
removed = runner.prepare_checker_overlay(rtl, checker_overlay)
if removed != 9:
    raise SystemExit(f"expected nine pinned checker diagnostics removed, got {removed}")
lines = [str(checker_overlay) if line == checker_original else line for line in lines]

overlay = [f"+incdir+{replacement.parent}", *lines, str(replacement), *(str(p) for p in sources)]
if (overlay.count(str(replacement)) != 1 or original in overlay
        or top_tb_original in overlay or overlay.count(str(top_tb_overlay)) != 1
        or checker_original in overlay or overlay.count(str(checker_overlay)) != 1):
    raise SystemExit("filelist self-check failed: duplicate replacement or upstream source remains")
for rel_path, overlay_path in axi_overlay_paths.items():
    if any(line == f"${{CALIPTRA_ROOT}}/{rel_path}" for line in overlay) or overlay.count(str(overlay_path)) != 1:
        raise SystemExit(f"filelist self-check failed for {rel_path}")
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text("\n".join(overlay) + "\n")
print(f"base_sha256={hashlib.sha256(base.read_bytes()).hexdigest()}")
print(f"overlay_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
print(f"top_tb_source_sha256={hashlib.sha256(top_tb_bytes).hexdigest()}")
print(f"top_tb_overlay_sha256={hashlib.sha256(top_tb_text).hexdigest()}")
print(f"checker_overlay_sha256={runner.sha256(checker_overlay)}")
for rel_path, overlay_path in axi_overlay_paths.items():
    print(f"{Path(rel_path).stem}_source_sha256={hashlib.sha256((rtl / rel_path).read_bytes()).hexdigest()}")
    print(f"{Path(rel_path).stem}_overlay_sha256={hashlib.sha256(overlay_path.read_bytes()).hexdigest()}")
print(f"checker_diagnostics_removed={removed}")
print(f"qd_source_count={len(sources) + 1}")
