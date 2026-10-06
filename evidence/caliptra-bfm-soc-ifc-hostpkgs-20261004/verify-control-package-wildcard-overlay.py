#!/usr/bin/env python3
"""Verify exact byte-bin overlay semantics and compile the generated package."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time


CALIPTRA_COMMIT = "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e"
COVERAGE_SHA256 = "9e5e6f540303af5302315afca7ea8323a3ef883024aa11a0410f83f24c1fbfaf"
OVERLAY_SHA256 = "1e34b47b59077b12f66c0b1b072cd4fdf64e7316e58b20ceec47ca172d6dad57"
PASS_MARKER = (
    "PASS: all 8 byte predicates matched all 255 nonzero values "
    "with no cross-byte hits"
)
OVERLAP_PASS_MARKER = (
    "PASS: a sample with two nonzero bytes hit exactly two byte bins"
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(command: list[str], *, cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def executable(value: str, sibling: str) -> Path | None:
    path = Path(value).expanduser()
    if path.is_file():
        return path.resolve()
    located = shutil.which(value)
    if located:
        return Path(located).resolve()
    if path.name == "iverilog":
        candidate = path.parent / sibling
        if candidate.is_file():
            return candidate.resolve()
    return None


def emit(label: str, result: subprocess.CompletedProcess[str]) -> None:
    print(f"--- {label}: exit {result.returncode} ---")
    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="" if result.stderr.endswith("\n") else "\n")


def main() -> int:
    evidence = Path(__file__).resolve().parent
    repo = evidence.parents[1]
    caliptra = Path(
        os.environ.get("CALIPTRA_ROOT", str(repo.parent / "caliptra-rtl"))
    ).resolve()
    requested_iverilog = os.environ.get("IVERILOG_BIN", "iverilog")
    iverilog = executable(requested_iverilog, "vvp")
    if iverilog is None:
        print(f"iverilog executable not found: {requested_iverilog}", file=sys.stderr)
        return 2
    requested_vvp = os.environ.get("VVP_BIN", str(iverilog.with_name("vvp")))
    vvp = executable(requested_vvp, "")
    if vvp is None:
        print(f"vvp executable not found: {requested_vvp}", file=sys.stderr)
        return 2

    commit = run(["git", "-C", str(caliptra), "rev-parse", "HEAD"], cwd=repo)
    if commit.returncode or commit.stdout.strip() != CALIPTRA_COMMIT:
        print(
            f"expected Caliptra {CALIPTRA_COMMIT}, got "
            f"{commit.stdout.strip() or 'unavailable'}",
            file=sys.stderr,
        )
        return 2

    coverage = caliptra / (
        "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/"
        "interface_packages/soc_ifc_ctrl_pkg/src/"
        "soc_ifc_ctrl_transaction_coverage.svh"
    )
    if not coverage.is_file() or sha256(coverage) != COVERAGE_SHA256:
        print(f"pinned coverage source hash mismatch: {coverage}", file=sys.stderr)
        return 2

    overlay_builder = (
        repo / "docs/conformance/release_overlays/caliptra/"
        "soc_ifc_generated_empty_psprintf_overlay.py"
    )
    bin_overlay = (
        repo / "docs/conformance/release_overlays/caliptra/"
        "soc_ifc_ctrl_nonzero_byte_coverage_overlay.py"
    )
    bin_smoke = evidence / "nonzero-byte-wildcard-smoke.sv"
    template = evidence / "ctrl-core-coverage.f.in"
    reducer = evidence / "soc_ifc_ctrl_core_coverage_pkg.sv"
    top = evidence / "hostpkg_compile_top.sv"
    for path in (overlay_builder, bin_overlay, bin_smoke, template, reducer, top):
        if not path.is_file():
            print(f"missing replay input: {path}", file=sys.stderr)
            return 2

    bin_smoke_hash = sha256(bin_smoke)
    print(f"Caliptra commit: {commit.stdout.strip()}")
    print(f"generated coverage SHA-256: {COVERAGE_SHA256}")
    print(f"overlay output SHA-256: {OVERLAY_SHA256}")
    print(f"Icarus SHA-256: {sha256(iverilog)}")
    print(f"VVP SHA-256: {sha256(vvp)}")
    print(f"semantic smoke SHA-256: {bin_smoke_hash}")

    with tempfile.TemporaryDirectory(prefix="caliptra-soc-ifc-wildcard-") as directory:
        temp = Path(directory)
        package_overlay = temp / "interface-packages"
        base = run(
            [
                sys.executable,
                str(overlay_builder),
                "--caliptra-root",
                str(caliptra),
                "--output",
                str(package_overlay),
            ],
            cwd=repo,
        )
        if base.returncode:
            emit("hash-guarded generated package copy", base)
            return base.returncode
        copied = sum(" -> " in line for line in base.stdout.splitlines())
        print(f"PASS: copied {copied} hash-guarded generated package files")

        transformed = run(
            [
                sys.executable,
                str(bin_overlay),
                "--caliptra-root",
                str(caliptra),
                "--package-overlay",
                str(package_overlay),
            ],
            cwd=repo,
        )
        emit("exact wildcard coverage overlay", transformed)
        if transformed.returncode:
            return transformed.returncode
        target = package_overlay / (
            "soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_transaction_coverage.svh"
        )
        if sha256(target) != OVERLAY_SHA256:
            print("wildcard overlay output hash mismatch", file=sys.stderr)
            return 1

        filelist_text = template.read_text()
        filelist_text = filelist_text.replace("@CALIPTRA_ROOT@", str(caliptra))
        filelist_text = filelist_text.replace("@OVERLAY_ROOT@", str(package_overlay))
        filelist = temp / "ctrl-core-coverage.f"
        filelist.write_text(filelist_text)

        compile_command = [
            str(iverilog),
            "-g2017",
            "-uvm",
            "-s",
            "hostpkg_compile_top",
            "-o",
            str(temp / "ctrl-package.vvp"),
            "-f",
            str(filelist),
            str(top),
        ]
        started = time.monotonic()
        package_compile = run(compile_command, cwd=repo)
        elapsed = time.monotonic() - started
        emit("generated control package compile", package_compile)
        diagnostics = (
            package_compile.stdout + package_compile.stderr
        ).count("'with' filter has more than 4096 candidate values")
        if package_compile.returncode or diagnostics:
            print(
                f"package compile failed: exit={package_compile.returncode}, "
                f"full-range-filter diagnostics={diagnostics}",
                file=sys.stderr,
            )
            return 1
        print(f"package compile elapsed: {elapsed:.2f}s")

        smoke_compile = run(
            [
                str(iverilog),
                "-g2017",
                "-o",
                str(temp / "coverage-smoke.vvp"),
                str(bin_smoke),
            ],
            cwd=repo,
        )
        emit("wildcard semantics compile", smoke_compile)
        if smoke_compile.returncode:
            return 1
        smoke_image = temp / "coverage-smoke.vvp"
        smoke_run = run([str(vvp), str(smoke_image)], cwd=repo)
        emit("wildcard all-values runtime", smoke_run)
        if smoke_run.returncode or PASS_MARKER not in smoke_run.stdout:
            print("wildcard all-values smoke did not pass", file=sys.stderr)
            return 1
        overlap_run = run([str(vvp), str(smoke_image), "+OVERLAP"], cwd=repo)
        emit("wildcard overlap runtime", overlap_run)
        if overlap_run.returncode or OVERLAP_PASS_MARKER not in overlap_run.stdout:
            print("wildcard overlap smoke did not pass", file=sys.stderr)
            return 1

    print(
        "PASS: generated control package elaborates through an exact wildcard "
        "overlay, and all byte predicates pass exhaustive 2-state tests."
    )
    return 0




def run_under_memory_guard() -> int | None:
    if os.environ.get("CALIPTRA_BFM_MEMORY_GUARD_CHILD") == "1" or "--help" in sys.argv or "-h" in sys.argv:
        return None
    repo = Path(__file__).resolve().parents[2]
    guard = repo / "scripts/run_with_memory_pressure_guard.py"
    environment = os.environ.copy()
    environment["CALIPTRA_BFM_MEMORY_GUARD_CHILD"] = "1"
    command = [
        sys.executable,
        str(guard),
        "--min-free-percent",
        "70",
        "--timeout-seconds",
        "600",
        "--",
        sys.executable,
        str(Path(__file__).resolve()),
        *sys.argv[1:],
    ]
    return subprocess.run(command, env=environment).returncode


if __name__ == "__main__":
    guarded_result = run_under_memory_guard()
    if guarded_result is not None:
        raise SystemExit(guarded_result)
    raise SystemExit(main())
