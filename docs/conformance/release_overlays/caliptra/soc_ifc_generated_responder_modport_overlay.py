#!/usr/bin/env python3
"""Fix generated SoC-IFC responder modport directions in a disposable overlay.

The generated driver BFMs dynamically switch between initiator and responder
roles and both sample and drive these signals. The pinned responder modports
declare those same signals as input/output, which prevents strict elaboration
of the driver BFM sources. This hash-guarded overlay marks only those signals
inout; clock and dummy remain inputs.
"""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


FILES = (
    (
        "soc_ifc_status_pkg/src/soc_ifc_status_if.sv",
        "5e7f4348685e33c3f3949dc24426b505cc931d90b1ba3c8acf88c2983a34fb31",
        9,
    ),
    (
        "cptra_status_pkg/src/cptra_status_if.sv",
        "aef8a93fae91a03902aae6bdcfb0251f3a2cf0d6388995472928c54b3eaa8a4d",
        17,
    ),
    (
        "ss_mode_status_pkg/src/ss_mode_status_if.sv",
        "10ecca966bb885e936a0be3e3ed7bea6f1a6c62bb538f743fef66fe77e52da04",
        4,
    ),
    (
        "mbox_sram_pkg/src/mbox_sram_if.sv",
        "18f7b70db1d3b9a5dd6644e57584be823e8b0813ef89801f35f4738ea1c0644b",
        2,
    ),
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_modport(text: str, expected_signal_count: int, source: Path) -> str:
    match = re.search(
        r"(modport\s+responder_port\s*\(\s*input\s+clk\s*,\s*input\s+dummy\s*,)(.*?)(\s*\);)",
        text,
        re.DOTALL,
    )
    if not match:
        raise SystemExit(f"responder modport changed unexpectedly: {source}")

    body = match.group(2)
    rewritten, changed = re.subn(r"\b(?:input|output)\b", "inout", body)
    if changed != expected_signal_count:
        raise SystemExit(
            f"expected {expected_signal_count} responder signals in {source}; found {changed}"
        )
    return text[: match.start(2)] + rewritten + text[match.end(2) :]


def prepare(package_root: Path) -> None:
    package_root = package_root.resolve()
    replacements = []
    for relative, expected, signal_count in FILES:
        target = package_root / relative
        original = target.read_bytes()
        if sha256(original) != expected:
            raise SystemExit(f"refusing unreviewed generated source: {target}")
        patched = patch_modport(original.decode(), signal_count, target).encode()
        replacements.append((target, patched, expected, signal_count))

    for target, patched, expected, signal_count in replacements:
        target.write_bytes(patched)
        print(
            f"{target.name}: {expected} -> {sha256(patched)} "
            f"({signal_count} responder signals set to inout)"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--packages",
        required=True,
        type=Path,
        help="disposable generated interface-packages overlay directory",
    )
    args = parser.parse_args()
    prepare(args.packages)


if __name__ == "__main__":
    main()
