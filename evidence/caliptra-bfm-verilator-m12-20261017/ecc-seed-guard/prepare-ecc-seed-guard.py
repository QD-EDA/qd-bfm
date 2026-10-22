#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


SOURCE_SHA256 = "bfe41f23b8002cc18e22c2f1fe8045fd0fb9c026d966154e3c6e845f9b24989b"
OLD = b"`CALIPTRA_ASSERT_STABLE(ERR_ECC_SEED_NOT_STABLE, seed_reg, clk, (!reset_n || ecc_ready_reg) )"
NEW = b"`CALIPTRA_ASSERT_STABLE(ERR_ECC_SEED_NOT_STABLE, seed_reg, clk, (!reset_n || ecc_ready_reg || hwif_in.ECC_SEED[0].SEED.hwclr || $past(hwif_in.ECC_SEED[0].SEED.hwclr)) )"

rtl, filelist, overlay_root = map(Path, sys.argv[1:])
source = rtl / "src/ecc/rtl/ecc_dsa_ctrl.sv"
source_bytes = source.read_bytes()
source_sha = hashlib.sha256(source_bytes).hexdigest()
if source_sha != SOURCE_SHA256:
    raise SystemExit(f"pinned ECC controller source hash mismatch: {source_sha}")
if source_bytes.count(OLD) != 1:
    raise SystemExit("expected one pinned ECC seed-stability assertion")

overlay_bytes = source_bytes.replace(OLD, NEW, 1)
if overlay_bytes.replace(NEW, OLD, 1) != source_bytes:
    raise SystemExit("ECC assertion guard changed bytes outside the assertion")

overlay = overlay_root / "rtl/src/ecc/rtl/ecc_dsa_ctrl.sv"
overlay.parent.mkdir(parents=True, exist_ok=True)
overlay.write_bytes(overlay_bytes)
text = filelist.read_text()
pinned = "${CALIPTRA_ROOT}/src/ecc/rtl/ecc_dsa_ctrl.sv"
if text.count(pinned) != 1:
    raise SystemExit(f"expected one pinned ECC controller filelist entry, found {text.count(pinned)}")
text = text.replace(pinned, str(overlay), 1)
if pinned in text or text.count(str(overlay)) != 1:
    raise SystemExit("ECC assertion overlay filelist replacement failed")
filelist.write_text(text)
print(f"ecc_source_sha256={source_sha}")
print(f"ecc_guard_overlay_sha256={hashlib.sha256(overlay_bytes).hexdigest()}")
print(f"filelist_sha256={hashlib.sha256(filelist.read_bytes()).hexdigest()}")
