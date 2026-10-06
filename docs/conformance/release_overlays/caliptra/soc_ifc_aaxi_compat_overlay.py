#!/usr/bin/env python3
"""Prepare a disposable SoC-IFC environment import for the open AAXI shim."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


SOURCE_SHA256 = "9031e1950c8e7d948ea4607ed7da2012ee71e876dd2d3d13094c2eea403b7b56"
SOURCE_RELATIVE = Path(
    "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/"
    "environment_packages/soc_ifc_env_pkg/soc_ifc_env_pkg.sv"
)
IMPORT_LINE = "  import aaxi_uvm_pkg::*;"
OPEN_IMPORT = "  import caliptra_aaxi_uvmf_compat_pkg::*;"


def main() -> None:
    repo_root = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root",
        type=Path,
        default=repo_root.parent / "caliptra-rtl",
        help="pinned Caliptra checkout (default: sibling caliptra-rtl)",
    )
    parser.add_argument("--output", required=True, type=Path, help="overlay output path")
    args = parser.parse_args()

    source_path = args.caliptra_root / SOURCE_RELATIVE
    source = source_path.read_text()
    actual_sha256 = hashlib.sha256(source.encode()).hexdigest()
    if actual_sha256 != SOURCE_SHA256:
        raise SystemExit(
            f"Refusing unreviewed SoC-IFC environment: {actual_sha256} != {SOURCE_SHA256}"
        )
    if source.count(IMPORT_LINE) != 1 or source.count(OPEN_IMPORT):
        raise SystemExit("Refusing SoC-IFC package with an unexpected AAXI import block")

    output = args.output.resolve()
    if output == source_path.resolve():
        raise SystemExit("Overlay output must not overwrite the pinned Caliptra source")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(source.replace(IMPORT_LINE, IMPORT_LINE + "\n" + OPEN_IMPORT, 1))


if __name__ == "__main__":
    main()
