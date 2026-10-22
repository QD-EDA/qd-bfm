#!/usr/bin/env python3
import hashlib
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "dv/caliptra_bfm/uvmf_lite/tests")
from run_m15_test import prepare_m16_mldsa_icarus_overlays

root, output = map(Path, sys.argv[1:3])
pin = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
assert pin == "b77e3d899e828d626cfc2a0d26a6b5704cc121e0", pin
filelist = root / "src/abr_top/uvmf/config/uvmf_mldsa.vf"
overlay_filelist, manifest_path = prepare_m16_mldsa_icarus_overlays(filelist, root, output)
manifest = json.loads(manifest_path.read_text())
expected = {
    "ML_DSA_randomized_verif_sequence.svh": ("cf63ffac725c0cc5f48a85d3ee68dadea3738aff48df97b4c12fae6e9e111c14", ("3'd1",)),
    "ML_DSA_randomized_two_verif_on_fail_sequence.svh": ("4f91d054d849c2aec83af1090eec603e631caace4c002d16009df53cb1757b75", ("3'd1", "3'd2")),
}
for name, (source_hash, commands) in expected.items():
    item = next(entry for entry in manifest["files"] if entry["source"].endswith(name))
    source = Path(item["source"])
    overlay = Path(item["overlay"])
    text = overlay.read_text()
    assert item["source_sha256"] == source_hash
    assert hashlib.sha256(overlay.read_bytes()).hexdigest() == item["overlay_sha256"]
    for command in commands:
        assert f'"%02X\\n", {command}' in text
    assert not any(f'"%02X\\n", {value});' in text for value in (1, 2))
    print(f"{name}: source={source_hash} overlay={item['overlay_sha256']} commands={commands}")
assert str(output / "overlays/mldsa_icarus/mldsa_sequences") in overlay_filelist.read_text()
print(f"Adams Bridge pin: {pin}")
print(f"overlay filelist SHA-256: {hashlib.sha256(overlay_filelist.read_bytes()).hexdigest()}")
print("predictor and driving-sequence overlays prepared and verified")
