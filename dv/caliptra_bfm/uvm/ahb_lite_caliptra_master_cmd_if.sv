// SPDX-License-Identifier: Apache-2.0
// Request/response mailbox between UVM and the AHB-Lite module task manager.
interface ahb_lite_caliptra_master_cmd_if(input wire HCLK);
  localparam integer MAX_BURST_BEATS = 256;
  wire HRESETn;

  logic request_valid = 0;
  logic request_write = 0;
  logic [31:0] request_address = 0;
  logic [2:0] request_size = 3;
  logic [63:0] request_write_data = 0;
  logic [8:0] request_burst_count = 1;
  logic [MAX_BURST_BEATS*64-1:0] request_burst_data = '0;

  // Testbench target controls; these do not represent AHB bus fields.
  logic [7:0] target_wait_cycles = 0;
  logic inject_target_error = 0;

  logic response_valid = 0;
  logic response_request_ok = 0;
  logic response_success = 0;
  logic response_error = 0;
  logic response_aborted = 0;
  logic [63:0] response_read_data = 0;
  logic [8:0] response_completed_beats = 0;
  logic [MAX_BURST_BEATS-1:0] response_beat_error = '0;
  logic [MAX_BURST_BEATS*64-1:0] response_burst_read_data = '0;
endinterface
