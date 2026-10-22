#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path

rtl, checker_overlay = map(Path, sys.argv[1:])
source = rtl / "src/integration/asserts/caliptra_top_sva.sv"
source_sha = hashlib.sha256(source.read_bytes()).hexdigest()
if source_sha != "6bd2ade137a90c0701aab28951ba6f8918724e0467c21756b0c308e6e9081c89":
    raise SystemExit(f"pinned Caliptra checker source hash mismatch: {source_sha}")

before = (
    b"DOE_clear_obf_status_valid: assert property (\n"
    b"                                            @(posedge `SVA_RDC_CLK)\n"
    b"                                            disable iff (~`DOE_PATH.rst_b)"
)
after = (
    b"DOE_clear_obf_status_valid: assert property (\n"
    b"                                            @(posedge `SVA_RDC_CLK)\n"
    b"                                            disable iff (~`DOE_PATH.rst_b || ~`CPTRA_TOP_PATH.cptra_rst_b)"
)
overlay_bytes = checker_overlay.read_bytes()
if overlay_bytes.count(before) != 1:
    raise SystemExit("expected one DOE clear-status property with the pinned DOE reset guard")

patched = overlay_bytes.replace(before, after, 1)
if (patched.count(before) != 0 or patched.count(after) != 1
        or patched.count(b"SVA ERROR: DOE STATUS valid bit not set after clear obf secrets cmd") != 1):
    raise SystemExit("DOE status reset guard self-check failed")

checker_overlay.write_bytes(patched)
print(f"checker_source_sha256={source_sha}")
print(f"checker_overlay_sha256={hashlib.sha256(patched).hexdigest()}")
print("doe_property_disable_iff=DOE reset or top-level Caliptra reset")
