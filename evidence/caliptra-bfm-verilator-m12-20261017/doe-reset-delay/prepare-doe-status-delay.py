#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path

rtl, checker_overlay = map(Path, sys.argv[1:])
source = rtl / "src/integration/asserts/caliptra_top_sva.sv"
source_bytes = source.read_bytes()
source_sha = hashlib.sha256(source_bytes).hexdigest()
if source_sha != "6bd2ade137a90c0701aab28951ba6f8918724e0467c21756b0c308e6e9081c89":
    raise SystemExit(f"pinned Caliptra checker source hash mismatch: {source_sha}")

before = (
    b"`CPTRA_TOP_PATH.clear_obf_secrets && `DOE_PATH.rst_b |=> "
    b"(`DOE_REG_PATH.field_storage.DOE_STATUS.VALID.value && "
    b"`DOE_REG_PATH.field_storage.DOE_STATUS.DEOBF_SECRETS_CLEARED.value)"
)
after = (
    b"`CPTRA_TOP_PATH.clear_obf_secrets && `DOE_PATH.rst_b |=> ##1 "
    b"(`DOE_REG_PATH.field_storage.DOE_STATUS.VALID.value && "
    b"`DOE_REG_PATH.field_storage.DOE_STATUS.DEOBF_SECRETS_CLEARED.value)"
)
if source_bytes.count(before) != 1:
    raise SystemExit("expected exactly one pinned DOE reset-corner property")

overlay_bytes = checker_overlay.read_bytes()
if overlay_bytes.count(before) != 1:
    raise SystemExit("expected one DOE property in generated assertion overlay")
patched = overlay_bytes.replace(before, after, 1)
if (patched.count(before) != 0 or patched.count(after) != 1
        or patched.count(b"SVA ERROR: DOE STATUS valid bit not set after clear obf secrets cmd") != 1):
    raise SystemExit("DOE status delay overlay self-check failed")

checker_overlay.write_bytes(patched)
print(f"checker_source_sha256={source_sha}")
print(f"checker_overlay_sha256={hashlib.sha256(patched).hexdigest()}")
print("doe_property_delay=one additional sampled clock after the existing |=>")
