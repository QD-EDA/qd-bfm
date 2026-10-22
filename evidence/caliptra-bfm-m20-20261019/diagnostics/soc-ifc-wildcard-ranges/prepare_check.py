#!/usr/bin/env python3
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory

sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "dv/caliptra_bfm/uvmf_lite/tests"))
from run_m15_test import prepare_soc_ifc_wildcard_coverage_overlay

caliptra = Path(os.environ["CALIPTRA_ROOT"])
pin = subprocess.check_output(["git", "-C", str(caliptra), "rev-parse", "HEAD"], text=True).strip()
assert pin == "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e", pin

with TemporaryDirectory(prefix="m20-socifc-wildcard-overlay-") as temp:
    output = Path(temp)
    filelist = output / "source.vf"
    filelist.write_text(
        "${CALIPTRA_ROOT}/src/soc_ifc/rtl/mbox_csr_uvm.sv\n"
        "${CALIPTRA_ROOT}/src/soc_ifc/rtl/soc_ifc_reg_uvm.sv\n"
    )
    overlay_filelist, manifest_path = prepare_soc_ifc_wildcard_coverage_overlay(
        filelist, caliptra, output
    )
    manifest = json.loads(manifest_path.read_text())
    updated = overlay_filelist.read_text()
    assert "${CALIPTRA_ROOT}/src/soc_ifc/rtl/" not in updated
    assert len(manifest["sources"]) == 2
    assert len(manifest["wrappers"]) == 2
    for item in manifest["sources"]:
        overlay = Path(item["overlay"])
        assert hashlib.sha256(overlay.read_bytes()).hexdigest() == item["overlay_sha256"]
        assert "wildcard bins" not in overlay.read_text()
    print(f"Caliptra pin: {pin}")
    print(f"overlay filelist SHA-256: {hashlib.sha256(overlay_filelist.read_bytes()).hexdigest()}")
    print("source and wrapper hashes verified; all targeted wildcard bins replaced")
