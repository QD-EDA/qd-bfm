#!/usr/bin/env python3
"""Replay the bounded generated SoC-IFC control-package coverage probe."""

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
EXPECTED_TOOL_SHA256 = "235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392"
EXPECTED_DIAGNOSTICS = 8
INPUT_SHA256 = {
    "ctrl-core-coverage.f.in": "95b63b5a55f0b7f462c3ec3d0996bc52fefddfaac4de06d49239728603c1b148",
    "soc_ifc_ctrl_core_coverage_pkg.sv": "403e020342a477aad078ab0b56c69316e71678f6f3fd89830b71ceab487dff11",
    "hostpkg_compile_top.sv": "92807628fbf65f49e0a1a7ceb378e7e30aaae87463130a5ec00c36b20aee9746",
    "soc_ifc_generated_empty_psprintf_overlay.py": "4743ab6c0b6c33282a57055cacfa370d01ec9e32cde87084c578a7875aadb00c",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(command: list[str], *, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def main() -> int:
    evidence = Path(__file__).resolve().parent
    repo = evidence.parents[1]
    caliptra = Path(
        os.environ.get("CALIPTRA_ROOT", str(repo.parent / "caliptra-rtl"))
    ).resolve()
    requested_iverilog = os.environ.get("IVERILOG_BIN", "iverilog")
    iverilog_path = Path(requested_iverilog).expanduser()
    resolved_iverilog = (
        iverilog_path.resolve()
        if iverilog_path.is_file()
        else Path(shutil.which(requested_iverilog) or "")
    )
    if not resolved_iverilog.is_file():
        print(f"iverilog executable not found: {requested_iverilog}", file=sys.stderr)
        return 2
    iverilog = resolved_iverilog

    commit = run(["git", "-C", str(caliptra), "rev-parse", "HEAD"])
    if commit.returncode != 0 or commit.stdout.strip() != CALIPTRA_COMMIT:
        print(
            f"expected Caliptra {CALIPTRA_COMMIT}, got {commit.stdout.strip() or 'unavailable'}",
            file=sys.stderr,
        )
        return 2

    coverage = caliptra / (
        "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/"
        "interface_packages/soc_ifc_ctrl_pkg/src/soc_ifc_ctrl_transaction_coverage.svh"
    )
    if not coverage.is_file() or sha256(coverage) != COVERAGE_SHA256:
        print(f"pinned coverage source hash mismatch: {coverage}", file=sys.stderr)
        return 2

    tool_hash = sha256(iverilog.resolve())
    if tool_hash != EXPECTED_TOOL_SHA256:
        print(
            f"warning: iverilog hash {tool_hash} differs from captured tool "
            f"{EXPECTED_TOOL_SHA256}",
            file=sys.stderr,
        )

    overlay_builder = repo / "docs/conformance/release_overlays/caliptra/soc_ifc_generated_empty_psprintf_overlay.py"
    template = evidence / "ctrl-core-coverage.f.in"
    template_hash = sha256(template)
    for name, expected in INPUT_SHA256.items():
        path = (
            repo / "docs/conformance/release_overlays/caliptra" / name
            if name == "soc_ifc_generated_empty_psprintf_overlay.py"
            else evidence / name
        )
        if sha256(path) != expected:
            print(f"replay input hash mismatch: {path}", file=sys.stderr)
            return 2

    with tempfile.TemporaryDirectory(prefix="caliptra-soc-ifc-ctrl-probe-") as tmp:
        temp = Path(tmp)
        overlay = temp / "interface-packages"
        overlay_result = run(
            [
                sys.executable,
                str(overlay_builder),
                "--caliptra-root",
                str(caliptra),
                "--output",
                str(overlay),
            ],
            cwd=repo,
        )
        if overlay_result.returncode:
            sys.stderr.write(overlay_result.stdout)
            sys.stderr.write(overlay_result.stderr)
            return overlay_result.returncode

        filelist_text = template.read_text()
        filelist_text = filelist_text.replace("@CALIPTRA_ROOT@", str(caliptra))
        filelist_text = filelist_text.replace("@OVERLAY_ROOT@", str(overlay))
        filelist = temp / "ctrl-core-coverage.f"
        filelist.write_text(filelist_text)

        command = [
            str(iverilog),
            "-g2017",
            "-uvm",
            "-s",
            "hostpkg_compile_top",
            "-o",
            str(temp / "probe.vvp"),
            "-f",
            str(filelist),
            str(evidence / "hostpkg_compile_top.sv"),
        ]
        started = time.monotonic()
        try:
            result = subprocess.run(
                command,
                cwd=repo,
                text=True,
                capture_output=True,
                timeout=60,
                check=False,
            )
        except subprocess.TimeoutExpired as error:
            print("probe exceeded 60 seconds", file=sys.stderr)
            if error.stdout:
                sys.stderr.write(error.stdout if isinstance(error.stdout, str) else error.stdout.decode())
            if error.stderr:
                sys.stderr.write(error.stderr if isinstance(error.stderr, str) else error.stderr.decode())
            return 1

        output = result.stdout + result.stderr
        sys.stdout.write(output)
        diagnostics = output.count("'with' filter has more than 4096 candidate values")
        elapsed = time.monotonic() - started
        print(f"Caliptra commit: {commit.stdout.strip()}")
        print(f"generated coverage SHA-256: {COVERAGE_SHA256}")
        print(f"iverilog SHA-256: {tool_hash}")
        print(f"filelist template SHA-256: {template_hash}")
        print(f"overlay builder SHA-256: {INPUT_SHA256['soc_ifc_generated_empty_psprintf_overlay.py']}")
        print(f"compile elapsed: {elapsed:.2f}s; exit code: {result.returncode}")

        if result.returncode == EXPECTED_DIAGNOSTICS and diagnostics == EXPECTED_DIAGNOSTICS:
            print(
                "PASS: the generated control-package reducer reports all eight "
                "over-limit bins promptly; full-domain with-filter coverage remains unsupported."
            )
            return 0

        print(
            f"expected exit {EXPECTED_DIAGNOSTICS} with {EXPECTED_DIAGNOSTICS} "
            f"over-limit diagnostics; observed exit {result.returncode} and {diagnostics} diagnostics",
            file=sys.stderr,
        )
        return 1




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
