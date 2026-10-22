#!/usr/bin/env python3
"""Create a hash-guarded, read-only trace overlay for the SHA512 block assertion."""

import hashlib
import sys
from pathlib import Path

source_path, output_path = map(Path, sys.argv[1:])
source = source_path.read_text()
source_sha = hashlib.sha256(source.encode()).hexdigest()
expected_sha = "5656d5a09d1570a567bb674b1b419775a83a08b37ee70792d28ab72ae0510d82"
assert source_sha == expected_sha, (source_sha, expected_sha)
assert source.count("ERR_SHA_BLOCK_NOT_STABLE, block_reg, clk, (!reset_n || ready_reg)") == 1
assert "M10_SHA_BLOCK_CHANGE" not in source
assert source.count("endmodule") == 1

monitor = r'''
// Diagnostic-only read-only trace for the block stability assertion.
logic m10_sha_trace_valid;
integer m10_sha_trace_count;
logic [DATA_WIDTH-1:0][BLOCK_NUM_DWORDS-1:0] m10_sha_trace_prev_block;
initial begin
  m10_sha_trace_valid = 1'b0;
  m10_sha_trace_count = 0;
end
always @(block_reg) begin
  if (m10_sha_trace_valid && reset_n && !ready_reg &&
      block_reg !== m10_sha_trace_prev_block && m10_sha_trace_count < 8) begin
    $display("M10_SHA_BLOCK_CHANGE time=%0t reset_n=%b ready_reg=%b zeroize_reg=%b gen_hash_ip=%b gen_hash_block_write_en=%b gen_hash_block_write_offset=%0d kv_src_write_en=%b kv_src_write_offset=%0d kv_read_data_present_reset=%b prev=%h current=%h",
      $time, reset_n, ready_reg, zeroize_reg, gen_hash_ip,
      gen_hash_block_write_en, gen_hash_block_write_offset,
      kv_src_write_en, kv_src_write_offset, kv_read_data_present_reset,
      m10_sha_trace_prev_block, block_reg);
    m10_sha_trace_count = m10_sha_trace_count + 1;
  end
  m10_sha_trace_prev_block = block_reg;
  m10_sha_trace_valid = 1'b1;
end
'''

output = source.replace("endmodule", monitor + "\nendmodule", 1)
assert output.count("ERR_SHA_BLOCK_NOT_STABLE, block_reg, clk, (!reset_n || ready_reg)") == 1
assert output.count("M10_SHA_BLOCK_CHANGE") == 1
output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(output)
print(f"source_sha256={source_sha}")
print(f"trace_overlay_sha256={hashlib.sha256(output.encode()).hexdigest()}")
