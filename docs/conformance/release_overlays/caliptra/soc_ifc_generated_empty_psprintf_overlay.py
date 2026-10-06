#!/usr/bin/env python3
"""Prepare hash-guarded Icarus copies of Caliptra's generated SoC-IFC VIP packages.

Invalid trailing empty actuals on generated diagnostic ``$psprintf`` calls are
removed. The generated mailbox SRAM responder's packed concatenation of two
object properties is lowered to one temporary decode result and two scalar
property writes. Signal behavior, transaction structures, and UVM APIs are
otherwise copied from the pinned source.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
from pathlib import Path


SOURCE_RELATIVE = Path(
    "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/interface_packages"
)
PACKAGES = (
    "soc_ifc_ctrl_pkg",
    "cptra_ctrl_pkg",
    "ss_mode_ctrl_pkg",
    "soc_ifc_status_pkg",
    "cptra_status_pkg",
    "ss_mode_status_pkg",
    "mbox_sram_pkg",
)
FILES = (
    ("soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_configuration.svh", "5dc88118e56c6d2ea63402859dae708b0d194c4a11d13ddfaa41d44e84aca8ee", b"interface_name, ),", b"interface_name),"),
    ("soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_driver_bfm.sv", "c674bfa5a519adf8276efabb529833ef2f5206976ca4b2a6638ac260f3767ab4", b'parameters: ", ),', b'parameters: "),'),
    ("soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_monitor_bfm.sv", "d875c888448152709c0822d1871bab3debb84baa13ca775d6f38fd8678ecfa86", b'parameters: ", ),', b'parameters: "),'),
    ("cptra_ctrl_pkg/src/cptra_ctrl_configuration.svh", "1de12cdc45ab0bceb1c3590cd25b984784736c4ad332396401109db7fe7c3bf0", b"interface_name, ),", b"interface_name),"),
    ("cptra_ctrl_pkg/src/cptra_ctrl_driver_bfm.sv", "3ac1542766c7260a800b2c014694e078f9563c51bc2edc9e5d4a5500c8f1f456", b'parameters: ", ),', b'parameters: "),'),
    ("cptra_ctrl_pkg/src/cptra_ctrl_monitor_bfm.sv", "b0bf7bb675d07e4e62f0a4b86be39ff74b78caacb828c942781668359f3ce32a", b'parameters: ", ),', b'parameters: "),'),
    ("ss_mode_ctrl_pkg/src/ss_mode_ctrl_configuration.svh", "d4cecd5fffa008bdb4d604362b69b5010dbe0f705819a5fbc0bffca129d2020c", b"interface_name, ),", b"interface_name),"),
    ("ss_mode_ctrl_pkg/src/ss_mode_ctrl_driver_bfm.sv", "c6056fa803ed50e360b38069c92dec078db6f176663625e9557f1eb2852eada1", b'parameters: ", ),', b'parameters: "),'),
    ("ss_mode_ctrl_pkg/src/ss_mode_ctrl_monitor_bfm.sv", "8284bcbde745355b961a6b247e1903689b05e45dc949b33b261680440a495ece", b'parameters: ", ),', b'parameters: "),'),
    ("soc_ifc_status_pkg/src/soc_ifc_status_configuration.svh", "3e941ba3722d92ced3012d1030b93ae222af41cd122110e220ee801b7ff64c23", b"interface_name, ),", b"interface_name),"),
    ("soc_ifc_status_pkg/src/soc_ifc_status_driver_bfm.sv", "a0e26ac2a86acfe2e78bb95f6f701a24ac72b0ba8b4fd0c627352559ac9af619", b'parameters: ", ),', b'parameters: "),'),
    ("soc_ifc_status_pkg/src/soc_ifc_status_monitor_bfm.sv", "62d004a5462dbcacab9dc896f972ce820aa739118512f0ba7c6fd5d3abf69ab5", b'parameters: ", ),', b'parameters: "),'),
    ("cptra_status_pkg/src/cptra_status_configuration.svh", "f0a0f16c52be3b799afa0b5252e833420d3a64a8ebeba759b40541afdda8bd2b", b"interface_name, ),", b"interface_name),"),
    ("cptra_status_pkg/src/cptra_status_driver_bfm.sv", "70c47e2737dacda24a56c99076be75f919b9d75d95a2174710c39007d6f16311", b'parameters: ", ),', b'parameters: "),'),
    ("cptra_status_pkg/src/cptra_status_monitor_bfm.sv", "be1b334b043906de3f8b5747ca83cda470498b7aba85397330db9987f59d240a", b'parameters: ", ),', b'parameters: "),'),
    ("ss_mode_status_pkg/src/ss_mode_status_configuration.svh", "31f2df4961ee02f94cee792f7b2cf197151475ed31cf00bfaaa0784a2257ca0f", b"interface_name, ),", b"interface_name),"),
    ("ss_mode_status_pkg/src/ss_mode_status_driver_bfm.sv", "d64198c7ab5ec0028dda472fa7f688fffbfe62792e8de499352f9c9c2852b224", b'parameters: ", ),', b'parameters: "),'),
    ("ss_mode_status_pkg/src/ss_mode_status_monitor_bfm.sv", "e09af16cbf234e18a03484860e5a2decd9b537188232af5eb15b56bce664234a", b'parameters: ", ),', b'parameters: "),'),
    ("mbox_sram_pkg/src/mbox_sram_configuration.svh", "8575907e721ff2d0dc29ca75b096bf6d4cd5cbbe1d3f1cd2fb536452f33c899a", b"interface_name, ),", b"interface_name),"),
    ("mbox_sram_pkg/src/mbox_sram_driver_bfm.sv", "8e8e3973fe64221557c3df6fd32af9892e5d1443a5c662a3285d265db5eb6948", b'parameters: ", ),', b'parameters: "),'),
    ("mbox_sram_pkg/src/mbox_sram_monitor_bfm.sv", "50282a5ef7170e1f7aac005c3ee9847a388172d5f9bb0fab174dbd615ba51163", b'parameters: ", ),', b'parameters: "),'),
    (
        "mbox_sram_pkg/src/mbox_sram_responder_sequence.svh",
        "32269198b02ea423591f8ae036c37b6813acc5ca95c78a1bae4cc9826508ec79",
        b"        {req.ecc_double_bit_error,\n"
        b"         req.ecc_single_bit_error} = rvecc_decode(req.data, req.data_ecc);",
        b"        begin : decode_ecc_result\n"
        b"            bit [1:0] ecc_error_status;\n"
        b"            ecc_error_status = rvecc_decode(req.data, req.data_ecc);\n"
        b"            req.ecc_double_bit_error = ecc_error_status[1];\n"
        b"            req.ecc_single_bit_error = ecc_error_status[0];\n"
        b"        end",
    ),
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def prepare(source_root: Path, output_root: Path) -> None:
    source_root = source_root.resolve()
    output_root = output_root.resolve()
    if (
        output_root == source_root
        or source_root in output_root.parents
        or output_root in source_root.parents
    ):
        raise SystemExit("overlay output must not overlap the pinned Caliptra package")
    if output_root.exists():
        raise SystemExit(f"overlay output already exists: {output_root}")

    package_root = source_root / SOURCE_RELATIVE
    replacements = []
    for relative, expected, old, new in FILES:
        source = package_root / relative
        original = source.read_bytes()
        if sha256(original) != expected or original.count(old) != 1:
            raise SystemExit(f"refusing unreviewed generated source: {source}")
        replacements.append((relative, original.replace(old, new, 1), expected))

    output_root.parent.mkdir(parents=True, exist_ok=True)
    for package in PACKAGES:
        shutil.copytree(package_root / package, output_root / package)
    for relative, patched, expected in replacements:
        target = output_root / relative
        target.write_bytes(patched)
        print(f"{relative}: {expected} -> {sha256(patched)}")


def main() -> None:
    repository = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root",
        type=Path,
        default=repository.parent / "caliptra-rtl",
        help="pinned Caliptra checkout (default: sibling caliptra-rtl)",
    )
    parser.add_argument("--output", required=True, type=Path, help="new overlay directory")
    args = parser.parse_args()
    prepare(args.caliptra_root, args.output)


if __name__ == "__main__":
    main()
