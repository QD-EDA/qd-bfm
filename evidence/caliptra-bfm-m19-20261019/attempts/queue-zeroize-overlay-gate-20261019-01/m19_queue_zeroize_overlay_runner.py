#!/usr/bin/env python3
"""Apply a testbench-only zeroize timing overlay before the existing M19 trace."""

import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fix_text(text: str) -> tuple[str, str]:
    params = re.findall(r"(?m)^\s*parameter\s+(\w+_VLD_SAMPLES)\s*=\s*(\d+)\s*;", text)
    old = "if (vld_coeff_ctr == 256) begin"
    if text.count(old) != 1:
        raise RuntimeError(f"expected one boundary condition; found {text.count(old)}")
    if len(params) == 1:
        name, value = params[0]
        if int(value) <= 0 or int(value) > 256:
            raise RuntimeError(f"invalid sample rate {name}={value}")
    elif not params:
        names = set(re.findall(r"\b(\w+_VLD_SAMPLES)\b", text))
        if len(names) != 1:
            raise RuntimeError(f"expected one imported valid-sample parameter, found {sorted(names)}")
        name = names.pop()
    else:
        raise RuntimeError(f"expected at most one valid-sample parameter, found {params}")
    replacement = f"if (data_valid_o && vld_coeff_ctr == 256 - {name}) begin"
    return text.replace(old, replacement, 1), replacement


def self_check() -> None:
    source = "parameter REJ_VLD_SAMPLES = 4;\nif (vld_coeff_ctr == 256) begin\n"
    fixed, line = fix_text(source)
    assert line == "if (data_valid_o && vld_coeff_ctr == 256 - REJ_VLD_SAMPLES) begin"
    assert fixed.count(line) == 1 and "if (vld_coeff_ctr == 256) begin" not in fixed
    imported = "import abr_params_pkg::*;\nlogic [EXP_VLD_SAMPLES-1:0] data_o;\nif (vld_coeff_ctr == 256) begin\n"
    assert fix_text(imported)[1] == "if (data_valid_o && vld_coeff_ctr == 256 - EXP_VLD_SAMPLES) begin"
    for bad in ("parameter REJ_VLD_SAMPLES = 4;\n", "parameter REJ_VLD_SAMPLES = 4;\nif (vld_coeff_ctr == 256) begin\nif (vld_coeff_ctr == 256) begin\n"):
        try:
            fix_text(bad)
        except RuntimeError:
            pass
        else:
            raise AssertionError("ambiguous or missing overlay anchor was accepted")


def main() -> int:
    self_check()
    helper_path = Path(__file__).with_name("m19_trace_runner.py")
    spec = importlib.util.spec_from_file_location("m19_trace_runner", helper_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load trace helper {helper_path}")
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    original_patch = helper.patch_sources

    def patch_with_zeroize_fix(output, mode, target, filelists, env):
        if mode != "queue" or env.get("M19_QUEUE_ZEROIZE_OVERLAY") != "1":
            raise RuntimeError("queue zeroize gate requires queue trace mode and explicit overlay enable")
        override = original_patch(output, mode, target, filelists, env)
        trace_manifest_path = output / "m19_trace_manifest.json"
        if not trace_manifest_path.is_file():
            raise RuntimeError(f"trace helper did not create {trace_manifest_path}")
        trace_manifest = json.loads(trace_manifest_path.read_text())
        if override is not None:
            trace_file = output / "overlays" / "m19_trace" / target
        else:
            source_paths = []
            for filelist in filelists:
                if not filelist.is_file():
                    continue
                for entry in filelist.read_text().splitlines():
                    if target not in entry or entry.lstrip().startswith(("#", "//", "+incdir+")):
                        continue
                    resolved = re.sub(r"\$\{([^}]+)\}", lambda m: env.get(m.group(1), m.group(0)), entry.strip())
                    candidate = Path(resolved)
                    if str(output) in str(candidate) and candidate.is_file():
                        source_paths.append(candidate)
            if len(source_paths) != 1:
                raise RuntimeError(f"expected one run-local filelist source for {target}, found {source_paths}")
            trace_file = source_paths[0]
        if not trace_file.is_file():
            raise RuntimeError(f"trace helper did not create the expected {trace_file}")
        original = trace_file.read_bytes()
        fixed, replacement = fix_text(original.decode())
        trace_file.write_text(fixed)
        existing_record = None
        for entry in trace_manifest["files"]:
            if entry["path"] == str(trace_file):
                entry["trace_sha256"] = digest(fixed.encode())
                existing_record = entry
        if existing_record is None:
            source_record = next((e for e in trace_manifest["files"] if e["path"].endswith("/" + target)), None)
            trace_manifest["files"].append({
                "path": str(trace_file),
                "source_sha256": source_record["source_sha256"] if source_record else "unknown",
                "trace_sha256": digest(fixed.encode()),
            })
        if trace_manifest["filelist"].get("overlay_source"):
            trace_manifest["filelist"]["overlay_source_sha256"] = digest(fixed.encode())
        trace_manifest_path.write_text(json.dumps(trace_manifest, indent=2) + "\n")
        overlay_dir = output / "overlays" / "m19_queue_zeroize"
        overlay_dir.mkdir(parents=True, exist_ok=True)
        (overlay_dir / "overlay.json").write_text(json.dumps({
            "target": target,
            "staged_source": trace_file.as_posix(),
            "staged_source_sha256": next((e["source_sha256"] for e in trace_manifest["files"] if e["path"] == str(trace_file)), "unknown"),
            "trace_source_sha256_before_fix": digest(original),
            "overlay_source_sha256": digest(fixed.encode()),
            "change": {"from": "if (vld_coeff_ctr == 256) begin", "to": replacement},
            "scope": "testbench stimulus timing only; expected queue, comparisons, data, DUT, and pass criteria are unchanged",
        }, indent=2) + "\n")
        return override

    helper.patch_sources = patch_with_zeroize_fix
    sys.argv[0] = str(helper_path)
    return helper.main()


if __name__ == "__main__":
    raise SystemExit(main())
