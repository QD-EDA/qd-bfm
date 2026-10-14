#!/usr/bin/env python3
"""Rewrite selected Caliptra full-domain coverage filters exactly for Icarus.

The generated SoC-IFC coverage uses full-width ``with`` filters for nonzero
bytes, while the CSR covergroups use large aligned ranges. This overlay replaces
only those predicates with equivalent wildcard masks in disposable copies.
It does not alter the pinned Caliptra checkout or implement generic ``with``
filter semantics in Icarus.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import re


CALIPTRA_COMMIT = "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e"
INTERFACE_ROOT = Path(
    "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/"
    "interface_packages"
)
RTL_ROOT = Path("src/soc_ifc/rtl")

BYTE_FILES = (
    (
        INTERFACE_ROOT / "soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_transaction_coverage.svh",
        Path("soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_transaction_coverage.svh"),
        "9e5e6f540303af5302315afca7ea8323a3ef883024aa11a0410f83f24c1fbfaf",
        64,
    ),
    (
        INTERFACE_ROOT / "soc_ifc_status_pkg/src/soc_ifc_status_transaction_coverage.svh",
        Path("soc_ifc_status_pkg/src/soc_ifc_status_transaction_coverage.svh"),
        "72c789323c1d1e934cf051cfcc734bbca3f003219fed686fed9efe74399abf92",
        64,
    ),
)
RTL_BYTE_FILE = (
    RTL_ROOT / "soc_ifc_reg_covergroups.svh",
    Path("soc_ifc_reg_covergroups.svh"),
    "dd755ccfb21f8188ce4903dabd170808d1156ad0dd314867beb45f2f7d064d65",
    32,
)

ALIGNED_FILES = (
    (
        RTL_ROOT / "mbox_csr_covergroups.svh",
        Path("mbox_csr_covergroups.svh"),
        "974af3660d68930f4cd83704f38ffcc560eeffcefedd25ba0a55e437331dc6b3",
    ),
    (
        RTL_ROOT / "sha512_acc_csr_covergroups.svh",
        Path("sha512_acc_csr_covergroups.svh"),
        "abe8101925d9d7bad1c618d1b7a416d37af838e41426c5f5ae92f089b686f6a3",
    ),
)

BYTE_RE = re.compile(
    r"^(\s*)bins byte_(\d+)\s*=\s*\{\[0:\$\]\}\s+with\s+"
    r"\(\$countones\(item\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*>\s*0\)\);\s*$",
    re.MULTILINE,
)
ALIGN_RE = re.compile(
    r"^(\s*)bins legal_(word|dword|qword|oword)_aligned_val\s*=\s*"
    r"\{\[1:32'h8000\]\}\s+with\s+\(~\|item\[(\d+)(?::(\d+))?\]\);\s*$",
    re.MULTILINE,
)
ALIGN_BITS = {"word": 1, "dword": 2, "qword": 3, "oword": 4}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def byte_patterns(width: int, byte_index: int) -> list[str]:
    if width not in (32, 64) or width % 8:
        raise ValueError(f"unsupported sample width {width}")
    if not 0 <= byte_index < width // 8:
        raise ValueError(f"byte index outside {width}-bit sample: {byte_index}")
    result = []
    for bit_in_byte in range(8):
        absolute_bit = byte_index * 8 + bit_in_byte
        bits = ["?"] * width
        bits[width - 1 - absolute_bit] = "1"
        result.append(f"{width}'b" + "".join(bits))
    return result


def interval_blocks(lower: int, upper: int) -> list[tuple[int, int]]:
    """Return disjoint (base, free_low_bits) cubes covering an integer range."""
    if lower < 0 or upper < lower:
        raise ValueError(f"invalid interval [{lower}, {upper}]")
    blocks = []
    cursor = lower
    while cursor <= upper:
        alignment = (cursor & -cursor).bit_length() - 1 if cursor else upper.bit_length()
        remaining = upper - cursor + 1
        size = min(alignment, remaining.bit_length() - 1)
        blocks.append((cursor, size))
        cursor += 1 << size
    return blocks


def aligned_patterns(width: int, low_zero_bits: int) -> list[str]:
    """Encode [1:32'h8000] and item[low_zero_bits-1:0] == 0 exactly."""
    if width != 32 or low_zero_bits not in range(1, 5):
        raise ValueError(f"unsupported aligned coverage shape: {width}, {low_zero_bits}")
    y_width = width - low_zero_bits
    y_upper = 0x8000 >> low_zero_bits
    patterns = []
    total = 0
    previous_upper = -1
    for base, free_bits in interval_blocks(1, y_upper):
        block_upper = base + (1 << free_bits) - 1
        if base <= previous_upper or block_upper > y_upper or base == 0:
            raise AssertionError("interval decomposition overlaps or escapes its range")
        previous_upper = block_upper
        total += 1 << free_bits
        y_bits = [
            "?" if bit < free_bits else str((base >> bit) & 1)
            for bit in range(y_width - 1, -1, -1)
        ]
        patterns.append(f"32'b" + "".join(y_bits) + "0" * low_zero_bits)
    if total != y_upper:
        raise AssertionError(f"interval covers {total} values, expected {y_upper}")
    return patterns


def render_bin(indent: str, name: str, patterns: list[str]) -> str:
    lines = ",\n".join(indent + "  " + pattern for pattern in patterns)
    return f"{indent}wildcard bins {name} = {{\n{lines}\n{indent}}};"


def transform_byte_file(data: bytes, expected_width: int, groups: int = 1) -> bytes:
    text = data.decode("utf-8")
    matches = list(BYTE_RE.finditer(text))
    expected_count = expected_width // 8 * groups
    if len(matches) != expected_count:
        raise SystemExit(
            f"expected {expected_count} byte predicates for {expected_width}-bit sample; "
            f"found {len(matches)}"
        )
    indices = [int(match.group(2)) for match in matches]
    if any(indices.count(index) != groups for index in range(expected_width // 8)):
        raise SystemExit("unexpected byte-bin indices")
    for match in reversed(matches):
        indent, raw_index, high_text, low_text = match.groups()
        index, high, low = int(raw_index), int(high_text), int(low_text)
        if (high, low) != (index * 8 + 7, index * 8):
            raise SystemExit(f"byte_{index}: unexpected slice [{high}:{low}]")
        replacement = render_bin(indent, f"byte_{index}", byte_patterns(expected_width, index))
        text = text[:match.start()] + replacement + text[match.end():]
    if "$countones(item[" in text:
        raise SystemExit("unhandled full-domain byte predicate remains")
    return text.encode("utf-8")


def transform_aligned_file(data: bytes) -> bytes:
    text = data.decode("utf-8")
    matches = list(ALIGN_RE.finditer(text))
    if len(matches) != len(ALIGN_BITS):
        raise SystemExit(f"expected four aligned bins, found {len(matches)}")
    found = set()
    for match in reversed(matches):
        indent, name, high_text, low_text = match.groups()
        low_zero_bits = ALIGN_BITS[name]
        high = int(high_text)
        low = int(low_text) if low_text is not None else high
        if low != 0 or high != low_zero_bits - 1:
            raise SystemExit(f"{name}: unexpected item slice [{high}:{low}]")
        found.add(name)
        replacement = render_bin(
            indent,
            f"legal_{name}_aligned_val",
            aligned_patterns(32, low_zero_bits),
        )
        text = text[:match.start()] + replacement + text[match.end():]
    if found != set(ALIGN_BITS):
        raise SystemExit(f"unexpected aligned-bin set: {sorted(found)}")
    if "with (~|item[" in text:
        raise SystemExit("an unhandled alignment predicate remains")
    return text.encode("utf-8")


def prepare(caliptra_root: Path, package_overlay: Path, rtl_overlay: Path) -> dict[str, str]:
    caliptra_root = caliptra_root.resolve()
    package_overlay = package_overlay.resolve()
    rtl_overlay = rtl_overlay.resolve()
    for output in (package_overlay, rtl_overlay):
        if output == caliptra_root or caliptra_root in output.parents:
            raise SystemExit("overlay output must be outside the pinned Caliptra tree")
    if (
        package_overlay == rtl_overlay
        or package_overlay in rtl_overlay.parents
        or rtl_overlay in package_overlay.parents
    ):
        raise SystemExit("package and RTL overlays must be separate directories")
    if not package_overlay.is_dir():
        raise SystemExit(f"missing disposable package tree: {package_overlay}")
    if rtl_overlay.exists():
        raise SystemExit(f"RTL overlay already exists: {rtl_overlay}")
    commit = subprocess.run(
        ["git", "-C", str(caliptra_root), "rev-parse", "HEAD"],
        text=True,
        capture_output=True,
        check=False,
    )
    if commit.returncode or commit.stdout.strip() != CALIPTRA_COMMIT:
        raise SystemExit(f"expected Caliptra {CALIPTRA_COMMIT}, got {commit.stdout.strip()}")

    replacements = []
    for source_relative, target_relative, expected_hash, width in BYTE_FILES:
        source = caliptra_root / source_relative
        original = source.read_bytes()
        if sha256(original) != expected_hash:
            raise SystemExit(f"refusing unreviewed generated coverage: {source}")
        target = package_overlay / target_relative
        if not target.is_file() or sha256(target.read_bytes()) != expected_hash:
            raise SystemExit(f"expected pristine disposable package source: {target}")
        replacements.append((target, transform_byte_file(original, width), expected_hash))

    source_relative, target_relative, expected_hash, width = RTL_BYTE_FILE
    source = caliptra_root / source_relative
    original = source.read_bytes()
    if sha256(original) != expected_hash:
        raise SystemExit(f"refusing unreviewed CSR coverage: {source}")
    rtl_replacements = [
        (target_relative, transform_byte_file(original, width, groups=2), expected_hash)
    ]

    for source_relative, target_relative, expected_hash in ALIGNED_FILES:
        source = caliptra_root / source_relative
        original = source.read_bytes()
        if sha256(original) != expected_hash:
            raise SystemExit(f"refusing unreviewed CSR coverage: {source}")
        rtl_replacements.append(
            (target_relative, transform_aligned_file(original), expected_hash)
        )

    for target, output, original_hash in replacements:
        target.write_bytes(output)
        print(f"{target.name}: {original_hash} -> {sha256(output)}")
    rtl_overlay.mkdir(parents=True)
    for relative, output, original_hash in rtl_replacements:
        target = rtl_overlay / relative
        target.write_bytes(output)
        print(f"{target.name}: {original_hash} -> {sha256(output)}")
    return {str(path): sha256(output) for path, output, _ in replacements} | {
        str(rtl_overlay / path): sha256(output) for path, output, _ in rtl_replacements
    }


def main() -> None:
    repository = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root",
        type=Path,
        default=repository.parent / "caliptra-rtl",
        help="pinned Caliptra checkout (default: sibling caliptra-rtl)",
    )
    parser.add_argument("--packages", required=True, type=Path, help="disposable VIP packages")
    parser.add_argument("--rtl-output", required=True, type=Path, help="new RTL include overlay")
    args = parser.parse_args()
    prepare(args.caliptra_root, args.packages, args.rtl_output)


if __name__ == "__main__":
    main()
