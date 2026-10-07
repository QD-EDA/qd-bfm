#!/usr/bin/env python3
"""Emit a hash-recorded inventory of pinned Caliptra/Adams Bridge DV consumers.

Uses only the Python standard library. It reads the pinned RTL checkouts and
writes JSON into this repository; it never modifies either input checkout.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


SOURCE_SUFFIXES = {".sv", ".svh", ".v", ".vh", ".yaml", ".yml", ".vf", ".f"}
TEXT_SUFFIXES = {".yaml", ".yml", ".vf", ".f"}
API_PATTERNS = {
    "avery_axi_types_and_agents": re.compile(
        r"\b(?:aaxi_master_tr|aaxi_uvm_[A-Za-z0-9_]*|aaxi_intf|AVERY_AXI|AVERY_SIM)\b"
    ),
    "qvip_ahb": re.compile(
        r"\b(?:qvip_ahb_lite_slave[A-Za-z0-9_]*|ahb_master_burst_transfer|QVIP_AHB_LITE_SLAVE_DIR)\b"
    ),
    "axi4pc": re.compile(r"\b(?:Axi4PC|CALIPTRA_AXI4PC_DIR)\b"),
    "uvmf_provider": re.compile(r"\b(?:UVMF_HOME|UVMF_VIP_LIBRARY_HOME|uvmf_base_pkg)\b"),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def git_value(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def source_files(root: Path) -> list[Path]:
    return sorted(
        path
        for path in (root / "src").rglob("*")
        if path.is_file() and path.suffix.lower() in SOURCE_SUFFIXES
    )


def entry(root: Path, path: Path) -> dict[str, str]:
    return {"path": path.relative_to(root).as_posix(), "sha256": sha256(path)}


def consumer_inventory(
    root: Path,
    label: str,
    census_entries: list[dict[str, object]] | None = None,
) -> dict[str, object]:
    files = source_files(root)
    suites = [
        path
        for path in files
        if "/stimulus/testsuites/" in path.as_posix()
        and path.suffix.lower() in TEXT_SUFFIXES
    ]
    authored_tests = [
        path
        for path in files
        if "/stimulus/tests/" in path.as_posix()
        and path.suffix.lower() in {".yaml", ".yml"}
    ]
    generated_tests = [
        path
        for path in files
        if "/uvmf_template_output/project_benches/" in path.as_posix()
        and "/tb/tests/src/" in path.as_posix()
        and path.suffix.lower() in {".yaml", ".yml"}
    ]
    if census_entries is None:
        unit_filelists = [
            path
            for path in files
            if path.suffix.lower() == ".vf"
            and path.name.endswith("tb.vf")
            and path.name != "ntt_utb.vf"
        ]
    else:
        repository_prefix = "caliptra_v2.1.2" if label == "caliptra-rtl" else "adams_bridge_v2.0.3"
        unit_filelists = [
            root / item["filelist"]
            for item in census_entries
            if item["repository"] == repository_prefix
        ]
        missing_filelists = [path for path in unit_filelists if not path.is_file()]
        if missing_filelists:
            raise FileNotFoundError(f"census filelist missing from {label}: {missing_filelists[0]}")
    regression_candidates = [
        path
        for path in files
        if path.suffix.lower() in {".yaml", ".yml"}
        and "regress" in path.name.lower()
    ]
    regression_references = []
    for path in suites:
        for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            value = line.strip()
            if value and not value.startswith("#") and re.search(r"\$[A-Z][A-Z0-9_]*ROOT/", value):
                regression_references.append(
                    {
                        "source": path.relative_to(root).as_posix(),
                        "line": number,
                        "reference": value,
                    }
                )

    api_evidence: dict[str, list[dict[str, object]]] = {key: [] for key in API_PATTERNS}
    provider_variables: dict[str, set[str]] = {}
    hash_cache: dict[Path, str] = {}
    for path in files:
        if path.suffix.lower() not in SOURCE_SUFFIXES:
            continue
        for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            code = line.strip()
            if not code or code.startswith(("//", "#", "/*", "*")):
                continue
            for name, pattern in API_PATTERNS.items():
                if pattern.search(line):
                    if path not in hash_cache:
                        hash_cache[path] = sha256(path)
                    api_evidence[name].append(
                        {
                            "source": path.relative_to(root).as_posix(),
                            "line": number,
                            "text": code[:240],
                            "source_sha256": hash_cache[path],
                        }
                    )
            if path.suffix.lower() in TEXT_SUFFIXES:
                for match in re.finditer(r"\$\{?([A-Z][A-Z0-9_]*)\}?", line):
                    provider_variables.setdefault(match.group(1), set()).add(
                        path.relative_to(root).as_posix()
                    )

    return {
        "label": label,
        "revision": git_value(root, "rev-parse", "HEAD"),
        "dirty": bool(git_value(root, "status", "--porcelain")),
        "inventory": {
            "regression_group_files": [entry(root, path) for path in suites],
            "regression_named_yaml_candidates": [
                entry(root, path) for path in regression_candidates
            ],
            "authored_stimulus_test_yaml": [entry(root, path) for path in authored_tests],
            "generated_uvmf_test_yaml": [entry(root, path) for path in generated_tests],
            "unit_rtl_filelists": [entry(root, path) for path in unit_filelists],
            "regression_path_references": regression_references,
        },
        "provider_variables": {
            name: sorted(paths) for name, paths in sorted(provider_variables.items())
        },
        "api_evidence": api_evidence,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--caliptra-root", type=Path, required=True)
    parser.add_argument("--adams-root", type=Path, required=True)
    parser.add_argument("--unit-census-json", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    census = None
    if args.unit_census_json:
        census_path = args.unit_census_json.resolve()
        census = json.loads(census_path.read_text())

    manifest = {
        "schema_version": 1,
        "purpose": "Phase 0 source/API/license inventory for a clean-room Caliptra BFM replacement",
        "inputs": [
            consumer_inventory(
                args.caliptra_root.resolve(), "caliptra-rtl", census["entries"] if census else None
            ),
            consumer_inventory(
                args.adams_root.resolve(), "adams-bridge", census["entries"] if census else None
            ),
        ],
        "unit_census": None,
        "limitations": [
            "Source references prove declarations, filelist inclusion, or visible connections only; they do not prove runtime behavior.",
            "External Avery, QVIP, UVMF, and ARM implementation details are absent from these pinned source checkouts.",
            "Counts are scoped by the named path filters; they are not regression-pass counts or a license grant.",
        ],
    }
    if census:
        census_fields = (
            "case",
            "repository",
            "filelist",
            "top",
            "classification",
            "exit_code",
            "timed_out",
            "timeout_seconds",
            "first_diagnostic",
        )
        manifest["unit_census"] = {
            "artifact": census_path.name,
            "artifact_sha256": sha256(census_path),
            "source_inventory_sha256": census["source_inventory_sha256"],
            "entries": [
                {field: item.get(field) for field in census_fields}
                for item in census["entries"]
            ],
        }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {args.output}")
    for repo in manifest["inputs"]:
        inventory = repo["inventory"]
        print(
            f"{repo['label']} {repo['revision']}: "
            f"{len(inventory['regression_group_files'])} regression groups, "
            f"{len(inventory['authored_stimulus_test_yaml'])} authored test YAML, "
            f"{len(inventory['generated_uvmf_test_yaml'])} generated UVMF test YAML, "
            f"{len(inventory['unit_rtl_filelists'])} unit RTL filelists"
        )
    if manifest["unit_census"]:
        counts: dict[str, int] = {}
        for item in manifest["unit_census"]["entries"]:
            status = str(item["classification"])
            counts[status] = counts.get(status, 0) + 1
        print(f"frozen unit census: {json.dumps(counts, sort_keys=True)}")


if __name__ == "__main__":
    main()
