#!/usr/bin/env python3
"""Apply hash-guarded Icarus adaptations to generated SoC-IFC host sources.

The pinned SoC-IFC UVMF sources use method calls such as
``case (axs_reg.get_name()) inside``. SystemVerilog evaluates a case selector
once, while Icarus currently lowers case-inside to membership tests. This
overlay stores the selector in a block-local string before the original
case-inside statement, preserving its value, ranges, and once-only evaluation.

The generated register and sequence classes also register objects without
declaring their inherited ``new(string name)`` constructor. Icarus currently
resolves those factory constructor calls as zero-argument constructors when
the classes are declared in the package. This overlay adds explicit forwarding
constructors to disposable generated-source copies; pinned Caliptra files
remain unchanged.
"""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


SOURCES = {
    "soc_ifc_env_pkg.sv": (
        "9031e1950c8e7d948ea4607ed7da2012ee71e876dd2d3d13094c2eea403b7b56",
        0,
    ),
    "registers/soc_ifc_reg_model_top_pkg.sv": (
        "194ce0892d96b1d02cdaddc36c28e0cc41833a444cd39f88558c09590b521573",
        0,
    ),
    "src/soc_ifc_predictor.svh": (
        "97cce766f61178f22b4e7dc50931d56733b9c3808cdc29b73480c67b907bdafa",
        10,
    ),
    "src/soc_ifc_env_cov_subscriber.svh": (
        "bc6bc294bb3572445f5d8f58cc5e343293250813da14444758585ef2e1683dfb",
        2,
    ),
    "src/soc_ifc_env_configuration.svh": (
        "7c88a8eb8f0a045b5f564d0716b6ad008c3c9bcf3e86c0a173bfe98c3ff1ae42",
        0,
    ),
    "sequences/mbox/soc_ifc/soc_ifc_env_mbox_reg_axs_invalid_sequence.svh": (
        "d4e872da14a6568c6d72e6593aafbfe0b474a5045fa0159bd795a062ed9e205b",
        1,
    ),
    "sequences/mbox/soc_ifc/soc_ifc_env_soc_mbox_reg_axs_invalid_handler_sequence.svh": (
        "38a99d7855bcb43a1e71c3a788d6801a81c63b03dab898178556a31c13d793ed",
        1,
    ),
    "sequences/mbox/soc_ifc/soc_ifc_env_mbox_real_fw_sequence.svh": (
        "479544e6fc941b54865fb0dd21ec1e3b7b2fe2782c96c6e080af85c771a3378d",
        0,
    ),
    "sequences/mbox/soc_ifc/soc_ifc_env_mbox_rand_multi_agent_sequence.svh": (
        "a666930e731def8ffca4b785841911afba032b6a248c4f5a529155f22ef20eee",
        0,
    ),
    "sequences/mbox/soc_ifc/soc_ifc_env_mbox_uc_reg_access_sequence.svh": (
        "e0406e2693ea1f66adcdcd5d310d926902a2b460c23afaacb639486d59483ea6",
        0,
    ),
    "sequences/mbox/soc_ifc_env_top_mbox_rand_axi_user_sequence.svh": (
        "7369bc3a796b9be880234e2579fae01e7c9ecebd17ca0117d201606e3c464d50",
        0,
    ),
    "sequences/sha_accel/soc_ifc_env_sha_accel_sequence.svh": (
        "94059d2acc6f79d918edf7c13fff8838da2b834f4335eb2d7d41d637ce12ddba",
        0,
    ),
    "registers/soc_ifc_reg_cbs_mbox_csr_mbox_dataout_dataout.svh": (
        "f895f1629d065f74b5e5cafc1a03c61dac6b1980fc6c90b3a51662583e327b81",
        1,
    ),
    "registers/soc_ifc_reg_cbs_mbox_csr_mbox_lock_lock.svh": (
        "1aad76e0d8bd7f9b17866b8df8e3f75064f2085a21cb3c00302d9f02d1e89abe",
        0,
    ),
}
SEQUENCE_TREE_SHA256 = "668956ce39cc79eb8b8cdd8f4c0161d92efef12cd3a2c7c0d8c3b8935aa80c82"
REGISTERS_TREE_SHA256 = "0669b3e035845fb835403edffa4918a4c9f41cd2bfe3cf28c87e092c72a6fa5f"
OBJECT_UTILS_CONSTRUCTORS_EXPECTED = 47
CLASS_DECL = re.compile(
    r"(?m)^[ \t]*(?:virtual[ \t]+)?class[ \t]+(\w+)[ \t]+extends[ \t]+"
    r"([A-Za-z_]\w*(?:::\w+)?(?:[ \t]*#[ \t]*\([^;]*\))?)[ \t]*;"
)
CLASS_END = re.compile(r"(?m)^[ \t]*endclass\b")
CONSTRUCTOR_MARKER = "// Icarus SoC-IFC UVM object constructor overlay"
SELECTOR_CASE = re.compile(
    r"case\s*\(\s*(axs_reg\.get_name\(\)|map\.get_name\(\))\s*\)\s+inside\b"
)
TEMP_PREFIX = "__ivl_case_inside_selector_"
LOCK_CHAIN = (
    'rm.get_parent().get_block_by_name("soc_ifc_reg_rm")'
    '.get_block_by_name("intr_block_rf_ext")'
    '.get_field_by_name("notif_soc_req_lock_sts")'
    '.predict(1\'b1, -1, UVM_PREDICT_READ, UVM_PREDICT, '
    'rm.get_parent().get_map_by_name(this.AHB_map_name));'
)
LOCK_CHAIN_REPLACEMENT = (
    'soc_ifc_parent_block = rm.get_parent();\n'
    '                            soc_ifc_reg_block = '
    'soc_ifc_parent_block.get_block_by_name("soc_ifc_reg_rm");\n'
    '                            soc_ifc_intr_block = '
    'soc_ifc_reg_block.get_block_by_name("intr_block_rf_ext");\n'
    '                            soc_ifc_notif_lock_field = '
    'soc_ifc_intr_block.get_field_by_name("notif_soc_req_lock_sts");\n'
    '                            soc_ifc_notif_lock_field.predict('
    '1\'b1, -1, UVM_PREDICT_READ, UVM_PREDICT, '
    'soc_ifc_parent_block.get_map_by_name(this.AHB_map_name));'
)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def replace_once(source: str, old: str, new: str, relative: str) -> str:
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"{relative}: expected one overlay anchor, found {count}: {old!r}")
    return source.replace(old, new, 1)


def sequence_tree_digest(source_root: Path) -> str:
    digest_builder = hashlib.sha256()
    files = sorted((source_root / "sequences").rglob("*.svh"))
    for path in files:
        relative = path.relative_to(source_root).as_posix()
        digest_builder.update(relative.encode("utf-8"))
        digest_builder.update(b"\0")
        digest_builder.update(path.read_bytes())
        digest_builder.update(b"\0")
    return digest_builder.hexdigest()


def registers_tree_digest(register_root: Path) -> str:
    digest_builder = hashlib.sha256()
    for path in sorted(p for p in register_root.rglob("*") if p.is_file()):
        relative = path.relative_to(register_root).as_posix()
        digest_builder.update(relative.encode("utf-8"))
        digest_builder.update(b"\0")
        digest_builder.update(path.read_bytes())
        digest_builder.update(b"\0")
    return digest_builder.hexdigest()


def overlay_object_constructors(source: str, relative: str) -> tuple[str, int]:
    """Add explicit name-forwarding constructors to registered RAL classes."""
    insertions: list[tuple[int, str]] = []
    for declaration in CLASS_DECL.finditer(source):
        class_name, _ = declaration.groups()
        class_end = CLASS_END.search(source, declaration.end())
        if not class_end:
            raise SystemExit(f"{relative}: unterminated class {class_name}")
        body = source[declaration.start():class_end.end()]
        macro = re.search(
            r"`uvm_object_utils(?:_begin)?\s*\(\s*"
            + re.escape(class_name)
            + r"\s*\)",
            body,
        )
        if not macro:
            continue

        if CONSTRUCTOR_MARKER in body:
            expected = (
                f'{CONSTRUCTOR_MARKER}\n'
                f'    function new(string name = "{class_name}");\n'
                f'      super.new(name);\n'
                f'    endfunction'
            )
            if expected not in body:
                raise SystemExit(
                    f"{relative}: incompatible existing constructor overlay for {class_name}"
                )
            continue
        if re.search(r"\bfunction\s+(?:automatic\s+)?new\s*(?:\(|;)", body):
            continue

        macro_start = declaration.start() + macro.start()
        line_start = source.rfind("\n", 0, macro_start) + 1
        indent = source[line_start:macro_start]
        line_end = source.find("\n", declaration.start() + macro.end())
        if line_end < 0:
            raise SystemExit(f"{relative}: constructor macro line is unterminated")
        constructor = (
            f"{indent}{CONSTRUCTOR_MARKER}\n"
            f'{indent}function new(string name = "{class_name}");\n'
            f"{indent}  super.new(name);\n"
            f"{indent}endfunction\n"
        )
        insertions.append((line_end + 1, constructor))

    for offset, constructor in reversed(insertions):
        source = source[:offset] + constructor + source[offset:]
    return source, len(insertions)


def overlay_void_sequence_helpers(source: str, relative: str) -> tuple[str, int]:
    """Give generated no-result sequence helpers an explicit void type."""
    definition = re.compile(
        r"\bfunction\s+([A-Za-z_]\w*)::([A-Za-z_]\w*)\s*\(\s*\)"
    )
    matches = list(definition.finditer(source))
    changed = 0
    for match in reversed(matches):
        class_name, method_name = match.groups()
        end = source.find("endfunction", match.end())
        if end < 0:
            raise SystemExit(f"{relative}: unterminated {class_name}::{method_name}")
        body = source[match.end():end]
        if re.search(r"\breturn\b", body):
            raise SystemExit(
                f"{relative}: refusing implicit-return helper {class_name}::{method_name}"
            )

        declaration = re.compile(
            r"\bextern\s+virtual\s+function\s+"
            + re.escape(method_name)
            + r"\s*\(\s*\)\s*;"
        )
        if len(declaration.findall(source)) != 1:
            raise SystemExit(
                f"{relative}: expected one extern prototype for {class_name}::{method_name}"
            )
        source, decl_count = declaration.subn(
            f"extern virtual function void {method_name}();", source, count=1
        )
        if decl_count != 1:
            raise SystemExit(f"{relative}: failed to type {class_name}::{method_name}")

        # Earlier source edits occur after this definition when iterating in
        # reverse, so its original offset remains valid.
        header = f"function {class_name}::{method_name}()"
        typed_header = f"function void {class_name}::{method_name}()"
        if source.count(header) != 1:
            raise SystemExit(f"{relative}: expected one definition header {header}")
        source = source.replace(header, typed_header, 1)
        changed += 1
    return source, changed


def matching_endcase(text: str, start: int) -> int:
    """Return the end offset for the case beginning at start, ignoring comments."""
    depth = 0
    state = "code"
    i = start
    while i < len(text):
        if state == "line_comment":
            if text[i] == "\n":
                state = "code"
            i += 1
            continue
        if state == "block_comment":
            if text.startswith("*/", i):
                state = "code"
                i += 2
            else:
                i += 1
            continue
        if state == "string":
            if text[i] == "\\":
                i += 2
            elif text[i] == '"':
                state = "code"
                i += 1
            else:
                i += 1
            continue

        if text.startswith("//", i):
            state = "line_comment"
            i += 2
            continue
        if text.startswith("/*", i):
            state = "block_comment"
            i += 2
            continue
        if text[i] == '"':
            state = "string"
            i += 1
            continue
        if text[i].isalpha() or text[i] == "_":
            j = i + 1
            while j < len(text) and (text[j].isalnum() or text[j] in "_$"):
                j += 1
            token = text[i:j]
            if token == "case":
                depth += 1
            elif token == "endcase":
                depth -= 1
                if depth == 0:
                    return j
            i = j
            continue
        i += 1

    raise SystemExit("could not find matching endcase for method selector")


def overlay_multi_agent_delay_randomize(source: str, relative: str) -> str:
    """Randomize a scalar, then store it in the selected dynamic-array slot."""
    declaration = "    int unsigned delay_clks[]; // Delay prior to running start\n"
    source = replace_once(
        source,
        declaration,
        declaration + "    int unsigned delay_clk;\n",
        relative,
    )
    old = (
        '        if (!std::randomize(delay_clks[ii]) with '
        '{delay_clks[ii] < 4*(soc_ifc_env_mbox_multi_agent_seq[ii].mbox_op_rand.dlen+20); '
        'delay_clks[ii] > 0;}) begin\n'
        '            `uvm_fatal("SOC_IFC_MBOX", '
        '$sformatf("soc_ifc_env_mbox_rand_multi_agent_sequence::body() - %s '
        'randomization failed", "delay_clks"));\n'
        "        end\n"
        "        else\n"
        '            `uvm_info("SOC_IFC_MBOX", '
        '$sformatf("soc_ifc_env_mbox_rand_multi_agent_sequence::body() - '
        '%s[%0d] randomized to value: %0d", "delay_clks", ii, '
        'delay_clks[ii]), UVM_HIGH);\n'
    )
    new = (
        '        if (!std::randomize(delay_clk) with '
        '{delay_clk < 4*(soc_ifc_env_mbox_multi_agent_seq[ii].mbox_op_rand.dlen+20); '
        'delay_clk > 0;}) begin\n'
        '            `uvm_fatal("SOC_IFC_MBOX", '
        '$sformatf("soc_ifc_env_mbox_rand_multi_agent_sequence::body() - %s '
        'randomization failed", "delay_clks"));\n'
        "        end\n"
        "        else begin\n"
        "            delay_clks[ii] = delay_clk;\n"
        '            `uvm_info("SOC_IFC_MBOX", '
        '$sformatf("soc_ifc_env_mbox_rand_multi_agent_sequence::body() - '
        '%s[%0d] randomized to value: %0d", "delay_clks", ii, '
        'delay_clk), UVM_HIGH);\n'
        "        end\n"
    )
    return replace_once(source, old, new, relative)


def overlay_top_mbox_user_array_copy(source: str, relative: str) -> str:
    """Expand the five-element source array into the six-element target."""
    return replace_once(
        source,
        "        mbox_valid_users = {soc_ifc_env_axi_user_init_seq.mbox_valid_users, 32'hFFFF_FFFF}; // FIXME hardcoded\n",
        "        for (ii=0; ii < 5; ii++)\n"
        "            mbox_valid_users[ii] = soc_ifc_env_axi_user_init_seq.mbox_valid_users[ii];\n"
        "        mbox_valid_users[5] = 32'hFFFF_FFFF; // FIXME hardcoded\n",
        relative,
    )


def overlay_sha_axi_user_snapshot(source: str, relative: str) -> str:
    """Capture a RAL getter before using its value in an inline constraint."""
    source = replace_once(
        source,
        "    op_sts_e op_sts;\n",
        "    op_sts_e op_sts;\n"
        "    bit [aaxi_pkg::AAXI_AWUSER_WIDTH-1:0] ss_caliptra_dma_axi_user;\n",
        relative,
    )
    return replace_once(
        source,
        "    axi_user_obj.randomize() with { (addr_user == reg_model.soc_ifc_reg_rm.SS_CALIPTRA_DMA_AXI_USER.get_mirrored_value()) dist { 0 := 1, 1 := 1 }; };\n"
        "    valid_user = axi_user_obj.get_addr_user() == reg_model.soc_ifc_reg_rm.SS_CALIPTRA_DMA_AXI_USER.get_mirrored_value();\n",
        "    ss_caliptra_dma_axi_user = reg_model.soc_ifc_reg_rm.SS_CALIPTRA_DMA_AXI_USER.get_mirrored_value();\n"
        "    axi_user_obj.randomize() with { (addr_user == ss_caliptra_dma_axi_user) dist { 0 := 1, 1 := 1 }; };\n"
        "    valid_user = axi_user_obj.get_addr_user() == ss_caliptra_dma_axi_user;\n",
        relative,
    )


def transform(source: str, relative: str, expected_count: int) -> str:
    matches = list(SELECTOR_CASE.finditer(source))
    if len(matches) != expected_count:
        raise SystemExit(
            f"{relative}: expected {expected_count} method selectors, found {len(matches)}"
        )
    if TEMP_PREFIX in source:
        raise SystemExit(f"{relative}: temporary selector prefix already exists")

    for index, match in reversed(list(enumerate(matches))):
        end = matching_endcase(source, match.start())
        selector = match.group(1)
        name = f"{TEMP_PREFIX}{index}"
        case_text = source[match.start():match.end()]
        case_text = re.sub(
            r"case\s*\(\s*" + re.escape(selector) + r"\s*\)\s+inside\b",
            f"case ({name}) inside",
            case_text,
            count=1,
        )
        wrapper = (
            f"begin\n"
            f"  string {name};\n"
            f"  {name} = {selector};\n"
        )
        source = (
            source[:match.start()]
            + wrapper
            + case_text
            + source[match.end():end]
            + "\nend"
            + source[end:]
        )
    if relative.endswith("soc_ifc_reg_cbs_mbox_csr_mbox_lock_lock.svh"):
        declaration_anchor = "        mbox_csr_ext rm; /* mbox_csr_rm */\n"
        if source.count(declaration_anchor) != 1 or source.count(LOCK_CHAIN) != 1:
            raise SystemExit(f"{relative}: expected callback declaration/call anchors")
        declarations = (
            declaration_anchor
            + "        uvm_reg_block soc_ifc_parent_block;\n"
            + "        uvm_reg_block soc_ifc_reg_block;\n"
            + "        uvm_reg_block soc_ifc_intr_block;\n"
            + "        uvm_reg_field soc_ifc_notif_lock_field;\n"
        )
        source = source.replace(declaration_anchor, declarations, 1)
        source = source.replace(LOCK_CHAIN, LOCK_CHAIN_REPLACEMENT, 1)
    if relative.endswith("soc_ifc_env_mbox_real_fw_sequence.svh"):
        # The generated declaration makes fw_img's byte lanes an unpacked
        # array. Reassemble the first dword as the later mailbox write path
        # does instead of casting an unpacked-array range to an integer.
        source = replace_once(
            source,
            "int'(fw_img[0][3:0])",
            "int'({fw_img[0][3], fw_img[0][2], fw_img[0][1], fw_img[0][0]})",
            relative,
        )
        source = replace_once(
            source,
            "int'(fw_img[firmware_iccm_end>>2][3:0])",
            "int'({fw_img[firmware_iccm_end>>2][3], "
            "fw_img[firmware_iccm_end>>2][2], "
            "fw_img[firmware_iccm_end>>2][1], "
            "fw_img[firmware_iccm_end>>2][0]})",
            relative,
        )
    if relative.endswith("soc_ifc_env_mbox_rand_multi_agent_sequence.svh"):
        source = overlay_multi_agent_delay_randomize(source, relative)
    if relative.endswith("soc_ifc_env_top_mbox_rand_axi_user_sequence.svh"):
        source = overlay_top_mbox_user_array_copy(source, relative)
    if relative.endswith("soc_ifc_env_sha_accel_sequence.svh"):
        source = overlay_sha_axi_user_snapshot(source, relative)
    if relative.endswith("soc_ifc_env_cov_subscriber.svh"):
        source = replace_once(
            source,
            "step:{null_action: 1'b1, default: 1'b0}",
            "step:'{null_action: 1'b1, default: 1'b0}",
            relative,
        )
        source = replace_once(
            source,
            "prev_step_sampled = {is_ahb:NOT_AHB_REQ,step:pred.next_step};",
            "prev_step_sampled = '{is_ahb:NOT_AHB_REQ,step:pred.next_step};",
            relative,
        )
    if relative == "src/soc_ifc_predictor.svh":
        source = replace_once(
            source,
            "uvm_top.uvm_get_max_verbosity()",
            "uvm_top.get_report_max_verbosity_level()",
            relative,
        )
        zero_data = "soc_ifc_sb_axi_ap_output_transaction.data = {0,0,0,0};"
        if source.count(zero_data) != 10:
            raise SystemExit(f"{relative}: expected ten zero-data assignments")
        source = source.replace(
            zero_data,
            "soc_ifc_sb_axi_ap_output_transaction.data = '0;",
        )
    if relative == "src/soc_ifc_env_configuration.svh":
        for old, new in (
            ("qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];",
             "qvip_ahb_lite_slave_subenv_interface_names[0]  = interface_names[0];"),
            ("qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];",
             "qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];"),
            ("axi_slave_subenv_interface_names     = interface_names[1:1];",
             "axi_slave_subenv_interface_names[0]  = interface_names[1];"),
            ("axi_slave_subenv_interface_activity  = interface_activity[1:1];",
             "axi_slave_subenv_interface_activity[0] = interface_activity[1];"),
        ):
            source = replace_once(source, old, new, relative)
    return source


def main() -> None:
    repo_root = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--caliptra-root",
        type=Path,
        default=repo_root.parent / "caliptra-rtl",
        help="pinned Caliptra checkout (default: sibling caliptra-rtl)",
    )
    parser.add_argument("--output", required=True, type=Path, help="overlay output path")
    args = parser.parse_args()

    source_root = (
        args.caliptra_root
        / "src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/"
        "environment_packages/soc_ifc_env_pkg"
    )
    output = args.output.resolve()
    if output == source_root.resolve() or source_root.resolve() in output.parents:
        raise SystemExit("overlay output must be outside the pinned Caliptra tree")

    sequence_hash = sequence_tree_digest(source_root)
    if sequence_hash != SEQUENCE_TREE_SHA256:
        raise SystemExit(
            "refusing unreviewed SoC-IFC sequence tree: "
            f"expected SHA-256 {SEQUENCE_TREE_SHA256}, got {sequence_hash}"
        )

    register_root = source_root / "registers"
    register_hash = registers_tree_digest(register_root)
    if register_hash != REGISTERS_TREE_SHA256:
        raise SystemExit(
            "refusing unreviewed SoC-IFC register tree: "
            f"expected SHA-256 {REGISTERS_TREE_SHA256}, got {register_hash}"
        )

    for relative, (expected_hash, expected_count) in SOURCES.items():
        source_path = source_root / relative
        original = source_path.read_bytes()
        actual_hash = digest(original)
        if actual_hash != expected_hash:
            raise SystemExit(
                f"refusing unreviewed source {relative}: "
                f"expected SHA-256 {expected_hash}, got {actual_hash}"
            )
        transformed = transform(original.decode("utf-8"), relative, expected_count)
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(transformed, encoding="utf-8")
        print(f"{relative}: {expected_hash} -> {digest(transformed.encode())}")

    helper_count = 0
    helper_files = 0
    sequence_constructor_count = 0
    sequence_constructor_files = 0
    for source_path in sorted((source_root / "sequences").rglob("*.svh")):
        relative = source_path.relative_to(source_root).as_posix()
        target = output / relative
        original = target.read_text(encoding="utf-8") if target.is_file() else source_path.read_text(encoding="utf-8")
        transformed, count = overlay_void_sequence_helpers(original, relative)
        transformed, constructors = overlay_object_constructors(transformed, relative)
        if count or constructors:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(transformed, encoding="utf-8")
        if count:
            helper_count += count
            helper_files += 1
        if constructors:
            sequence_constructor_count += constructors
            sequence_constructor_files += 1
    print(
        f"sequence helpers: explicit void return in {helper_count} methods across "
        f"{helper_files} generated files (sequence tree SHA-256 {sequence_hash})"
    )
    print(
        f"sequence factory constructors: {sequence_constructor_count} inserted "
        f"across {sequence_constructor_files} generated files"
    )

    constructor_count = 0
    constructor_files = 0
    registered_classes = 0
    for source_path in sorted(p for p in register_root.rglob("*") if p.suffix in (".sv", ".svh")):
        relative = source_path.relative_to(source_root).as_posix()
        target = output / relative
        original = target.read_text(encoding="utf-8") if target.is_file() else source_path.read_text(encoding="utf-8")
        transformed, inserted = overlay_object_constructors(original, relative)
        if inserted:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(transformed, encoding="utf-8")
            constructor_count += inserted
            constructor_files += 1
        # Existing explicit constructors and constructors inserted by a
        # previous run both count toward the pinned expected class inventory.
        registered_classes += len(re.findall(CONSTRUCTOR_MARKER, transformed))
    if registered_classes != OBJECT_UTILS_CONSTRUCTORS_EXPECTED:
        raise SystemExit(
            "unexpected registered object constructor inventory: "
            f"found {registered_classes}, expected {OBJECT_UTILS_CONSTRUCTORS_EXPECTED}"
        )
    print(
        f"register factory constructors: {constructor_count} inserted across "
        f"{constructor_files} files; {registered_classes} overlay constructors "
        f"accounted (register tree SHA-256 {register_hash})"
    )


if __name__ == "__main__":
    main()
