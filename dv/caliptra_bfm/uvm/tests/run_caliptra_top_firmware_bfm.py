#!/usr/bin/env python3
"""Run Caliptra DMA firmware on the open AXI target and full testbench top."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys


REPO = Path(__file__).resolve().parents[4]
ORIGINAL_AES_PKG = "${CALIPTRA_ROOT}/src/aes/rtl/aes_pkg.sv"
ORIGINAL_AXI_IF = "${CALIPTRA_ROOT}/src/axi/rtl/axi_if.sv"
ORIGINAL_AXI_COMPLEX = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_axi_complex.sv"
ORIGINAL_SRAM_EXPORT = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_veer_sram_export.sv"
ORIGINAL_TOP_SVA = "${CALIPTRA_ROOT}/src/integration/asserts/caliptra_top_sva.sv"
ORIGINAL_SOC_BFM = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_soc_bfm.sv"
ORIGINAL_TOP_TB = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb.sv"
ORIGINAL_TOP_SERVICES = "${CALIPTRA_ROOT}/src/integration/tb/caliptra_top_tb_services.sv"
ORIGINAL_DMA_GENERATOR = "${CALIPTRA_ROOT}/src/integration/tb/dma_testcase_generator.sv"
ORIGINAL_AXI4PC = "${CALIPTRA_AXI4PC_DIR}/Axi4PC.sv"
CASE_NAMES = ("smoke_test_dma", "smoke_test_dma_aes_gcm_short_1_dword", "rand_test_dma")
AES_PKG_SHA256 = "19a0096ffb731c99778d68a7baa81d0aa33c8b86a665231005d50251087a710f"
AES_PKG_OVERLAY_SHA256 = "d29c80cd5e51629b25a924e5249f85032c0b42f0f4006c3944906395e98ec158"
AXI_IF_SHA256 = "e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c"
AXI_IF_OVERLAY_SHA256 = "d9173b5d3ecf2bff70412016f752e902f3f6ccf4fdb68ffd58764fb33e34f834"
VECTOR_OUTPUTS = {
    "ecc_secp384r1.exe": "ecc_secp384r1.exe",
    "test_dilithium5": "test_dilithium5",
    "doe_test_gen.py": "doe_test_gen.py",
    "sha256_wntz_test_gen.py": "sha256_wntz_test_gen.py",
    "smoke_test_mldsa_vector.hex": "smoke_test_mldsa_vector.hex",
    "ml-kem/native_mlkem": "native_mlkem",
    "ml-kem/random_test_ml_kem.py": "random_test_ml_kem.py",
}
TOP_SVA_SHA256 = "6bd2ade137a90c0701aab28951ba6f8918724e0467c21756b0c308e6e9081c89"
TOP_SVA_OVERLAY_SHA256 = "6e67d67966b030931ec222aacfd0863086c7d35b5e916acd5f358a90ed538654"
SVA_DIAGNOSTICS_TO_REMOVE = (
    "SVA ERROR: KV[%0d][%0d] debug flush failed. Expected: %h, Got: %h, SelValue: %0d",
    "SVA ERROR: [MLDSA keygen] SK register %h does not match expected %h at index %h",
    "SVA ERROR: [MLDSA keygen] SK bank0 %h does not match expected %h at index %h",
    "SVA ERROR: [MLDSA keygen] SK bank1 %h does not match expected %h at index %h",
    "SVA ERROR: [MLDSA keygen] PK register %h does not match expected %h at index %h",
    "SVA ERROR: [MLDSA keygen] PK memory %h does not match expected %h at index %0d %0d",
    "SVA ERROR: [MLDSA signing] Signature C %h does not match expected %h at index %h",
    "SVA ERROR: [MLDSA signing] Signature H %h does not match expected %h at index %h",
    "SVA ERROR: [MLDSA signing] Sig output %h does not match expected sig %h at index %0d %0d",
)
SOC_BFM_SHA256 = "e0c60be6ad48681458ca38093a494ae263304997e658c5eefa006881da10ae06"
TOP_TB_SHA256 = "c212c32da99e90cd3991da65e653998cac3e945d7479abfd640b9d82f47659f9"
PHYSICAL_RNG_SHA256 = "85b73db47fdab769e55d8ca58c976a0cad68631d3f3eed0e7d13649c38abf01f"
TOP_TB_JTAG_OVERLAY_SHA256 = "6b3d6eeb6bbb3acddcc6045b86c9cc6c6ca3934164f29564485a9a3d2fc4d02a"
FAST_TRNG_TOP_TB_OVERLAY_SHA256 = "c4dbd3f75055982a5b31d05d8ba66039027b48b056e769985722a4db4b02dea6"
TOP_SERVICES_SHA256 = "5a048411bf1dcae2cda6406a6d32afba0dc9f9ef447c301875f7b6c7e1939343"
DMA_GENERATOR_HELPER_SCOPE = "caliptra_top_tb.tb_services_i"
FINISH = re.compile(r"Finished : minstret = (\d+), mcycle = (\d+)")
BAD = re.compile(
    r"\b(?:UVM_)?(?:ERROR|FATAL)\b|\bassert(?:ion)?\b[^\n]*\b(?:fail(?:ed|ure)?|error)\b",
    re.IGNORECASE,
)
JTAG_ERROR = re.compile(r"(?m)^jtag0: (?:Failed to|Unable to|Socket read failed|Error while|Client disappeared)")


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def prepare_sram_export_overlay(rtl_root, output_path):
    source = Path(rtl_root) / "src/integration/tb/caliptra_veer_sram_export.sv"
    text = source.read_text()
    anchor = "int ii,jj,kk,ll;"
    dccm_q_port = re.compile(
        r"\.Q\s*\(\s*\{el2_mem_export\.dccm_bank_ecc\[i\]\[pt\.DCCM_ECC_WIDTH-1:0\],"
        r"el2_mem_export\.dccm_bank_dout\[i\]\[pt\.DCCM_DATA_WIDTH-1:0\]\}\s*\)"
    )
    iccm_q_port = re.compile(
        r"\.Q\s*\(\s*\{el2_mem_export\.iccm_bank_ecc\[i\]\[pt\.ICCM_ECC_WIDTH-1:0\],"
        r"el2_mem_export\.iccm_bank_dout\[i\]\[31:0\]\}\s*\)"
    )
    counts = (len(dccm_q_port.findall(text)), len(iccm_q_port.findall(text)))
    if text.count(anchor) != 1 or not all(counts):
        raise ValueError(f"unexpected Caliptra SRAM exporter structure: {source}")
    text = text.replace(
        anchor,
        anchor + "\n    logic [pt.ICCM_NUM_BANKS-1:0][pt.ICCM_ECC_WIDTH-1:0] iccm_bank_ecc_icarus;"
        "\n    logic [pt.ICCM_NUM_BANKS-1:0][31:0] iccm_bank_dout_icarus;"
        "\n    logic [pt.DCCM_NUM_BANKS-1:0][pt.DCCM_ECC_WIDTH-1:0] dccm_bank_ecc_icarus;"
        "\n    logic [pt.DCCM_NUM_BANKS-1:0][pt.DCCM_DATA_WIDTH-1:0] dccm_bank_dout_icarus;"
        "\n    assign el2_mem_export.iccm_bank_ecc = iccm_bank_ecc_icarus;"
        "\n    assign el2_mem_export.iccm_bank_dout = iccm_bank_dout_icarus;"
        "\n    assign el2_mem_export.dccm_bank_ecc = dccm_bank_ecc_icarus;"
        "\n    assign el2_mem_export.dccm_bank_dout = dccm_bank_dout_icarus;",
        1,
    )
    text, dccm_replaced = dccm_q_port.subn(
        ".Q({dccm_bank_ecc_icarus[i], dccm_bank_dout_icarus[i]})", text
    )
    text, iccm_replaced = iccm_q_port.subn(
        ".Q({iccm_bank_ecc_icarus[i], iccm_bank_dout_icarus[i]})", text
    )
    if (dccm_replaced, iccm_replaced) != counts:
        raise ValueError(f"SRAM exporter overlay changed Q ports from {counts} to {(dccm_replaced, iccm_replaced)}")
    Path(output_path).write_text(text)
    return {"dccm_q_ports": dccm_replaced, "iccm_q_ports": iccm_replaced}


def allocate_axi_read_resp_user(text):
    before = "            data = new[len+1];\n            resp = new[len+1];"
    after = "            data = new[len+1];\n            resp_user = new[len+1];\n            resp = new[len+1];"
    if text.count(before) != 1:
        raise ValueError("expected one AXI read response-array allocation sequence")
    return text.replace(before, after, 1)


def replace_aes_mul2_partial_writes(text):
    before = (
        "  out[7] = in[6];\n"
        "  out[6] = in[5];\n"
        "  out[5] = in[4];\n"
        "  out[4] = in[3] ^ in[7];\n"
        "  out[3] = in[2] ^ in[7];\n"
        "  out[2] = in[1];\n"
        "  out[1] = in[0] ^ in[7];\n"
        "  out[0] = in[7];"
    )
    after = "  out = {in[6:0], 1'b0} ^ (in[7] ? 8'h1b : 8'h00);"
    if text.count(before) != 1:
        raise ValueError("expected one AES mul2 partial-write block")
    return text.replace(before, after, 1)


def prepare_aes_pkg_overlay(rtl_root, output_path):
    source = Path(rtl_root) / "src/aes/rtl/aes_pkg.sv"
    if sha256(source) != AES_PKG_SHA256:
        raise ValueError(f"Caliptra AES package source hash mismatch: {source}")
    Path(output_path).write_text(replace_aes_mul2_partial_writes(source.read_text()))
    if sha256(output_path) != AES_PKG_OVERLAY_SHA256:
        raise ValueError("Icarus AES package overlay did not match its recorded hash")


def prepare_axi_if_overlay(rtl_root, output_path):
    source = Path(rtl_root) / "src/axi/rtl/axi_if.sv"
    if sha256(source) != AXI_IF_SHA256:
        raise ValueError(f"Caliptra AXI interface source hash mismatch: {source}")
    Path(output_path).write_text(allocate_axi_read_resp_user(source.read_text()))
    if sha256(output_path) != AXI_IF_OVERLAY_SHA256:
        raise ValueError("Icarus AXI interface overlay did not match its recorded hash")


def remove_sva_debug_print(text, message):
    pattern = re.compile(
        r'(?ms)^[ \t]*\$display\("' + re.escape(message) +
        r'".*?\);[ \t]*(?:\r?\n)?'
    )
    return pattern.subn("", text)


def remove_sva_debug_prints(text):
    removed = 0
    for message in SVA_DIAGNOSTICS_TO_REMOVE:
        text, count = remove_sva_debug_print(text, message)
        if count != 1:
            raise ValueError(f"expected one checker diagnostic {message!r}, found {count}")
        removed += count
    return text, removed


def prepare_checker_overlay(rtl_root, output_path):
    source = Path(rtl_root) / "src/integration/asserts/caliptra_top_sva.sv"
    if sha256(source) != TOP_SVA_SHA256:
        raise ValueError(f"Caliptra checker source hash mismatch: {source}")
    text, removed = remove_sva_debug_prints(source.read_text())
    if removed != 9:
        raise ValueError(f"expected nine checker diagnostic prints, removed {removed}")
    Path(output_path).write_text(text)
    if sha256(output_path) != TOP_SVA_OVERLAY_SHA256:
        raise ValueError("Icarus checker overlay did not match its recorded hash")
    return removed


def prepare_reset_overlay(rtl_root, output_path):
    source = Path(rtl_root) / "src/integration/tb/caliptra_top_tb_soc_bfm.sv"
    if sha256(source) != SOC_BFM_SHA256:
        raise ValueError(f"Caliptra reset BFM source hash mismatch: {source}")
    text = source.read_text()
    before = "    initial begin\n        cptra_pwrgood = 1'b0;\n        BootFSM_BrkPoint ="
    after = "    initial begin\n        #0 cptra_pwrgood = 1'b0;\n        BootFSM_BrkPoint ="
    if text.count(before) != 1:
        raise ValueError("expected exactly one Caliptra reset-startup sequence")
    Path(output_path).write_text(text.replace(before, after, 1))


def accelerate_physical_rng_for_diagnostic(text):
    before = "physical_rng physical_rng ("
    if text.count(before) != 1:
        raise ValueError("expected exactly one physical_rng instance")
    return text.replace(before, "physical_rng #(.DutyCycle(50)) physical_rng (", 1)


def prepare_jtag_port_overlay(rtl_root, output_path, fast_trng=False):
    source = Path(rtl_root) / "src/integration/tb/caliptra_top_tb.sv"
    if sha256(source) != TOP_TB_SHA256:
        raise ValueError(f"Caliptra top testbench source hash mismatch: {source}")
    rng_model = Path(rtl_root) / "src/entropy_src/tb/physical_rng.sv"
    if sha256(rng_model) != PHYSICAL_RNG_SHA256:
        raise ValueError(f"Caliptra physical RNG model hash mismatch: {rng_model}")
    text = source.read_text()
    before = ".ListenPort     (63224)"
    if text.count(before) != 1:
        raise ValueError("expected exactly one JTAG DPI listen port")
    overlay = "`timescale 1ns/1ps\n" + text.replace(before, ".ListenPort     (0)", 1)
    if fast_trng:
        overlay = accelerate_physical_rng_for_diagnostic(overlay)
    Path(output_path).write_text(overlay)
    expected = FAST_TRNG_TOP_TB_OVERLAY_SHA256 if fast_trng else TOP_TB_JTAG_OVERLAY_SHA256
    if sha256(output_path) != expected:
        raise ValueError("Caliptra top testbench overlay did not match its recorded hash")


def skip_pq_vector_generators(text):
    before = "            mldsa_input_hex_gen();\n            mlkem_testvector_generator();"
    after = (
        '            if (!$test$plusargs("CLP_SKIP_PQ_VECTOR_GENERATION")) begin\n'
        "                mldsa_input_hex_gen();\n"
        "                mlkem_testvector_generator();\n"
        "            end"
    )
    if text.count(before) != 1:
        raise ValueError("expected one MLDSA/MLKEM vector-generation call block")
    return text.replace(before, after, 1)


def prepare_pq_vector_overlay(rtl_root, output_path):
    source = Path(rtl_root) / "src/integration/tb/caliptra_top_tb_services.sv"
    if sha256(source) != TOP_SERVICES_SHA256:
        raise ValueError(f"Caliptra top services source hash mismatch: {source}")
    Path(output_path).write_text(skip_pq_vector_generators(source.read_text()))


def prepare_dma_generator_overlay(rtl_root, output_path, force_first_reset=False):
    generator_script = REPO / "docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py"
    command = [
        sys.executable, str(generator_script), "--caliptra-root", str(rtl_root),
        "--output", str(output_path), "--top", DMA_GENERATOR_HELPER_SCOPE,
    ]
    if force_first_reset:
        command.append("--force-first-reset")
    subprocess.run(command, check=True)


def prepare_limited_aes_case_source(rtl_root, output_dir, case_limit):
    source = Path(rtl_root) / "src/integration/test_suites/smoke_test_dma_aes_gcm_short_1_dword"
    source_file = source / "smoke_test_dma_aes_gcm_short_1_dword.c"
    text = source_file.read_text()
    table = re.search(r"test_config_t\s+test_cases\[\]\s*=\s*\{(.*?)\n\s*\};", text, re.S)
    if not table:
        raise ValueError(f"unexpected AES DMA test-case table: {source_file}")
    case_count = len(re.findall(r"(?m)^\s*\{AES_(?:ENC|DEC),", table.group(1)))
    if not 1 <= case_limit <= case_count:
        raise ValueError(f"AES DMA case limit must be between 1 and {case_count}")
    before = "int num_tests = sizeof(test_cases) / sizeof(test_config_t);"
    if text.count(before) != 1:
        raise ValueError(f"unexpected AES DMA firmware loop: {source_file}")
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True)
    patched_source = output_dir / source_file.name
    patched_source.write_text(
        text.replace(before, f"int num_tests = {case_limit}; /* bounded AES DMA diagnostic */", 1)
    )
    shutil.copy2(source / "caliptra_isr.h", output_dir / "caliptra_isr.h")
    return output_dir, sha256(patched_source)


def prepare_iverilog_profile(base_profile, output_profile, repo_root, rtl_root,
                             checker_overlay, reset_overlay, jtag_overlay,
                             generator_overlay=None, pq_vector_overlay=None):
    text = Path(base_profile).read_text()
    lines = text.splitlines()
    if lines.count(ORIGINAL_AXI4PC) > 1:
        raise ValueError(f"Icarus profile contains duplicate licensed checker entries: {ORIGINAL_AXI4PC}")
    excluded_sources = [ORIGINAL_AXI4PC] if ORIGINAL_AXI4PC in lines else []
    lines = [line for line in lines if line != ORIGINAL_AXI4PC]
    for source in (ORIGINAL_AES_PKG, ORIGINAL_AXI_IF, ORIGINAL_AXI_COMPLEX, ORIGINAL_SRAM_EXPORT, ORIGINAL_TOP_SVA,
                   ORIGINAL_SOC_BFM, ORIGINAL_TOP_TB, ORIGINAL_DMA_GENERATOR):
        if lines.count(source) != 1:
            raise ValueError(f"Icarus profile must contain exactly one {source}")

    sram_overlay = Path(output_profile).parent / "caliptra_veer_sram_export_icarus.sv"
    prepare_sram_export_overlay(rtl_root, sram_overlay)
    aes_overlay = Path(output_profile).parent / "aes_pkg_icarus.sv"
    prepare_aes_pkg_overlay(rtl_root, aes_overlay)
    axi_if_overlay = Path(output_profile).parent / "axi_if_icarus.sv"
    prepare_axi_if_overlay(rtl_root, axi_if_overlay)

    bfm_sources = []
    for line in (Path(repo_root) / "dv/caliptra_bfm/caliptra_bfm.f").read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        source = (Path(repo_root) / line).resolve()
        if not source.is_file():
            raise ValueError(f"missing BFM source in caliptra_bfm.f: {source}")
        bfm_sources.append(source)

    replacement = Path(repo_root) / "dv/caliptra_bfm/axi/caliptra_top_tb_axi_complex_bfm.sv"
    checker_overlay = Path(checker_overlay)
    sources = [replacement, *bfm_sources]
    overlays = [aes_overlay, axi_if_overlay, sram_overlay, checker_overlay, reset_overlay, jtag_overlay]
    if generator_overlay:
        overlays.append(generator_overlay)
    if pq_vector_overlay:
        overlays.append(pq_vector_overlay)
    for source in [*overlays, *sources]:
        if any(char.isspace() for char in str(source)):
            raise ValueError(f"Icarus filelists cannot safely represent a source path with whitespace: {source}")
    lines = [line for line in lines if line != ORIGINAL_AXI_COMPLEX]
    replacements = {
        ORIGINAL_AES_PKG: str(aes_overlay),
        ORIGINAL_AXI_IF: str(axi_if_overlay),
        ORIGINAL_SRAM_EXPORT: str(sram_overlay),
        ORIGINAL_TOP_SVA: str(checker_overlay),
        ORIGINAL_SOC_BFM: str(reset_overlay),
        ORIGINAL_TOP_TB: str(jtag_overlay),
    }
    if generator_overlay:
        replacements[ORIGINAL_DMA_GENERATOR] = str(generator_overlay)
    if pq_vector_overlay:
        if lines.count(ORIGINAL_TOP_SERVICES) != 1:
            raise ValueError(f"Icarus profile must contain exactly one {ORIGINAL_TOP_SERVICES}")
        replacements[ORIGINAL_TOP_SERVICES] = str(pq_vector_overlay)
    lines = [replacements.get(line, line) for line in lines]
    lines.extend(str(source) for source in sources)
    Path(output_profile).write_text("\n".join(lines) + "\n")
    return excluded_sources


def load_case(rtl_root, name):
    if name not in CASE_NAMES:
        raise ValueError(f"supported cases: {', '.join(CASE_NAMES)}")
    case_yaml = Path(rtl_root) / "src/integration/test_suites" / name / f"{name}.yml"
    text = case_yaml.read_text()
    testnames = re.findall(r"(?m)^testname:\s*(\S+)\s*$", text)
    seeds = re.findall(r"(?m)^seed:\s*(\S+)\s*$", text)
    if testnames != [name] or len(seeds) != 1:
        raise ValueError(f"unexpected Caliptra case YAML: {case_yaml}")
    seed = "1" if seeds[0] == "${PLAYBOOK_RANDOM_SEED}" else seeds[0]
    if not seed.isdigit():
        raise ValueError(f"case seed must be numeric: {seed}")
    plusargs = re.findall(r"(?m)^\s*-\s+(\+\S+)\s*$", text)
    return case_yaml, seed, plusargs


DCCM_BASE = 0x50000000
DCCM_SIZE = 0x40000
DATA_COPY_BRANCH_PC = 0x46
DATA_COPY_BRANCH = bytes.fromhex("63 fa 62 00")
FAST_BRANCH = bytes.fromhex("6f 00 40 01")


def readmemh_image(text):
    # Caliptra's program and DCCM hex files are byte-addressed and fit in 256 KiB.
    image = bytearray(DCCM_SIZE)
    present = bytearray(DCCM_SIZE)
    address = None
    for line_number, line in enumerate(text.splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        if line.startswith("@"):
            if not re.fullmatch(r"@[0-9a-fA-F]+", line):
                raise ValueError(f"invalid readmemh address on line {line_number}")
            address = int(line[1:], 16)
            if address >= DCCM_SIZE:
                raise ValueError(f"readmemh address exceeds the 256 KiB image on line {line_number}")
            continue
        tokens = line.split()
        if address is None or any(not re.fullmatch(r"[0-9a-fA-F]{2}", token) for token in tokens):
            raise ValueError(f"invalid byte data on readmemh line {line_number}")
        for token in tokens:
            if address >= DCCM_SIZE or present[address]:
                raise ValueError(f"duplicate or out-of-range readmemh byte on line {line_number}")
            image[address] = int(token, 16)
            present[address] = 1
            address += 1
    return image, present


def read_hex_range(text, start, end):
    if start < 0 or end <= start or end > DCCM_SIZE:
        raise ValueError("invalid Caliptra readmemh byte range")
    image, present = readmemh_image(text)
    if not all(present[start:end]):
        raise ValueError(f"readmemh image does not cover 0x{start:x}-0x{end:x}")
    return bytes(image[start:end])


def replace_hex_range(text, start, replacement):
    read_hex_range(text, start, start + len(replacement))
    end = start + len(replacement)
    output = []
    address = None
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            output.append(line)
        elif stripped.startswith("@"):
            address = int(stripped[1:], 16)
            output.append(line)
        else:
            tokens = stripped.split()
            changed = False
            for index in range(len(tokens)):
                if start <= address < end:
                    tokens[index] = f"{replacement[address - start]:02X}"
                    changed = True
                address += 1
            output.append(" ".join(tokens) if changed else line)
    return "\n".join(output) + ("\n" if text.endswith("\n") else "")


def format_readmemh_segment(start, data):
    lines = [f"@{start:08X}"]
    lines.extend(" ".join(f"{byte:02X}" for byte in data[offset:offset + 16])
                  for offset in range(0, len(data), 16))
    return "\n".join(lines) + "\n"


def prepare_fast_boot_data_preload(program_path, dccm_path, map_path, dis_path):
    symbols = {}
    map_text = Path(map_path).read_text()
    for name in ("_data_lma_start", "_bss_lma_start", "_data_vma_start"):
        matches = re.findall(rf"(?m)^\s*0x([0-9a-fA-F]+)\s+{name}\s*=", map_text)
        if len(matches) != 1:
            raise ValueError(f"firmware map must define {name} exactly once")
        symbols[name] = int(matches[0], 16)

    disassembly = Path(dis_path).read_text()
    if (not re.search(r"(?m)^\s*46:\s+0062fa63\s+bgeu\s+t0,t1,5a\s+<bss_cp_setup>\s*$", disassembly) or
            any(not re.search(rf"(?m)^000000{address} <{label}>:$", disassembly)
                for address, label in (("4a", "data_cp_loop"), ("5a", "bss_cp_setup"),
                                       ("76", "bss_cp_loop"), ("86", "post_cp_loops")))):
        raise ValueError("firmware CRT0 startup branch or data/BSS loops are not the verified layout")

    data_start = symbols["_data_lma_start"]
    data_end = symbols["_bss_lma_start"]
    data_vma = symbols["_data_vma_start"]
    if (data_end <= data_start or (data_start | data_end | data_vma) & 3 or
            data_end > DCCM_SIZE or data_end - data_start > DCCM_SIZE):
        raise ValueError("firmware .data range is empty, unaligned, or outside the image")
    if not DCCM_BASE <= data_vma < DCCM_BASE + DCCM_SIZE:
        raise ValueError("firmware .data destination is outside DCCM")
    destination = data_vma - DCCM_BASE
    destination_end = destination + data_end - data_start
    if destination_end > DCCM_SIZE:
        raise ValueError("firmware .data destination exceeds DCCM")

    program_path = Path(program_path)
    dccm_path = Path(dccm_path)
    program_text = program_path.read_text()
    dccm_text = dccm_path.read_text()
    program, program_present = readmemh_image(program_text)
    dccm, dccm_present = readmemh_image(dccm_text)
    if (not all(program_present[DATA_COPY_BRANCH_PC:DATA_COPY_BRANCH_PC + 4]) or
            bytes(program[DATA_COPY_BRANCH_PC:DATA_COPY_BRANCH_PC + 4]) != DATA_COPY_BRANCH):
        raise ValueError("firmware startup branch bytes do not match the verified data-copy branch")
    if not all(program_present[data_start:data_end]):
        raise ValueError("firmware program image does not cover its .data load range")
    if any(dccm_present[destination:destination_end]):
        raise ValueError("firmware .data destination overlaps existing DCCM image data")

    data = bytes(program[data_start:data_end])
    patched_program = replace_hex_range(program_text, DATA_COPY_BRANCH_PC, FAST_BRANCH)
    preloaded_dccm = format_readmemh_segment(destination, data) + dccm_text
    program_path.write_text(patched_program)
    dccm_path.write_text(preloaded_dccm)
    return {
        "diagnostic_only": True,
        "source_lma_start": f"0x{data_start:x}",
        "source_lma_end": f"0x{data_end:x}",
        "destination_vma_start": f"0x{data_vma:x}",
        "destination_offset": f"0x{destination:x}",
        "data_bytes": len(data),
        "data_sha256": hashlib.sha256(data).hexdigest(),
        "branch_pc": f"0x{DATA_COPY_BRANCH_PC:x}",
        "original_branch": DATA_COPY_BRANCH.hex(),
        "replacement_branch": FAST_BRANCH.hex(),
    }

def required_env(name):
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"set {name} before running this test")
    path = Path(value).expanduser().resolve()
    if not path.exists():
        raise ValueError(f"{name} does not exist: {path}")
    return path


def normalize_gcc_prefix(prefix, env):
    prefix_path = Path(prefix.removesuffix("-"))
    if prefix_path.parent != Path("."):
        env["PATH"] = f"{prefix_path.parent}{os.pathsep}{env.get('PATH', '')}"
    return prefix_path.name


def run_logged(command, cwd, env, logfile):
    with Path(logfile).open("wb") as log:
        return subprocess.run(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT).returncode


def scan_sim_log(path):
    passed = failed = bad = jtag_errors = 0
    finish = None
    with Path(path).open(errors="replace") as log:
        for line in log:
            passed += line.count("* TESTCASE PASSED")
            failed += line.count("TESTCASE FAILED")
            bad += bool(BAD.search(line))
            jtag_errors += bool(JTAG_ERROR.match(line))
            match = FINISH.search(line)
            if match:
                finish = [int(match.group(1)), int(match.group(2))]
    return {"passed": passed, "failed": failed, "bad": bad,
            "jtag_errors": jtag_errors, "finish": finish}


def prepare_native_vectors(rtl_root, output, env):
    if sys.platform != "darwin" or platform.machine() != "arm64":
        raise RuntimeError("native Caliptra vector preparation currently requires macOS ARM64")
    tools = {name: shutil.which(name) for name in ("brew", "clang", "make", "openssl", "xxd", "python3.12")}
    missing = [name for name, path in tools.items() if path is None]
    if missing:
        raise RuntimeError(f"missing native vector tools: {missing}")
    roots = {
        package: Path(subprocess.check_output([tools["brew"], "--prefix", package], text=True).strip())
        for package in ("openssl@3", "mbedtls@3")
    }
    adams = Path(rtl_root) / "submodules/adams-bridge"
    ref_source = adams / "src/abr_top/uvmf/Dilithium_ref/dilithium/ref"
    vectors = REPO / "dv/caliptra_bfm/native_vectors"
    inputs = {
        "native_mlkem.c": vectors / "native_mlkem.c",
        "random_test_ml_kem.py": vectors / "random_test_ml_kem.py",
        "stage_mldsa.py": vectors / "stage_mldsa.py",
        "stage_sha256_wntz.py": vectors / "stage_sha256_wntz.py",
        "check_native_mlkem.py": vectors / "check_native_mlkem.py",
        "check_native_mldsa.py": vectors / "check_native_mldsa.py",
        "ecc_secp384r1.c": Path(rtl_root) / "src/ecc/tb/ecc_secp384r1.c",
        "doe_test_gen.py": Path(rtl_root) / "src/doe/tb/doe_test_gen.py",
        "sha256_wntz_test_gen.py": Path(rtl_root) / "src/sha256/tb/sha256_wntz_test_gen.py",
        "test_dilithium.c": ref_source / "test/test_dilithium.c",
        "smoke_test_mldsa_vector.hex": Path(rtl_root) / "src/mldsa/tb/smoke_test_mldsa_vector.hex",
        "openssl_libcrypto": roots["openssl@3"] / "lib/libcrypto.dylib",
        "mbedtls_libcrypto": roots["mbedtls@3"] / "lib/libmbedcrypto.dylib",
        "mbedtls_libx509": roots["mbedtls@3"] / "lib/libmbedx509.dylib",
        "mbedtls_libtls": roots["mbedtls@3"] / "lib/libmbedtls.dylib",
    }
    missing = [name for name, path in inputs.items() if not path.is_file()]
    if missing:
        raise RuntimeError(f"missing native vector inputs: {missing}")

    native = Path(output) / "native_vectors"
    native.mkdir()
    openssl = roots["openssl@3"]
    mbedtls = roots["mbedtls@3"]
    ref = native / "dilithium-ref"
    shutil.copytree(ref_source, ref)
    (ref / "test/test_dilithium5").unlink(missing_ok=True)
    generated = {
        "ecc_secp384r1.exe": native / "ecc_secp384r1.exe",
        "test_dilithium5": ref / "test/test_dilithium5",
        "sha256_wntz_test_gen.py": native / "sha256_wntz_test_gen.py",
        "native_mlkem": native / "native_mlkem",
    }
    commands = [
        [tools["clang"], "-Wall", "-Wextra", "-Werror", "-O2", f"-I{openssl / 'include'}",
         str(vectors / "native_mlkem.c"), f"-L{openssl / 'lib'}", "-lcrypto", "-o", str(generated["native_mlkem"])],
        [tools["clang"], "-O2", f"-I{mbedtls / 'include'}", str(inputs["ecc_secp384r1.c"]),
         f"-L{mbedtls / 'lib'}", "-lmbedtls", "-lmbedx509", "-lmbedcrypto", "-o", str(generated["ecc_secp384r1.exe"])],
        [sys.executable, str(vectors / "stage_mldsa.py"), str(inputs["test_dilithium.c"]),
         str(ref / "test/test_dilithium.c")],
        [tools["make"], "-C", str(ref), f"CC={tools['clang']}", "test/test_dilithium5"],
        [sys.executable, str(vectors / "stage_sha256_wntz.py"), str(inputs["sha256_wntz_test_gen.py"]),
         str(generated["sha256_wntz_test_gen.py"])],
        [sys.executable, str(vectors / "check_native_mlkem.py"), str(adams), str(generated["native_mlkem"])],
        [sys.executable, str(vectors / "check_native_mldsa.py"), str(adams), str(generated["test_dilithium5"])],
    ]
    for index, command in enumerate(commands):
        log = native / f"step_{index}.log"
        if run_logged(command, native, env, log):
            raise RuntimeError(f"native vector preparation failed at step {index}; see {log}")
    files = {
        "ecc_secp384r1.exe": generated["ecc_secp384r1.exe"],
        "test_dilithium5": generated["test_dilithium5"],
        "doe_test_gen.py": inputs["doe_test_gen.py"],
        "sha256_wntz_test_gen.py": generated["sha256_wntz_test_gen.py"],
        "smoke_test_mldsa_vector.hex": inputs["smoke_test_mldsa_vector.hex"],
        "native_mlkem": generated["native_mlkem"],
        "random_test_ml_kem.py": vectors / "random_test_ml_kem.py",
    }
    return files, {name: sha256(path) for name, path in files.items()}, commands, tools


def stage_native_vectors(test_output, files, hashes, tools, env):
    (test_output / "ml-kem/tv").mkdir(parents=True)
    bin_dir = test_output / ".bin"
    bin_dir.mkdir()
    for relative, name in VECTOR_OUTPUTS.items():
        target = test_output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(files[name], target)
        if sha256(target) != hashes[name]:
            raise RuntimeError(f"native vector copy hash mismatch: {relative}")
    for alias in ("python", "python3.9"):
        (bin_dir / alias).symlink_to(tools["python3.12"])
    for alias in ("openssl", "xxd"):
        (bin_dir / alias).symlink_to(tools[alias])
    env["PATH"] = f"{bin_dir}{os.pathsep}{env['PATH']}"
    return {relative: hashes[name] for relative, name in VECTOR_OUTPUTS.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", choices=CASE_NAMES, default="smoke_test_dma")
    parser.add_argument("--output", required=True, type=Path, help="new directory outside the source checkouts")
    parser.add_argument("--fast-trng", action="store_true",
                        help="use the diagnostic 50-cycle physical RNG cadence; default is 500")
    parser.add_argument("--fast-boot-data-preload", action="store_true",
                        help="diagnostic only: preload .data and skip its CRT0 copy for a supported DMA firmware case")
    parser.add_argument("--first-aes-case-diagnostic", action="store_true",
                        help="diagnostic only: run one AES/DMA case and skip unrelated MLDSA/MLKEM vector generation")
    parser.add_argument("--limit-aes-cases", type=int, metavar="N",
                        help="diagnostic only: run the first N cases of the short AES/DMA firmware suite")
    parser.add_argument("--skip-pq-vector-generation", action="store_true",
                        help="diagnostic only: skip unrelated MLDSA/MLKEM vector generation; keep all AES DMA cases")
    parser.add_argument("--quiet-firmware", action="store_true",
                        help="diagnostic only: suppress low-priority firmware prints for supported DMA cases")
    parser.add_argument("--trace-axi", action="store_true",
                        help="diagnostic only: trace CPU progress and full-top AXI handshakes with VPI")
    parser.add_argument("--rand-dma-iterations", type=int, metavar="N",
                        help="diagnostic only: run the first N generated rand_test_dma transfers (1..100)")
    parser.add_argument("--force-first-rand-dma-reset", action="store_true",
                        help="diagnostic only: set inject_rst on the first generated rand_test_dma transfer")
    args = parser.parse_args()
    if args.fast_boot_data_preload and args.case not in (
            "smoke_test_dma_aes_gcm_short_1_dword", "rand_test_dma"):
        raise ValueError("--fast-boot-data-preload requires a supported DMA firmware case")
    if args.first_aes_case_diagnostic and args.limit_aes_cases is not None:
        raise ValueError("use only one of --first-aes-case-diagnostic and --limit-aes-cases")
    aes_case_limit = 1 if args.first_aes_case_diagnostic else args.limit_aes_cases
    if aes_case_limit is not None and args.case != "smoke_test_dma_aes_gcm_short_1_dword":
        raise ValueError("AES case limits are available only for smoke_test_dma_aes_gcm_short_1_dword")
    if aes_case_limit is not None and aes_case_limit < 1:
        raise ValueError("--limit-aes-cases must be positive")
    if args.skip_pq_vector_generation and args.case != "smoke_test_dma_aes_gcm_short_1_dword":
        raise ValueError("--skip-pq-vector-generation is limited to smoke_test_dma_aes_gcm_short_1_dword")
    if args.quiet_firmware and args.case not in (
            "smoke_test_dma_aes_gcm_short_1_dword", "rand_test_dma"):
        raise ValueError("--quiet-firmware requires a supported DMA firmware case")
    if args.rand_dma_iterations is not None:
        if args.case != "rand_test_dma":
            raise ValueError("--rand-dma-iterations is limited to rand_test_dma")
        if not 1 <= args.rand_dma_iterations <= 100:
            raise ValueError("--rand-dma-iterations must be between 1 and 100")
    if args.force_first_rand_dma_reset:
        if args.case != "rand_test_dma":
            raise ValueError("--force-first-rand-dma-reset is limited to rand_test_dma")
        if args.rand_dma_iterations is None:
            raise ValueError("--force-first-rand-dma-reset requires --rand-dma-iterations")
    skip_pq_vectors = aes_case_limit is not None or args.skip_pq_vector_generation
    quiet_firmware = aes_case_limit is not None or args.quiet_firmware

    rtl = required_env("CALIPTRA_RTL")
    base_profile = required_env("CALIPTRA_BFM_PROFILE")
    jtagdpi = required_env("CALIPTRA_JTAGDPI_VPI")
    gcc_prefix = os.environ.get("CALIPTRA_GCC_PREFIX")
    if not gcc_prefix:
        raise ValueError("set CALIPTRA_GCC_PREFIX to the RISC-V toolchain prefix")
    iverilog = shutil.which(os.environ.get("IVERILOG_BIN", "iverilog"))
    vvp = shutil.which(os.environ.get("VVP_BIN", "vvp"))
    if not iverilog or not vvp:
        raise ValueError("IVERILOG_BIN and VVP_BIN must name executable tools")
    if args.output.exists():
        raise ValueError(f"output directory already exists: {args.output}")

    case_yaml, seed, plusargs = load_case(rtl, args.case)
    source_commit = subprocess.check_output(["git", "-C", str(rtl), "rev-parse", "HEAD"], text=True).strip()
    args.output.mkdir(parents=True)
    args.output = args.output.resolve()
    profile = args.output / "open_caliptra_top.vf"
    checker_overlay = args.output / "caliptra_top_sva_icarus.sv"
    prepare_checker_overlay(rtl, checker_overlay)
    reset_overlay = args.output / "caliptra_top_tb_soc_bfm_icarus.sv"
    prepare_reset_overlay(rtl, reset_overlay)
    jtag_overlay = args.output / "caliptra_top_tb_ephemeral_jtag.sv"
    prepare_jtag_port_overlay(rtl, jtag_overlay, args.fast_trng)
    generator_overlay = None
    if args.case == "rand_test_dma":
        generator_overlay = args.output / "dma_testcase_generator_icarus.sv"
        prepare_dma_generator_overlay(rtl, generator_overlay, args.force_first_rand_dma_reset)
    pq_vector_overlay = None
    case_limit_source = None
    if skip_pq_vectors:
        pq_vector_overlay = args.output / "caliptra_top_tb_services_skip_pq_vectors.sv"
        prepare_pq_vector_overlay(rtl, pq_vector_overlay)
    if aes_case_limit is not None:
        case_limit_source = prepare_limited_aes_case_source(
            rtl, args.output / "limited_aes_case_source", aes_case_limit
        )
    env = os.environ.copy()
    gcc_prefix = normalize_gcc_prefix(gcc_prefix, env)
    env.update(
        CALIPTRA_ROOT=str(rtl),
        CALIPTRA_PRIM_ROOT=str(rtl / "src/caliptra_prim_generic"),
        CALIPTRA_PRIM_MODULE_PREFIX="caliptra_prim_generic",
        CALIPTRA_AXI4PC_DIR=str(rtl / "src/integration/tb"),
    )
    profile_excluded_sources = prepare_iverilog_profile(
        base_profile, profile, REPO, rtl, checker_overlay,
        reset_overlay, jtag_overlay, generator_overlay, pq_vector_overlay)
    vector_files, vector_hashes, vector_commands, vector_tools = prepare_native_vectors(
        rtl, args.output, env
    )
    binary = args.output / "caliptra_top_tb.vvp"
    compile_command = [
        iverilog, "-g2017", "-gassertions", "-gcommercial-unsafe", "-s", "caliptra_top_tb",
        "-D", "RV_OPENSOURCE", "-D", "CLP_ASSERT_ON", "-D", "CALIPTRA_INTERNAL_TRNG",
        "-f", str(profile), "-o", str(binary),
    ]
    compile_exit = run_logged(compile_command, args.output, env, args.output / "compile.log")
    if compile_exit:
        raise RuntimeError(f"top compile failed ({compile_exit}); see {args.output / 'compile.log'}")

    trace_source = None
    trace_plugin = None
    trace_compile_command = None
    trace_compile_exit = None
    if args.trace_axi:
        trace_source = REPO / "evidence/caliptra-bfm-open-top-smoke-20261006/sim-axi-trace-vpi.c"
        trace_compiler = shutil.which(os.environ.get(
            "IVERILOG_VPI_BIN", str(Path(iverilog).with_name("iverilog-vpi"))))
        if not trace_compiler:
            raise ValueError("--trace-axi requires IVERILOG_VPI_BIN or sibling iverilog-vpi")
        trace_dir = args.output / "trace_vpi"
        trace_dir.mkdir()
        trace_compile_command = [trace_compiler, str(trace_source)]
        trace_compile_exit = run_logged(
            trace_compile_command, trace_dir, env, trace_dir / "compile.log")
        trace_plugin = trace_dir / f"{trace_source.stem}.vpi"
        if trace_compile_exit or not trace_plugin.is_file():
            raise RuntimeError(f"AXI trace VPI build failed ({trace_compile_exit}); see {trace_dir / 'compile.log'}")

    test_output = args.output / args.case
    test_output.mkdir()
    build_flags = "-std=gnu11 -O2"
    if quiet_firmware:
        build_flags += " -DCPT_VERBOSITY=ERROR"
    firmware_command = [
        "make", "-f", str(rtl / "tools/scripts/Makefile"), f"TESTNAME={args.case}",
        f"GCC_PREFIX={gcc_prefix}", "CALIPTRA_INTERNAL_TRNG=1", f"PLAYBOOK_RANDOM_SEED={seed}",
        f"BUILD_CFLAGS={build_flags}",
    ]
    if case_limit_source:
        firmware_command.append(f"TEST_DIR={case_limit_source[0]}")
    firmware_command.append("program.hex")
    firmware_exit = run_logged(firmware_command, test_output, env, test_output / "firmware.log")
    images = ["program.hex", "dccm.hex", "iccm.hex", "mailbox.hex"]
    missing_images = [name for name in images if not (test_output / name).is_file()]
    if firmware_exit or missing_images or (test_output / "program.hex").stat().st_size == 0:
        raise RuntimeError(f"firmware build failed ({firmware_exit}); missing/empty images: {missing_images}")

    stock_firmware_image_sha256 = {name: sha256(test_output / name) for name in images}
    fast_boot_data_preload = None
    if args.fast_boot_data_preload or aes_case_limit is not None:
        fast_boot_data_preload = prepare_fast_boot_data_preload(
            test_output / "program.hex", test_output / "dccm.hex",
            test_output / f"{args.case}.map", test_output / f"{args.case}.dis",
        )
    simulation_image_sha256 = {name: sha256(test_output / name) for name in images}
    staged_vector_hashes = stage_native_vectors(test_output, vector_files, vector_hashes, vector_tools, env)
    sim_command = [str(vvp), "-d", str(jtagdpi), "-n"]
    if trace_plugin:
        sim_command.extend(["-m", str(trace_plugin)])
    sim_command.extend([str(binary), "+CLP_REGRESSION", *plusargs])
    if args.rand_dma_iterations is not None:
        sim_command.append(f"+NUM_ITERATIONS={args.rand_dma_iterations}")
    if skip_pq_vectors:
        sim_command.append("+CLP_SKIP_PQ_VECTOR_GENERATION")
    sim_exit = run_logged(sim_command, test_output, env, test_output / "sim.log")
    log_scan = scan_sim_log(test_output / "sim.log")
    passed = (sim_exit == 0 and log_scan["passed"] == 1 and log_scan["failed"] == 0 and
              log_scan["bad"] == 0 and log_scan["jtag_errors"] == 0 and log_scan["finish"] is not None)
    result = {
        "test": args.case,
        "passed": passed,
        "caliptra_commit": source_commit,
        "case_yaml_sha256": sha256(case_yaml),
        "bfm_wrapper_sha256": sha256(REPO / "dv/caliptra_bfm/axi/caliptra_top_tb_axi_complex_bfm.sv"),
        "aes_pkg_overlay_sha256": sha256(args.output / "aes_pkg_icarus.sv"),
        "trng_duty_cycle": 50 if args.fast_trng else 500,
        "physical_rng_source_sha256": sha256(rtl / "src/entropy_src/tb/physical_rng.sv"),
        "axi_if_overlay_sha256": sha256(args.output / "axi_if_icarus.sv"),
        "checker_overlay_sha256": sha256(checker_overlay),
        "reset_overlay_sha256": sha256(reset_overlay),
        "jtag_overlay_sha256": sha256(jtag_overlay),
        "pq_vector_source_sha256": TOP_SERVICES_SHA256 if pq_vector_overlay else None,
        "pq_vector_overlay_sha256": sha256(pq_vector_overlay) if pq_vector_overlay else None,
        "dma_generator_overlay_sha256": sha256(generator_overlay) if generator_overlay else None,
        "profile_sha256": sha256(profile),
        "profile_excluded_sources": profile_excluded_sources,
        "compile_command": compile_command,
        "compile_exit": compile_exit,
        "firmware_command": firmware_command,
        "firmware_exit": firmware_exit,
        "aes_case_limit": aes_case_limit,
        "aes_case_limit_source_sha256": case_limit_source[1] if case_limit_source else None,
        "rand_dma_iterations": args.rand_dma_iterations,
        "force_first_rand_dma_reset": args.force_first_rand_dma_reset,
        "firmware_image_sha256": stock_firmware_image_sha256,
        "simulation_image_sha256": simulation_image_sha256,
        "fast_boot_data_preload": fast_boot_data_preload,
        "diagnostic_modes": {"fast_trng": args.fast_trng,
                             "fast_boot_data_preload": args.fast_boot_data_preload or aes_case_limit is not None,
                             "first_aes_case": args.first_aes_case_diagnostic,
                             "aes_case_limit": aes_case_limit,
                             "rand_dma_iterations": args.rand_dma_iterations,
                             "force_first_rand_dma_reset": args.force_first_rand_dma_reset,
                             "skip_pq_vector_generation": skip_pq_vectors,
                             "quiet_firmware": quiet_firmware},
        "native_vector_build_commands": vector_commands,
        "native_vector_tools": vector_tools,
        "native_vector_sha256": staged_vector_hashes,
        "axi_trace_source_sha256": sha256(trace_source) if trace_source else None,
        "axi_trace_plugin_sha256": sha256(trace_plugin) if trace_plugin else None,
        "axi_trace_compile_command": trace_compile_command,
        "axi_trace_compile_exit": trace_compile_exit,
        "sim_command": sim_command,
        "sim_exit": sim_exit,
        "testcase_pass_markers": log_scan["passed"],
        "testcase_fail_markers": log_scan["failed"],
        "jtag_server_errors": log_scan["jtag_errors"],
        "bad_diagnostics": log_scan["bad"],
        "finish": log_scan["finish"],
        "sim_log_sha256": sha256(test_output / "sim.log"),
    }
    (args.output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    label = "PASS" if passed else "FAIL"
    if aes_case_limit is not None:
        label += f" (first {aes_case_limit} AES DMA case(s); not stock firmware qualification)"
    elif args.rand_dma_iterations is not None:
        reset_note = ", forced first reset" if args.force_first_rand_dma_reset else ""
        label += f" (first {args.rand_dma_iterations} random DMA transfer(s){reset_note}; not full-suite qualification)"
    elif args.fast_boot_data_preload:
        label += " (diagnostic fast boot; not stock firmware qualification)"
    elif quiet_firmware:
        label += " (diagnostic firmware verbosity; not stock firmware qualification)"
    print(f"{label} {args.case}: {args.output / 'result.json'}")
    return 0 if passed else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, subprocess.CalledProcessError, ValueError, RuntimeError) as exc:
        print(f"Caliptra full-top BFM run failed: {exc}", file=sys.stderr)
        sys.exit(1)
