#!/usr/bin/env python3
"""Guard unsupported firmware-image sequence execution in an Icarus probe copy."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


SOURCES = {
    "sequences/mbox/soc_ifc/soc_ifc_env_mbox_real_fw_sequence.svh": (
        "479544e6fc941b54865fb0dd21ec1e3b7b2fe2782c96c6e080af85c771a3378d",
        {
            '$readmemh("caliptra_fmc.hex", fw_img);': "FMC",
            '$readmemh("caliptra_rt.hex", fw_img);': "RT",
        },
    ),
    "sequences/mbox/soc_ifc/soc_ifc_env_mbox_rom_fw_sequence.svh": (
        "cf9b4bb5ef6c222b18fd489c5f4a6d860e9dcd26340e63533f49798ddb017c3d",
        {'$readmemh("fw_update.hex", fw_img);': "ROM"},
    ),
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    repo_root = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--caliptra-root", required=True, type=Path)
    parser.add_argument("--environment-overlay", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()

    caliptra = args.caliptra_root.resolve()
    source_root = (
        caliptra
        / "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/environment_packages/soc_ifc_env_pkg"
    ).resolve()
    overlay_root = args.environment_overlay.resolve()
    if overlay_root == source_root or source_root in overlay_root.parents:
        raise SystemExit("environment overlay must not be inside pinned Caliptra sources")

    records = []
    for relative, (expected_source_sha, anchors) in SOURCES.items():
        source = source_root / relative
        source_bytes = source.read_bytes()
        actual_source_sha = sha256(source_bytes)
        if actual_source_sha != expected_source_sha:
            raise SystemExit(
                f"Refusing unreviewed generated source {relative}: {actual_source_sha}"
            )

        destination = overlay_root / relative
        made_overlay_copy = not destination.exists()
        if made_overlay_copy:
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(source_bytes)
        text = destination.read_text()
        overlay_input_sha = sha256(text.encode())
        for anchor, sequence_name in anchors.items():
            if text.count(anchor) != 1:
                raise SystemExit(
                    f"{relative}: expected exactly one {sequence_name} firmware loader"
                )
            text = text.replace(
                anchor,
                f'$fatal(1, "Icarus runtime probe excludes {sequence_name} firmware image loading");',
                1,
            )
        destination.write_text(text)
        records.append(
            {
                "source": str(source),
                "source_sha256": actual_source_sha,
                "overlay_input_sha256": overlay_input_sha,
                "overlay": str(destination),
                "copied_from_pinned_source": made_overlay_copy,
                "overlay_sha256": sha256(text.encode()),
                "guarded_sequences": list(anchors.values()),
            }
        )

    manifest = args.manifest.resolve()
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(
        json.dumps(
            {
                "purpose": "Compile a generated-environment AAXI smoke without claiming firmware-update support.",
                "excluded_behavior": "FMC, RT, and ROM firmware image loading; invoking one terminates with $fatal.",
                "source_checkout_modified": False,
                "sources": records,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )
    print("PASS: guarded unsupported generated firmware-image loaders in disposable runtime copies")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
