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
    if len(params) != 1 or text.count(old) != 1:
        raise RuntimeError(f"expected one valid-sample parameter and one boundary condition; found {len(params)} and {text.count(old)}")
    name, value = params[0]
    if int(value) <= 0 or int(value) > 256:
        raise RuntimeError(f"invalid sample rate {name}={value}")
    replacement = f"if (data_valid_o && vld_coeff_ctr == 256 - {name}) begin"
    return text.replace(old, replacement, 1), replacement


def self_check() -> None:
    source = "parameter REJ_VLD_SAMPLES = 4;\nif (vld_coeff_ctr == 256) begin\n"
    fixed, line = fix_text(source)
    assert line == "if (data_valid_o && vld_coeff_ctr == 256 - REJ_VLD_SAMPLES) begin"
    assert fixed.count(line) == 1 and "if (vld_coeff_ctr == 256) begin" not in fixed
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
        if override is None:
            raise RuntimeError(f"no traced filelist override for {target}")
        trace_file = output / "overlays" / "m19_trace" / target
        trace_manifest_path = output / "m19_trace_manifest.json"
        if not trace_file.is_file() or not trace_manifest_path.is_file():
            raise RuntimeError(f"trace helper did not create the expected {trace_file}")
        trace_manifest = json.loads(trace_manifest_path.read_text())
        original = trace_file.read_bytes()
        fixed, replacement = fix_text(original.decode())
        trace_file.write_text(fixed)
        for entry in trace_manifest["files"]:
            if entry["path"].endswith("/" + target):
                entry["trace_sha256"] = digest(fixed.encode())
        trace_manifest["filelist"]["overlay_source_sha256"] = digest(fixed.encode())
        trace_manifest_path.write_text(json.dumps(trace_manifest, indent=2) + "\n")
        overlay_dir = output / "overlays" / "m19_queue_zeroize"
        overlay_dir.mkdir(parents=True, exist_ok=True)
        (overlay_dir / "overlay.json").write_text(json.dumps({
            "target": target,
            "staged_source": trace_manifest["files"][0]["path"],
            "staged_source_sha256": trace_manifest["files"][0]["source_sha256"],
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
