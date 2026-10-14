#!/usr/bin/env python3
"""Exclude the generated dynamic-factory command-line test from Icarus probes."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


SOURCES = {
    "sequences/soc_ifc_sequences_pkg.sv": (
        "837d3e1e73d13f644fb31eeccc6be883602b5db7d58f32f5afcd0189f5a110d0",
        '  `include "src/soc_ifc_cmdline_test_sequence.svh"',
    ),
    "tests/soc_ifc_tests_pkg.sv": (
        "df467377efe37cf3ce39e5319d8f51cab8bfb21dbcacd9b7c299b077de2a1fe4",
        '   `include "src/soc_ifc_cmdline_test.svh"',
    ),
}
REPLACEMENT = (
    "  // Icarus probe omits the command-line test requiring the unavailable "
    "dynamic factory API."
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    repo_root = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root", type=Path, default=repo_root.parent / "caliptra-rtl"
    )
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()

    caliptra_root = args.caliptra_root.resolve()
    source_root = (
        caliptra_root
        / "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/project_benches/soc_ifc/tb"
    )
    output_root = args.output.resolve()
    if output_root == source_root.resolve() or source_root.resolve() in output_root.parents:
        raise SystemExit("overlay output must remain outside the pinned Caliptra sources")

    records = []
    for relative, (expected_sha, anchor) in SOURCES.items():
        source_path = source_root / relative
        original = source_path.read_bytes()
        actual_sha = sha256(original)
        if actual_sha != expected_sha:
            raise SystemExit(f"Refusing unreviewed generated source {relative}: {actual_sha}")
        text = original.decode()
        if text.count(anchor) != 1:
            raise SystemExit(f"{relative}: expected exactly one command-line include anchor")
        replacement = REPLACEMENT if relative.startswith("sequences/") else REPLACEMENT.replace("  //", "   //")
        transformed = text.replace(anchor, replacement, 1).encode()
        destination = output_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(transformed)
        records.append(
            {
                "source": str(source_path),
                "source_sha256": actual_sha,
                "overlay": str(destination),
                "overlay_sha256": sha256(transformed),
            }
        )

    if args.manifest:
        args.manifest.parent.mkdir(parents=True, exist_ok=True)
        args.manifest.write_text(
            json.dumps(
                {
                    "purpose": "Compile generated SoC-IFC project-bench packages with Icarus.",
                    "excluded_feature": "soc_ifc_cmdline_test and its dynamic factory sequence",
                    "reason": "The generated sequence uses factory.create_object_by_name, unavailable in this UVM implementation.",
                    "sources": records,
                },
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
