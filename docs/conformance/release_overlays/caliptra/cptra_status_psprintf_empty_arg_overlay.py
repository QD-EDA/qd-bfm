#!/usr/bin/env python3
"""Copy the pinned cptra_status package with three invalid empty $psprintf arguments removed."""

import argparse
import hashlib
from pathlib import Path


FILES = (
    (
        "src/cptra_status_configuration.svh",
        "f0a0f16c52be3b799afa0b5252e833420d3a64a8ebeba759b40541afdda8bd2b",
        b"interface_name, ),",
        b"interface_name),",
        "8cf93c07590f8984ba312e05cb817e574a689b78cc14dd537bb69bd7066f50f4",
    ),
    (
        "src/cptra_status_driver_bfm.sv",
        "70c47e2737dacda24a56c99076be75f919b9d75d95a2174710c39007d6f16311",
        b'parameters: ", ),',
        b'parameters: "),',
        "25979b890c6f488077961593006545ce668fc3ce46994e994ff8c28b9c1b0600",
    ),
    (
        "src/cptra_status_monitor_bfm.sv",
        "be1b334b043906de3f8b5747ca83cda470498b7aba85397330db9987f59d240a",
        b'parameters: ", ),',
        b'parameters: "),',
        "54e50da3b305106085844dab33eb1a114e077595e030df57fa0495a98d98484a",
    ),
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def prepare(source_root: Path, output_root: Path) -> None:
    source_root = source_root.resolve()
    output_root = output_root.resolve()
    if output_root == source_root or source_root in output_root.parents:
        raise ValueError("overlay output must be outside the pinned package")
    if output_root.exists():
        raise ValueError(f"overlay output already exists: {output_root}")

    prepared = []
    for relative, source_hash, old, new, overlay_hash in FILES:
        source = source_root / relative
        original = source.read_bytes()
        if sha256(original) != source_hash or original.count(old) != 1:
            raise ValueError(f"unexpected pinned source: {source}")
        patched = original.replace(old, new, 1)
        if sha256(patched) != overlay_hash:
            raise ValueError(f"unexpected overlay output: {relative}")
        prepared.append((relative, patched, source_hash, overlay_hash))

    for relative, patched, source_hash, overlay_hash in prepared:
        output = output_root / relative
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(patched)
        print(f"{relative}: {source_hash} -> {overlay_hash}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_root", type=Path, help="pinned cptra_status_pkg directory")
    parser.add_argument("output_root", type=Path, help="new disposable overlay directory")
    args = parser.parse_args()
    prepare(args.source_root, args.output_root)
