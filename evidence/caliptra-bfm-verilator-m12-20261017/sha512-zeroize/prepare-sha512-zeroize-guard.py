#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


SOURCE_SHA256 = "5656d5a09d1570a567bb674b1b419775a83a08b37ee70792d28ab72ae0510d82"
OLD = b"`CALIPTRA_ASSERT_STABLE(ERR_SHA_BLOCK_NOT_STABLE, block_reg, clk, (!reset_n || ready_reg) )"
NEW = b"`CALIPTRA_ASSERT_STABLE(ERR_SHA_BLOCK_NOT_STABLE, block_reg, clk, (!reset_n || ready_reg || zeroize_reg || $past(zeroize_reg)) )"

rtl, filelist, overlay_root = map(Path, sys.argv[1:])
source = rtl / "src/sha512/rtl/sha512.sv"
source_bytes = source.read_bytes()
source_sha = hashlib.sha256(source_bytes).hexdigest()
if source_sha != SOURCE_SHA256:
    raise SystemExit(f"pinned SHA512 source hash mismatch: {source_sha}")
if source_bytes.count(OLD) != 1:
    raise SystemExit("expected one pinned SHA block-stability assertion")

overlay_bytes = source_bytes.replace(OLD, NEW, 1)
if overlay_bytes.replace(NEW, OLD, 1) != source_bytes:
    raise SystemExit("SHA512 assertion guard changed bytes outside the assertion")

overlay = overlay_root / "rtl/src/sha512/rtl/sha512.sv"
overlay.parent.mkdir(parents=True, exist_ok=True)
overlay.write_bytes(overlay_bytes)
text = filelist.read_text()
pinned = "${CALIPTRA_ROOT}/src/sha512/rtl/sha512.sv"
if text.count(pinned) != 1:
    raise SystemExit(f"expected one pinned SHA512 filelist entry, found {text.count(pinned)}")
text = text.replace(pinned, str(overlay), 1)
if pinned in text or text.count(str(overlay)) != 1:
    raise SystemExit("SHA512 assertion overlay filelist replacement failed")
filelist.write_text(text)
print(f"sha512_source_sha256={source_sha}")
print(f"sha512_guard_overlay_sha256={hashlib.sha256(overlay_bytes).hexdigest()}")
print(f"filelist_sha256={hashlib.sha256(filelist.read_bytes()).hexdigest()}")
