#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path

rtl, filelist, overlay_root = map(Path, sys.argv[1:])


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one anchor, found {count}")
    return text.replace(old, new, 1)


def write_overlay(rel_path, transform):
    source = rtl / rel_path
    text = source.read_text()
    changed = transform(text)
    output = overlay_root / "rtl" / rel_path
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(changed)
    return output, hashlib.sha256(source.read_bytes()).hexdigest(), hashlib.sha256(output.read_bytes()).hexdigest()


def ecc_trace(text):
    anchor = "`CALIPTRA_ASSERT_STABLE(ERR_ECC_PRIVKEY_NOT_STABLE, privkey_reg, clk, (!reset_n || ecc_ready_reg) )"
    trace = r"""
`ifdef VERILATOR
    M11_ECC_PRIVKEY_CLEAR_TRACE: assert property (@(posedge clk) disable iff (!reset_n || ecc_ready_reg)
        !$stable(privkey_reg) |-> 1'b0)
        else $display("M11_ECC_CLEAR_TRACE kind=privkey time=%0t previous=%096h current=%096h ready=%b zeroize=%b key_present_reset=%b kv_read_fail=%b hwclr=%b",
                      $time, $past(privkey_reg), $sampled(privkey_reg), $sampled(ecc_ready_reg),
                      $sampled(zeroize_reg), $sampled(kv_key_data_present_reset),
                      $sampled(kv_privkey_error == KV_READ_FAIL), $sampled(hwif_in.ECC_PRIVKEY_IN[0].PRIVKEY_IN.hwclr));
    M11_ECC_SEED_CLEAR_TRACE: assert property (@(posedge clk) disable iff (!reset_n || ecc_ready_reg)
        !$stable(seed_reg) |-> 1'b0)
        else $display("M11_ECC_CLEAR_TRACE kind=seed time=%0t previous=%096h current=%096h ready=%b zeroize=%b seed_present_reset=%b kv_read_fail=%b hwclr=%b",
                      $time, $past(seed_reg), $sampled(seed_reg), $sampled(ecc_ready_reg),
                      $sampled(zeroize_reg), $sampled(kv_seed_data_present_reset),
                      $sampled(kv_seed_error == KV_READ_FAIL), $sampled(hwif_in.ECC_SEED[0].SEED.hwclr));
`endif
"""
    return replace_once(text, anchor, anchor + "\n" + trace, "ECC assertion anchor")


def dma_trace(text):
    marker = "`CALIPTRA_ASSERT(AXI_DMA_AES_FSM_ERR_SYNC,"
    lines = text.splitlines()
    hits = [i for i, line in enumerate(lines) if line.lstrip().startswith(marker)]
    if len(hits) != 1:
        raise SystemExit(f"DMA assertion anchor: expected one line, found {len(hits)}")
    trace = r"""
`ifdef VERILATOR
    M11_DMA_FSM_HISTORY_TRACE: assert property (@(posedge clk) disable iff (!rst_n)
        ($changed(ctrl_fsm_ps) || $changed(aes_fsm_ps)) |-> 1'b0)
        else $display("M11_DMA_FSM_HISTORY time=%0t ctrl_prev=%0d ctrl=%0d ctrl_next=%0d aes_prev=%0d aes=%0d aes_next=%0d aes_mode=%b cmd_parse_error=%b axi_error=%b mb_lock_error=%b aes_error=%b kv_any_error=%b all_bytes=%b",
                      $time, $past(ctrl_fsm_ps), $sampled(ctrl_fsm_ps), $sampled(ctrl_fsm_ns),
                      $past(aes_fsm_ps), $sampled(aes_fsm_ps), $sampled(aes_fsm_ns),
                      $sampled(hwif_out.ctrl.aes_mode_en.value), $sampled(cmd_parse_error),
                      $sampled(axi_error), $sampled(mb_lock_error), $sampled(aes_error),
                      $sampled(kv_any_error), $sampled(all_bytes_transferred));
    M11_DMA_ERR_SYNC_TRACE: assert property (@(posedge clk) disable iff (!rst_n)
        (ctrl_fsm_ps == DMA_ERROR && hwif_out.ctrl.aes_mode_en.value && !cmd_parse_error && aes_fsm_ps != AES_ERROR) |-> 1'b0)
        else $display("M11_DMA_ERR_SYNC_EDGE time=%0t ctrl_prev=%0d ctrl=%0d ctrl_next=%0d aes_prev=%0d aes=%0d aes_next=%0d aes_mode=%b cmd_parse_error=%b axi_error=%b mb_lock_error=%b aes_error=%b kv_any_error=%b all_bytes=%b",
                      $time, $past(ctrl_fsm_ps), $sampled(ctrl_fsm_ps), $sampled(ctrl_fsm_ns),
                      $past(aes_fsm_ps), $sampled(aes_fsm_ps), $sampled(aes_fsm_ns),
                      $sampled(hwif_out.ctrl.aes_mode_en.value), $sampled(cmd_parse_error),
                      $sampled(axi_error), $sampled(mb_lock_error), $sampled(aes_error),
                      $sampled(kv_any_error), $sampled(all_bytes_transferred));
`endif
"""
    lines.insert(hits[0] + 1, trace)
    return "\n".join(lines) + "\n"


def mlkem_trace(text):
    decl_anchor = "    logic [7:0][31:0] kv_entry_data;"
    declarations = r"""
`ifdef VERILATOR
    integer m11_mlkem_cycle = 0;
    integer m11_mlkem_last_write_cycle [0:7];
    logic [4:0] m11_mlkem_last_write_slot [0:7];
    logic [31:0] m11_mlkem_last_write_data [0:7];
    initial begin
        for (integer m11_i = 0; m11_i < 8; m11_i = m11_i + 1) begin
            m11_mlkem_last_write_cycle[m11_i] = -1;
            m11_mlkem_last_write_slot[m11_i] = '0;
            m11_mlkem_last_write_data[m11_i] = '0;
        end
    end
    always @(posedge clk) m11_mlkem_cycle <= m11_mlkem_cycle + 1;
`endif
"""
    text = replace_once(text, decl_anchor, decl_anchor + "\n" + declarations, "MLKEM declaration anchor")
    write_anchor = "            assign kv_entry_data[g_dword] = `CPTRA_TOP_PATH.key_vault1.kv_reg_hwif_out.KEY_ENTRY[kv_entry_id][g_dword].data.value;"
    write_trace = r"""
`ifdef VERILATOR
            always @(posedge clk) begin
                if (`CPTRA_TOP_PATH.key_vault1.kv_reg_hwif_in.KEY_ENTRY[kv_entry_id][g_dword].data.we === 1'b1) begin
                    m11_mlkem_last_write_cycle[g_dword] <= m11_mlkem_cycle;
                    m11_mlkem_last_write_slot[g_dword] <= kv_entry_id;
                    m11_mlkem_last_write_data[g_dword] <= `CPTRA_TOP_PATH.key_vault1.kv_reg_hwif_in.KEY_ENTRY[kv_entry_id][g_dword].data.next;
                end
            end
`endif
"""
    text = replace_once(text, write_anchor, write_anchor + "\n" + write_trace, "MLKEM key-vault write anchor")
    check = "`CALIPTRA_ASSERT(KV_MLKEM_CHECK0,"
    lines = text.splitlines()
    hits = [i for i, line in enumerate(lines) if line.lstrip().startswith(check)]
    if len(hits) != 1:
        raise SystemExit(f"MLKEM assertion anchor: expected one line, found {len(hits)}")
    check_trace = r"""
`ifdef VERILATOR
            M11_MLKEM_BYTE_TRACE: assert property (@(posedge clk) disable iff (mlkem_kv_check_dis)
                (kv_entry_data[g_dword][g_byte*8 +: 8] != mlkem_test_vector.sharedkey[8-1-g_dword][(g_byte*8) +: 8]) |-> 1'b0)
                else $display("M11_MLKEM_CHECK time=%0t cycle=%0d slot=%0d dword=%0d byte=%0d actual=%02h expected=%02h last_write_cycle=%0d last_write_slot=%0d last_write_dword=%08h",
                              $time, $sampled(m11_mlkem_cycle), $sampled(kv_entry_id), g_dword, g_byte,
                              $sampled(kv_entry_data[g_dword][g_byte*8 +: 8]),
                              $sampled(mlkem_test_vector.sharedkey[8-1-g_dword][(g_byte*8) +: 8]),
                              $sampled(m11_mlkem_last_write_cycle[g_dword]),
                              $sampled(m11_mlkem_last_write_slot[g_dword]),
                              $sampled(m11_mlkem_last_write_data[g_dword]));
`endif
"""
    lines.insert(hits[0], check_trace)
    return "\n".join(lines) + "\n"


def dccm_trace(text):
    old = 'if (!hex_file_is_empty) $readmemh("dccm.hex",     dummy_dccm_preloader.ram,0,`RV_DCCM_EADR - `RV_DCCM_SADR);'
    new = r"""if (!hex_file_is_empty) begin
            $display("M11_DCCM_PRELOAD time=%0t base=%0h limit=%0h bytes=%0d array_depth=%0d word_bits=%0d array_last_word=%0d readmemh_end_index=%0d",
                     $time, `RV_DCCM_SADR, `RV_DCCM_EADR, DCCM_BYTE_SIZE,
                     DCCM_PRELOADER_DEPTH, DCCM_PRELOADER_WIDTH,
                     DCCM_PRELOADER_DEPTH-1, `RV_DCCM_EADR - `RV_DCCM_SADR);
            $readmemh("dccm.hex", dummy_dccm_preloader.ram, 0, `RV_DCCM_EADR - `RV_DCCM_SADR);
        end"""
    return replace_once(text, old, new, "DCCM preload anchor")


def services_trace(text):
    return dccm_trace(mlkem_trace(text))


transforms = {
    "src/ecc/rtl/ecc_dsa_ctrl.sv": ecc_trace,
    "src/axi/rtl/axi_dma_ctrl.sv": dma_trace,
    "src/integration/tb/caliptra_top_tb_services.sv": services_trace,
}
manifest = []
for rel_path, transform in transforms.items():
    output, source_hash, overlay_hash = write_overlay(rel_path, transform)
    entry = f"${{CALIPTRA_ROOT}}/{rel_path}"
    contents = filelist.read_text()
    if contents.splitlines().count(entry) != 1:
        raise SystemExit(f"expected one filelist entry for {entry}")
    filelist.write_text("\n".join(str(output) if line == entry else line for line in contents.splitlines()) + "\n")
    manifest.append(f"{rel_path} source_sha256={source_hash} overlay_sha256={overlay_hash}")

manifest.append(f"diagnostic_filelist_sha256={hashlib.sha256(filelist.read_bytes()).hexdigest()}")
print("\n".join(manifest))
