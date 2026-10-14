#!/usr/bin/env python3
"""Suppress the reset-only HMAC output sample in Icarus runtime probes."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


SOURCE_RELATIVE = Path(
    "src/hmac/uvmf_2022/uvmf_template_output/verification_ip/"
    "interface_packages/HMAC_out_pkg/src/HMAC_out_monitor_bfm.sv"
)
SOURCE_SHA256 = "ec42c64cbb690a8e7fcc63508d03886c301cc73e56c0c974a78fa2a40bbdbb50"
RESET_NOTIFY = """      HMAC_out_monitor_struct.result = 0;
    end
    else begin"""
RESET_ONLY_SKIP = """    end
    begin"""


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
        / "evidence/caliptra-bfm-generated-hmac-runtime-20261005/hmac_generated_full.f",
    )
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()

    source_path = (args.caliptra_root / SOURCE_RELATIVE).resolve()
    output_dir = args.output_dir.resolve()
    if output_dir == args.caliptra_root.resolve() or args.caliptra_root.resolve() in output_dir.parents:
        raise SystemExit("overlay output must remain outside the pinned Caliptra sources")

    original = source_path.read_bytes()
    actual_sha = sha256(original)
    if actual_sha != SOURCE_SHA256:
        raise SystemExit(f"Refusing unreviewed HMAC monitor source: {actual_sha}")
    text = original.decode()
    if text.count(RESET_NOTIFY) != 1:
        raise SystemExit("HMAC monitor reset branch differs from the reviewed source")
    transformed = text.replace(RESET_NOTIFY, RESET_ONLY_SKIP, 1).encode()

    filelist_text = args.filelist.read_text()
    if filelist_text.count(str(source_path)) != 1:
        raise SystemExit("HMAC filelist must contain the monitor source exactly once")

    output_dir.mkdir(parents=True, exist_ok=True)
    overlay_source = output_dir / "HMAC_out_monitor_bfm.sv"
    overlay_filelist = output_dir / "hmac_generated_overlay.f"
    overlay_source.write_bytes(transformed)
    overlay_filelist.write_text(
        filelist_text.replace(str(source_path), str(overlay_source), 1)
    )

    record = {
        "purpose": "Avoid a reset-only HMAC output record shifting the generated monitor scoreboard stream.",
        "change": "After reset, wait for the transaction flag and capture one output record; do not publish a reset-only record.",
        "source": str(source_path),
        "source_sha256": actual_sha,
        "overlay_source": str(overlay_source),
        "overlay_sha256": sha256(transformed),
        "filelist": str(args.filelist.resolve()),
        "overlay_filelist": str(overlay_filelist),
    }
    if args.manifest:
        manifest_path = args.manifest.resolve()
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
    print(json.dumps(record, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
