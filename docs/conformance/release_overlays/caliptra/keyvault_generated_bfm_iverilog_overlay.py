#!/usr/bin/env python3
"""Create exact-source Icarus overlays for Caliptra's generated KeyVault bench."""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path


EXPECTED = {
    "project_benches/kv/tb/testbench/hdl_top.sv":
        "61d0cb67cc535c2570d839ca869ab96a14e9c30ebf40e4963b446af9148f7cbf",
    "verification_ip/interface_packages/kv_rst_pkg/kv_rst_pkg.sv":
        "9a4c019fec946f89c4dab76c06b709ca30a0704b7e4c941ef58f3f2c0718ae09",
    "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_configuration.svh":
        "9d1682590cb85410b67cefe0df3f66f6ca31304f03a1458d283df99411c3a2a6",
    "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_driver_bfm.sv":
        "a187499aa5e809b06b741bd1b95060ad90e0784930756ef3beeaa32e804267f7",
    "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_monitor_bfm.sv":
        "6cd9918c54dfb3e53db82f83a859bf28fb48592e0447e9674ac3be60506fa5ab",
    "verification_ip/interface_packages/kv_write_pkg/kv_write_pkg.sv":
        "3de2e8c1591217faf20626316b4c806192c0314f7a490e421eb2e4d8e57782b1",
    "verification_ip/interface_packages/kv_read_pkg/src/kv_read_monitor_bfm.sv":
        "bd85776012a7e35affdb0842824b57d8ca0fd86690cbc8afa4439e3f349143bf",
    "project_benches/kv/tb/tests/src/test_top.svh":
        "7fff7e3b225ae13660aa2a4b4642d4069d7004aa3b45fa988ce31960154e8fd8",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_env_configuration.svh":
        "52de073510ca16bb8d672d355f54170bedd60268acc00b097d7ad6bcd40b862a",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_env_sequence_base.svh":
        "2da8d4b1b176151d7570c68c94773ca09cad16a126918624d90cdbc7b78d7dd9",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_predictor.svh":
        "4d119cc45db7c78fbdd7128f979a922e9d1246db3bda98a739b87683f8ec7d08",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_cold_rst_sequence.svh":
        "6205e7ded281753c52ade2f7a96b6c11d6226fda86a2472a8ff9ea1995483ff5",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_cold_rst_sequence.svh":
        "1574183c3dde6496e98d5d429804b965d1a30233eda590e597e1d127d7297e8c",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_core_rst_sequence.svh":
        "67d1e7db7c026b91d781c95688a0aaefe7320b3bd59aaf9fc9eb0d7b07e8ce75",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_lock_clear_rst_sequence.svh":
        "d408c0a17281bfd9013f9a9c9444447514ac0baf43d3415bdd75bf25df28032c",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_lock_sequence.svh":
        "5148eeede2711bd8dce8637d3f563a9e7a076ae9c0adb570171b94e5176174d2",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_sequence.svh":
        "34576d4893be6b41c8145af0dffcff379e6cfb885b5ea0a55fa6fb9c64a97953",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_warm_rst_sequence.svh":
        "413d01f2490c4d93463d885646d2ad01bee4ff57d08c9382649fced59c6eb54c",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_lock_sequence.svh":
        "49ea430a7dee3a12d17f51ec036d53aedb4f162aad334cf2bc6c3d2453cc6ff6",
    "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_rst_sequence.svh":
        "45169b8a87aa60ddcf4c311ec6716d82618b00111b51ef1e115b073764e94742",
}


def read_pinned(source_root: Path, relative: str) -> str:
    path = source_root / relative
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    expected = EXPECTED[relative]
    if digest != expected:
        raise SystemExit(
            f"refusing stale KeyVault source {path}: expected SHA-256 {expected}, got {digest}"
        )
    return path.read_text(encoding="utf-8")


def replace_once(text: str, old: str, new: str, source: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"expected exactly one overlay anchor in {source}; found {count}")
    return text.replace(old, new, 1)


def write_overlay(root: Path, text: str, output: str) -> None:
    target = root / output
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")


def main() -> int:
    diagnostic = len(sys.argv) == 4 and sys.argv[3] == "--diagnose"
    if len(sys.argv) not in (3, 4) or (len(sys.argv) == 4 and not diagnostic):
        raise SystemExit(
            f"usage: {Path(sys.argv[0]).name} <keyvault-uvmf-template-output> "
            "<overlay-dir> [--diagnose]"
        )
    source_root, overlay_root = map(Path, sys.argv[1:3])

    relative = "project_benches/kv/tb/testbench/hdl_top.sv"
    text = read_pinned(source_root, relative)
    initiator_count = text.count(".initiator_port")
    responder_count = text.count(".responder_port")
    if (initiator_count, responder_count) != (15, 0):
        raise SystemExit(
            "expected the pinned KeyVault top to have 15 initiator and no responder "
            f"driver modports; found {initiator_count} and {responder_count}"
        )
    text = text.replace(".initiator_port", "")
    if diagnostic:
        text = replace_once(
            text,
            '      .pcr_mldsa_signing_key() //TODO\n  );\n',
            '      .pcr_mldsa_signing_key() //TODO\n  );\n'
            '\n  // Opt-in edge trace for same-entry read/write mismatches.\n'
            '  integer kv_trace_r, kv_trace_w;\n'
            '  always @(posedge clk) begin\n'
            '    if ($test$plusargs("KV_PIN_TRACE")) begin\n'
            '      for (kv_trace_r = 0; kv_trace_r < KV_NUM_READ; kv_trace_r = kv_trace_r + 1) begin\n'
            '        for (kv_trace_w = 0; kv_trace_w < KV_NUM_WRITE; kv_trace_w = kv_trace_w + 1) begin\n'
            '          if (kv_write[kv_trace_w].write_en &&\n'
            '              kv_write[kv_trace_w].write_entry == kv_read[kv_trace_r].read_entry &&\n'
            '              (kv_read[kv_trace_r].read_entry == 0 ||\n'
            '               kv_read[kv_trace_r].read_entry == 19 ||\n'
            '               kv_read[kv_trace_r].read_entry == 23)) begin\n'
            '            $display("KV_PIN_PRE t=%0t r=%0d entry=%h offset=%h resp_error=%b resp_last=%b w=%0d wen=%b wentry=%h woffset=%h wdest=%h rtl_dest=%h rtl_last=%h",\n'
            '              $time, kv_trace_r, kv_read[kv_trace_r].read_entry, kv_read[kv_trace_r].read_offset,\n'
            '              kv_rd_resp[kv_trace_r].error, kv_rd_resp[kv_trace_r].last, kv_trace_w,\n'
            '              kv_write[kv_trace_w].write_en, kv_write[kv_trace_w].write_entry,\n'
            '              kv_write[kv_trace_w].write_offset, kv_write[kv_trace_w].write_dest_valid,\n'
            '              dut.kv_reg_hwif_out.KEY_CTRL[kv_read[kv_trace_r].read_entry].dest_valid.value,\n'
            '              dut.kv_reg_hwif_out.KEY_CTRL[kv_read[kv_trace_r].read_entry].last_dword.value);\n'
            '          end\n'
            '        end\n'
            '      end\n'
            '    end\n'
            '  end\n',
            relative,
        )
    write_overlay(overlay_root, text, "hdl_top.sv")

    relative = "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_driver_bfm.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        'The BFM at \'%m\' has the following parameters: ", ),',
        'The BFM at \'%m\' has the following parameters: "),',
        relative,
    )
    write_overlay(overlay_root, text, "src/kv_rst_driver_bfm.sv")

    relative = "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_monitor_bfm.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        'The BFM at \'%m\' has the following parameters: ", ),',
        'The BFM at \'%m\' has the following parameters: "),',
        relative,
    )
    write_overlay(overlay_root, text, "src/kv_rst_monitor_bfm.sv")

    relative = "verification_ip/interface_packages/kv_rst_pkg/src/kv_rst_configuration.svh"
    text = read_pinned(source_root, relative)
    text = replace_once(text, "agent_path, interface_name, )", "agent_path, interface_name)", relative)
    write_overlay(overlay_root, text, "kv_rst_configuration.svh")

    relative = "verification_ip/interface_packages/kv_rst_pkg/kv_rst_pkg.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        '`include "src/kv_rst_configuration.svh"',
        '`include "kv_rst_configuration.svh"',
        relative,
    )
    write_overlay(overlay_root, text, "kv_rst_pkg.sv")

    relative = "verification_ip/interface_packages/kv_write_pkg/kv_write_pkg.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        '   `include "src/kv_write_AHB_lock_set_sequence.svh"\n',
        "",
        relative,
    )
    write_overlay(overlay_root, text, "kv_write_pkg.sv")

    relative = "verification_ip/interface_packages/kv_read_pkg/src/kv_read_monitor_bfm.sv"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        '    kv_read_monitor_struct.read_data    = kv_rd_resp_i[31:0];\n\n'
        '    // pragma uvmf custom do_monitor end',
        '    kv_read_monitor_struct.read_data    = kv_rd_resp_i[31:0];\n\n'
        '    // Let same-edge write-monitor analysis callbacks update the model first.\n'
        '    #0;\n\n'
        '    // pragma uvmf custom do_monitor end',
        relative,
    )
    write_overlay(overlay_root, text, "src/kv_read_monitor_bfm.sv")

    relative = "project_benches/kv/tb/tests/src/test_top.svh"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        '    ACTIVE /* kv_mlkem_msg_read_agent     [14] */\n};',
        '    ACTIVE /* kv_mlkem_msg_read_agent     [14] */ ,\n'
        '    ACTIVE /* kv_dma_read_agent           [15] */\n};',
        relative,
    )
    write_overlay(overlay_root, text, "src/test_top.svh")

    relative = "verification_ip/environment_packages/kv_env_pkg/src/kv_env_configuration.svh"
    text = read_pinned(source_root, relative)
    text = replace_once(
        text,
        '    qvip_ahb_lite_slave_subenv_interface_names     = interface_names[0:0];\n'
        '    qvip_ahb_lite_slave_subenv_interface_activity  = interface_activity[0:0];',
        '    qvip_ahb_lite_slave_subenv_interface_names[0] = interface_names[0];\n'
        '    qvip_ahb_lite_slave_subenv_interface_activity[0] = interface_activity[0];',
        relative,
    )
    write_overlay(overlay_root, text, "src/kv_env_configuration.svh")

    sequence_sources = (
        "verification_ip/environment_packages/kv_env_pkg/src/kv_env_sequence_base.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_cold_rst_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_cold_rst_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_core_rst_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_lock_clear_rst_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_lock_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_debug_warm_rst_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_lock_sequence.svh",
        "verification_ip/environment_packages/kv_env_pkg/src/kv_wr_rd_rst_sequence.svh",
    )
    for relative in sequence_sources:
        text = read_pinned(source_root, relative)
        text, count = re.subn(
            r"configuration(\.[A-Za-z0-9_]+_agent_config\s*\.wait_for_num_clocks\s*\()",
            r"kv_cfg\1",
            text,
        )
        if count == 0:
            raise SystemExit(f"expected generated clock-wait calls in {relative}")
        if relative.endswith("/kv_env_sequence_base.svh"):
            text = replace_once(
                text,
                '                           ) );\n',
                '                           ) );\n\n'
                '  // Concrete alias keeps Icarus from losing nested task members on CONFIG_T.\n'
                '  kv_env_configuration kv_cfg;\n\n'
                '  virtual task pre_body();\n'
                '    super.pre_body();\n'
                '    if (!$cast(kv_cfg, configuration))\n'
                '      `uvm_fatal("KV_CONFIG", "Could not cast environment configuration")\n'
                '  endtask\n',
                relative,
            )
        write_overlay(overlay_root, text, "src/" + Path(relative).name)

    relative = "verification_ip/environment_packages/kv_env_pkg/src/kv_predictor.svh"
    text = read_pinned(source_root, relative)
    text = replace_once(text, "  CONFIG_T configuration;", "  kv_env_configuration configuration;", relative)
    if not re.search(
        r"configuration\.[A-Za-z0-9_]+_agent_config\s*\.wait_for_num_clocks\s*\(",
        text,
    ):
        raise SystemExit(f"expected generated clock-wait calls in {relative}")
    if diagnostic:
        text = replace_once(
            text,
            '    logic client_dest_valid;\n',
            '    logic client_dest_valid;\n'
            '    uvm_reg_data_t key_ctrl_mirror;\n',
            relative,
        )
        text = replace_once(
            text,
            '    kv_reg_data = kv_reg.get_mirrored_value();\n'
            '    kv_reg = p_kv_rm.get_reg_by_name($sformatf("KEY_ENTRY[%0d][%0d]",t_received.read_entry,t_received.read_offset));',
            '    kv_reg_data = kv_reg.get_mirrored_value();\n'
            '    key_ctrl_mirror = kv_reg_data;\n'
            '    kv_reg = p_kv_rm.get_reg_by_name($sformatf("KEY_ENTRY[%0d][%0d]",t_received.read_entry,t_received.read_offset));',
            relative,
        )
        text = replace_once(
            text,
            '    t_expected.last = (last_dword_written[t_received.read_entry] == t_received.read_offset); \n',
            '    t_expected.last = (last_dword_written[t_received.read_entry] == t_received.read_offset); \n'
            '    if ($test$plusargs("KV_PIN_TRACE") &&\n'
            '        (t_received.read_entry == 0 || t_received.read_entry == 19 || t_received.read_entry == 23))\n'
            '      `uvm_info("KV_PIN_TRACE", $sformatf("MODEL_READ t=%0t client=%s entry=%h offset=%h received_error=%b received_last=%b mirror=%h dest=%h last_dword=%h history_last=%h expected_error=%b expected_last=%b",\n'
            '        $time, client, t_received.read_entry, t_received.read_offset, t_received.error, t_received.last,\n'
            '        key_ctrl_mirror, dest_valid, key_ctrl_mirror[21:18], last_dword_written[t_received.read_entry],\n'
            '        t_expected.error, t_expected.last), UVM_NONE)\n',
            relative,
        )
        text = replace_once(
            text,
            '    logic clear;\n',
            '    logic clear;\n'
            '    uvm_reg_data_t key_ctrl_mirror;\n',
            relative,
        )
        text = replace_once(
            text,
            '    kv_reg_data = kv_reg.get_mirrored_value();    \n',
            '    kv_reg_data = kv_reg.get_mirrored_value();    \n'
            '    key_ctrl_mirror = kv_reg_data;\n',
            relative,
        )
        write_end = '    end\n\n      \n  endfunction\n'
        text = replace_once(
            text,
            write_end,
            '    end\n'
            '    if ($test$plusargs("KV_PIN_TRACE") &&\n'
            '        (t_received.write_entry == 0 || t_received.write_entry == 19 || t_received.write_entry == 23))\n'
            '      `uvm_info("KV_PIN_TRACE", $sformatf("MODEL_WRITE t=%0t en=%b entry=%h offset=%h dest=%h mirror=%h history_last=%h expected_error=%b",\n'
            '        $time, t_received.write_en, t_received.write_entry, t_received.write_offset,\n'
            '        t_received.write_dest_valid, key_ctrl_mirror, last_dword_written[t_received.write_entry], t_expected.error), UVM_NONE)\n'
            '\n      \n  endfunction\n',
            relative,
        )
    write_overlay(overlay_root, text, "src/" + Path(relative).name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
