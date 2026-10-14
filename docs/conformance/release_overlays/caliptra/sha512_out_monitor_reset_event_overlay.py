#!/usr/bin/env python3
"""Apply the reviewed SHA-512 reset-event monitor overlay to a temporary copy."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path


SOURCE_RELATIVE = Path(
    "src/sha512/uvmf_sha512/uvmf_template_output/verification_ip/"
    "interface_packages/SHA512_out_pkg/src/SHA512_out_monitor_bfm.sv"
)
SOURCE_SHA256 = "3eb250732e4553aecf0e6e5515884c9394a88f3b2259c9a3d3b741275f9731ff"
RESET_NOTIFY = (
    b"      SHA512_out_monitor_struct.result = 0;\n"
    b"    end\n"
    b"    else begin"
)
RESET_ONLY_SKIP = b"    end\n    begin"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    repo_root = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root", type=Path, default=repo_root.parent / "caliptra-rtl"
    )
    parser.add_argument(
        "--filelist",
        type=Path,
        default=repo_root
        / "evidence/caliptra-bfm-generated-sha512-runtime-20261005/sha512_generated_full.f",
    )
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()

    caliptra_root = args.caliptra_root.resolve()
    source = (caliptra_root / SOURCE_RELATIVE).resolve()
    original = source.read_bytes()
    source_hash = sha256(original)
    if source_hash != SOURCE_SHA256:
        raise SystemExit(f"Refusing unreviewed SHA512 monitor source: {source_hash}")
    if original.count(RESET_NOTIFY) != 1:
        raise SystemExit("SHA512 monitor reset branch differs from the reviewed source")

    filelist = args.filelist.resolve()
    source_ref = Path(os.path.relpath(source, repo_root)).as_posix()
    filelist_text = filelist.read_text()
    if filelist_text.count(source_ref) != 1:
        raise SystemExit("SHA512 filelist must contain the monitor source exactly once")

    output_dir = args.output_dir.resolve()
    if output_dir == caliptra_root or caliptra_root in output_dir.parents:
        raise SystemExit("overlay output must remain outside the pinned Caliptra sources")
    output_dir.mkdir(parents=True, exist_ok=True)

    overlay = original.replace(RESET_NOTIFY, RESET_ONLY_SKIP, 1)
    overlay_source = output_dir / "SHA512_out_monitor_bfm.sv"
    overlay_filelist = output_dir / "sha512_generated_overlay.f"
    overlay_source.write_bytes(overlay)
    overlay_filelist.write_text(
        filelist_text.replace(source_ref, str(overlay_source), 1)
    )

    record = {
        "purpose": "Remove a reset-only SHA512 output record that shifts the expected/actual stream.",
        "change": "Wait through reset, then capture one output when read_flag_monitor is asserted.",
        "source": str(source),
        "source_sha256": source_hash,
        "overlay_source_sha256": sha256(overlay),
        "overlay_filelist_sha256": sha256(overlay_filelist.read_bytes()),
        "overlay_source_retained": False,
        "source_checkout_modified": False,
        "filelist": str(filelist),
        "filelist_sha256": sha256(filelist.read_bytes()),
    }
    if args.manifest:
        manifest = args.manifest.resolve()
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
    print(json.dumps(record, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
