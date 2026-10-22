#!/usr/bin/env python3
"""Run one pinned M15 YAML test and save a uniform result record."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import platform
import re
import shutil
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path


CALIPTRA_PIN = "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e"
ADAMS_BRIDGE_PIN = "b77e3d899e828d626cfc2a0d26a6b5704cc121e0"
IVERILOG_PIN = "9b5fad2afb4104caa816b257d5bccc40f01b8c66"
IVERILOG_SHA256 = "6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288"
SOC_IFC_TB_PKG_SHA256 = "72f75561e1b88976ee2fe6f16de9eeac8f1f90bcace7baf7513a67ebe403feed"
BUTTERFLY_TB_SHA256 = "53c38240f13e9f353f5ae4a028d6087aa7aa15ba3fd2eb557a7505db7a899366"
NORM_CHECK_TB_SHA256 = "c4db6339c90d483ca9aeba06fd6fcc0c36a9b9670f73759e2980e879cd36582b"
DECOMPOSE_TB_SHA256 = "faf59075d99baaf2b32e81755324d89722a193177a7cbc51fd3fc037ee387317"
SKDECODE_TB_SHA256 = "f1a7866df738fa78eea4922ca2b11b992b7fd892f4c4f89db78b49e7af12c2ff"
SIGDECODE_H_TB_SHA256 = "2e740d001e807a2387ff6df860bd07fe12538ccd6de0e4fc82e30388f9f7888c"
SIGDECODE_Z_TB_SHA256 = "de917095eee8bff95a9f95336ab8a5452c5ed5e7dd8be4937919b7a5d853aa1c"
PKDECODE_TB_SHA256 = "28c74a0138673adb1f01d307bec384a392aa09786f81ee67059e84a6664399ad"
SKENCODE_TB_SHA256 = "91fbec03b602723fb2469653b7d7d307fe3613986873d607b592f5eebdeeb019"
PASS_MARKERS = ("* TESTCASE PASSED", "** TESTCASE PASSED")
FAIL_MARKERS = (
    "* TESTCASE FAILED", "** TESTCASE FAILED", "UVMF_SB_MISMATCH", "UVMF_SB_LEFTOVER",
    "Test failed at NTT operation", "Test failed at INTT operation",
    "Error: Output mismatch at index", "Decompose failed",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run_git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def stop_group(process: subprocess.Popen[bytes]) -> None:
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=10)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def run_logged(command: list[str], cwd: Path, env: dict[str, str], log: Path, timeout: int) -> tuple[int, bool]:
    log.parent.mkdir(parents=True, exist_ok=True)
    resource = log.with_suffix(".resource")
    timed = ["/usr/bin/time", "-v", "-o", str(resource), *command] if platform.system() == "Linux" else command
    (log.parent / (log.stem + ".command")).write_text(json.dumps(command) + "\n")
    with log.open("wb") as output:
        process = subprocess.Popen(
            timed, cwd=cwd, env=env, stdout=output, stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        try:
            return process.wait(timeout=timeout), False
        except subprocess.TimeoutExpired:
            stop_group(process)
            return 124, True


def classify(log_text: str, return_code: int) -> tuple[str, str]:
    if any(marker in log_text for marker in FAIL_MARKERS):
        return "FAIL", "testbench reported a failure or scoreboard mismatch"
    if re.search(r"UVM_ERROR\s*:\s*[1-9]\d*|UVM_FATAL\s*:\s*[1-9]\d*", log_text):
        return "FAIL", "UVM reported one or more errors or fatals"
    if return_code != 0:
        if re.search(r"(vvp|iverilog).*(internal error|unsupported|error:)", log_text, re.I):
            return "BLOCKED", f"simulator runtime error (exit {return_code})"
        return "FAIL", f"simulation exited with status {return_code}"
    suite_errors = re.search(r"(?m)^Total tests: [1-9]\d*, Errors: ([1-9]\d*)\r?$", log_text)
    if suite_errors:
        return "FAIL", "standalone test suite reported one or more errors"
    if re.search(r"(?m)^Total tests: [1-9]\d*, Errors: 0\r?\nPASS\r?\nAll tests completed\.$", log_text):
        return "PASS", "standalone test suite reported zero errors and completed"
    if return_code == 0 and "Ctrl test done" in log_text:
        if re.search(r"(?m)^ERROR:", log_text):
            return "FAIL", "norm_check completed with an error"
        return "PASS", "norm_check completed all checks without errors"
    if ("Decompose success" in log_text or "Decompose + usehint success" in log_text) and re.search(r"(?m)^ERROR:", log_text):
        return "FAIL", "decompose testbench reported an error"
    if return_code == 0 and "Decompose success" in log_text and "Decompose + usehint success" in log_text:
        return "PASS", "decompose sign and verify checks completed without errors"
    if any(marker in log_text for marker in PASS_MARKERS):
        return "PASS", "testbench pass marker present; no failure marker or UVM error/fatal"
    diagnostic = first_diagnostic(log_text)
    if diagnostic != "Icarus returned nonzero without a concise diagnostic":
        return "BLOCKED", diagnostic
    return "BLOCKED", "simulation ended without a recognized test pass marker"


def classify_sigdecode_h(log_text: str, return_code: int) -> tuple[str, str]:
    if re.search(r"(?m)^ERROR:|Sigdecode error\. Test failed!", log_text, re.I):
        return "FAIL", "sigdecode_h testbench reported an error"
    status, cause = classify(log_text, return_code)
    if status != "BLOCKED":
        return status, cause
    if return_code == 0 and re.search(r"(?m)^Test passed$", log_text):
        return "PASS", "sigdecode_h completed without scoreboard errors"
    return status, cause


def classify_sigdecode_z(log_text: str, return_code: int) -> tuple[str, str]:
    if re.search(r"ERROR:|FATAL:", log_text):
        return "FAIL", "sigdecode_z testbench reported an error"
    status, cause = classify(log_text, return_code)
    if status != "BLOCKED":
        return status, cause
    if (
        return_code == 0
        and log_text.count("Checking output data") == 2
        and log_text.count("Test completed") == 2
        and "$finish called at " in log_text
    ):
        return "PASS", "both sigdecode_z comparisons completed without errors"
    return status, cause


def classify_pkdecode(log_text: str, return_code: int) -> tuple[str, str]:
    status, cause = classify(log_text, return_code)
    if status != "BLOCKED":
        return status, cause
    if (
        return_code == 0
        and log_text.count("Starting pkdecode test") == 2
        and log_text.count("Checking output data") == 2
        and log_text.count("Test completed") == 2
        and "$finish called at " in log_text
    ):
        return "PASS", "both PKDecode comparisons completed without mismatches"
    return status, cause


def classify_skencode(log_text: str, return_code: int) -> tuple[str, str]:
    if "Error: Error flag should have been asserted" in log_text:
        return "FAIL", "skencode negative-case error flag was not asserted"
    status, cause = classify(log_text, return_code)
    if status != "BLOCKED":
        return status, cause
    if (
        return_code == 0
        and log_text.count("Starting skencode test\n") == 2
        and log_text.count("Starting skencode error test") == 1
        and log_text.count("Starting skencode test again") == 1
        and log_text.count("Checking output data") == 3
        and log_text.count("Test completed") == 3
        and "$finish called at " in log_text
    ):
        return "PASS", "all skencode comparisons and the expected-error check completed"
    return status, cause


def first_diagnostic(log_text: str) -> str:
    for line in log_text.splitlines():
        if re.search(r"(error:|fatal:|sorry:|syntax error|could not open|No such file|include file .* not found)", line, re.I):
            return line.strip()[:500]
    return "Icarus returned nonzero without a concise diagnostic"


def stage_test_vectors(source_dir: Path, runtime: Path) -> None:
    vectors = source_dir / "test_vectors"
    if vectors.is_dir():
        shutil.copytree(vectors, runtime, dirs_exist_ok=True)


def prepare_python_alias(runtime: Path, env: dict[str, str]) -> None:
    python3 = shutil.which("python3", path=env.get("PATH"))
    if python3 is None:
        raise RuntimeError("testbench requires python3, but it is not on PATH")
    alias = runtime / "python"
    if alias.exists() or alias.is_symlink():
        raise RuntimeError(f"refusing to overwrite runtime path: {alias}")
    alias.symlink_to(python3)
    env["PATH"] = str(runtime) + os.pathsep + env.get("PATH", "")


def include_dirs_for_area(area: str, root: Path) -> list[Path]:
    relative = {
        "norm_check": ("src/abr_libs/rtl",),
        "decompose": ("src/abr_prim/rtl", "src/abr_libs/rtl"),
    }.get(area, ())
    return [root / path for path in relative]


def fix_norm_check_mem_addr_width(source_text: str) -> str:
    source = "MLDSA_MEM_ADDR_WIDTH"
    if source_text.count(source) != 3:
        raise RuntimeError("expected 3 undefined norm_check address-width references")
    return source_text.replace(source, "ABR_MEM_ADDR_WIDTH")


def fix_skdecode_tb(source_text: str) -> str:
    source = "MLDSA_MEM_ADDR_WIDTH"
    if source_text.count(source) != 2:
        raise RuntimeError("expected 2 undefined skdecode address-width references")
    b_port_block = (
        "        if (keymem_b_rd_req_tb.rd_wr_en == RW_READ)\n"
        "            keymem_b_data_tb <= s1_array_tb[keymem_b_rd_req_tb.addr];"
    )
    if source_text.count(b_port_block) != 1:
        raise RuntimeError("expected one B-port error injection block")
    replacement = (
        "        if (keymem_b_rd_req_tb.rd_wr_en == RW_READ) begin\n"
        "            if (rand_address == keymem_b_rd_req_tb.addr)\n"
        "                keymem_b_data_tb <= $urandom_range(5,7);\n"
        "            else\n"
        "                keymem_b_data_tb <= s1_array_tb[keymem_b_rd_req_tb.addr];\n"
        "        end"
    )
    return source_text.replace(source, "ABR_MEM_ADDR_WIDTH").replace(b_port_block, replacement)


def fix_sigdecode_h_tb(source_text: str) -> str:
    source = "MLDSA_MEM_ADDR_WIDTH"
    if source_text.count(source) != 1:
        raise RuntimeError("expected 1 undefined sigdecode_h address-width reference")
    return source_text.replace(source, "ABR_MEM_ADDR_WIDTH")


def fix_sigdecode_z_tb(source_text: str) -> str:
    if source_text.count("MLDSA_MEM_ADDR_WIDTH") != 1:
        raise RuntimeError("expected one MLDSA_MEM_ADDR_WIDTH occurrence")
    calls = {
        "sigdecode_z_test('h0,'h0);": "sigdecode_z_test('h0);",
        "sigdecode_z_test('h40, 'h20);": "sigdecode_z_test('h20);",
    }
    if any(source_text.count(source) != 1 for source in calls):
        raise RuntimeError("expected the two pinned sigdecode_z task calls")
    for source, replacement in calls.items():
        source_text = source_text.replace(source, replacement)
    return source_text.replace("MLDSA_MEM_ADDR_WIDTH", "ABR_MEM_ADDR_WIDTH")


def fix_pkdecode_tb(source_text: str) -> str:
    replacements = (
        ("parameter MEM_ADDR_WIDTH = MLDSA_MEM_ADDR_WIDTH,", "parameter MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH,"),
        ("    .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),\n", ""),
        ("pkdecode_test('h40, 'h20);", "pkdecode_test('h40, 'h0);"),
    )
    if any(source_text.count(source) != 1 for source, _ in replacements):
        raise RuntimeError("expected one pinned PKDecode width, stale parameter, and address pair")
    for source, replacement in replacements:
        source_text = source_text.replace(source, replacement)
    return source_text


def fix_skencode_tb(source_text: str) -> str:
    width = "parameter MEM_ADDR_WIDTH = MLDSA_MEM_ADDR_WIDTH,"
    ports = "    .skencode_done(skencode_done_tb),\n    .skencode_error(skencode_error_tb)\n);"
    if source_text.count(width) != 1 or source_text.count(ports) != 1:
        raise RuntimeError("expected one pinned skencode width and obsolete error port")
    return source_text.replace(width, "parameter MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH,").replace(
        ports,
        "    .skencode_done(skencode_done_tb)\n);\n\nassign skencode_error_tb = dut.error_flag;",
    )


def fix_decompose_tb(source_text: str) -> str:
    source = "MLDSA_MEM_ADDR_WIDTH"
    if source_text.count(source) != 1:
        raise RuntimeError("expected 1 undefined decompose address-width reference")
    port_block = "    .decompose_done(),\n    .w1_encode_done()\n);"
    if source_text.count(port_block) != 1:
        raise RuntimeError("expected 1 stale decompose w1_encode_done connection")
    return source_text.replace(source, "ABR_MEM_ADDR_WIDTH").replace(
        port_block, "    .decompose_done()\n);"
    )


def fix_soc_ifc_dict_initializers(source_text: str) -> str:
    anchor = "[string] = {"
    if source_text.count(anchor) != 8:
        raise RuntimeError(f"expected 8 pinned SoC-IFC string maps, found {source_text.count(anchor)}")
    return source_text.replace(anchor, "[string] = '{")


def fix_butterfly_expected_vector(source_text: str) -> str:
    source = '$readmemh("kyber_stage0_out.hex", in_val);'
    if source_text.count(source) != 1:
        raise RuntimeError("expected one pinned butterfly expected-vector load into in_val")
    return source_text.replace(source, '$readmemh("kyber_stage0_out.hex", out_val);')


def fix_csrng_tb_filelist(source_text: str) -> str:
    package = "${CALIPTRA_ROOT}/src/caliptra_prim/rtl/caliptra_prim_ram_1p_pkg.sv\n"
    ram = "${CALIPTRA_PRIM_ROOT}/rtl/${CALIPTRA_PRIM_MODULE_PREFIX}_ram_1p.sv\n"
    incdir = "+incdir+${CALIPTRA_ROOT}/src/integration/rtl\n"
    reg_incdir = "+incdir+${CALIPTRA_ROOT}/src/integration/rtl/caliptra_reg\n"
    if (
        source_text.count(package) != 1
        or source_text.count(ram) != 1
        or source_text.count(incdir) != 1
        or reg_incdir in source_text
    ):
        raise RuntimeError("expected one CSRNG RAM package entry and one generic RAM source entry")
    if source_text.index(package) < source_text.index(ram):
        raise RuntimeError("expected the CSRNG RAM package after the generic RAM source")
    source_text = source_text.replace(incdir, incdir + reg_incdir)
    return source_text.replace(package, "").replace(ram, package + ram)


def _replace_mldsa_source_once(source_text: str, source: str, replacement: str) -> str:
    if source_text.count(source) != 1 or source_text.count(replacement) != 0:
        raise RuntimeError(f"expected one unmodified MLDSA source snippet: {source}")
    return source_text.replace(source, replacement, 1)


def fix_mldsa_env_configuration(source_text: str) -> str:
    source_text = _replace_mldsa_source_once(
        source_text,
        "qvip_ahb_lite_slave_subenv_config.convert2string",
        "qvip_ahb_lite_slave_subenv_config.convert2string()",
    )
    source_text = _replace_mldsa_source_once(
        source_text,
        "qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];",
        "qvip_ahb_lite_slave_subenv_interface_names[0] = interface_names[0];",
    )
    return _replace_mldsa_source_once(
        source_text,
        "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];",
        "qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];",
    )


def fix_mldsa_config_rm_access(source_text: str, target: str) -> str:
    source = f"{target} = configuration.mldsa_rm;"
    replacement = (
        "begin\n"
        "      mldsa_env_configuration mldsa_config_local;\n"
        "      mldsa_config_local = configuration;\n"
        f"      {target} = mldsa_config_local.mldsa_rm;\n"
        "    end"
    )
    return _replace_mldsa_source_once(source_text, source, replacement)


def fix_mldsa_substr(source_text: str) -> str:
    return _replace_mldsa_source_once(
        source_text,
        "line = line.substr(8);",
        'if (line.len() <= 8) line = "";\n        else line = line.substr(8, line.len() - 1);',
    )


def fix_mldsa_ahb_transfer_types(source_text: str, expected_count: int) -> str:
    parameters = (
        "ahb_lite_slave_0_params::AHB_NUM_MASTERS",
        "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS",
        "ahb_lite_slave_0_params::AHB_NUM_SLAVES",
        "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH",
        "ahb_lite_slave_0_params::AHB_WDATA_WIDTH",
        "ahb_lite_slave_0_params::AHB_RDATA_WIDTH",
    )
    pattern = r"ahb_master_burst_transfer\s*#\(\s*" + r"\s*,\s*".join(
        re.escape(parameter) for parameter in parameters
    ) + r"\s*\)\s*(\w+)(\s*\[\s*\$\s*\])?\s*;"
    source_text, replacements = re.subn(
        pattern,
        r"ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer \1\2;",
        source_text,
    )
    if replacements != expected_count:
        raise RuntimeError(f"expected {expected_count} generated MLDSA AHB transfer types")
    return source_text


def fix_mldsa_predictor(source_text: str) -> str:
    source_text = fix_mldsa_config_rm_access(source_text, "p_mldsa_rm")
    source_text = fix_mldsa_substr(source_text)
    return fix_mldsa_ahb_transfer_types(source_text, 2)


def fix_mldsa_scoreboard(source_text: str) -> str:
    source_text = fix_mldsa_config_rm_access(source_text, "scbr_mldsa_rm")
    return fix_mldsa_ahb_transfer_types(source_text, 6)


def fix_mldsa_kem_fatals(source_text: str) -> str:
    source = '$fatal("'
    if source_text.count(source) != 6:
        raise RuntimeError("expected six ML-KEM fatal calls without a finish number")
    return source_text.replace(source, '$fatal(1, "')


def fix_mldsa_reg_model_endian(source_text: str) -> str:
    class_start = re.compile(r"(?m)^[ \t]*class abr_reg extends uvm_reg_block;[ \t]*$")
    class_end = re.compile(r"(?m)^[ \t]*endclass : abr_reg[ \t]*$")
    no_endian_map = 'this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);'
    starts = list(class_start.finditer(source_text))
    ends = list(class_end.finditer(source_text))
    if len(starts) != 1 or len(ends) != 1 or ends[0].start() < starts[0].end():
        raise RuntimeError("expected one abr_reg class in the pinned RAL source")
    start = starts[0].start()
    end = ends[0].start()
    block = source_text[start:end]
    if block.count(no_endian_map) != 1:
        raise RuntimeError("expected one no-endian top-level abr_reg map")
    block = block.replace(no_endian_map, no_endian_map.replace("UVM_NO_ENDIAN", "UVM_LITTLE_ENDIAN"), 1)
    return source_text[:start] + block + source_text[end:]


def prepare_mldsa_native_model(
    root: Path, repo: Path, output: Path, runtime: Path, env: dict[str, str], deadline: float
) -> Path:
    source = root / "src/abr_top/uvmf/Dilithium_ref/dilithium/ref"
    model = output / "native-models/dilithium-ref"
    model.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source, model)
    source_test = source / "test/test_dilithium.c"
    model_test = model / "test/test_dilithium.c"
    binary = model / "test/test_dilithium5"
    binary.unlink(missing_ok=True)
    stage_script = repo / "dv/caliptra_bfm/native_vectors/stage_mldsa.py"
    check_script = repo / "dv/caliptra_bfm/native_vectors/check_native_mldsa.py"
    compiler = shutil.which("cc", path=env.get("PATH"))
    make = shutil.which("make", path=env.get("PATH"))
    if compiler is None or make is None:
        raise RuntimeError("MLDSA reference model setup requires cc and make")
    commands = [
        [sys.executable, str(stage_script), str(source_test), str(model_test)],
        [make, "-C", str(model), f"CC={compiler}", "test/test_dilithium5"],
        [sys.executable, str(check_script), str(root), str(binary)],
    ]
    logs = []
    for name, command in zip(("stage.log", "build.log", "check.log"), commands):
        log = output / "native-models" / name
        code, timed_out = run_logged(
            command, model, env, log, max(0, int(deadline - time.monotonic()))
        )
        logs.append({"command": command, "log": str(log), "exit": code, "timed_out": timed_out})
        if code or timed_out:
            raise RuntimeError(f"MLDSA reference model {name} failed; see {log}")

    runtime_binary = runtime / "test_dilithium5"
    shutil.copy2(binary, runtime_binary)
    manifest = output / "overlays/mldsa-native-model.json"
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(json.dumps({
        "source_test": str(source_test), "source_test_sha256": sha256(source_test),
        "staged_test_sha256": sha256(model_test), "stage_script": str(stage_script),
        "stage_script_sha256": sha256(stage_script), "check_script": str(check_script),
        "check_script_sha256": sha256(check_script), "build_logs": logs,
        "binary": str(runtime_binary), "binary_sha256": sha256(runtime_binary),
        "scope": "testbench setup only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return manifest


def prepare_m16_mldsa_icarus_overlays(
    filelist: Path, root: Path, output: Path
) -> tuple[Path, Path]:
    env_pkg = root / "src/abr_top/uvmf/uvmf_template_output/verification_ip/environment_packages/mldsa_env_pkg"
    sequences = root / "src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/sequences"
    overlay_root = output / "overlays/mldsa_icarus"
    files = (
        (
            env_pkg / "src/mldsa_env_configuration.svh",
            "mldsa_env_pkg/src/mldsa_env_configuration.svh",
            fix_mldsa_env_configuration,
        ),
        (
            env_pkg / "src/mldsa_predictor.svh",
            "mldsa_env_pkg/src/mldsa_predictor.svh",
            fix_mldsa_predictor,
        ),
        (
            env_pkg / "src/mldsa_scoreboard.svh",
            "mldsa_env_pkg/src/mldsa_scoreboard.svh",
            fix_mldsa_scoreboard,
        ),
        (
            sequences / "src/mldsa_bench_sequence_base.svh",
            "mldsa_sequences/src/mldsa_bench_sequence_base.svh",
            fix_mldsa_substr,
        ),
        (
            sequences / "src/ML_KEM_base_sequence.svh",
            "mldsa_sequences/src/ML_KEM_base_sequence.svh",
            fix_mldsa_kem_fatals,
        ),
        (
            root / "src/abr_top/rtl/abr_reg_uvm.sv",
            "abr_top/rtl/abr_reg_uvm.sv",
            fix_mldsa_reg_model_endian,
        ),
    )
    manifest_files = []
    for source, relative_overlay, transform in files:
        overlay = overlay_root / relative_overlay
        overlay.parent.mkdir(parents=True, exist_ok=True)
        overlay.write_text(transform(source.read_text()))
        manifest_files.append({
            "source": str(source), "source_sha256": sha256(source),
            "overlay": str(overlay), "overlay_sha256": sha256(overlay),
        })

    env_incdir = f"+incdir+{overlay_root / 'mldsa_env_pkg'}"
    sequence_incdir = f"+incdir+{overlay_root / 'mldsa_sequences'}"
    env_marker = "+incdir+${ADAMSBRIDGE_ROOT}/src/abr_top/uvmf/uvmf_template_output/verification_ip/environment_packages/mldsa_env_pkg\n"
    sequence_marker = "+incdir+${ADAMSBRIDGE_ROOT}/src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/sequences\n"
    ral_marker = "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_reg_uvm.sv\n"
    source_text = filelist.read_text()
    if (
        source_text.count(env_marker) != 1
        or source_text.count(sequence_marker) != 1
        or source_text.count(ral_marker) != 1
        or env_incdir in source_text
        or sequence_incdir in source_text
    ):
        raise RuntimeError("expected pinned MLDSA include directories and RAL source")
    source_filelist = filelist
    source_filelist_sha256 = sha256(source_filelist)
    source_text = source_text.replace(env_marker, env_incdir + "\n" + env_marker, 1)
    source_text = source_text.replace(sequence_marker, sequence_incdir + "\n" + sequence_marker, 1)
    source_text = source_text.replace(ral_marker, str(overlay_root / "abr_top/rtl/abr_reg_uvm.sv") + "\n", 1)
    filelist = output / "overlays/mldsa-ahb-open-mvc-icarus.vf"
    filelist.write_text(source_text)
    manifest = output / "overlays/mldsa-icarus-compat.json"
    manifest.write_text(json.dumps({
        "source_filelist": str(source_filelist), "source_filelist_sha256": source_filelist_sha256,
        "overlay_filelist": str(filelist), "overlay_filelist_sha256": sha256(filelist),
        "files": manifest_files,
        "compile_defines": ["CALIPTRA_BFM_AHB_32BIT"],
        "reason": "compile the generated 32-bit AHB environment at its declared width, rewrite unsupported testbench constructs, and specify little-endian RAL access without changing transactions or checks",
        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return filelist, manifest


def prepare_m16_ahb_open_mvc_filelist(
    filelist: Path, repo: Path, output: Path, component_id: str
) -> tuple[Path, Path]:
    source_text = filelist.read_text()
    required = (
        "${QUESTA_MVC_HOME}/include/questa_mvc_svapi.svh",
        "${QUESTA_MVC_HOME}/questa_mvc_src/sv/mvc_pkg.sv",
        "${UVMF_HOME}/uvmf_base_pkg/uvmf_base_pkg.sv",
        "qvip_ahb_lite_slave_dir/uvmf/qvip_ahb_lite_slave_pkg.sv",
    )
    if any(source_text.count(marker) != 1 for marker in required):
        raise RuntimeError(f"pinned {component_id} filelist no longer has the expected MVC/UVMF/QVIP entries")

    support_filelist = repo / "dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f"
    support_sources = []
    for entry in support_filelist.read_text().splitlines():
        entry = entry.strip()
        if not entry or entry.startswith("#"):
            continue
        source = (repo / entry).resolve()
        if not source.is_file():
            raise RuntimeError(f"missing QD-BFM MVC support source: {source}")
        support_sources.append(str(source))
    for suffix in (
        "caliptra_ahb_mvc_compat_pkg.sv", "caliptra_ahb_qvip_compat_pkg.sv",
        "ahb_lite_caliptra_qvip_hdl.sv", "uvmf_base_pkg.sv",
    ):
        if not any(source.endswith(suffix) for source in support_sources):
            raise RuntimeError(f"QD-BFM MVC support filelist omits {suffix}")

    lines = source_text.splitlines()
    marker_index = next(i for i, line in enumerate(lines) if required[0] in line)
    external_paths = ("QUESTA_MVC_HOME", "UVMF_HOME", "qvip_ahb_lite_slave_dir/")
    counts = {path: sum(path in line for line in lines) for path in external_paths}
    if any(count == 0 for count in counts.values()):
        raise RuntimeError(f"expected external MVC/UVMF/QVIP paths are missing: {counts}")

    overlay_lines = []
    for i, line in enumerate(lines):
        if i == marker_index:
            overlay_lines.extend(support_sources)
        if not any(path in line for path in external_paths):
            overlay_lines.append(line)
    if any(path in line for line in overlay_lines for path in external_paths):
        raise RuntimeError("open MVC filelist still contains a removed external dependency")

    overlay_dir = output / "overlays"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    overlay = overlay_dir / f"{component_id}-ahb-open-mvc.vf"
    overlay.write_text("\n".join(overlay_lines) + "\n")
    manifest = overlay_dir / f"{component_id}-ahb-open-mvc.json"
    manifest.write_text(json.dumps({
        "source_filelist": str(filelist), "source_sha256": sha256(filelist),
        "overlay_filelist": str(overlay), "overlay_sha256": sha256(overlay),
        "support_filelist": str(support_filelist), "support_filelist_sha256": sha256(support_filelist),
        "support_sources": [{"path": source, "sha256": sha256(Path(source))} for source in support_sources],
        "removed_entry_counts": counts,
        "scope": "testbench, BFM, filelist, and setup only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return overlay, manifest


def root_for(repo_name: str, caliptra: Path) -> Path:
    return caliptra if repo_name == "caliptra" else caliptra / "submodules/adams-bridge"


def find_top(root: Path, top: str) -> Path | None:
    matches = list(root.glob(f"src/**/tb/{top}.sv"))
    return matches[0] if len(matches) == 1 else None


def needs_m16_open_mvc_filelist(row: dict[str, str]) -> bool:
    return row["test_kind"] == "generated-uvmf" and row["environment_id"] in (
        "uvmf-caliptra_top", "uvmf-kv", "uvmf-mldsa", "uvmf-pv", "uvmf-soc_ifc", "uvmf-sha512"
    )


def main() -> int:
    repo = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=repo)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--row-id", type=int, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--timeout", type=int, default=3600)
    args = parser.parse_args()
    repo = args.repo_root.resolve()
    manifest = args.manifest.resolve()
    output = args.output_dir.resolve()
    rows = list(csv.DictReader(manifest.open(), delimiter="\t"))
    matches = [row for row in rows if int(row["row_id"]) == args.row_id]
    if len(matches) != 1:
        raise SystemExit(f"expected one row_id={args.row_id} in {manifest}")
    row = matches[0]
    output.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    deadline = started + args.timeout
    result: dict[str, object] = {
        "row_id": args.row_id, "testname": row["testname"],
        "source_repo": row["source_repo"], "source_file": row["source_file"],
        "source_pin": row["source_pin"], "source_yaml_sha256": row["source_yaml_sha256"],
        "environment_id": row["environment_id"], "runner_profile": row["runner_profile"],
        "filelist": row["filelist"], "filelist_sha256_json": row["filelist_sha256_json"],
        "run_plusargs": json.loads(row["run_plusargs_json"]),
        "host": socket.gethostname(), "platform": platform.platform(),
        "slurm_job_id": os.environ.get("SLURM_JOB_ID", "local"),
        "slurm_array_task_id": os.environ.get("SLURM_ARRAY_TASK_ID", "local"),
        "timeout_seconds": args.timeout,
    }
    try:
        caliptra = Path(os.environ.get("CALIPTRA_ROOT", "/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl")).resolve()
        root = root_for(row["source_repo"], caliptra)
        expected_pin = CALIPTRA_PIN if row["source_repo"] == "caliptra" else ADAMS_BRIDGE_PIN
        actual_pin = run_git(root, "rev-parse", "HEAD")
        if actual_pin != expected_pin or row["source_pin"] != expected_pin:
            raise RuntimeError(f"source pin mismatch: expected {expected_pin}, found {actual_pin}")
        if run_git(root, "status", "--porcelain", "--untracked-files=normal"):
            raise RuntimeError(f"refusing dirty pinned source checkout: {root}")
        yaml_path = root / row["source_file"]
        if sha256(yaml_path) != row["source_yaml_sha256"]:
            raise RuntimeError(f"source YAML hash mismatch: {yaml_path}")
        for relative, expected in json.loads(row["filelist_sha256_json"]).items():
            if sha256(root / relative) != expected:
                raise RuntimeError(f"filelist hash mismatch: {relative}")

        iverilog = Path(os.environ.get("IVERILOG_BIN", "/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog")).resolve()
        vvp = Path(os.environ.get("VVP_BIN", str(iverilog.with_name("vvp")))).resolve()
        if sha256(iverilog) != IVERILOG_SHA256:
            raise RuntimeError(f"Icarus binary hash mismatch: {sha256(iverilog)}")
        result["iverilog"] = subprocess.check_output([str(iverilog), "-V"], text=True, stderr=subprocess.STDOUT).splitlines()[0]
        result["vvp"] = subprocess.check_output([str(vvp), "-V"], text=True, stderr=subprocess.STDOUT).splitlines()[0]
        result["iverilog_source_pin"] = IVERILOG_PIN
        result["iverilog_binary_sha256"] = sha256(iverilog)
        env = os.environ.copy()
        env.update({
            "CALIPTRA_ROOT": str(caliptra),
            "CALIPTRA_PRIM_ROOT": str(caliptra / "src/caliptra_prim_generic"),
            "CALIPTRA_PRIM_MODULE_PREFIX": "caliptra_prim_generic",
            "CALIPTRA_AXI4PC_DIR": str(caliptra / "src/integration/tb"),
            "ADAMSBRIDGE_ROOT": str(caliptra / "submodules/adams-bridge"),
            "UVM_HOME": str(iverilog.parent.parent / "lib/ivl/uvm"),
            "IVERILOG_BIN": str(iverilog), "VVP_BIN": str(vvp),
            "PATH": str(iverilog.parent) + os.pathsep + env.get("PATH", ""),
        })
        env["LD_LIBRARY_PATH"] = os.pathsep.join(filter(None, [
            str(iverilog.parent.parent / "lib"), str(iverilog.parent.parent / "lib64"),
            "/usr/lib/x86_64-linux-gnu", env.get("LD_LIBRARY_PATH", ""),
        ]))
        plusargs = [arg.replace("${CALIPTRA_ROOT}", str(caliptra)).replace("${ADAMSBRIDGE_ROOT}", str(caliptra / "submodules/adams-bridge")) for arg in result["run_plusargs"]]
        if row["runner_profile"] == "compile-yaml-unresolved":
            result.update(status="BLOCKED", cause="upstream UART compile.yml has no Icarus filelist/setup")
        elif row["testname"] == "HMAC_otf_reset_test":
            script = repo / "dv/caliptra_bfm/uvmf_lite/tests/run_generated_hmac_runtime.sh"
            hmac_dir = output / "hmac"
            env.update({
                "CALIPTRA_BFM_HMAC_TESTNAME": row["testname"],
                "CALIPTRA_BFM_HMAC_SEED": str(row["selected_seed"]),
                "CALIPTRA_BFM_HMAC_RUN_DIR": str(hmac_dir),
            })
            rc, timed_out = run_logged(["/bin/sh", str(script)], repo, env, output / "runner.log", max(0, int(deadline - time.monotonic())))
            result["runner_exit"] = rc
            result["runner_timed_out"] = timed_out
            sim_log = hmac_dir / "run.log"
            log_text = sim_log.read_text(errors="replace") if sim_log.exists() else (output / "runner.log").read_text(errors="replace")
            if timed_out:
                result.update(status="TIMEOUT", cause="HMAC compile/runtime exceeded per-row timeout")
            elif rc != 0 and not sim_log.exists():
                compile_log = hmac_dir / "compile.log"
                diagnostic = first_diagnostic(compile_log.read_text(errors="replace")) if compile_log.exists() else first_diagnostic(log_text)
                result.update(status="BLOCKED", cause=diagnostic)
            else:
                status, cause = classify(log_text, rc)
                result.update(status=status, cause=cause)
            result["compile_exit"] = 0 if sim_log.exists() else (1 if (hmac_dir / "compile.log").exists() else None)
            result["sim_exit"] = rc if sim_log.exists() else None
            result["compile_log"] = str(hmac_dir / "compile.log")
            result["sim_log"] = str(sim_log)
        else:
            top_file = find_top(root, row["top"])
            if row["runner_profile"] == "m7-component" and top_file is None:
                result.update(status="BLOCKED", cause=f"no unique source testbench found for top {row['top']}")
            else:
                runtime = output / "runtime"
                source_dir = top_file.parent if top_file else Path(row["hdl_filelist"])
                if top_file:
                    shutil.copytree(source_dir, runtime, dirs_exist_ok=True)
                else:
                    runtime.mkdir(exist_ok=True)
                if row["area"] == "ntt_top":
                    stage_test_vectors(source_dir, runtime)
                if row["area"] == "rej_bounded":
                    prepare_python_alias(runtime, env)
                if row["testname"] == "ML_DSA_randomized_early_run_test":
                    native_model_manifest = prepare_mldsa_native_model(
                        root, repo, output, runtime, env, deadline
                    )
                    result["mldsa_native_model_manifest"] = str(native_model_manifest)
                filelist = root / row["filelist"]
                if needs_m16_open_mvc_filelist(row):
                    component_id = row["environment_id"].replace("uvmf-", "")
                    filelist, overlay_manifest = prepare_m16_ahb_open_mvc_filelist(
                        filelist, repo, output, component_id
                    )
                    result["overlay_manifest"] = str(overlay_manifest)
                    if row["environment_id"] == "uvmf-mldsa":
                        filelist, mldsa_manifest = prepare_m16_mldsa_icarus_overlays(
                            filelist, root, output
                        )
                        result["mldsa_icarus_overlay_manifest"] = str(mldsa_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-pkdecode_tb":
                    source = root / "src/pk_decode/tb/pkdecode_tb.sv"
                    if sha256(source) != PKDECODE_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed pkdecode testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "pkdecode_tb.sv"
                    overlay.write_text(fix_pkdecode_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/pk_decode/tb/pkdecode_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned pkdecode filelist source entry changed")
                    overlay_filelist = overlay_dir / "pkdecode_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "pkdecode_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": PKDECODE_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "use the exported address width, drop the unsupported DUT parameter, and separate the second source and destination regions",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-skencode_tb":
                    source = root / "src/sk_encode/tb/skencode_tb.sv"
                    if sha256(source) != SKENCODE_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed skencode testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "skencode_tb.sv"
                    overlay.write_text(fix_skencode_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/sk_encode/tb/skencode_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned skencode filelist source entry changed")
                    overlay_filelist = overlay_dir / "skencode_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "skencode_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": SKENCODE_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "use the exported address width and preserve the existing negative-case check through the DUT error flag",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-skdecode_tb":
                    source = root / "src/sk_decode/tb/skdecode_tb.sv"
                    if sha256(source) != SKDECODE_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed skdecode testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "skdecode_tb.sv"
                    overlay.write_text(fix_skdecode_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/sk_decode/tb/skdecode_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned skdecode filelist source entry changed")
                    overlay_filelist = overlay_dir / "skdecode_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "skdecode_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": SKDECODE_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "use the exported address width and inject the negative-case value on either memory port",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-sigdecode_h_tb":
                    source = root / "src/sigdecode_h/tb/sigdecode_h_tb.sv"
                    if sha256(source) != SIGDECODE_H_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed sigdecode_h testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "sigdecode_h_tb.sv"
                    overlay.write_text(fix_sigdecode_h_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/sigdecode_h/tb/sigdecode_h_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned sigdecode_h filelist source entry changed")
                    overlay_filelist = overlay_dir / "sigdecode_h_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "sigdecode_h_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": SIGDECODE_H_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "use the address-width parameter exported by abr_params_pkg",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-sigdecode_z_tb":
                    source = root / "src/sig_decode_z/tb/sigdecode_z_tb.sv"
                    if sha256(source) != SIGDECODE_Z_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed sigdecode_z testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "sigdecode_z_tb.sv"
                    overlay.write_text(fix_sigdecode_z_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/sig_decode_z/tb/sigdecode_z_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned sigdecode_z filelist source entry changed")
                    overlay_filelist = overlay_dir / "sigdecode_z_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "sigdecode_z_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": SIGDECODE_Z_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "use the exported address width and remove the obsolete unused task arguments",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-norm_check_tb":
                    source = root / "src/norm_check/tb/norm_check_tb.sv"
                    if sha256(source) != NORM_CHECK_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed norm_check testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(exist_ok=True)
                    overlay = overlay_dir / "norm_check_tb.sv"
                    overlay.write_text(fix_norm_check_mem_addr_width(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/norm_check/tb/norm_check_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned norm_check filelist source entry changed")
                    overlay_filelist = overlay_dir / "norm_check_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "norm_check_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": NORM_CHECK_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "use the address-width parameter exported by abr_params_pkg",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-decompose_tb":
                    source = root / "src/decompose/tb/decompose_tb.sv"
                    if sha256(source) != DECOMPOSE_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed decompose testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "decompose_tb.sv"
                    overlay.write_text(fix_decompose_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/decompose/tb/decompose_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned decompose filelist source entry changed")
                    overlay_filelist = overlay_dir / "decompose_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "decompose_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": DECOMPOSE_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "use the package address width and remove the stale decompose port connection",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-butterfly_top_tb":
                    source = top_file
                    if sha256(source) != BUTTERFLY_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed butterfly testbench source: {source}")
                    # The pinned testbench reads expected results back into its input array.
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(exist_ok=True)
                    overlay = overlay_dir / "butterfly_top_tb.sv"
                    overlay.write_text(fix_butterfly_expected_vector(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/ntt_top/tb/butterfly_top_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("pinned butterfly filelist source entry changed")
                    filelist = overlay_dir / "butterfly_top_tb.overlay.vf"
                    filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "butterfly_top_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source": str(source), "source_sha256": BUTTERFLY_TB_SHA256,
                        "overlay": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(filelist), "overlay_filelist_sha256": sha256(filelist),
                        "reason": "load the existing expected-output vector into out_val rather than overwriting in_val",
                        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] == "caliptra-v2-1-2-csrng_tb":
                    filelist_text = filelist.read_text()
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay_filelist = overlay_dir / "csrng_tb.overlay.vf"
                    overlay_filelist.write_text(fix_csrng_tb_filelist(filelist_text))
                    overlay_manifest = overlay_dir / "csrng_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "add the register include directory and compile the RAM configuration package before its importer",
                        "scope": "filelist only; no RTL, firmware, or pass criteria changed",
                    }, indent=2) + "\n")
                    filelist = overlay_filelist
                    result["overlay_manifest"] = str(overlay_manifest)
                image = output / "test.vvp"
                if row["runner_profile"] == "m7-component":
                    if row["environment_id"] == "caliptra-v2-1-2-soc_ifc_tb":
                        source = caliptra / "src/soc_ifc/tb/soc_ifc_tb_pkg.sv"
                        if sha256(source) != SOC_IFC_TB_PKG_SHA256:
                            raise RuntimeError(f"refusing unreviewed SoC-IFC testbench source: {source}")
                        overlay_dir = output / "overlays"
                        overlay_dir.mkdir(exist_ok=True)
                        overlay = overlay_dir / "soc_ifc_tb_pkg.sv"
                        overlay.write_text(fix_soc_ifc_dict_initializers(source.read_text()))
                        filelist_text = filelist.read_text()
                        source_entry = "${CALIPTRA_ROOT}/src/soc_ifc/tb/soc_ifc_tb_pkg.sv"
                        if filelist_text.count(source_entry) != 1:
                            raise RuntimeError("pinned SoC-IFC filelist source entry changed")
                        filelist = overlay_dir / "soc_ifc_tb.overlay.vf"
                        filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                        overlay_manifest = overlay_dir / "manifest.json"
                        overlay_manifest.write_text(json.dumps({
                            "source": str(source), "source_sha256": SOC_IFC_TB_PKG_SHA256,
                            "overlay": str(overlay), "overlay_sha256": sha256(overlay),
                            "filelist": str(filelist), "filelist_sha256": sha256(filelist),
                            "reason": "add the SystemVerilog assignment-pattern marker to eight string-keyed testbench maps",
                            "scope": "testbench only; no RTL, firmware, or pass criteria changed",
                        }, indent=2) + "\n")
                        result["overlay_manifest"] = str(overlay_manifest)
                    command = [str(iverilog), "-g2017", "-gassertions", "-s", row["top"]]
                    for include_dir in include_dirs_for_area(row["area"], root):
                        command.extend(["-I", str(include_dir)])
                    command += ["-f", str(filelist), "-o", str(image)]
                else:
                    project = (root / row["hdl_filelist"]).parents[2]
                    env["UVMF_PROJECT_DIR"] = str(project)
                    wrapper = output / "m15_uvmf_top.sv"
                    wrapper.write_text("module m15_uvmf_top; hdl_top hdl(); hvl_top hvl(); endmodule\n")
                    command = [str(iverilog), "-uvm", "-g2017", "-gassertions", "-s", "m15_uvmf_top", "-f", str(filelist)]
                    if row["environment_id"] == "uvmf-mldsa":
                        command.insert(1, "-DCALIPTRA_BFM_AHB_32BIT")
                    if "hdl_top.sv" not in filelist.read_text():
                        command += ["-f", str(root / row["hdl_filelist"])]
                    if "hvl_top.sv" not in filelist.read_text():
                        command += ["-f", str(root / row["hvl_filelist"])]
                    command += ["-o", str(image), str(wrapper)]
                    sim_cwd = project / "tb/testbench"
                    if sim_cwd.is_dir():
                        shutil.copytree(sim_cwd, runtime, dirs_exist_ok=True)
                compile_rc, compile_timeout = run_logged(command, runtime, env, output / "compile.log", max(0, int(deadline - time.monotonic())))
                result["compile_exit"] = compile_rc
                result["compile_timed_out"] = compile_timeout
                if compile_timeout:
                    result.update(status="TIMEOUT", cause="Icarus compile exceeded per-row timeout")
                elif compile_rc != 0:
                    compile_text = (output / "compile.log").read_text(errors="replace")
                    result.update(status="BLOCKED", cause=first_diagnostic(compile_text))
                else:
                    sim_command = [str(vvp), "-n", str(image), *plusargs]
                    sim_rc, sim_timeout = run_logged(sim_command, runtime, env, output / "sim.log", max(0, int(deadline - time.monotonic())))
                    result["sim_exit"] = sim_rc
                    result["sim_timed_out"] = sim_timeout
                    sim_text = (output / "sim.log").read_text(errors="replace")
                    if sim_timeout:
                        result.update(status="TIMEOUT", cause="VVP exceeded per-row timeout")
                    else:
                        if row["testname"] == "sigdecode_h_normal_test":
                            status, cause = classify_sigdecode_h(sim_text, sim_rc)
                        elif row["testname"] == "sigdecode_z_normal_test":
                            status, cause = classify_sigdecode_z(sim_text, sim_rc)
                        elif row["testname"] == "pkdecode_normal_test":
                            status, cause = classify_pkdecode(sim_text, sim_rc)
                        elif row["testname"] == "skencode_normal_test":
                            status, cause = classify_skencode(sim_text, sim_rc)
                        else:
                            status, cause = classify(sim_text, sim_rc)
                        result.update(status=status, cause=cause)
                    result["sim_log"] = str(output / "sim.log")
                result["compile_log"] = str(output / "compile.log")
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        result.update(status="BLOCKED", cause=str(error))

    result["elapsed_seconds"] = round(time.monotonic() - started, 3)
    (output / "result.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    (output / "result.txt").write_text(
        f"row_id={result['row_id']}\ntestname={result['testname']}\nstatus={result['status']}\ncause={result['cause']}\nelapsed_seconds={result['elapsed_seconds']}\n"
    )
    print(f"{result['status']} row={args.row_id} test={row['testname']}: {result['cause']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
