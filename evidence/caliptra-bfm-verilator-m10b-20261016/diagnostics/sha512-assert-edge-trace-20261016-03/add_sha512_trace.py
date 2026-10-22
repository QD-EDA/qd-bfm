#!/usr/bin/env python3
"""Create a hash-guarded edge-level trace overlay for SHA512 block clear."""

import hashlib
import sys
from pathlib import Path

source_path, output_path = map(Path, sys.argv[1:])
source = source_path.read_text()
source_sha = hashlib.sha256(source.encode()).hexdigest()
expected_sha = "5656d5a09d1570a567bb674b1b419775a83a08b37ee70792d28ab72ae0510d82"
assert source_sha == expected_sha, (source_sha, expected_sha)
assert source.count("ERR_SHA_BLOCK_NOT_STABLE, block_reg, clk, (!reset_n || ready_reg)") == 1
assert "M10_SHA_EDGE" not in source
assert source.count("endmodule") == 1

monitor = r'''
// Diagnostic-only edge/control trace; the existing assertion and RTL are untouched.
integer m10_sha_edge_cycle;
integer m10_sha_block_events;
integer m10_sha_trace_edges;
integer m10_sha_low_zeroize_edges;
logic m10_sha_trace_active;
logic [DATA_WIDTH-1:0][BLOCK_NUM_DWORDS-1:0] m10_sha_edge_prev_block;
initial begin
  m10_sha_edge_cycle = 0;
  m10_sha_block_events = 0;
  m10_sha_trace_edges = 0;
  m10_sha_low_zeroize_edges = 0;
  m10_sha_trace_active = 1'b0;
  m10_sha_edge_prev_block = '0;
end
always @(posedge clk) begin
  m10_sha_edge_cycle = m10_sha_edge_cycle + 1;
  if (m10_sha_trace_active) begin
    m10_sha_trace_edges = m10_sha_trace_edges + 1;
    if (zeroize_reg === 1'b0)
      m10_sha_low_zeroize_edges = m10_sha_low_zeroize_edges + 1;
    else
      m10_sha_low_zeroize_edges = 0;
    $display("M10_SHA_EDGE time=%0t cycle=%0d clk=%b reset_n=%b ready=%b zeroize=%b sw_zeroize=%b debug_unlock=%b gen_hash_ip=%b gen_hash_we=%b kv_src_we=%b kv_read_reset=%b hwclr0=%b hwclr31=%b we0=%b we31=%b block0=%h block31=%h block=%h",
      $time, m10_sha_edge_cycle, clk, reset_n, ready_reg, zeroize_reg,
      hwif_out.SHA512_CTRL.ZEROIZE.value, debugUnlock_or_scan_mode_switch,
      gen_hash_ip, gen_hash_block_write_en, kv_src_write_en,
      kv_read_data_present_reset, hwif_in.SHA512_BLOCK[0].BLOCK.hwclr,
      hwif_in.SHA512_BLOCK[31].BLOCK.hwclr, hwif_in.SHA512_BLOCK[0].BLOCK.we,
      hwif_in.SHA512_BLOCK[31].BLOCK.we, block_reg[0], block_reg[31], block_reg);
    if (m10_sha_trace_edges >= 64 || m10_sha_low_zeroize_edges >= 8)
      m10_sha_trace_active = 1'b0;
  end
end
always @(zeroize_reg) begin
  if (zeroize_reg === 1'b1) begin
    m10_sha_trace_active = 1'b1;
    m10_sha_trace_edges = 0;
    m10_sha_low_zeroize_edges = 0;
    m10_sha_block_events = 0;
  end
  if (m10_sha_trace_active)
    $display("M10_SHA_ZEROIZE_CHANGE time=%0t cycle=%0d clk=%b zeroize=%b sw_zeroize=%b debug_unlock=%b ready=%b hwclr0=%b hwclr31=%b kv_read_reset=%b block=%h",
      $time, m10_sha_edge_cycle, clk, zeroize_reg,
      hwif_out.SHA512_CTRL.ZEROIZE.value, debugUnlock_or_scan_mode_switch,
      ready_reg, hwif_in.SHA512_BLOCK[0].BLOCK.hwclr,
      hwif_in.SHA512_BLOCK[31].BLOCK.hwclr, kv_read_data_present_reset, block_reg);
end
always @(hwif_in.SHA512_BLOCK[0].BLOCK.hwclr) begin
  if (m10_sha_trace_active)
    $display("M10_SHA_HWCLR_CHANGE time=%0t cycle=%0d clk=%b hwclr0=%b hwclr31=%b zeroize=%b sw_zeroize=%b ready=%b block=%h",
      $time, m10_sha_edge_cycle, clk,
      hwif_in.SHA512_BLOCK[0].BLOCK.hwclr,
      hwif_in.SHA512_BLOCK[31].BLOCK.hwclr, zeroize_reg,
      hwif_out.SHA512_CTRL.ZEROIZE.value, ready_reg, block_reg);
end
always @(block_reg) begin
  if (m10_sha_trace_active && block_reg !== m10_sha_edge_prev_block &&
      m10_sha_block_events < 32) begin
    $display("M10_SHA_BLOCK_CHANGE time=%0t cycle=%0d clk=%b reset_n=%b ready=%b zeroize=%b sw_zeroize=%b debug_unlock=%b hwclr0=%b hwclr31=%b we0=%b we31=%b prev=%h current=%h",
      $time, m10_sha_edge_cycle, clk, reset_n, ready_reg, zeroize_reg,
      hwif_out.SHA512_CTRL.ZEROIZE.value, debugUnlock_or_scan_mode_switch,
      hwif_in.SHA512_BLOCK[0].BLOCK.hwclr,
      hwif_in.SHA512_BLOCK[31].BLOCK.hwclr,
      hwif_in.SHA512_BLOCK[0].BLOCK.we,
      hwif_in.SHA512_BLOCK[31].BLOCK.we,
      m10_sha_edge_prev_block, block_reg);
    m10_sha_block_events = m10_sha_block_events + 1;
  end
  m10_sha_edge_prev_block = block_reg;
end
'''

output = source.replace("endmodule", monitor + "\nendmodule", 1)
assert output.count("ERR_SHA_BLOCK_NOT_STABLE, block_reg, clk, (!reset_n || ready_reg)") == 1
assert output.count("M10_SHA_EDGE") == 1
output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(output)
print(f"source_sha256={source_sha}")
print(f"trace_overlay_sha256={hashlib.sha256(output.encode()).hexdigest()}")
