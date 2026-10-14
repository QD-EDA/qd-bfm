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
HDL_SUFFIXES = {".sv", ".svh", ".v", ".vh"}
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
UVMF_CLASS = re.compile(r"\bclass\s+([A-Za-z_]\w*)\b([^;]*);")
UVMF_BASE = re.compile(r"\bextends\s+(uvmf_[A-Za-z_]\w*)\b")
METHOD_DECLARATION = re.compile(r"\b(function|task)\b")
SUPER_CALL = re.compile(r"\bsuper\s*\.\s*([A-Za-z_]\w*)\s*\(")


def uncomment(text: str) -> str:
    return re.sub(
        r"/\*.*?\*/|//[^\n]*",
        lambda match: "".join("\n" if char == "\n" else " " for char in match.group()),
        text,
        flags=re.S,
    )


def argument_count(text: str, opening: int) -> int:
    depth = 0
    braces = brackets = 0
    quoted = escaped = False
    commas = 0
    for index in range(opening, len(text)):
        char = text[index]
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
            continue
        if char == '"':
            quoted = True
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                arguments = text[opening + 1:index].strip()
                return 0 if not arguments else commas + 1
        elif depth == 1 and char == "{":
            braces += 1
        elif depth == 1 and char == "}":
            braces -= 1
        elif depth == 1 and char == "[":
            brackets += 1
        elif depth == 1 and char == "]":
            brackets -= 1
        elif depth == 1 and braces == 0 and brackets == 0 and char == ",":
            commas += 1
    return -1


def method_declarations(body: str, body_line: int) -> list[dict[str, object]]:
    methods = []
    for match in METHOD_DECLARATION.finditer(body):
        opening = body.find("(", match.end())
        semicolon = body.find(";", match.end())
        if opening < 0 or (semicolon >= 0 and semicolon < opening):
            continue
        prefix = body[match.end():opening].strip()
        name_match = re.search(r"([A-Za-z_]\w*)\s*$", prefix)
        if not name_match:
            continue
        arity = argument_count(body, opening)
        if arity < 0:
            continue
        methods.append(
            {
                "name": name_match.group(1),
                "kind": match.group(1),
                "arity": arity,
                "line": body_line + body.count("\n", 0, match.start()),
            }
        )
    return methods


def uvmf_api_inventory(root: Path, files: list[Path]) -> dict[str, object]:
    classes = []
    macros = {}
    plusargs = []
    for path in files:
        if path.suffix.lower() not in HDL_SUFFIXES:
            continue
        raw = path.read_text(errors="replace")
        code = uncomment(raw)
        relative = path.relative_to(root).as_posix()
        digest = sha256(path)
        for match in UVMF_CLASS.finditer(code):
            base = UVMF_BASE.search(match.group(2))
            if not base:
                continue
            end = re.search(r"\bendclass\b", code[match.end():])
            if not end:
                continue
            body_start = match.end()
            body = code[body_start:body_start + end.start()]
            class_line = code.count("\n", 0, match.start()) + 1
            body_line = code.count("\n", 0, body_start) + 1
            super_calls = []
            for call in SUPER_CALL.finditer(body):
                arity = argument_count(body, call.end() - 1)
                if arity >= 0:
                    super_calls.append(
                        {
                            "name": call.group(1),
                            "arity": arity,
                            "line": body_line + body.count("\n", 0, call.start()),
                        }
                    )
            classes.append(
                {
                    "source": relative,
                    "source_sha256": digest,
                    "line": class_line,
                    "class": match.group(1),
                    "base_class": base.group(1),
                    "methods": method_declarations(body, body_line),
                    "super_calls": super_calls,
                }
            )
        macro_counts = {}
        for match in re.finditer(r"`(uvm(?:f)?_[A-Za-z_]\w*)", code):
            name = match.group(1)
            macro_counts[name] = macro_counts.get(name, 0) + 1
        for name, count in sorted(macro_counts.items()):
            macros[(relative, name)] = {
                "source": relative,
                "source_sha256": digest,
                "name": name,
                "count": count,
            }
        for match in re.finditer(
            r"\$(test|value)\$plusargs\s*\(\s*\"([^\"]+)\"", code
        ):
            plusargs.append(
                {
                    "source": relative,
                    "source_sha256": digest,
                    "line": code.count("\n", 0, match.start()) + 1,
                    "kind": match.group(1),
                    "format": match.group(2),
                }
            )
    return {
        "class_extensions": classes,
        "uvm_macros": list(macros.values()),
        "runtime_plusargs": plusargs,
        "limitations": [
            "Method arity is a source-text count; macro-expanded declarations and compiler-resolved override relationships are not inferred.",
            "Class records include checked-in HDL under src; nested filelist expansion and per-unit transitive attribution are not performed.",
            "Runtime plusarg literals are source declarations; inherited simulator launch arguments are not included.",
        ],
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


def yaml_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("''", "'")
    if len(value) >= 2 and value[0] == value[-1] == '"':
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            pass
    return value


def test_yaml_configuration(root: Path, path: Path, category: str) -> dict[str, object]:
    fields: dict[str, tuple[str, int]] = {}
    runtime_plusargs = []
    warnings = []
    plusargs_declared = False
    in_plusargs = False

    for number, raw in enumerate(path.read_text(errors="replace").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if in_plusargs:
            item = re.match(r"^\s*-\s*(.*?)\s*$", raw)
            if item:
                value = yaml_scalar(item.group(1))
                if value.startswith("+"):
                    runtime_plusargs.append({"line": number, "value": value})
                else:
                    warnings.append({"line": number, "text": line})
                continue
            in_plusargs = False

        field = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*?)\s*$", raw)
        if not field:
            continue
        name, value = field.groups()
        value = value.split(" #", 1)[0].strip()
        if name == "plusargs":
            plusargs_declared = True
            if not value:
                in_plusargs = True
            elif value in {"[]", "null", "~"}:
                pass
            else:
                scalar = yaml_scalar(value)
                if scalar.startswith("+"):
                    runtime_plusargs.append({"line": number, "value": scalar})
                else:
                    warnings.append({"line": number, "text": line})
        elif name in {"testname", "seed"}:
            fields[name] = (yaml_scalar(value), number)

    return {
        "source": path.relative_to(root).as_posix(),
        "category": category,
        "testname": fields.get("testname", (None, None))[0],
        "testname_line": fields.get("testname", (None, None))[1],
        "seed": fields.get("seed", (None, None))[0],
        "seed_line": fields.get("seed", (None, None))[1],
        "runtime_plusargs_declared": plusargs_declared,
        "runtime_plusargs": runtime_plusargs,
        "parse_warnings": warnings,
    }


def filelist_evidence(
    root: Path,
    path: Path,
    provider_roots: dict[str, Path],
) -> dict[str, object]:
    provider_variables: set[str] = set()
    include_roots: set[str] = set()
    defines: set[str] = set()
    compile_options: set[str] = set()
    source_references = []
    symbolic_sources: set[str] = set()
    absent_sources: set[str] = set()
    imported_packages: set[str] = set()
    dpi_imports: set[str] = set()
    conditional_macros: set[str] = set()

    for raw in path.read_text(errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith(("#", "//", "/*")):
            continue
        provider_variables.update(re.findall(r"\$\{?([A-Z][A-Z0-9_]*)\}?", line))
        if line.startswith("+incdir+"):
            include_roots.update(value for value in line[8:].split("+") if value)
        elif line.startswith("+define+"):
            defines.update(value for value in line[8:].split("+") if value)
        elif line.startswith("+") or line.startswith(("-f", "-F")):
            compile_options.add(line)
        elif Path(line).suffix.lower() in HDL_SUFFIXES:
            source_references.append(line)
            resolved = line
            for name, provider_root in provider_roots.items():
                resolved = resolved.replace(f"${{{name}}}", str(provider_root))
                resolved = re.sub(rf"\${name}\b", str(provider_root), resolved)
            if re.search(r"\$\{?[A-Z][A-Z0-9_]*\}?", resolved):
                symbolic_sources.add(line)
                continue
            source = Path(resolved)
            if not source.is_absolute():
                source = root / source
            if not source.is_file():
                absent_sources.add(line)
                continue
            text = source.read_text(errors="replace")
            code = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.S)
            imported_packages.update(re.findall(r"\bimport\s+([A-Za-z_]\w*)\s*::", code))
            for declaration in re.findall(
                r'\bimport\s+"DPI-C"\s+(?:context\s+)?function\s+([^;]+);', code
            ):
                match = re.search(r"\b([A-Za-z_]\w*)\s*\(", declaration)
                if match:
                    dpi_imports.add(match.group(1))
            conditional_macros.update(
                re.findall(r"(?m)^\s*`(?:ifdef|ifndef|elsif)\s+([A-Za-z_]\w*)", code)
            )

    return {
        "provider_variables": sorted(provider_variables),
        "include_roots": sorted(include_roots),
        "defines": sorted(defines),
        "other_compile_options": sorted(compile_options),
        "hdl_file_reference_count": len(source_references),
        "imported_packages": sorted(imported_packages),
        "dpi_imports": sorted(dpi_imports),
        "conditional_macros": sorted(conditional_macros),
        "symbolic_source_references": sorted(symbolic_sources),
        "absent_source_references": sorted(absent_sources),
        "runtime_plusargs_status": "listed separately from test YAML; simulator expansion is unresolved",
    }


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
    provider_roots = {"CALIPTRA_ROOT": root} if label == "caliptra-rtl" else {}
    if label == "caliptra-rtl":
        provider_roots.update(
            {
                "ADAMSBRIDGE_ROOT": root / "submodules/adams-bridge",
                "CALIPTRA_PRIM_ROOT": root / "src/caliptra_prim",
            }
        )
    else:
        provider_roots["ADAMSBRIDGE_ROOT"] = root
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
            "test_yaml_configuration": [
                test_yaml_configuration(root, path, category)
                for category, paths in (
                    ("authored", authored_tests),
                    ("generated_uvmf", generated_tests),
                )
                for path in paths
            ],
            "unit_rtl_filelists": [
                {
                    **entry(root, path),
                    **(
                        filelist_evidence(root, path, provider_roots)
                        if census_entries is not None
                        else {}
                    ),
                }
                for path in unit_filelists
            ],
            "regression_path_references": regression_references,
        },
        "provider_variables": {
            name: sorted(paths) for name, paths in sorted(provider_variables.items())
        },
        "api_evidence": api_evidence,
        "uvmf_api_inventory": uvmf_api_inventory(root, files),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--caliptra-root", type=Path, required=True)
    parser.add_argument("--adams-root", type=Path, required=True)
    parser.add_argument("--unit-census-json", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    census = None
    census_artifact = None
    census_artifact_sha256 = None
    if args.unit_census_json:
        census_path = args.unit_census_json.resolve()
        census_input = json.loads(census_path.read_text())
        if "unit_census" in census_input:
            embedded = census_input["unit_census"]
            census = {
                "source_inventory_sha256": embedded["source_inventory_sha256"],
                "entries": embedded["entries"],
            }
            census_artifact = embedded["artifact"]
            census_artifact_sha256 = embedded["artifact_sha256"]
        else:
            census = census_input
            census_artifact = census_path.name
            census_artifact_sha256 = sha256(census_path)

    manifest = {
        "schema_version": 3,
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
            "Per-unit filelist details scan direct HDL references only; nested response files are not expanded.",
            "Test YAML records literal test names, seeds, and plusargs; simulator command inheritance and variable expansion are unresolved.",
            "Package imports, DPI imports, and conditional macros are textual source matches, not compiler-resolved dependencies.",
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
            "artifact": census_artifact,
            "artifact_sha256": census_artifact_sha256,
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
