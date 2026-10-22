#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


RUNNER_SHA256 = "cde90b92ddc9035474db1b1cf3453a44706ce75442110d1ea7248b205fd53f49"

source, output = map(Path, sys.argv[1:])
source_bytes = source.read_bytes()
if hashlib.sha256(source_bytes).hexdigest() != RUNNER_SHA256:
    raise SystemExit("pinned top-case runner hash mismatch")
text = source_bytes.decode()

import_before = "from pathlib import Path\n"
import_after = import_before + "from normalize_lms_dccm import normalize_dccm_text\n"
if text.count(import_before) != 1:
    raise SystemExit("expected one top-case runner import anchor")
text = text.replace(import_before, import_after, 1)

stage_before = """            result["native_vector_sha256"] = runner.stage_native_vectors(
                test_output, vector_files, vector_hashes, vector_tools, env
            )
            sim_command = [str(model), "+CLP_REGRESSION", *plusargs]"""
stage_after = """            result["native_vector_sha256"] = runner.stage_native_vectors(
                test_output, vector_files, vector_hashes, vector_tools, env
            )
            dccm_overlay_plusargs = []
            if args.case.startswith("fw_test_lms"):
                dccm_path = test_output / "dccm.hex"
                normalized_path = test_output / "dccm.normalized.hex"
                normalized_text, address_map = normalize_dccm_text(dccm_path.read_text())
                runner.readmemh_image(normalized_text)
                normalized_path.write_text(normalized_text)
                result["dccm_load_overlay"] = {
                    "original_sha256": runner.sha256(dccm_path),
                    "normalized_sha256": runner.sha256(normalized_path),
                    "address_map": [[f"0x{address:x}", f"0x{offset:x}"]
                                    for address, offset in address_map],
                }
                dccm_overlay_plusargs = ["+M12_DCCM_IMAGE=dccm.normalized.hex"]
                shutil.copy2(normalized_path, output / "dccm.normalized.hex")
            sim_command = [str(model), "+CLP_REGRESSION", *plusargs, *dccm_overlay_plusargs]"""
if text.count(stage_before) != 1:
    raise SystemExit("expected one firmware-to-simulation runner anchor")
text = text.replace(stage_before, stage_after, 1)

if text.count("normalize_dccm_text(dccm_path.read_text())") != 1:
    raise SystemExit("LMS DCCM normalizer self-check failed")
if text.count("+M12_DCCM_IMAGE=dccm.normalized.hex") != 1:
    raise SystemExit("LMS DCCM plusarg self-check failed")
if text.count("shutil.copy2(normalized_path, output / \"dccm.normalized.hex\")") != 1:
    raise SystemExit("normalized DCCM evidence copy self-check failed")

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(text)
print(f"base_runner_sha256={RUNNER_SHA256}")
print(f"lms_runner_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
print("change=normalize and retain only LMS DCCM load file; record both hashes and pass a testbench plusarg")
