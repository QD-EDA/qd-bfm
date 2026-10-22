#!/usr/bin/env python3
"""Apply per-run Icarus syntax overlays to SoC-IFC UVM sources."""

import hashlib
import json
import os
import re
import sys
from pathlib import Path


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"expected exactly one overlay anchor: {old[:100]!r}")
    return text.replace(old, new, 1)


def add_local(text: str, header: str, name: str) -> str:
    return once(text, header + "\n", header + f"\n    string {name};\n")


def transform_covergroups(text: str) -> str:
    pattern = re.compile(r"wildcard bins (ROM|ICCM0|ICCM1)\s*\[16\]\s*=\s*(\{32'h[0-9a-fA-F?]+\});")
    text, count = pattern.subn(r"wildcard bins \1 = \2;", text)
    if count != 3:
        raise RuntimeError(f"expected three fixed-array wildcard bins, found {count}")
    return transform_nonzero_byte_bins(text, 32, 8)


def transform_nonzero_byte_bins(text: str, width: int, expected_count: int) -> str:
    pattern = re.compile(
        r"(?m)^([ \t]*)bins byte_(\d+)[ \t]*=[ \t]*\{\[0:\$\]\}[ \t]*"
        r"with[ \t]*\(\$countones\(item\[\s*(\d+):\s*(\d+)\]\s*>\s*0\)\);\r?$"
    )
    digits = width // 4

    def replace(match: re.Match[str]) -> str:
        lane, high, low = map(int, match.groups()[1:])
        if lane >= width // 8 or (high, low) != (lane * 8 + 7, lane * 8):
            raise RuntimeError(f"unexpected byte-lane coverage filter: {match.group(0)}")
        patterns = []
        prefix = "?" * (digits - 2 * lane - 2)
        suffix = "?" * (2 * lane)
        for value in range(1, 256):
            patterns.append(f"{width}'h{prefix}{value:02x}{suffix}")
        return f"{match.group(1)}wildcard bins byte_{lane} = {{{', '.join(patterns)}}};"

    text, count = pattern.subn(replace, text)
    if count != expected_count:
        raise RuntimeError(f"expected {expected_count} nonzero-byte coverage filters, found {count}")
    return text


def transform_aligned_length_bins(text: str) -> str:
    chunks = [(1 + 4096 * i, min(4096 * (i + 1), 32768)) for i in range(8)]
    for name in ("legal_word_aligned_val", "legal_dword_aligned_val", "legal_qword_aligned_val", "legal_oword_aligned_val"):
        pattern = re.compile(
            rf"(?m)^([ \t]*)bins {name}[ \t]*=[ \t]*\{{\[1:32'h8000\]\}}[ \t]*"
            r"with[ \t]*\(~\|item\[([0-3](?::[0-3])?)\]\);\r?$"
        )

        def replace(match: re.Match[str]) -> str:
            return "\n".join(
                f"{match.group(1)}bins {name}_{index:02d} = {{[{start}:{end}]}} with (~|item[{match.group(2)}]);"
                for index, (start, end) in enumerate(chunks)
            )

        text, count = pattern.subn(replace, text)
        if count != 1:
            raise RuntimeError(f"expected one {name} coverage bin, found {count}")
    return text


def transform_empty_psprintf(text: str) -> str:
    return once(
        text,
        '$psprintf("The agent at \'%s\' is using interface named %s has the following parameters: ", agent_path, interface_name, )',
        '$psprintf("The agent at \'%s\' is using interface named %s has the following parameters: ", agent_path, interface_name)',
    )


def transform_ctrl_transaction_coverage(text: str) -> str:
    text = once(
        text,
        "T coverage_trans;",
        "T coverage_trans;\n"
        "  bit [1:0] m20_cptra_obf_key_class;\n"
        "  bit m20_cptra_obf_field_entropy_any;\n"
        "  bit m20_cptra_obf_uds_seed_any;\n"
        "  bit [7:0] m20_generic_input_byte_nonzero;",
    )

    def replace_coverpoint(source_text: str, name: str, old_expr: str, new_expr: str, body: list[str]) -> str:
        pattern = re.compile(
            rf"(?ms)^([ \t]*){re.escape(name)}: coverpoint {re.escape(old_expr)} \{{.*?^\1\}}"
        )

        def replace(match: re.Match[str]) -> str:
            indent = match.group(1)
            bins = "\n".join(f"{indent}    {line}" for line in body)
            return f"{indent}{name}: coverpoint {new_expr} {{\n{bins}\n{indent}}}"

        replaced, count = pattern.subn(replace, source_text, count=1)
        if count != 1:
            raise RuntimeError(f"expected one {name} wide coverpoint, found {count}")
        return replaced

    text = replace_coverpoint(
        text,
        "cptra_obf_key_rand",
        "coverage_trans.cptra_obf_key_rand",
        "m20_cptra_obf_key_class",
        [
            "bins zero_key = {2'd0};",
            "bins rand_key = {2'd1};",
            "bins ones_key = {2'd2};",
        ],
    )
    for name in ("cptra_obf_field_entropy", "cptra_obf_uds_seed"):
        text = once(
            text,
            f"{name}: coverpoint coverage_trans.{name};",
            f"{name}: coverpoint m20_{name}_any {{\n        bins any_value = {{1'b0, 1'b1}};\n    }}",
        )
    text = replace_coverpoint(
        text,
        "generic_input_val",
        "coverage_trans.generic_input_val",
        "m20_generic_input_byte_nonzero",
        [
            "bins byte_none = {8'b0000_0000};",
            *[
                f"wildcard bins byte_{lane} = {{8'b{'?' * (7 - lane)}1{'?' * lane}}};"
                for lane in range(8)
            ],
        ],
    )
    text = once(
        text,
        "    coverage_trans = t;\n    soc_ifc_ctrl_transaction_cg.sample();",
        "    coverage_trans = t;\n"
        "    if (t.cptra_obf_key_rand == '0) m20_cptra_obf_key_class = 2'd0;\n"
        "    else if (&t.cptra_obf_key_rand) m20_cptra_obf_key_class = 2'd2;\n"
        "    else m20_cptra_obf_key_class = 2'd1;\n"
        "    m20_cptra_obf_field_entropy_any = |t.cptra_obf_field_entropy;\n"
        "    m20_cptra_obf_uds_seed_any = |t.cptra_obf_uds_seed;\n"
        "    for (int m20_lane = 0; m20_lane < 8; m20_lane++)\n"
        "      m20_generic_input_byte_nonzero[m20_lane] = |t.generic_input_val[m20_lane*8 +: 8];\n"
        "    soc_ifc_ctrl_transaction_cg.sample();",
    )
    return text


def transform_reg_uvm(text: str, coverage_overlay: Path) -> str:
    return once(text, '`include "soc_ifc_reg_covergroups.svh"', f'`include "{coverage_overlay.resolve()}"')


def transform_predictor(text: str) -> str:
    for header in (
        "virtual function void write_ahb_slave_0_ae(mvc_sequence_item_base t);",
        "virtual function void write_axi_sub_0_ae(aaxi_master_tr t);",
        "function bit soc_ifc_predictor::check_mbox_no_lock_error(aaxi_master_tr txn, uvm_reg axs_reg);",
        "function bit soc_ifc_predictor::check_mbox_ooo_error(aaxi_master_tr txn, uvm_reg axs_reg);",
        "function bit soc_ifc_predictor::check_mbox_inv_user_error(aaxi_master_tr txn, uvm_reg axs_reg);",
    ):
        text = add_local(text, header, "m20_case_reg_name")
    pattern = re.compile(r"(?m)^([ \t]*)case \(axs_reg\.get_name\(\)\) inside$")
    text, count = pattern.subn(r"\1m20_case_reg_name = axs_reg.get_name();\n\1case (m20_case_reg_name) inside", text)
    if count != 10:
        raise RuntimeError(f"expected ten predictor method-call case selectors, found {count}")
    return text


def transform_subscriber(text: str) -> str:
    text = once(
        text,
        "mbox_steps_by_if_s prev_step_sampled = '{is_ahb: NOT_AHB_REQ, step:{null_action: 1'b1, default: 1'b0}};",
        "mbox_steps_by_if_s prev_step_sampled = '0;",
    )
    text = once(
        text,
        "super.new(name, parent);\n",
        "super.new(name, parent);\n    prev_step_sampled.is_ahb = NOT_AHB_REQ;\n    prev_step_sampled.step.null_action = 1'b1;\n",
    )
    assignment = re.compile(r"(?m)^([ \t]*)prev_step_sampled\s*=\s*'?[{]is_ahb:\s*(NOT_AHB_REQ|AHB_REQ),\s*step:\s*pred\.next_step};$")
    text, count = assignment.subn(
        lambda m: f"{m.group(1)}prev_step_sampled.is_ahb = {m.group(2)};\n{m.group(1)}prev_step_sampled.step = pred.next_step;",
        text,
    )
    if count != 3:
        raise RuntimeError(f"expected three coverage-state assignments, found {count}")
    for header in (
        "virtual function void write_cov_ahb_ae(mvc_sequence_item_base txn);",
        "virtual function void write_cov_axi_ae(aaxi_master_tr txn);",
    ):
        text = add_local(text, header, "m20_case_reg_name")
    selector = re.compile(r"(?m)^([ \t]*)case \(axs_reg\.get_name\(\)\) inside$")
    text, count = selector.subn(r"\1m20_case_reg_name = axs_reg.get_name();\n\1case (m20_case_reg_name) inside", text)
    if count != 2:
        raise RuntimeError(f"expected two coverage subscriber selectors, found {count}")
    return text


def transform_dataout_callback(text: str) -> str:
    text = add_local(text, "                                       input uvm_reg_map    map);", "m20_case_map_name")
    old = "        case (map.get_name()) inside"
    return once(text, old, "        m20_case_map_name = map.get_name();\n        case (m20_case_map_name) inside")


def transform_lock_callback(text: str) -> str:
    header = "                                       input uvm_reg_map    map);"
    declarations = (
        "        uvm_reg_block m20_soc_ifc_reg_rm;\n"
        "        uvm_reg_block m20_intr_block_rf_ext;\n"
        "        uvm_reg_field m20_notif_soc_req_lock_sts;\n"
        "        uvm_reg_map m20_ahb_map;\n"
    )
    text = once(text, header + "\n", header + "\n" + declarations)
    old = ('rm.get_parent().get_block_by_name("soc_ifc_reg_rm").get_block_by_name("intr_block_rf_ext").'
           'get_field_by_name("notif_soc_req_lock_sts").predict(1\'b1, -1, UVM_PREDICT_READ, UVM_PREDICT, '
           'rm.get_parent().get_map_by_name(this.AHB_map_name));')
    new = (
        'm20_soc_ifc_reg_rm = rm.get_parent().get_block_by_name("soc_ifc_reg_rm");\n'
        '                            m20_intr_block_rf_ext = m20_soc_ifc_reg_rm.get_block_by_name("intr_block_rf_ext");\n'
        '                            m20_notif_soc_req_lock_sts = m20_intr_block_rf_ext.get_field_by_name("notif_soc_req_lock_sts");\n'
        '                            m20_ahb_map = rm.get_parent().get_map_by_name(this.AHB_map_name);\n'
        '                            m20_notif_soc_req_lock_sts.predict(1\'b1, -1, UVM_PREDICT_READ, UVM_PREDICT, m20_ahb_map);'
    )
    return once(text, old, new)


def transform_sequence_methods(text: str) -> str:
    for name in ("create_seqs", "randomize_seqs", "create_and_randomize_seqs"):
        declaration = re.compile(rf"(?m)^([ \t]*extern[ \t]+virtual[ \t]+function)[ \t]+(?={name}\s*\()")
        definition = re.compile(rf"(?m)^([ \t]*function)[ \t]+(?=(?:[A-Za-z_$][\w$]*::)*{name}\s*\()")
        text = declaration.sub(r"\1 void ", text)
        text = definition.sub(r"\1 void ", text)
    return text


def transform_invalid_access_sequence(text: str, function_header: str) -> str:
    text = add_local(text, function_header, "m20_case_reg_name")
    old = "    case (axs_reg.get_name()) inside"
    return once(text, old, "    m20_case_reg_name = axs_reg.get_name();\n    case (m20_case_reg_name) inside")


def prepare_overlay(output: Path, caliptra: Path, filelist: Path) -> dict:
    soc_ifc = caliptra / "src/soc_ifc"
    package = soc_ifc / "uvmf_soc_ifc/uvmf_template_output/verification_ip/environment_packages/soc_ifc_env_pkg"
    overlay = output / "overlays/m20-socifc-icarus"
    overlay.mkdir(parents=True, exist_ok=True)
    files = []

    def write(source: Path, relative: str, transform) -> Path:
        before = source.read_bytes()
        after = transform(before.decode()).encode()
        target = overlay / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(after)
        files.append({"source": str(source), "source_sha256": digest(before),
                      "overlay": str(target), "overlay_sha256": digest(after)})
        return target

    coverage = write(soc_ifc / "rtl/soc_ifc_reg_covergroups.svh", "soc_ifc_reg_covergroups.svh", transform_covergroups)
    reg_uvm = write(soc_ifc / "rtl/soc_ifc_reg_uvm.sv", "soc_ifc_reg_uvm.sv", lambda s: transform_reg_uvm(s, coverage))
    write(soc_ifc / "rtl/sha512_acc_csr_covergroups.svh", "sha512_acc_csr_covergroups.svh", transform_aligned_length_bins)
    write(soc_ifc / "rtl/mbox_csr_covergroups.svh", "mbox_csr_covergroups.svh", transform_aligned_length_bins)
    interface_packages = soc_ifc / "uvmf_soc_ifc/uvmf_template_output/verification_ip/interface_packages"
    ctrl_src = interface_packages / "soc_ifc_ctrl_pkg/src"
    write(ctrl_src / "soc_ifc_ctrl_configuration.svh", "src/soc_ifc_ctrl_configuration.svh", transform_empty_psprintf)
    for package_name, filename in (
        ("cptra_ctrl_pkg", "cptra_ctrl_configuration.svh"),
        ("ss_mode_ctrl_pkg", "ss_mode_ctrl_configuration.svh"),
        ("soc_ifc_status_pkg", "soc_ifc_status_configuration.svh"),
    ):
        write(interface_packages / package_name / "src" / filename, f"src/{filename}", transform_empty_psprintf)
    write(ctrl_src / "soc_ifc_ctrl_transaction_coverage.svh", "src/soc_ifc_ctrl_transaction_coverage.svh", transform_ctrl_transaction_coverage)
    write(package / "src/soc_ifc_predictor.svh", "src/soc_ifc_predictor.svh", transform_predictor)
    write(package / "src/soc_ifc_env_cov_subscriber.svh", "src/soc_ifc_env_cov_subscriber.svh", transform_subscriber)
    write(package / "registers/soc_ifc_reg_cbs_mbox_csr_mbox_dataout_dataout.svh", "registers/soc_ifc_reg_cbs_mbox_csr_mbox_dataout_dataout.svh", transform_dataout_callback)
    write(package / "registers/soc_ifc_reg_cbs_mbox_csr_mbox_lock_lock.svh", "registers/soc_ifc_reg_cbs_mbox_csr_mbox_lock_lock.svh", transform_lock_callback)
    sequence_dir = package / "sequences/mbox/soc_ifc"
    write(sequence_dir / "soc_ifc_env_mbox_reg_axs_invalid_sequence.svh", "sequences/mbox/soc_ifc/soc_ifc_env_mbox_reg_axs_invalid_sequence.svh", lambda s: transform_invalid_access_sequence(s, "function uvm_reg_data_t soc_ifc_env_mbox_reg_axs_invalid_sequence::get_rand_wr_data(uvm_reg axs_reg);"))
    write(sequence_dir / "soc_ifc_env_soc_mbox_reg_axs_invalid_handler_sequence.svh", "sequences/mbox/soc_ifc/soc_ifc_env_soc_mbox_reg_axs_invalid_handler_sequence.svh", lambda s: transform_invalid_access_sequence(s, "function uvm_reg_data_t soc_ifc_env_soc_mbox_reg_axs_invalid_handler_sequence::get_rand_wr_data(uvm_reg axs_reg);"))
    all_sequences = package / "sequences"
    for source in sorted(all_sequences.rglob("*.svh")):
        original = source.read_text()
        if transform_sequence_methods(original) != original:
            write(source, source.relative_to(package).as_posix(), transform_sequence_methods)

    filelist_before = filelist.read_bytes()
    text = filelist_before.decode()
    old_entry = "${CALIPTRA_ROOT}/src/soc_ifc/rtl/soc_ifc_reg_uvm.sv"
    text = once(text, old_entry, str(reg_uvm.resolve()))
    incdirs = f"+incdir+{overlay.resolve()}\n+incdir+{(overlay / 'registers').resolve()}\n"
    if incdirs.splitlines()[0] in text:
        raise RuntimeError("M20 SoC-IFC overlay include path already present")
    updated = (incdirs + text).encode()
    filelist.write_bytes(updated)
    manifest = {
        "source_pin": "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e",
        "adams_bridge_pin": "b77e3d899e828d626cfc2a0d26a6b5704cc121e0",
        "files": files,
        "filelist": str(filelist), "filelist_sha256_before": digest(filelist_before),
        "filelist_sha256_after": digest(updated), "replaced_reg_model_sources": 1,
        "coverage_scope": "three fixed-array wildcard groups and nonzero-byte lanes are aggregated; aligned length bins are split into eight ranges; wide entropy/seed/key bins are aggregated",
        "sequence_methods": "implicit one-bit returns on generated sequence setup methods are made explicitly void",
        "functional_scope": "testbench-only parser compatibility; stimulus, transactions, expected values, assertions, and pass criteria are unchanged",
    }
    (output / "m20-socifc-overlay-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def self_check() -> None:
    bins = "\n".join(f"wildcard bins {name} [16] = {{{value}}};" for name, value in (
        ("ROM", "32'h0000????"), ("ICCM0", "32'h4000????"), ("ICCM1", "32'h4001????")))
    byte_bins = "\n".join(
        f"bins byte_{lane} = {{[0:$]}} with ($countones(item[{lane * 8 + 7}:{lane * 8}] > 0));"
        for _ in range(2) for lane in range(4)
    )
    transformed_covergroups = transform_covergroups(bins + "\n" + byte_bins)
    assert transformed_covergroups.count("wildcard bins byte_") == 8
    assert "with ($countones" not in transformed_covergroups
    assert "32'h??????01" in transformed_covergroups and "32'h01??????" in transformed_covergroups
    aligned = "\n".join(
        f"bins {name} = {{[1:32'h8000]}} with (~|item[{index}]);"
        for index, name in enumerate(("legal_word_aligned_val", "legal_dword_aligned_val", "legal_qword_aligned_val", "legal_oword_aligned_val"))
    )
    aligned = transform_aligned_length_bins(aligned)
    assert aligned.count("_07 = {[28673:32768]}") == 4
    assert "legal_word_aligned_val = {[1:32'h8000]}" not in aligned
    call = '$psprintf("The agent at \'%s\' is using interface named %s has the following parameters: ", agent_path, interface_name, )'
    config = transform_empty_psprintf("before\n" + call + "\nafter")
    assert config == "before\n" + call.replace("interface_name, )", "interface_name)") + "\nafter"
    transaction_coverage = "\n".join((
        "T coverage_trans;",
        "cptra_obf_key_rand: coverpoint coverage_trans.cptra_obf_key_rand {",
        "    bins zero_key = {0};",
        "    bins rand_key  = {[1:{`CLP_OBF_KEY_DWORDS{32'hFFFF_FFFF}}-1]};",
        "    bins ones_key = {{`CLP_OBF_KEY_DWORDS{32'hFFFF_FFFF}}};",
        "}",
        "cptra_obf_field_entropy: coverpoint coverage_trans.cptra_obf_field_entropy;",
        "cptra_obf_uds_seed: coverpoint coverage_trans.cptra_obf_uds_seed;",
        "generic_input_val: coverpoint coverage_trans.generic_input_val {",
        "    bins byte_none = {64'h0000_0000_0000_0000};",
        *[f"    bins byte_{lane} = {{[0:$]}} with ($countones(item[{lane * 8 + 7}:{lane * 8}] > 0));" for lane in range(8)],
        "}",
        "virtual function void write (T t);",
        "    coverage_trans = t;",
        "    soc_ifc_ctrl_transaction_cg.sample();",
        "    per_bit_cg.sample(t.cptra_obf_key_rand[0][0]);",
        "endfunction",
    ))
    transaction_coverage = transform_ctrl_transaction_coverage(transaction_coverage)
    assert transaction_coverage.count("wildcard bins byte_") == 8
    assert "bit [1:0] m20_cptra_obf_key_class;" in transaction_coverage
    assert "bit m20_cptra_obf_field_entropy_any;" in transaction_coverage
    assert "bit m20_cptra_obf_uds_seed_any;" in transaction_coverage
    assert "bit [7:0] m20_generic_input_byte_nonzero;" in transaction_coverage
    assert "coverpoint m20_cptra_obf_key_class" in transaction_coverage
    assert "bins zero_key = {2'd0};" in transaction_coverage
    assert "bins rand_key = {2'd1};" in transaction_coverage
    assert "bins ones_key = {2'd2};" in transaction_coverage
    assert transaction_coverage.count("bins any_value = {1'b0, 1'b1};") == 2
    assert "coverpoint m20_generic_input_byte_nonzero" in transaction_coverage
    assert "wildcard bins byte_0 = {8'b???????1};" in transaction_coverage
    assert "wildcard bins byte_7 = {8'b1???????};" in transaction_coverage
    assert "m20_cptra_obf_key_class = 2'd0;" in transaction_coverage
    assert "m20_cptra_obf_key_class = 2'd2;" in transaction_coverage
    assert "m20_cptra_obf_key_class = 2'd1;" in transaction_coverage
    assert "m20_cptra_obf_field_entropy_any = |t.cptra_obf_field_entropy;" in transaction_coverage
    assert "m20_cptra_obf_uds_seed_any = |t.cptra_obf_uds_seed;" in transaction_coverage
    assert "for (int m20_lane = 0; m20_lane < 8; m20_lane++)" in transaction_coverage
    assert "per_bit_cg.sample(t.cptra_obf_key_rand[0][0]);" in transaction_coverage
    assert "coverpoint coverage_trans.cptra_obf_key_rand" not in transaction_coverage
    assert "coverpoint coverage_trans.generic_input_val" not in transaction_coverage
    seq = transform_sequence_methods("\n".join((
        "extern virtual function      create_seqs();",
        "extern virtual function      randomize_seqs();",
        "extern virtual function create_and_randomize_seqs();",
        "function soc_ifc_env_mbox_rand_multi_agent_sequence::create_seqs();",
        "function soc_ifc_env_mbox_rand_multi_agent_sequence::randomize_seqs();",
        "function soc_ifc_env_top_mbox_multi_agent_sequence::create_and_randomize_seqs();",
        "function int soc_ifc_env_mbox_rand_multi_agent_sequence::create_seqs();",
    )))
    assert "extern virtual function void create_seqs();" in seq
    assert "extern virtual function void randomize_seqs();" in seq
    assert "extern virtual function void create_and_randomize_seqs();" in seq
    assert "function void soc_ifc_env_mbox_rand_multi_agent_sequence::create_seqs();" in seq
    assert "function void soc_ifc_env_mbox_rand_multi_agent_sequence::randomize_seqs();" in seq
    assert "function void soc_ifc_env_top_mbox_multi_agent_sequence::create_and_randomize_seqs();" in seq
    assert "function int soc_ifc_env_mbox_rand_multi_agent_sequence::create_seqs();" in seq
    invalid_sequence_header = "function uvm_reg_data_t soc_ifc_env_mbox_reg_axs_invalid_sequence::get_rand_wr_data(uvm_reg axs_reg);"
    invalid_sequence = transform_invalid_access_sequence(invalid_sequence_header + "\n    uvm_reg_data_t tmp_data;\n    case (axs_reg.get_name()) inside", invalid_sequence_header)
    assert invalid_sequence.index("string m20_case_reg_name;") < invalid_sequence.index("uvm_reg_data_t tmp_data;")
    assert "m20_case_reg_name = axs_reg.get_name();\n    case (m20_case_reg_name) inside" in invalid_sequence
    predictor = "\n".join((
        "virtual function void write_ahb_slave_0_ae(mvc_sequence_item_base t);\n" + "\n".join(["        case (axs_reg.get_name()) inside"] * 5),
        "virtual function void write_axi_sub_0_ae(aaxi_master_tr t);\n" + "\n".join(["        case (axs_reg.get_name()) inside"] * 2),
        "function bit soc_ifc_predictor::check_mbox_no_lock_error(aaxi_master_tr txn, uvm_reg axs_reg);\n        case (axs_reg.get_name()) inside",
        "function bit soc_ifc_predictor::check_mbox_ooo_error(aaxi_master_tr txn, uvm_reg axs_reg);\n        case (axs_reg.get_name()) inside",
        "function bit soc_ifc_predictor::check_mbox_inv_user_error(aaxi_master_tr txn, uvm_reg axs_reg);\n        case (axs_reg.get_name()) inside",
    ))
    rewritten = transform_predictor(predictor)
    assert rewritten.count("m20_case_reg_name = axs_reg.get_name();") == 10
    assert "case (axs_reg.get_name()) inside" not in rewritten
    subscriber = "\n".join((
        "mbox_steps_by_if_s prev_step_sampled = '{is_ahb: NOT_AHB_REQ, step:{null_action: 1'b1, default: 1'b0}};",
        "function new (string name, uvm_component parent);", "    super.new(name, parent);",
        "virtual function void write_cov_ahb_ae(mvc_sequence_item_base txn);",
        "virtual function void write_cov_axi_ae(aaxi_master_tr txn);",
        "prev_step_sampled = {is_ahb:NOT_AHB_REQ,step:pred.next_step};",
        "prev_step_sampled = '{is_ahb:AHB_REQ, step:pred.next_step};",
        "prev_step_sampled = '{is_ahb: NOT_AHB_REQ, step:pred.next_step};",
        "        case (axs_reg.get_name()) inside", "        case (axs_reg.get_name()) inside",
    ))
    sub_rewritten = transform_subscriber(subscriber)
    assert sub_rewritten.count("m20_case_reg_name = axs_reg.get_name();") == 2
    assert sub_rewritten.count("prev_step_sampled.step = pred.next_step;") == 3
    callback_header = "                                       input uvm_reg_map    map);\n"
    dataout = transform_dataout_callback(callback_header + "        case (map.get_name()) inside")
    assert "m20_case_map_name = map.get_name();" in dataout
    chain = ('rm.get_parent().get_block_by_name("soc_ifc_reg_rm").get_block_by_name("intr_block_rf_ext").'
             'get_field_by_name("notif_soc_req_lock_sts").predict(1\'b1, -1, UVM_PREDICT_READ, UVM_PREDICT, '
             'rm.get_parent().get_map_by_name(this.AHB_map_name));')
    lock = transform_lock_callback(callback_header + chain)
    assert "m20_notif_soc_req_lock_sts.predict" in lock and chain not in lock
    reg_uvm = transform_reg_uvm('`include "soc_ifc_reg_covergroups.svh"\n', Path("coverage-overlay.svh"))
    assert f'`include "{Path("coverage-overlay.svh").resolve()}"' in reg_uvm


def main() -> int:
    if sys.argv[1:] == ["--self-check"]:
        self_check()
        print("SoC-IFC overlay transformation self-check passed")
        return 0
    runner = Path(os.environ["M20_BASE_RUNNER"]).resolve()
    caliptra = Path(os.environ["CALIPTRA_ROOT"]).resolve()
    namespace = {"__name__": "m20_base_runner", "__file__": str(runner), "__package__": None}
    exec(compile(runner.read_bytes(), str(runner), "exec"), namespace)
    original_run_logged = namespace["run_logged"]
    installed = False

    def overlay_run_logged(command, cwd, env, log, timeout):
        nonlocal installed
        if command and Path(command[0]).name == "iverilog" and not installed:
            filelist = Path(command[command.index("-f") + 1])
            manifest = prepare_overlay(log.parent, caliptra, filelist)
            installed = True
            print("M20 SoC-IFC overlay installed: " + json.dumps(manifest, sort_keys=True))
        return original_run_logged(command, cwd, env, log, timeout)

    namespace["run_logged"] = overlay_run_logged
    sys.argv = [str(runner), *sys.argv[1:]]
    result = namespace["main"]()
    if not installed:
        raise RuntimeError("runner completed without intercepting an Icarus compile")
    return result


if __name__ == "__main__":
    raise SystemExit(main())
