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
IVERILOG_PIN = "cc25756d187314742d347267c2a513b3e640a7fb"
IVERILOG_SHA256 = "87bb417df23d260bcfde3fb372b4a80eaad69e4fd2eea1ffb8b0eff10f7af08e"
SOC_IFC_TB_PKG_SHA256 = "72f75561e1b88976ee2fe6f16de9eeac8f1f90bcace7baf7513a67ebe403feed"
SOC_IFC_INTRBLK_TB_SHA256 = "3309558e728491436df653570daa386b95e914e33533d0ba2ffddd721f3c42c7"
SOC_IFC_TB_TOP_SHA256 = "1071521c4712c6aad4a5e7e4cb6020378d0e17ddb828cf286fd4fd0a4a1d7614"
KV_EXAMPLE_SEQUENCE_SHA256 = "bac84c79a3a8a7fd8f424a530d228a2974b4264a39cb5a45b34f79ac77070042"
ABR_CONFIG_DEFINES_SHA256 = "68b2bc72efb9040e29b96ab6b44d7ec4f801f8b6c1b45cf040562fe75629a3d4"
ABR_PARAMS_PKG_SHA256 = "4bf9b0f78c39869949d07f8b37c70a04d0f23a6f486982e0b98a78531aa675e9"
ABR_SAMPLER_PKG_SHA256 = "1fba5ed692e185ee04406e3ab0636dc99c3cd06a1caaec0e24c487d854fa29ae"
ABR_SHA3_TB_SHA256 = "ab8792587a73ad006f28907fcb1f0f70be7e5b3419c76556f8918ec97728f4cb"
COMPRESS_TB_SHA256 = "c0656d94f742dd7f56b57ec980fe45a7801dda823660bce713bf63ec0e78ef89"
BUTTERFLY_TB_SHA256 = "53c38240f13e9f353f5ae4a028d6087aa7aa15ba3fd2eb557a7505db7a899366"
NORM_CHECK_TB_SHA256 = "c4db6339c90d483ca9aeba06fd6fcc0c36a9b9670f73759e2980e879cd36582b"
DECOMPOSE_TB_SHA256 = "faf59075d99baaf2b32e81755324d89722a193177a7cbc51fd3fc037ee387317"
SKDECODE_TB_SHA256 = "f1a7866df738fa78eea4922ca2b11b992b7fd892f4c4f89db78b49e7af12c2ff"
SIGDECODE_H_TB_SHA256 = "2e740d001e807a2387ff6df860bd07fe12538ccd6de0e4fc82e30388f9f7888c"
SIGDECODE_Z_TB_SHA256 = "de917095eee8bff95a9f95336ab8a5452c5ed5e7dd8be4937919b7a5d853aa1c"
PKDECODE_TB_SHA256 = "28c74a0138673adb1f01d307bec384a392aa09786f81ee67059e84a6664399ad"
SKENCODE_TB_SHA256 = "91fbec03b602723fb2469653b7d7d307fe3613986873d607b592f5eebdeeb019"
MAKEHINT_TB_SHA256 = "bc12eca2023a27f02fc018cce587e6430c99c214870d4551c152b6c438208afe"
NTT_TOP_MASKING_TB_SHA256 = "59b9402650f64fd98b85c3c6c8f9e79f166273ba3e96bfa7009a52f3e5d0f053"
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


def fix_makehint_tb(source_text: str) -> str:
    source = "MLDSA_MEM_ADDR_WIDTH"
    if source_text.count(source) != 1:
        raise RuntimeError("expected one undefined makehint address-width reference")
    return source_text.replace(source, "ABR_MEM_ADDR_WIDTH")


def fix_ntt_top_masking_tb(source_text: str) -> str:
    source = "masked_uvw_i_tb = {'h0, 'h0, 'h0, 'h0, 'h0, 'h0};"
    if source_text.count(source) != 1:
        raise RuntimeError("expected one pinned all-zero masked UVW assignment")
    source_text = source_text.replace(source, "masked_uvw_i_tb = '0;")
    port = "    .hybrid_pw_uvw_i(),\n"
    if source_text.count(port) != 1:
        raise RuntimeError("expected one stale unconnected hybrid port")
    source_text = source_text.replace(port, "")
    call = "    masked_bfu_1x2_test();"
    if source_text.count(call) != 1:
        raise RuntimeError("expected one call to the commented-out masking task")
    return source_text.replace(call, "    masked_hybrid_bf_2x2_test();")


def fix_soc_ifc_tb_pkg(source_text: str) -> str:
    anchor = "[string] = {"
    if source_text.count(anchor) != 8:
        raise RuntimeError(f"expected 8 pinned SoC-IFC string maps, found {source_text.count(anchor)}")
    transaction = "new_trans = {addr: addr,"
    if source_text.count(transaction) != 2:
        raise RuntimeError(f"expected 2 pinned SoC-IFC transaction patterns, found {source_text.count(transaction)}")
    result = "matched_p = {d: matched_d,"
    if source_text.count(result) != 1:
        raise RuntimeError(f"expected one pinned SoC-IFC result pattern, found {source_text.count(result)}")
    rewrites = (
        ("extern function lock_fuses();", "extern function void lock_fuses();"),
        ("extern function unlock_fuses();", "extern function void unlock_fuses();"),
        ("function SocRegisters::lock_fuses();", "function void SocRegisters::lock_fuses();"),
        ("function SocRegisters::unlock_fuses();", "function void SocRegisters::unlock_fuses();"),
    )
    for source, replacement in rewrites:
        if source_text.count(source) != 1:
            raise RuntimeError(f"expected one pinned SoC-IFC declaration: {source}")
        source_text = source_text.replace(source, replacement)
    return (
        source_text.replace(transaction, "new_trans = '{addr: addr,")
        .replace(result, "matched_p = '{d: matched_d,")
        .replace(anchor, "[string] = '{")
    )


def fix_soc_ifc_intrblk_constraint(source_text: str) -> str:
    declaration = "        word_addr_t associated_addr;"
    constraint = "wrtrans.randomize() with {wrtrans.data & get_mask(rname) != 0;}"
    write_data = "ahb_wrdata = wrtrans.data & get_mask(rname);"
    for source in (declaration, constraint, write_data):
        if source_text.count(source) != 1:
            raise RuntimeError(f"expected one pinned SoC-IFC INTRBLK snippet: {source}")
    return (
        source_text.replace(declaration, declaration + "\n        dword_t wr_mask;")
        .replace(constraint, "wr_mask = get_mask(rname);\n        " + constraint.replace("get_mask(rname)", "wr_mask"))
        .replace(write_data, "ahb_wrdata = wrtrans.data & wr_mask;")
    )


def fix_soc_ifc_tb(source_text: str, intrblk_overlay: str) -> str:
    clocking = "default clocking default_clk @(posedge clk_tb); endclocking"
    include = '`include "soc_reg_intrblk_test.svh"'
    event = "forever @($changed("
    for source in (clocking, include):
        if source_text.count(source) != 1:
            raise RuntimeError(f"expected one pinned SoC-IFC top snippet: {source}")
    if source_text.count(event) != 5:
        raise RuntimeError(f"expected five pinned SoC-IFC $changed events, found {source_text.count(event)}")
    return source_text.replace(include, f'`include "{intrblk_overlay}"').replace(
        event, "forever @(posedge clk_tb) if ($changed("
    )


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
    source_text = _replace_mldsa_source_once(
        source_text,
        "qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];",
        "qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];",
    )
    return fix_mldsa_ahb_transfer_type_aliases(source_text, 2)


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


MLDSA_AHB_TRANSFER_PARAMETERS = (
    "ahb_lite_slave_0_params::AHB_NUM_MASTERS",
    "ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS",
    "ahb_lite_slave_0_params::AHB_NUM_SLAVES",
    "ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH",
    "ahb_lite_slave_0_params::AHB_WDATA_WIDTH",
    "ahb_lite_slave_0_params::AHB_RDATA_WIDTH",
)


def fix_mldsa_ahb_transfer_type_aliases(source_text: str, expected_count: int) -> str:
    pattern = r"ahb_master_burst_transfer\s*#\(\s*" + r"\s*,\s*".join(
        re.escape(parameter) for parameter in MLDSA_AHB_TRANSFER_PARAMETERS
    ) + r"\s*\)"
    source_text, replacements = re.subn(pattern, "ahb_lite_slave_0_transfer_t", source_text)
    if replacements != expected_count:
        raise RuntimeError(f"expected {expected_count} generated MLDSA AHB transfer type references")
    return source_text


def fix_soc_ifc_wildcard_transition_bins(source_text: str, expected_count: int) -> str:
    def full_range(width_text: str, mask: str) -> tuple[int, str, str]:
        width = int(width_text)
        if mask.replace("_", "") != "?" * (width // 4):
            raise RuntimeError(f"unsupported {width}-bit wildcard transition mask: {mask}")
        digits = width // 4

        def value_hex(value: int) -> str:
            encoded = f"{value:0{digits}X}"
            return "_".join(encoded[i : i + 4] for i in range(0, digits, 4))

        return width, value_hex(0), value_hex((1 << width) - 1)

    def replace_set(match: re.Match[str]) -> str:
        width, low, high = full_range(match.group(2), match.group(3))
        return f"{match.group(1)}bins set = (0 => [{width}'h{low}:{width}'h{high}]);"

    def replace_clear(match: re.Match[str]) -> str:
        width, low, high = full_range(match.group(2), match.group(3))
        return f"{match.group(1)}bins clr = ([{width}'h{low}:{width}'h{high}] => 0);"

    pattern = r"^([ \t]*)wildcard bins {name} = \({expr}\);$"
    set_re = re.compile(
        pattern.format(name="set", expr=r"0 => (4|8|32)'h([?0-9A-Fa-f_]+)"),
        re.MULTILINE,
    )
    clr_re = re.compile(
        pattern.format(name="clr", expr=r"(4|8|32)'h([?0-9A-Fa-f_]+) => 0"),
        re.MULTILINE,
    )
    source_text, set_count = set_re.subn(replace_set, source_text)
    source_text, clr_count = clr_re.subn(replace_clear, source_text)
    if set_count + clr_count != expected_count or set_count != clr_count:
        raise RuntimeError(
            f"expected {expected_count} wildcard transition bins in pairs; "
            f"found {set_count} set and {clr_count} clear bins"
        )
    return source_text


def fix_soc_ifc_fixed_array_wildcard_bins(source_text: str) -> str:
    expected = {"ROM": "0000", "ICCM0": "4000", "ICCM1": "4001"}
    pattern = re.compile(
        r"^([ \t]*)wildcard bins (ROM|ICCM0|ICCM1)\s*\[16\]\s*=\s*"
        r"\{32'h([0-9A-Fa-f]{4})\?\?\?\?\};$",
        re.MULTILINE,
    )
    seen: dict[str, str] = {}

    def replace(match: re.Match[str]) -> str:
        indent, name, prefix = match.groups()
        if name in seen:
            raise RuntimeError(f"duplicate fixed-array wildcard bin: {name}")
        seen[name] = prefix.upper()
        return (
            f"{indent}bins {name} [16] = "
            f"{{[32'h{prefix}_0000:32'h{prefix}_FFFF]}};"
        )

    source_text, count = pattern.subn(replace, source_text)
    if count != len(expected) or seen != expected:
        raise RuntimeError(f"expected fixed-array patterns {expected}; found {seen}")
    return source_text


def fix_soc_ifc_aligned_length_bins(source_text: str) -> str:
    for name, low_zero_bits in (
        ("legal_word_aligned_val", 1),
        ("legal_dword_aligned_val", 2),
        ("legal_qword_aligned_val", 3),
        ("legal_oword_aligned_val", 4),
    ):
        pattern = re.compile(
            rf"(?m)^([ \t]*)bins {name}[ \t]*=[ \t]*\{{\[1:32'h8000\]\}}[ \t]*"
            r"with[ \t]*\(~\|item\[([0-3])(?::([0-3]))?\]\);\r?$"
        )

        def replace(match: re.Match[str]) -> str:
            high, low = int(match.group(2)), int(match.group(3) or match.group(2))
            if (high, low) != (low_zero_bits - 1, 0):
                raise RuntimeError(f"unexpected {name} alignment filter: {match.group(0)}")
            width = 32 - low_zero_bits
            upper = 0x8000 >> low_zero_bits
            cursor = 1
            values = []
            while cursor <= upper:
                free_bits = min(
                    (cursor & -cursor).bit_length() - 1,
                    (upper - cursor + 1).bit_length() - 1,
                )
                prefix = format(cursor >> free_bits, f"0{width - free_bits}b")
                values.append(f"32'b{prefix}{'?' * free_bits}{'0' * low_zero_bits}")
                cursor += 1 << free_bits
            bins = ",\n".join(f"{match.group(1)}  {value}" for value in values)
            return f"{match.group(1)}wildcard bins {name} = {{\n{bins}\n{match.group(1)}}};"

        source_text, count = pattern.subn(replace, source_text)
        if count != 1:
            raise RuntimeError(f"expected one {name} coverage bin, found {count}")
    return source_text


def fix_soc_ifc_nonzero_byte_bins(source_text: str, width: int, groups: int = 1) -> str:
    pattern = re.compile(
        r"(?m)^([ \t]*)bins byte_(\d+)[ \t]*=[ \t]*\{\[0:\$\]\}[ \t]*"
        r"with[ \t]*\(\$countones\(item\[\s*(\d+):\s*(\d+)\]\s*>\s*0\)\);\r?$"
    )
    matches = list(pattern.finditer(source_text))
    lanes = width // 8
    if width not in (32, 64) or len(matches) != lanes * groups:
        raise RuntimeError(f"expected {lanes * groups} byte coverage bins for {width}-bit samples")
    indices = [int(match.group(2)) for match in matches]
    if any(indices.count(lane) != groups for lane in range(lanes)):
        raise RuntimeError(f"unexpected byte-bin indices for {width}-bit samples: {indices}")

    for match in reversed(matches):
        indent, lane_text, high_text, low_text = match.groups()
        lane, high, low = int(lane_text), int(high_text), int(low_text)
        if (high, low) != (lane * 8 + 7, lane * 8):
            raise RuntimeError(f"unexpected SoC-IFC byte coverage filter: {match.group(0)}")
        patterns = []
        for bit in range(8):
            bits = ["?"] * width
            bits[width - 1 - (lane * 8 + bit)] = "1"
            patterns.append(f"{width}'b" + "".join(bits))
        rendered = ",\n".join(f"{indent}  {value}" for value in patterns)
        replacement = f"{indent}wildcard bins byte_{lane} = {{\n{rendered}\n{indent}}};"
        source_text = source_text[:match.start()] + replacement + source_text[match.end():]
    return source_text


def fix_soc_ifc_ctrl_transaction_coverage(source_text: str) -> str:
    old = "bins rand_key  = {[1:{`CLP_OBF_KEY_DWORDS{32'hFFFF_FFFF}}-1]};"
    if source_text.count(old) != 1:
        raise RuntimeError("expected one wide SoC-IFC rand_key coverage bin")
    source_text = source_text.replace(
        old, f"bins rand_key  = {{[256'h1:256'h{(1 << 256) - 2:064X}]}};", 1
    )
    for name, width in (("cptra_obf_field_entropy", 256), ("cptra_obf_uds_seed", 512)):
        old = f"{name}: coverpoint coverage_trans.{name};"
        if source_text.count(old) != 1:
            raise RuntimeError(f"expected one wide {name} coverage point")
        maximum = "F" * (width // 4)
        new = (
            f"{name}: coverpoint coverage_trans.{name} {{\n"
            f"        bins any_value = {{[{width}'h0:{width}'h{maximum}]}};\n"
            "    }"
        )
        source_text = source_text.replace(old, new, 1)
    return fix_soc_ifc_nonzero_byte_bins(source_text, 64)


def fix_soc_ifc_empty_psprintf_args(source_text: str) -> str:
    source_text, count = re.subn(r"(\$psprintf\([^\n]*?),\s*\)", r"\1)", source_text)
    if count != 1:
        raise RuntimeError(f"expected one trailing empty $psprintf argument, found {count}")
    return source_text


def rewrite_soc_ifc_package_filelist(
    filelist_text: str, package_overlays: dict[str, Path]
) -> str:
    package_root = (
        "${CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
        "verification_ip/interface_packages"
    )
    include_dirs = []
    for package, overlay in package_overlays.items():
        package_source = f"{package_root}/{package}/{package}.sv"
        if filelist_text.count(package_source) != 1:
            raise RuntimeError(f"expected one SoC-IFC package source: {package}")
        include_dir = f"+incdir+{overlay.parent.resolve()}"
        if include_dir in filelist_text:
            raise RuntimeError(f"SoC-IFC package overlay include directory already present: {package}")
        include_dirs.append(include_dir)
        filelist_text = filelist_text.replace(package_source, str(overlay.resolve()), 1)
    return "\n".join(include_dirs) + "\n" + filelist_text


def validate_soc_ifc_wildcard_coverage(source_name: str, source_text: str) -> None:
    expected = {
        "mbox_csr_covergroups.svh": 4,
        "sha512_acc_csr_covergroups.svh": 4,
        "soc_ifc_reg_covergroups.svh": 8,
        "soc_ifc_ctrl_transaction_coverage.svh": 8,
        "soc_ifc_status_transaction_coverage.svh": 8,
    }.get(source_name, 0)
    if source_text.count("wildcard bins") != expected:
        raise RuntimeError(f"unhandled wildcard coverage remains in {source_name}")


def prepare_soc_ifc_wildcard_coverage_overlay(
    filelist: Path, caliptra: Path, output: Path
) -> tuple[Path, Path]:
    rtl = caliptra / "src/soc_ifc/rtl"
    overlay_dir = output / "overlays/soc-ifc-wildcard-coverage"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    source_specs = (
        ("mbox_csr_covergroups.svh", "974af3660d68930f4cd83704f38ffcc560eeffcefedd25ba0a55e437331dc6b3", 10, False, True, None),
        ("soc_ifc_reg_covergroups.svh", "dd755ccfb21f8188ce4903dabd170808d1156ad0dd314867beb45f2f7d064d65", 28, True, False, (32, 2)),
        ("sha512_acc_csr_covergroups.svh", "abe8101925d9d7bad1c618d1b7a416d37af838e41426c5f5ae92f089b686f6a3", 4, False, True, None),
    )
    overlays: dict[str, Path] = {}
    manifest_sources = []
    for name, expected_hash, transition_count, has_fixed_arrays, has_aligned_bins, byte_shape in source_specs:
        source = rtl / name
        if sha256(source) != expected_hash:
            raise RuntimeError(f"refusing unreviewed SoC-IFC coverage source: {source}")
        text = fix_soc_ifc_wildcard_transition_bins(source.read_text(), transition_count)
        if has_fixed_arrays:
            text = fix_soc_ifc_fixed_array_wildcard_bins(text)
        if byte_shape:
            text = fix_soc_ifc_nonzero_byte_bins(text, *byte_shape)
        if has_aligned_bins:
            text = fix_soc_ifc_aligned_length_bins(text)
        validate_soc_ifc_wildcard_coverage(name, text)
        overlay = overlay_dir / name
        overlay.write_text(text)
        overlays[name] = overlay
        manifest_sources.append({
            "source": str(source), "source_sha256": expected_hash,
            "overlay": str(overlay), "overlay_sha256": sha256(overlay),
        })

    package_root = caliptra / (
        "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/interface_packages"
    )
    package_specs = (
        ("soc_ifc_ctrl_pkg", "b03fda170b5bf0302a20413ea09e6a96b1ede29c12b51219a89a1bdbed807f7c", (
            ("soc_ifc_ctrl_transaction_coverage.svh", "9e5e6f540303af5302315afca7ea8323a3ef883024aa11a0410f83f24c1fbfaf", fix_soc_ifc_ctrl_transaction_coverage),
            ("soc_ifc_ctrl_configuration.svh", "5dc88118e56c6d2ea63402859dae708b0d194c4a11d13ddfaa41d44e84aca8ee", fix_soc_ifc_empty_psprintf_args),
        )),
        ("soc_ifc_status_pkg", "33532db2ee7b43467d737a0a2b3362fe699b6e524cb2ed5a890453f49f3c0bd5", (
            ("soc_ifc_status_transaction_coverage.svh", "72c789323c1d1e934cf051cfcc734bbca3f003219fed686fed9efe74399abf92", lambda text: fix_soc_ifc_nonzero_byte_bins(text, 64)),
            ("soc_ifc_status_configuration.svh", "3e941ba3722d92ced3012d1030b93ae222af41cd122110e220ee801b7ff64c23", fix_soc_ifc_empty_psprintf_args),
        )),
        ("cptra_ctrl_pkg", "40fd534ce94ad7d58fcb4b881e6eab075e487bbc142e37a903ae0f96ecd20595", (
            ("cptra_ctrl_configuration.svh", "1de12cdc45ab0bceb1c3590cd25b984784736c4ad332396401109db7fe7c3bf0", fix_soc_ifc_empty_psprintf_args),
        )),
        ("ss_mode_ctrl_pkg", "4279a836c46cacc26de6adefa99ce8019255af83eca9a0dec67e9342cdb9fb3e", (
            ("ss_mode_ctrl_configuration.svh", "d4cecd5fffa008bdb4d604362b69b5010dbe0f705819a5fbc0bffca129d2020c", fix_soc_ifc_empty_psprintf_args),
        )),
    )
    package_overlays: dict[str, Path] = {}
    for package, package_hash, includes in package_specs:
        package_source = package_root / package / f"{package}.sv"
        if sha256(package_source) != package_hash:
            raise RuntimeError(f"refusing unreviewed SoC-IFC package source: {package_source}")
        package_text = package_source.read_text()
        package_overlay_dir = overlay_dir / package
        package_overlay_dir.mkdir(parents=True, exist_ok=True)
        for name, expected_hash, transform in includes:
            source = package_root / package / "src" / name
            if sha256(source) != expected_hash:
                raise RuntimeError(f"refusing unreviewed SoC-IFC package include: {source}")
            include = f'`include "src/{name}"'
            if package_text.count(include) != 1:
                raise RuntimeError(f"expected one {include} in {package_source}")
            overlay = package_overlay_dir / "src" / name
            overlay.parent.mkdir(parents=True, exist_ok=True)
            overlay.write_text(transform(source.read_text()))
            if "transaction_coverage" in name:
                validate_soc_ifc_wildcard_coverage(name, overlay.read_text())
            manifest_sources.append({
                "source": str(source), "source_sha256": expected_hash,
                "overlay": str(overlay), "overlay_sha256": sha256(overlay),
            })
        package_overlay = package_overlay_dir / f"{package}.sv"
        package_overlay.write_text(package_text)
        package_overlays[package] = package_overlay
        manifest_sources.append({
            "source": str(package_source), "source_sha256": package_hash,
            "overlay": str(package_overlay), "overlay_sha256": sha256(package_overlay),
        })

    filelist_text = rewrite_soc_ifc_package_filelist(filelist.read_text(), package_overlays)
    manifest_wrappers = []
    for name, expected_hash, covergroup in (
        ("mbox_csr_uvm.sv", "5461c24bb9ca70411e91bb66e296016f7133a937eb64b738ba0222646c62fbe0", "mbox_csr_covergroups.svh"),
        ("soc_ifc_reg_uvm.sv", "59991b8e6d8d36c9935d82baf79d907ab65a2fe27d17545c380be68971eb21e3", "soc_ifc_reg_covergroups.svh"),
        ("sha512_acc_csr_uvm.sv", "50b08a6020386bc0858ce4c2ab31837a480fd6e3b072915f23d22d8eb5401e5f", "sha512_acc_csr_covergroups.svh"),
    ):
        source = rtl / name
        source_text = source.read_text()
        if sha256(source) != expected_hash:
            raise RuntimeError(f"refusing unreviewed SoC-IFC UVM wrapper: {source}")
        include = f'`include "{covergroup}"'
        if source_text.count(include) != 1:
            raise RuntimeError(f"expected one {include} in {source}")
        overlay = overlay_dir / name
        overlay.write_text(source_text.replace(include, f'`include "{overlays[covergroup]}"'))
        source_entry = f"${{CALIPTRA_ROOT}}/src/soc_ifc/rtl/{name}"
        if filelist_text.count(source_entry) != 1:
            raise RuntimeError(f"expected one source entry for {name} in {filelist}")
        filelist_text = filelist_text.replace(source_entry, str(overlay))
        manifest_wrappers.append({
            "source": str(source), "source_sha256": expected_hash,
            "overlay": str(overlay), "overlay_sha256": sha256(overlay),
        })

    overlay_filelist = output / "overlays/soc-ifc-wildcard-open-mvc.vf"
    overlay_filelist.write_text(filelist_text)
    manifest = output / "overlays/soc-ifc-wildcard-coverage.json"
    manifest.write_text(json.dumps({
        "sources": manifest_sources, "wrappers": manifest_wrappers,
        "source_filelist": str(filelist), "source_filelist_sha256": sha256(filelist),
        "overlay_filelist": str(overlay_filelist),
        "overlay_filelist_sha256": sha256(overlay_filelist),
        "reason": "rewrite pinned wildcard and filter syntax as equivalent Icarus-supported ranges and masks, and use single explicit bins for wide values",
        "scope": "per-run UVM coverage/testbench only; no design RTL, firmware, stimulus, assertions, or pass criteria changed",
    }, indent=2) + "\n")
    return overlay_filelist, manifest


def fix_mldsa_environment(source_text: str) -> str:
    return fix_mldsa_ahb_transfer_type_aliases(source_text, 1)


def fix_mldsa_ahb_transfer_types(source_text: str, expected_count: int) -> str:
    pattern = r"ahb_master_burst_transfer\s*#\(\s*" + r"\s*,\s*".join(
        re.escape(parameter) for parameter in MLDSA_AHB_TRANSFER_PARAMETERS
    ) + r"\s*\)\s*(\w+)(\s*\[\s*\$\s*\])?\s*;"
    source_text, replacements = re.subn(
        pattern,
        r"ahb_lite_slave_0_transfer_t \1\2;",
        source_text,
    )
    if replacements != expected_count:
        raise RuntimeError(f"expected {expected_count} generated MLDSA AHB transfer types")
    return source_text


def fix_mldsa_predictor(source_text: str) -> str:
    source_text = fix_mldsa_config_rm_access(source_text, "p_mldsa_rm")
    source_text = fix_mldsa_substr(source_text)
    source_text = fix_mldsa_ahb_transfer_types(source_text, 2)
    source_text = _replace_mldsa_source_once(
        source_text,
        'mldsa_sb_ahb_ap_output_transaction = mldsa_sb_ahb_ap_output_transaction_t::type_id::create("mldsa_sb_ahb_ap_output_transaction");',
        'mldsa_sb_ahb_ap_output_transaction = new("mldsa_sb_ahb_ap_output_transaction");',
    )
    command_write = '$fwrite(fd, "%02X\\n", op_code-1);'
    if source_text.count(command_write) != 3:
        raise RuntimeError("expected three MLDSA command-byte writers")
    return source_text.replace(
        command_write,
        "$fwrite(fd, \"%02X\\n\", op_code-3'd1);",
    )


def fix_mldsa_sequence_command_widths(
    source_text: str, expected_commands: tuple[int, ...]
) -> str:
    pattern = re.compile(r'(\$fwrite\(fd,\s*"%02X\\n",\s*)([12])(\);)')
    commands = tuple(int(match.group(2)) for match in pattern.finditer(source_text))
    if commands != expected_commands:
        raise RuntimeError(f"expected command literals {expected_commands}, found {commands}")
    return pattern.sub(lambda match: f"{match.group(1)}3'd{match.group(2)}{match.group(3)}", source_text)


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
    stream_binary_source = source / "test/test_dilithium5_strm_msg"
    stream_binary = runtime / "test_dilithium5_strm_msg"
    shutil.copy2(stream_binary_source, stream_binary)
    manifest = output / "overlays/mldsa-native-model.json"
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(json.dumps({
        "source_test": str(source_test), "source_test_sha256": sha256(source_test),
        "staged_test_sha256": sha256(model_test), "stage_script": str(stage_script),
        "stage_script_sha256": sha256(stage_script), "check_script": str(check_script),
        "check_script_sha256": sha256(check_script), "build_logs": logs,
        "binary": str(runtime_binary), "binary_sha256": sha256(runtime_binary),
        "stream_binary_source": str(stream_binary_source),
        "stream_binary_source_sha256": sha256(stream_binary_source),
        "stream_binary": str(stream_binary), "stream_binary_sha256": sha256(stream_binary),
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
            env_pkg / "src/mldsa_environment.svh",
            "mldsa_env_pkg/src/mldsa_environment.svh",
            fix_mldsa_environment,
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
            sequences / "src/ML_DSA_randomized_verif_sequence.svh",
            "mldsa_sequences/src/ML_DSA_randomized_verif_sequence.svh",
            lambda text: fix_mldsa_sequence_command_widths(text, (1,)),
        ),
        (
            sequences / "src/ML_DSA_randomized_two_verif_on_fail_sequence.svh",
            "mldsa_sequences/src/ML_DSA_randomized_two_verif_on_fail_sequence.svh",
            lambda text: fix_mldsa_sequence_command_widths(text, (1, 2)),
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


AAXI_ENV_PKG_ENTRY = (
    "${CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
    "verification_ip/environment_packages/soc_ifc_env_pkg/soc_ifc_env_pkg.sv"
)
AAXI4PC_ENTRY = "${CALIPTRA_AXI4PC_DIR}/Axi4PC.sv"


def rewrite_m17_aaxi_filelist(
    source_text: str, support_sources: list[str], package_overlay: str, *, drop_axi4pc: bool = False,
    include_dir: str | None = None,
) -> str:
    if source_text.count(AAXI_ENV_PKG_ENTRY) != 1:
        raise RuntimeError("expected one pinned SoC-IFC package in AAXI filelist")
    if drop_axi4pc and source_text.splitlines().count(AAXI4PC_ENTRY) != 1:
        raise RuntimeError("expected one unused ARM Axi4PC stub in SoC-IFC filelist")
    markers = ("AVERY_SIM", "AVERY_AXI")
    if any(not any(marker in line for line in source_text.splitlines()) for marker in markers):
        raise RuntimeError("expected AVERY_SIM and AVERY_AXI entries in generated filelist")

    existing_sources = set(source_text.splitlines())
    support_sources = list(dict.fromkeys(source for source in support_sources if source not in existing_sources))
    include_entry = f"+incdir+{include_dir}" if include_dir else None
    lines = [include_entry] if include_entry and include_entry not in source_text.splitlines() else []
    inserted = False
    for line in source_text.splitlines():
        if drop_axi4pc and line == AAXI4PC_ENTRY:
            continue
        if any(marker in line for marker in markers):
            if not inserted:
                lines.extend(support_sources)
                inserted = True
            continue
        lines.append(line.replace(AAXI_ENV_PKG_ENTRY, package_overlay))
    if not inserted or any(marker in line for line in lines for marker in markers):
        raise RuntimeError("open AAXI filelist retained a proprietary source entry")
    return "\n".join(lines) + "\n"


def prepare_m17_aaxi_open_filelist(
    filelist: Path, caliptra: Path, repo: Path, output: Path, *, drop_axi4pc: bool = False
) -> tuple[Path, Path]:
    overlay_dir = output / "overlays"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    package_source = caliptra / AAXI_ENV_PKG_ENTRY.removeprefix("${CALIPTRA_ROOT}/")
    package_overlay = overlay_dir / "soc_ifc_env_pkg.sv"
    avery_header = repo / "dv/caliptra_bfm/uvm/avery_defines.svh"
    if not avery_header.is_file():
        raise RuntimeError(f"missing open AVERY compatibility header: {avery_header}")
    helper = repo / "docs/conformance/release_overlays/caliptra/soc_ifc_aaxi_compat_overlay.py"
    subprocess.run(
        [sys.executable, str(helper), "--caliptra-root", str(caliptra), "--output", str(package_overlay)],
        cwd=repo,
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
    )

    support_filelist = repo / "dv/caliptra_bfm/uvm/caliptra_bfm_aaxi_compat.f"
    support_sources = []
    for entry in support_filelist.read_text().splitlines():
        entry = entry.strip()
        if entry and not entry.startswith("#"):
            source = (repo / entry).resolve()
            if not source.is_file():
                raise RuntimeError(f"missing QD-BFM AAXI support source: {source}")
            support_sources.append(str(source))
    filelist_text = filelist.read_text()
    overlay_text = rewrite_m17_aaxi_filelist(
        filelist_text, support_sources, str(package_overlay), drop_axi4pc=drop_axi4pc,
        include_dir=str(avery_header.parent),
    )
    overlay_filelist = overlay_dir / "soc-ifc-aaxi-open-mvc.vf"
    overlay_filelist.write_text(overlay_text)
    manifest = overlay_dir / "soc-ifc-aaxi-open-mvc.json"
    manifest.write_text(json.dumps({
        "source_filelist": str(filelist), "source_filelist_sha256": sha256(filelist),
        "overlay_filelist": str(overlay_filelist), "overlay_filelist_sha256": sha256(overlay_filelist),
        "package_source": str(package_source), "package_source_sha256": sha256(package_source),
        "package_overlay": str(package_overlay), "package_overlay_sha256": sha256(package_overlay),
        "avery_defines_header": str(avery_header), "avery_defines_sha256": sha256(avery_header),
        "support_filelist": str(support_filelist), "support_filelist_sha256": sha256(support_filelist),
        "support_sources": [{"path": source, "sha256": sha256(Path(source))} for source in support_sources],
        "removed_arm_axi4pc_stub": drop_axi4pc,
        "removed_proprietary_paths": {marker: filelist_text.count(marker) for marker in ("AVERY_SIM", "AVERY_AXI")},
        "scope": "testbench, BFM, filelist, and setup only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return overlay_filelist, manifest


def rewrite_soc_ifc_generated_case_filelist(
    source_text: str, aaxi_package_overlay: str, overlay_root: str | Path
) -> str:
    root = (
        "$" + "{CALIPTRA_ROOT}/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/"
        "verification_ip/environment_packages/soc_ifc_env_pkg"
    )
    reg_model = f"{root}/registers/soc_ifc_reg_model_top_pkg.sv"
    if source_text.count(aaxi_package_overlay) != 1:
        raise RuntimeError("expected one AAXI SoC-IFC package overlay in filelist")
    if source_text.count(reg_model) != 1:
        raise RuntimeError("expected one pinned soc_ifc_reg_model_top_pkg in filelist")

    overlay_root = Path(overlay_root)
    include_dirs = (
        f"+incdir+{overlay_root}",
        f"+incdir+{overlay_root / 'registers'}",
    )
    lines = source_text.splitlines()
    if any(line in lines for line in include_dirs):
        raise RuntimeError("generated SoC-IFC overlay include path is already present")
    lines = [
        line.replace(aaxi_package_overlay, str(overlay_root / "soc_ifc_env_pkg.sv"))
        .replace(reg_model, str(overlay_root / "registers/soc_ifc_reg_model_top_pkg.sv"))
        for line in lines
    ]
    return "\n".join((*include_dirs, *lines)) + "\n"


def prepare_soc_ifc_generated_case_filelist(
    filelist: Path, caliptra: Path, repo: Path, output: Path
) -> tuple[Path, Path]:
    overlay_root = output / "overlays/soc-ifc-generated-case-selector"
    selector_helper = repo / "docs/conformance/release_overlays/caliptra/soc_ifc_generated_case_selector_overlay.py"
    aaxi_helper = repo / "docs/conformance/release_overlays/caliptra/soc_ifc_aaxi_compat_overlay.py"
    selector_result = subprocess.run(
        [
            sys.executable, str(selector_helper), "--caliptra-root", str(caliptra),
            "--output", str(overlay_root),
        ],
        cwd=repo, check=True, capture_output=True, text=True, timeout=60,
    )
    generation_log = overlay_root / "overlay-generation.log"
    package_overlay = overlay_root / "soc_ifc_env_pkg.sv"
    aaxi_result = subprocess.run(
        [
            sys.executable, str(aaxi_helper), "--caliptra-root", str(caliptra),
            "--output", str(package_overlay),
        ],
        cwd=repo, check=True, capture_output=True, text=True, timeout=30,
    )
    package_source = caliptra / AAXI_ENV_PKG_ENTRY.removeprefix("$" + "{CALIPTRA_ROOT}/")
    generation_log.write_text(
        "=== generated case-selector overlay ===\n"
        + selector_result.stdout
        + selector_result.stderr
        + "\n=== AAXI package overlay ===\n"
        + aaxi_result.stdout
        + aaxi_result.stderr
        + "\n"
        + f"selector helper SHA-256: {sha256(selector_helper)}\n"
        + f"AAXI helper SHA-256: {sha256(aaxi_helper)}\n"
        + "AAXI package overlay replaces the unmodified generated package copy.\n"
    )
    overlay_text = rewrite_soc_ifc_generated_case_filelist(
        filelist.read_text(),
        str((output / "overlays/soc_ifc_env_pkg.sv").resolve()),
        str(overlay_root.resolve()),
    )
    overlay_filelist = output / "overlays/soc-ifc-generated-case-selector.vf"
    overlay_filelist.write_text(overlay_text)
    manifest = output / "overlays/soc-ifc-generated-case-selector.json"
    manifest.write_text(json.dumps({
        "source_filelist": str(filelist), "source_filelist_sha256": sha256(filelist),
        "overlay_filelist": str(overlay_filelist), "overlay_filelist_sha256": sha256(overlay_filelist),
        "selector_helper": str(selector_helper), "selector_helper_sha256": sha256(selector_helper),
        "selector_overlay_root": str(overlay_root),
        "generation_log": str(generation_log), "generation_log_sha256": sha256(generation_log),
        "package_source": str(package_source), "package_source_sha256": sha256(package_source),
        "aaxi_helper": str(aaxi_helper), "aaxi_helper_sha256": sha256(aaxi_helper),
        "package_overlay": str(package_overlay), "package_overlay_sha256": sha256(package_overlay),
        "scope": "per-run generated SoC-IFC UVM source and filelist only; pinned RTL, firmware, sequences' intent, assertions, and pass criteria are unchanged",
    }, indent=2) + "\n")
    return overlay_filelist, manifest


def fix_compress_tb_filelist(source_text: str) -> str:
    params = "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv"
    ntt = "${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_defines_pkg.sv"
    if source_text.count(params) != 1:
        raise RuntimeError("expected one pinned ABR params package in compress filelist")
    if source_text.count(ntt):
        raise RuntimeError("compress filelist already contains the NTT package")
    return source_text.replace(params, params + "\n" + ntt, 1)


def fix_compress_tb_testbench(source_text: str) -> str:
    replacements = (
        (
            "reg [3:0][REG_SIZE-1:0] coeff_tb, mem_wr_data_o;",
            "reg [3:0][REG_SIZE-1:0] coeff_tb;\n"
            "mem_if_t mem_rd_req_tb;\n"
            "integer mem_word_index_tb;\n"
            "logic [1:0] api_rw_en_tb;\n"
            "logic [DATA_WIDTH-1:0] api_wr_data_tb;\n"
            "logic compress_done_tb;\n"
            "localparam COMPRESS_STREAM_BITS = 4*256*11;\n"
            "logic [COMPRESS_STREAM_BITS-1:0] packed_output_tb;\n"
            "integer packed_output_bit_count_tb;",
            "pinned compress_tb port declaration",
        ),
        (
            "    .src_base_addr(src_base_tb),\n"
            "    .dest_base_addr(dest_base_tb),\n"
            "    .mem_rd_req(),\n"
            "    .mem_wr_req(),\n"
            "    .mem_rd_data(coeff_tb),\n"
            "    .mem_wr_data(mem_wr_data_o),\n"
            "    .compress_done()\n"
            ");",
            "    .src_base_addr(src_base_tb),\n"
            "    .dest_base_addr(dest_base_tb),\n"
            "    .compare_mode(1'b0),\n"
            "    .num_poly(3'd4),\n"
            "    .mem_rd_req(mem_rd_req_tb),\n"
            "    .mem_rd_data(coeff_tb),\n"
            "    .api_rw_en(api_rw_en_tb),\n"
            "    .api_rw_addr(),\n"
            "    .api_wr_data(api_wr_data_tb),\n"
            "    .api_rd_data('0),\n"
            "    .compare_failed(),\n"
            "    .compress_done(compress_done_tb)\n"
            ");",
            "pinned compress_top instantiation",
        ),
        (
            "    mode_tb_dut = 0;",
            "    mode_tb_dut = 0;\n"
            "        error_count = 0;\n"
            "        packed_output_bit_count_tb = 0;",
            "pinned compress_tb initialization",
        ),
        ("    logic flag;\n", "", "pinned compress_test flag declaration"),
    )
    for source, replacement, label in replacements:
        if source_text.count(source) != 1:
            raise RuntimeError(f"expected one {label}")
        source_text = source_text.replace(source, replacement, 1)

    instance_end = "    .compress_done(compress_done_tb)\n);\n"
    monitor = (
        "\n// The existing testbench reuses one coefficient vector for each polynomial.\n"
        "always_comb mem_word_index_tb = (mem_rd_req_tb.addr - src_base_tb) % 64;\n"
        "always @(posedge clk_tb) begin\n"
        "    if (!reset_n_tb) coeff_tb <= '0;\n"
        "    else if (mem_rd_req_tb.rd_wr_en == RW_READ)\n"
        "        coeff_tb <= {coeff_array[mem_word_index_tb*4+3], coeff_array[mem_word_index_tb*4+2],\n"
        "                     coeff_array[mem_word_index_tb*4+1], coeff_array[mem_word_index_tb*4]};\n"
        "end\n"
        "\nalways @(posedge clk_tb) begin\n"
        "    if (!reset_n_tb) begin\n"
        "        packed_output_bit_count_tb = 0;\n"
        "    end else if (api_rw_en_tb[0]) begin\n"
        "        if (packed_output_bit_count_tb + DATA_WIDTH > COMPRESS_STREAM_BITS) begin\n"
        "            $display(\"Unexpected extra compress API write\");\n"
        "            error_count++;\n"
        "        end else begin\n"
        "            for (int packed_bit = 0; packed_bit < DATA_WIDTH; packed_bit++)\n"
        "                packed_output_tb[packed_output_bit_count_tb + packed_bit] = api_wr_data_tb[packed_bit];\n"
        "            packed_output_bit_count_tb += DATA_WIDTH;\n"
        "        end\n"
        "    end\n"
        "end\n"
    )
    if source_text.count(instance_end) != 1:
        raise RuntimeError("expected one pinned compress_tb DUT instance end")
    source_text = source_text.replace(instance_end, instance_end + monitor, 1)

    old_body = re.compile(
        r"(?ms)    flag = 0;\n"
        r"    mode_tb_dut = mode_tb;\n\n"
        r"    fork\n.*?    join\n"
        r"(?=    \$display\(\"Compression done\"\);)"
    )
    new_body = """    mode_tb_dut = mode_tb;
    packed_output_bit_count_tb = 0;
    do @(posedge clk_tb); while (!compress_done_tb);
    @(posedge clk_tb);

    if (packed_output_bit_count_tb != 4*256*d) begin
        $display("Expected %0d compress bits, captured %0d", 4*256*d, packed_output_bit_count_tb);
        error_count++;
    end else begin
        for (int coeff_index = 0; coeff_index < 4*256; coeff_index++) begin
            logic [10:0] expected, actual;
            expected = '0;
            actual = '0;
            for (int bit_index = 0; bit_index < d; bit_index++) begin
                expected[bit_index] = coeff_exp[coeff_index % 256][bit_index];
                actual[bit_index] = packed_output_tb[coeff_index*d + bit_index];
            end
            if (actual !== expected) begin
                $display("Mismatch at index %0d: expected %0h, got %0h at time %t", coeff_index, expected, actual, $time);
                error_count++;
            end
        end
    end
"""
    source_text, count = old_body.subn(new_body, source_text)
    if count != 1:
        raise RuntimeError("expected one pinned compress_tb driver and checker block")
    for marker in (
        "coeff_exp[i] = ((coeff_array[i] << d) + MLKEM_Q/2) / MLKEM_Q;",
        '$display("* TESTCASE PASSED");',
        '$display("* TESTCASE FAILED with %0d errs.", error_count);',
    ):
        if source_text.count(marker) != 1:
            raise RuntimeError(f"compress_tb expected-value or pass/fail marker changed: {marker}")
    return source_text


def prepare_adams_mldsa_filelist(filelist: Path, adamsbridge: Path, output: Path) -> tuple[Path, Path]:
    source_text = filelist.read_text()
    old_root = "+incdir+${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl"
    old_sampler_root = "+incdir+${ADAMSBRIDGE_ROOT}/src/mldsa_sampler_top/rtl"
    old_sampler_package = "${ADAMSBRIDGE_ROOT}/src/mldsa_sampler_top/rtl/mldsa_sampler_pkg.sv"
    old_files = (
        "${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl/mldsa_config_defines.svh",
        "${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl/mldsa_params_pkg.sv",
        "${ADAMSBRIDGE_ROOT}/src/mldsa_top/rtl/mldsa_reg_pkg.sv",
    )
    if source_text.count(old_root) != 1 or any(source_text.count(entry) != 1 for entry in old_files):
        raise RuntimeError("expected one stale MLDSA hierarchy include directory and three source entries")
    stale_piso_entry = "${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_piso_4.sv"
    if source_text.count(stale_piso_entry) != 1:
        raise RuntimeError("expected one stale abr_piso_4 filelist entry")

    config = adamsbridge / "src/abr_top/rtl/abr_config_defines.svh"
    params = adamsbridge / "src/abr_top/rtl/abr_params_pkg.sv"
    if sha256(config) != ABR_CONFIG_DEFINES_SHA256 or sha256(params) != ABR_PARAMS_PKG_SHA256:
        raise RuntimeError("refusing unreviewed ABR configuration sources")
    sampler_counts = (source_text.count(old_sampler_root), source_text.count(old_sampler_package))
    if sampler_counts not in ((0, 0), (1, 1)):
        raise RuntimeError("expected zero or one stale MLDSA sampler package directory/source pair")

    overlay_dir = output / "overlays/adams-mldsa"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    config_alias = overlay_dir / "mldsa_config_defines.svh"
    config_alias.write_text('`include "abr_config_defines.svh"\n')
    abr_root = "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl"
    overlay_text = source_text.replace(old_root, f"+incdir+{abr_root}", 1)
    overlay_text = overlay_text.replace(old_files[0], str(config_alias), 1)
    overlay_text = overlay_text.replace(old_files[1], f"{abr_root}/abr_params_pkg.sv", 1)
    overlay_text = overlay_text.replace(old_files[2], f"{abr_root}/abr_reg_pkg.sv", 1)
    overlay_text = overlay_text.replace(stale_piso_entry, "", 1)
    sampler_import_overlays = []
    if sampler_counts == (1, 1):
        sampler_pkg = adamsbridge / "src/abr_sampler_top/rtl/abr_sampler_pkg.sv"
        if sha256(sampler_pkg) != ABR_SAMPLER_PKG_SHA256:
            raise RuntimeError("refusing unreviewed ABR sampler package")
        sampler_root = "+incdir+${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl"
        sampler_package = "${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl/abr_sampler_pkg.sv"
        overlay_text = overlay_text.replace(old_sampler_root, sampler_root, 1)
        overlay_text = overlay_text.replace(old_sampler_package, sampler_package, 1)
        for entry in source_text.splitlines():
            if not entry.startswith("${ADAMSBRIDGE_ROOT}/") or "/tb/" not in entry or not entry.endswith(".sv"):
                continue
            testbench = adamsbridge / entry.removeprefix("${ADAMSBRIDGE_ROOT}/")
            if not testbench.is_file():
                continue
            testbench_text = testbench.read_text()
            old_imports = ("import mldsa_sampler_pkg::*;", "import sampler_pkg::*;")
            matches = [entry for entry in old_imports if entry in testbench_text]
            if not matches:
                continue
            if len(matches) != 1 or testbench_text.count(matches[0]) != 1:
                raise RuntimeError(f"expected one removed MLDSA sampler package import: {testbench}")
            old_import = matches[0]
            testbench_overlay = overlay_dir / "tb" / entry.removeprefix("${ADAMSBRIDGE_ROOT}/")
            testbench_overlay.parent.mkdir(parents=True, exist_ok=True)
            testbench_overlay.write_text(testbench_text.replace(old_import, "import abr_sampler_pkg::*;", 1))
            overlay_text = overlay_text.replace(entry, str(testbench_overlay), 1)
            sampler_import_overlays.append({
                "source": str(testbench), "source_sha256": sha256(testbench),
                "overlay": str(testbench_overlay), "overlay_sha256": sha256(testbench_overlay),
                "package_import": f"{old_import.removeprefix('import ').removesuffix(';')} -> abr_sampler_pkg::*",
            })
    abr_sha3_entry = "${ADAMSBRIDGE_ROOT}/src/abr_sha3/tb/abr_sha3_tb.sv"
    port_overlays = []
    if source_text.count(abr_sha3_entry) > 1:
        raise RuntimeError("expected at most one abr_sha3 testbench source entry")
    if source_text.count(abr_sha3_entry) == 1:
        abr_sha3_tb = adamsbridge / "src/abr_sha3/tb/abr_sha3_tb.sv"
        if sha256(abr_sha3_tb) != ABR_SHA3_TB_SHA256:
            raise RuntimeError(f"refusing unreviewed abr_sha3 testbench: {abr_sha3_tb}")
        old_port = ".done_i     (sha3_done        ),"
        testbench_overlay = overlay_dir / "tb/src/abr_sha3/tb/abr_sha3_tb.sv"
        testbench_text = testbench_overlay.read_text() if testbench_overlay.exists() else abr_sha3_tb.read_text()
        if testbench_text.count(old_port) != 1:
            raise RuntimeError("expected one stale abr_sha3 done_i connection")
        testbench_overlay.parent.mkdir(parents=True, exist_ok=True)
        testbench_overlay.write_text(testbench_text.replace(old_port, "", 1))
        overlay_text = overlay_text.replace(abr_sha3_entry, str(testbench_overlay), 1)
        for import_overlay in sampler_import_overlays:
            if import_overlay["overlay"] == str(testbench_overlay):
                import_overlay["overlay_sha256"] = sha256(testbench_overlay)
        port_overlays.append({
            "source": str(abr_sha3_tb), "source_sha256": sha256(abr_sha3_tb),
            "overlay": str(testbench_overlay), "overlay_sha256": sha256(testbench_overlay),
            "removed_port": ".done_i",
        })
    overlay_filelist = output / "overlays/mldsa-config-abr-open.vf"
    overlay_filelist.write_text(f"+incdir+{overlay_dir}\n" + overlay_text)
    manifest = output / "overlays/mldsa-config-abr-open.json"
    manifest.write_text(json.dumps({
        "source_filelist": str(filelist), "source_filelist_sha256": sha256(filelist),
        "overlay_filelist": str(overlay_filelist), "overlay_filelist_sha256": sha256(overlay_filelist),
        "removed_header_alias": {"source": old_files[0], "overlay": str(config_alias), "overlay_sha256": sha256(config_alias),
                                  "target": str(config), "target_sha256": ABR_CONFIG_DEFINES_SHA256},
        "renamed_packages": {
            old_files[1]: str(params), old_files[2]: str(adamsbridge / "src/abr_top/rtl/abr_reg_pkg.sv"),
            **({old_sampler_package: str(sampler_pkg)} if sampler_counts == (1, 1) else {}),
        },
        "testbench_import_overlays": sampler_import_overlays,
        "testbench_port_overlays": port_overlays,
        "removed_stale_sources": {stale_piso_entry: "source is absent from the pinned tree and no bench instantiates abr_piso_4"},
        "history": "upstream Adams Bridge hierarchy rename 0a45a695",
        "reason": "redirect the stale mldsa_top filelist names to their renamed abr_top sources",
        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return overlay_filelist, manifest


def fix_kv_factory_sequence_base(source_text: str) -> str:
    source = "class example_derived_test_sequence extends kv_rst_sequence_base;"
    if source_text.count(source) != 1:
        raise RuntimeError("expected one pinned KeyVault example sequence declaration")
    return source_text.replace(source, "class example_derived_test_sequence extends kv_bench_sequence_base;")


def prepare_kv_factory_overlay(filelist: Path, caliptra: Path, output: Path) -> tuple[Path, Path]:
    source = caliptra / "src/keyvault/uvmf_kv/uvmf_template_output/project_benches/kv/tb/sequences/src/example_derived_test_sequence.svh"
    if sha256(source) != KV_EXAMPLE_SEQUENCE_SHA256:
        raise RuntimeError(f"refusing unreviewed KeyVault example sequence: {source}")

    overlay_dir = output / "overlays/kv-factory"
    overlay = overlay_dir / "src/example_derived_test_sequence.svh"
    overlay.parent.mkdir(parents=True, exist_ok=True)
    overlay.write_text(fix_kv_factory_sequence_base(source.read_text()))

    include_entry = f"+incdir+{overlay_dir}"
    source_filelist = filelist.read_text()
    if include_entry in source_filelist:
        raise RuntimeError("KeyVault factory include directory is already in the overlay filelist")
    overlay_filelist = output / "overlays/kv-factory-open-ahb.vf"
    overlay_filelist.write_text(include_entry + "\n" + source_filelist)
    manifest = output / "overlays/kv-factory-overlay.json"
    manifest.write_text(json.dumps({
        "source": str(source), "source_sha256": KV_EXAMPLE_SEQUENCE_SHA256,
        "overlay": str(overlay), "overlay_sha256": sha256(overlay),
        "source_filelist": str(filelist), "source_filelist_sha256": sha256(filelist),
        "overlay_filelist": str(overlay_filelist), "overlay_filelist_sha256": sha256(overlay_filelist),
        "reason": "make the generated example sequence satisfy test_top's declared kv_bench_sequence_base factory contract",
        "scope": "testbench and filelist only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return overlay_filelist, manifest


def prepare_generated_bfm_raw_interface_overlay(
    runtime: Path, environment_id: str, output: Path, filelist: Path
) -> tuple[Path, Path]:
    hdl_top = runtime / "hdl_top.sv"
    source_text = hdl_top.read_text()
    if environment_id in {"uvmf-caliptra_top", "uvmf-soc_ifc"}:
        pattern = re.compile(
            r"(?m)^(\s*((?:soc_ifc_status|cptra_status|ss_mode_status|mbox_sram)_driver_bfm)\s+\w+\s*\()(\w+)\.responder_port(\s*\);)"
        )
        matches = list(pattern.finditer(source_text))
        expected = (
            {"soc_ifc_status_driver_bfm", "ss_mode_status_driver_bfm", "mbox_sram_driver_bfm"}
            if environment_id == "uvmf-caliptra_top" else
            {"soc_ifc_status_driver_bfm", "cptra_status_driver_bfm", "ss_mode_status_driver_bfm", "mbox_sram_driver_bfm"}
        )
        found = {match.group(2) for match in matches}
        if found != expected or len(matches) != len(expected):
            raise RuntimeError(f"unexpected {environment_id} responder BFM bindings: {sorted(found)}")
        overlay_text = pattern.sub(lambda match: match.group(1) + match.group(3) + match.group(4), source_text)
    elif environment_id == "uvmf-ecc":
        pattern = re.compile(
            r"(?m)^(\s*ECC_in_driver_bfm\s+ECC_in_agent_drv_bfm\()ECC_in_agent_bus\.initiator_port(\);)"
        )
        if len(pattern.findall(source_text)) != 1:
            raise RuntimeError("expected one ECC_in_driver_bfm initiator modport binding")
        overlay_text = pattern.sub(r"\1ECC_in_agent_bus\2", source_text)
    elif environment_id == "uvmf-pv":
        replacements = (
            ("pv_write_driver_bfm  pv_sha512_write_agent_drv_bfm(pv_sha512_write_agent_bus.initiator_port);",
             "pv_write_driver_bfm  pv_sha512_write_agent_drv_bfm(pv_sha512_write_agent_bus);"),
            ("pv_read_driver_bfm  pv_sha512_block_read_agent_drv_bfm(pv_sha512_block_read_agent_bus.initiator_port);",
             "pv_read_driver_bfm  pv_sha512_block_read_agent_drv_bfm(pv_sha512_block_read_agent_bus);"),
        )
        overlay_text = source_text
        for old, new in replacements:
            if overlay_text.count(old) != 1:
                raise RuntimeError(f"expected one PV driver binding: {old}")
            overlay_text = overlay_text.replace(old, new, 1)
    else:
        raise RuntimeError(f"unsupported raw-interface BFM overlay environment: {environment_id}")

    overlay_dir = output / "overlays/raw-interface-bfm"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    original_copy = overlay_dir / "hdl_top.sv.original"
    overlay = overlay_dir / "hdl_top.sv"
    original_copy.write_text(source_text)
    overlay.write_text(overlay_text)
    hdl_top.write_text(overlay_text)
    if sha256(hdl_top) != sha256(overlay) or source_text == overlay_text:
        raise RuntimeError("raw-interface BFM overlay failed its copy or change check")
    source_filelist = filelist
    filelist_text = source_filelist.read_text()
    source_entries = [line for line in filelist_text.splitlines() if line.strip().endswith("/tb/testbench/hdl_top.sv")]
    if len(source_entries) != 1:
        raise RuntimeError("expected one generated HDL-top entry in the primary filelist")
    overlay_filelist = overlay_dir / "primary.vf"
    source_entry = source_entries[0]
    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay), 1))
    manifest = overlay_dir / "manifest.json"
    manifest.write_text(json.dumps({
        "environment_id": environment_id,
        "source_runtime_copy": str(hdl_top),
        "source_sha256": hashlib.sha256(source_text.encode()).hexdigest(),
        "original_copy": str(original_copy),
        "overlay": str(overlay),
        "overlay_sha256": sha256(overlay),
        "source_filelist": str(source_filelist),
        "source_filelist_sha256": sha256(source_filelist),
        "overlay_filelist": str(overlay_filelist),
        "overlay_filelist_sha256": sha256(overlay_filelist),
        "reason": "connect interface-formal BFMs to the full interface because their responder/initiator modports mark BFM-driven signals as inputs",
        "scope": "per-run generated testbench copy only; no Caliptra source, RTL, stimulus, or pass criteria changed",
    }, indent=2) + "\n")
    return manifest, overlay_filelist


def prepare_kv_generated_bfm_overlay(
    filelist: Path, caliptra: Path, repo: Path, output: Path
) -> tuple[Path, Path]:
    template_root = caliptra / "src/keyvault/uvmf_kv/uvmf_template_output"
    overlay_dir = output / "overlays/kv-generated-bfm"
    helper = repo / "docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py"
    subprocess.run([sys.executable, str(helper), str(template_root), str(overlay_dir)], check=True)

    overlay_sources = {
        "project_benches/kv/tb/testbench/hdl_top.sv": "hdl_top.sv",
        "verification_ip/interface_packages/kv_rst_pkg/kv_rst_pkg.sv": "kv_rst_pkg.sv",
        "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_driver_bfm.sv": "src/kv_rst_driver_bfm.sv",
        "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_monitor_bfm.sv": "src/kv_rst_monitor_bfm.sv",
        "verification_ip/interface_packages/kv_write_pkg/kv_write_pkg.sv": "kv_write_pkg.sv",
        "verification_ip/interface_packages/kv_read_pkg/src/kv_read_monitor_bfm.sv": "src/kv_read_monitor_bfm.sv",
    }
    source_filelist = filelist.read_text()
    filelist_text = source_filelist
    source_prefix = "${CALIPTRA_ROOT}/src/keyvault/uvmf_kv/uvmf_template_output/"
    for relative, target in overlay_sources.items():
        source_entry = source_prefix + relative
        if filelist_text.count(source_entry) != 1:
            raise RuntimeError(f"expected one generated KeyVault BFM source in filelist: {relative}")
        filelist_text = filelist_text.replace(source_entry, str(overlay_dir / target), 1)

    include_entry = f"+incdir+{overlay_dir}"
    if include_entry in filelist_text.splitlines():
        raise RuntimeError("KeyVault generated-BFM include directory is already in the filelist")
    overlay_filelist = output / "overlays/kv-generated-bfm-open-ahb.vf"
    overlay_filelist.write_text(include_entry + "\n" + filelist_text)
    overlay_files = sorted(path for path in overlay_dir.rglob("*") if path.is_file())
    if not overlay_files:
        raise RuntimeError("KeyVault generated-BFM helper produced no overlays")
    manifest = output / "overlays/kv-generated-bfm-overlay.json"
    manifest.write_text(json.dumps({
        "helper": str(helper), "helper_sha256": sha256(helper),
        "template_root": str(template_root), "overlay_dir": str(overlay_dir),
        "overlays": [{"path": str(path), "sha256": sha256(path)} for path in overlay_files],
        "source_filelist": str(filelist), "source_filelist_sha256": sha256(filelist),
        "overlay_filelist": str(overlay_filelist), "overlay_filelist_sha256": sha256(overlay_filelist),
        "reason": "apply the existing generated-KeyVault Icarus BFM compatibility overlay",
        "scope": "testbench and BFM only; no RTL, firmware, or pass criteria changed",
    }, indent=2) + "\n")
    return overlay_filelist, manifest


def prepare_compress_tb_filelist(filelist: Path, adamsbridge: Path, output: Path) -> tuple[Path, Path]:
    overlay_dir = output / "overlays"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    testbench = adamsbridge / "src/compress/tb/compress_tb.sv"
    if sha256(testbench) != COMPRESS_TB_SHA256:
        raise RuntimeError(f"refusing unreviewed pinned compress_tb: {testbench}")
    testbench_overlay = overlay_dir / "compress_tb.sv"
    testbench_overlay.write_text(fix_compress_tb_testbench(testbench.read_text()))
    source_entry = "${ADAMSBRIDGE_ROOT}/src/compress/tb/compress_tb.sv"
    filelist_text = fix_compress_tb_filelist(filelist.read_text())
    if filelist_text.count(source_entry) != 1:
        raise RuntimeError("expected one pinned compress_tb source entry")
    overlay = overlay_dir / "compress_tb.overlay.vf"
    overlay.write_text(filelist_text.replace(source_entry, str(testbench_overlay), 1))
    manifest = overlay_dir / "compress_tb.manifest.json"
    manifest.write_text(json.dumps({
        "source_testbench": str(testbench), "source_testbench_sha256": COMPRESS_TB_SHA256,
        "overlay_testbench": str(testbench_overlay), "overlay_testbench_sha256": sha256(testbench_overlay),
        "source_filelist": str(filelist), "source_filelist_sha256": sha256(filelist),
        "overlay_filelist": str(overlay), "overlay_filelist_sha256": sha256(overlay),
        "reason": "map legacy testbench writes to the current packed API bus and put NTT before its importers",
        "scope": "testbench and filelist only; input vectors, expected compression values, and pass markers remain unchanged",
    }, indent=2) + "\n")
    return overlay, manifest


def prepare_uart_filelist(root: Path, output: Path) -> tuple[Path, Path]:
    compile_yml = root / "src/uart/config/compile.yml"
    prim_filelist = root / "src/caliptra_prim/config/caliptra_prim.vf"
    if not compile_yml.is_file() or not prim_filelist.is_file():
        raise RuntimeError("UART compile.yml or Caliptra primitive filelist is missing")
    entries = re.findall(
        r"^\s*-\s+\$COMPILE_ROOT/(rtl|tb)/([A-Za-z0-9_.-]+\.sv)\s*$",
        compile_yml.read_text(), re.MULTILINE,
    )
    source_paths = list(dict.fromkeys(root / "src/uart" / directory / name for directory, name in entries))
    if not any(path.name == "uart_tb.sv" for path in source_paths):
        raise RuntimeError("UART compile.yml does not list the self-checking uart_tb.sv")
    if not any(path.name == "uart_reg_pkg.sv" for path in source_paths):
        raise RuntimeError("UART compile.yml does not list uart_reg_pkg.sv")
    missing = [str(path) for path in source_paths if not path.is_file()]
    if missing:
        raise RuntimeError(f"UART compile.yml source is missing: {missing[0]}")

    overlay_dir = output / "overlays"
    overlay_dir.mkdir(parents=True, exist_ok=True)
    overlay = overlay_dir / "uart_tb.overlay.vf"
    overlay.write_text(prim_filelist.read_text().rstrip() + "\n" + "\n".join(map(str, source_paths)) + "\n")
    manifest = overlay_dir / "uart_tb.manifest.json"
    manifest.write_text(json.dumps({
        "source_compile_yml": str(compile_yml), "source_compile_yml_sha256": sha256(compile_yml),
        "source_primitive_filelist": str(prim_filelist), "source_primitive_filelist_sha256": sha256(prim_filelist),
        "overlay_filelist": str(overlay), "overlay_filelist_sha256": sha256(overlay),
        "reason": "assemble the upstream UART compile.yml sources with the pinned Caliptra primitive filelist for Icarus",
        "scope": "filelist/setup only",
    }, indent=2) + "\n")
    return overlay, manifest


def root_for(repo_name: str, caliptra: Path) -> Path:
    return caliptra if repo_name == "caliptra" else caliptra / "submodules/adams-bridge"


def find_top(root: Path, top: str) -> Path | None:
    matches = list(root.glob(f"src/**/tb/{top}.sv"))
    return matches[0] if len(matches) == 1 else None


def needs_m16_open_mvc_filelist(row: dict[str, str]) -> bool:
    return row["test_kind"] == "generated-uvmf" and row["environment_id"] in (
        "uvmf-caliptra_top", "uvmf-ecc", "uvmf-kv", "uvmf-mldsa", "uvmf-pv", "uvmf-soc_ifc", "uvmf-sha512"
    )


def needs_mldsa_reference_model(row: dict[str, str]) -> bool:
    return row["environment_id"] == "uvmf-mldsa" and row["testname"].startswith("ML_DSA_")


def should_drop_axi4pc_stub(environment_id: str) -> bool:
    return environment_id in ("uvmf-caliptra_top", "uvmf-soc_ifc")


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

        iverilog = Path(os.environ.get("IVERILOG_BIN", "/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog")).resolve()
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
        if row["runner_profile"] == "compile-yaml-unresolved" and row["area"] != "uart":
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
            if (row["runner_profile"] == "m7-component" or row["area"] == "uart") and top_file is None:
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
                if row["area"] in {"rej_bounded", "rej_sampler", "sample_in_ball", "abr_sha3", "exp_mask"}:
                    prepare_python_alias(runtime, env)
                if needs_mldsa_reference_model(row):
                    native_model_manifest = prepare_mldsa_native_model(
                        root, repo, output, runtime, env, deadline
                    )
                    result["mldsa_native_model_manifest"] = str(native_model_manifest)
                filelist = root / row["filelist"]
                if row["area"] == "uart":
                    filelist, overlay_manifest = prepare_uart_filelist(root, output)
                    result["overlay_manifest"] = str(overlay_manifest)
                if row["environment_id"] in {
                    "adams-bridge-v2-0-3-mldsa_rej_sampler_tb",
                    "adams-bridge-v2-0-3-sample_in_ball_tb",
                    "adams-bridge-v2-0-3-abr_sha3_tb",
                    "adams-bridge-v2-0-3-exp_mask_tb",
                }:
                    filelist, mldsa_config_manifest = prepare_adams_mldsa_filelist(filelist, root, output)
                    result["adams_mldsa_config_overlay_manifest"] = str(mldsa_config_manifest)
                if row["environment_id"] == "adams-bridge-v2-0-3-compress_tb":
                    filelist, compress_manifest = prepare_compress_tb_filelist(filelist, root, output)
                    result["compress_filelist_manifest"] = str(compress_manifest)
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
                    if row["environment_id"] == "uvmf-kv":
                        filelist, kv_manifest = prepare_kv_factory_overlay(filelist, root, output)
                        result["kv_factory_overlay_manifest"] = str(kv_manifest)
                        filelist, kv_bfm_manifest = prepare_kv_generated_bfm_overlay(
                            filelist, caliptra, repo, output
                        )
                        result["kv_generated_bfm_overlay_manifest"] = str(kv_bfm_manifest)
                if row["environment_id"] in {"uvmf-caliptra_top", "uvmf-soc_ifc"}:
                    filelist, aaxi_manifest = prepare_m17_aaxi_open_filelist(
                        filelist, caliptra, repo, output,
                        drop_axi4pc=should_drop_axi4pc_stub(row["environment_id"]),
                    )
                    result["aaxi_overlay_manifest"] = str(aaxi_manifest)
                    filelist, case_selector_manifest = prepare_soc_ifc_generated_case_filelist(
                        filelist, caliptra, repo, output
                    )
                    result["soc_ifc_generated_case_selector_manifest"] = str(
                        case_selector_manifest
                    )
                    filelist, wildcard_manifest = prepare_soc_ifc_wildcard_coverage_overlay(
                        filelist, caliptra, output
                    )
                    result["soc_ifc_wildcard_coverage_manifest"] = str(wildcard_manifest)
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
                if row["environment_id"] == "adams-bridge-v2-0-3-makehint_tb":
                    source = root / "src/makehint/tb/makehint_tb.sv"
                    if sha256(source) != MAKEHINT_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed makehint testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "makehint_tb.sv"
                    overlay.write_text(fix_makehint_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/makehint/tb/makehint_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("expected one pinned makehint testbench in filelist")
                    overlay_filelist = overlay_dir / "makehint_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "makehint_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": MAKEHINT_TB_SHA256,
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
                if row["environment_id"] == "adams-bridge-v2-0-3-ntt_top_masking_tb":
                    source = root / "src/ntt_top/tb/ntt_top_masking_tb.sv"
                    if sha256(source) != NTT_TOP_MASKING_TB_SHA256:
                        raise RuntimeError(f"refusing unreviewed NTT masking testbench source: {source}")
                    overlay_dir = output / "overlays"
                    overlay_dir.mkdir(parents=True, exist_ok=True)
                    overlay = overlay_dir / "ntt_top_masking_tb.sv"
                    overlay.write_text(fix_ntt_top_masking_tb(source.read_text()))
                    source_entry = "${ADAMSBRIDGE_ROOT}/src/ntt_top/tb/ntt_top_masking_tb.sv"
                    filelist_text = filelist.read_text()
                    if filelist_text.count(source_entry) != 1:
                        raise RuntimeError("expected one pinned NTT masking testbench in filelist")
                    overlay_filelist = overlay_dir / "ntt_top_masking_tb.overlay.vf"
                    overlay_filelist.write_text(filelist_text.replace(source_entry, str(overlay)))
                    overlay_manifest = overlay_dir / "ntt_top_masking_tb.manifest.json"
                    overlay_manifest.write_text(json.dumps({
                        "source_file": str(source), "source_sha256": NTT_TOP_MASKING_TB_SHA256,
                        "overlay_file": str(overlay), "overlay_sha256": sha256(overlay),
                        "source_filelist": str(root / row["filelist"]),
                        "source_filelist_sha256": sha256(root / row["filelist"]),
                        "overlay_filelist": str(overlay_filelist),
                        "overlay_filelist_sha256": sha256(overlay_filelist),
                        "reason": "size the all-zero assignment, remove a stale unconnected port, and call the active in-file task; that task has no functional result checker",
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
                if row["runner_profile"] == "m7-component" or row["area"] == "uart":
                    if row["environment_id"] == "caliptra-v2-1-2-soc_ifc_tb":
                        source = caliptra / "src/soc_ifc/tb/soc_ifc_tb_pkg.sv"
                        if sha256(source) != SOC_IFC_TB_PKG_SHA256:
                            raise RuntimeError(f"refusing unreviewed SoC-IFC testbench source: {source}")
                        overlay_dir = output / "overlays"
                        overlay_dir.mkdir(exist_ok=True)
                        package_overlay = overlay_dir / "soc_ifc_tb_pkg.sv"
                        package_overlay.write_text(fix_soc_ifc_tb_pkg(source.read_text()))
                        intrblk_source = runtime / "soc_reg_intrblk_test.svh"
                        if sha256(intrblk_source) != SOC_IFC_INTRBLK_TB_SHA256:
                            raise RuntimeError(f"refusing unreviewed SoC-IFC INTRBLK testbench source: {intrblk_source}")
                        intrblk_overlay = overlay_dir / "soc_reg_intrblk_test.svh"
                        intrblk_overlay.write_text(fix_soc_ifc_intrblk_constraint(intrblk_source.read_text()))
                        top_source = caliptra / "src/soc_ifc/tb/soc_ifc_tb.sv"
                        if sha256(top_source) != SOC_IFC_TB_TOP_SHA256:
                            raise RuntimeError(f"refusing unreviewed SoC-IFC top testbench source: {top_source}")
                        top_overlay = overlay_dir / "soc_ifc_tb.sv"
                        top_overlay.write_text(fix_soc_ifc_tb(top_source.read_text(), str(intrblk_overlay)))
                        filelist_text = filelist.read_text()
                        package_entry = "${CALIPTRA_ROOT}/src/soc_ifc/tb/soc_ifc_tb_pkg.sv"
                        top_entry = "${CALIPTRA_ROOT}/src/soc_ifc/tb/soc_ifc_tb.sv"
                        if filelist_text.count(package_entry) != 1 or filelist_text.count(top_entry) != 1:
                            raise RuntimeError("pinned SoC-IFC filelist source entries changed")
                        filelist_text = filelist_text.replace(package_entry, str(package_overlay))
                        filelist_text = filelist_text.replace(top_entry, str(top_overlay))
                        filelist = overlay_dir / "soc_ifc_tb.overlay.vf"
                        filelist.write_text(filelist_text)
                        overlay_manifest = overlay_dir / "manifest.json"
                        overlay_manifest.write_text(json.dumps({
                            "package_source": str(source), "package_source_sha256": SOC_IFC_TB_PKG_SHA256,
                            "package_overlay": str(package_overlay), "package_overlay_sha256": sha256(package_overlay),
                            "intrblk_source": str(caliptra / "src/soc_ifc/tb/soc_reg_intrblk_test.svh"),
                            "intrblk_source_sha256": SOC_IFC_INTRBLK_TB_SHA256,
                            "intrblk_overlay": str(intrblk_overlay), "intrblk_overlay_sha256": sha256(intrblk_overlay),
                            "top_source": str(top_source), "top_source_sha256": SOC_IFC_TB_TOP_SHA256,
                            "top_overlay": str(top_overlay), "top_overlay_sha256": sha256(top_overlay),
                            "source_filelist": str(root / row["filelist"]),
                            "source_filelist_sha256": sha256(root / row["filelist"]),
                            "overlay_filelist": str(filelist), "overlay_filelist_sha256": sha256(filelist),
                            "reason": "make ignored fuse-lock returns void, fix pinned assignment-pattern syntax, precompute the testbench mask, and sample $changed at its default clock event",
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
                    need_hdl_filelist = "hdl_top.sv" not in filelist.read_text()
                    need_hvl_filelist = "hvl_top.sv" not in filelist.read_text()
                    hdl_filelist = root / row["hdl_filelist"]
                    sim_cwd = project / "tb/testbench"
                    if sim_cwd.is_dir():
                        shutil.copytree(sim_cwd, runtime, dirs_exist_ok=True)
                    if row["environment_id"] in {"uvmf-caliptra_top", "uvmf-soc_ifc", "uvmf-ecc", "uvmf-pv"}:
                        raw_interface_manifest, raw_interface_filelist = prepare_generated_bfm_raw_interface_overlay(
                            runtime, row["environment_id"], output, filelist
                        )
                        result["raw_interface_bfm_overlay_manifest"] = str(raw_interface_manifest)
                        command[command.index("-f") + 1] = str(raw_interface_filelist)
                    if need_hdl_filelist:
                        command += ["-f", str(hdl_filelist)]
                    if need_hvl_filelist:
                        command += ["-f", str(root / row["hvl_filelist"])]
                    command += ["-o", str(image), str(wrapper)]
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
