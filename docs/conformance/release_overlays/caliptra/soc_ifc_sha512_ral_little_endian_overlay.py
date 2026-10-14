#!/usr/bin/env python3
"""Give the SoC-IFC SHA512 RAL leaf maps their actual little-endian bus order."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


SOURCE = "src/soc_ifc/rtl/sha512_acc_csr_uvm.sv"
SOURCE_SHA256 = "50b08a6020386bc0858ce4c2ab31837a480fd6e3b072915f23d22d8eb5401e5f"
ANCHOR = 'create_map("reg_map", 0, 4, UVM_NO_ENDIAN)'
REPLACEMENT = 'create_map("reg_map", 0, 4, UVM_LITTLE_ENDIAN)'


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    repo_root = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--caliptra-root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()

    caliptra = args.caliptra_root.resolve()
    source = (caliptra / SOURCE).resolve()
    output = args.output.resolve()
    if output == caliptra or caliptra in output.parents:
        raise SystemExit("overlay output must remain outside pinned Caliptra sources")
    original = source.read_bytes()
    original_sha = sha256(original)
    if original_sha != SOURCE_SHA256:
        raise SystemExit(f"Refusing unreviewed Caliptra RAL source: {original_sha}")
    text = original.decode()
    if text.count(ANCHOR) != 2:
        raise SystemExit("expected exactly two SHA512 leaf maps with unspecified endianness")
    transformed = text.replace(ANCHOR, REPLACEMENT)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(transformed)

    manifest = args.manifest.resolve()
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(
        json.dumps(
            {
                "purpose": "Use the SoC-IFC little-endian AHB/AXI ordering on the SHA512 RAL leaf maps in the disposable runtime probe.",
                "source_checkout_modified": False,
                "source": str(source),
                "source_sha256": original_sha,
                "overlay": str(output),
                "overlay_sha256": sha256(transformed.encode()),
                "replacements": 2,
                "anchor": ANCHOR,
                "replacement": REPLACEMENT,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )
    print("PASS: copied SHA512 RAL leaf maps with the SoC-IFC little-endian setting")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
