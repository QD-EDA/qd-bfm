#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path

TOP_TB_SHA256 = "c212c32da99e90cd3991da65e653998cac3e945d7479abfd640b9d82f47659f9"
TOP_TB_JTAG_OVERLAY_SHA256 = "6b3d6eeb6bbb3acddcc6045b86c9cc6c6ca3934164f29564485a9a3d2fc4d02a"

rtl, repo, output = map(Path, sys.argv[1:])
base = rtl / "src/integration/config/caliptra_top_tb.vf"
original = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_axi_complex.sv"
top_tb_original = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb.sv"
lines = base.read_text().splitlines()
if lines.count(original) != 1:
    raise SystemExit(f"expected one upstream AXI complex BFM entry in {base}")
if lines.count(top_tb_original) != 1:
    raise SystemExit(f"expected one upstream top testbench entry in {base}")
lines.remove(original)

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

overlay = [f"+incdir+{replacement.parent}", *lines, str(replacement), *(str(p) for p in sources)]
if (overlay.count(str(replacement)) != 1 or original in overlay
        or top_tb_original in overlay or overlay.count(str(top_tb_overlay)) != 1):
    raise SystemExit("filelist self-check failed: duplicate replacement or upstream source remains")
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text("\n".join(overlay) + "\n")
print(f"base_sha256={hashlib.sha256(base.read_bytes()).hexdigest()}")
print(f"overlay_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
print(f"top_tb_source_sha256={hashlib.sha256(top_tb_bytes).hexdigest()}")
print(f"top_tb_overlay_sha256={hashlib.sha256(top_tb_text).hexdigest()}")
print(f"qd_source_count={len(sources) + 1}")
