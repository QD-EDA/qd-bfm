// SPDX-License-Identifier: Apache-2.0
// Record-level boundary between the pin monitor and the UVM analysis adapter.
// The AXI protocol monitor drives these fields; UVM samples them on ACLK's
// falling edge after the monitor's nonblocking updates have settled.
interface axi4_caliptra_record_if(input wire ACLK);
  // Icarus requires procedural monitor outputs to drive interface variables.
  logic ARESETn;

  // Packed channel records use 8-bit IDs, 48-bit addresses, and 32-bit payloads.
  logic [63:0] channel_cycle;
  logic [31:0] aw_count, w_count, b_count, ar_count, r_count;
  logic [31:0] aw_valid_cycles, w_valid_cycles, b_valid_cycles;
  logic [31:0] ar_valid_cycles, r_valid_cycles;
  logic [31:0] aw_stall_cycles, w_stall_cycles, b_stall_cycles;
  logic [31:0] ar_stall_cycles, r_stall_cycles;
  logic [31:0] aw_burst_fixed_count, aw_burst_incr_count;
  logic [31:0] aw_burst_wrap_count, aw_burst_reserved_count, aw_burst_unknown_count;
  logic [31:0] aw_lock_clear_count, aw_lock_set_count, aw_lock_unknown_count;
  logic [31:0] ar_burst_fixed_count, ar_burst_incr_count;
  logic [31:0] ar_burst_wrap_count, ar_burst_reserved_count, ar_burst_unknown_count;
  logic [31:0] ar_lock_clear_count, ar_lock_set_count, ar_lock_unknown_count;
  logic [31:0] b_resp_okay_count, b_resp_exokay_count, b_resp_slverr_count;
  logic [31:0] b_resp_decerr_count, b_resp_unknown_count;
  logic [31:0] r_resp_okay_count, r_resp_exokay_count, r_resp_slverr_count;
  logic [31:0] r_resp_decerr_count, r_resp_unknown_count;
  logic [31:0] w_strb_full_count, w_strb_partial_count;
  logic [31:0] w_strb_zero_count, w_strb_unknown_count;
  logic [31:0] w_last_count, r_last_count;
  logic aw_fire;
  logic [101:0] aw_record;
  logic w_fire;
  logic [68:0] w_record;
  logic b_fire;
  logic [41:0] b_record;
  logic ar_fire;
  logic [101:0] ar_record;
  logic r_fire;
  logic [74:0] r_record;

  logic write_complete;
  logic write_request_complete;
  logic write_request_error;
  logic [3:0] write_request_status;
  logic [7:0] write_request_id;
  logic [47:0] write_request_addr;
  logic [7:0] write_request_len;
  logic [2:0] write_request_size;
  logic [1:0] write_request_burst;
  logic write_request_lock;
  logic [31:0] write_request_awuser;
  logic [8:0] write_request_beat_count;
  logic [8191:0] write_request_data;
  logic [1023:0] write_request_strb;
  logic [8191:0] write_request_wuser;
  logic [255:0] write_request_last_mask;
  logic write_error;
  logic [3:0] write_error_code;
  logic [3:0] write_status;
  logic [7:0] write_id;
  logic [47:0] write_addr;
  logic [7:0] write_len;
  logic [2:0] write_size;
  logic [1:0] write_burst;
  logic write_lock;
  logic [31:0] write_awuser;
  logic [8:0] write_beat_count;
  logic [8191:0] write_data;
  logic [1023:0] write_strb;
  logic [8191:0] write_wuser;
  logic [255:0] write_last_mask;
  logic [7:0] write_response_id;
  logic [1:0] write_response;
  logic [31:0] write_buser;

  logic read_complete;
  logic read_error;
  logic [3:0] read_error_code;
  logic [3:0] read_status;
  logic [7:0] read_id;
  logic [47:0] read_addr;
  logic [7:0] read_len;
  logic [2:0] read_size;
  logic [1:0] read_burst;
  logic read_lock;
  logic [31:0] read_aruser;
  logic [8:0] read_beat_count;
  logic [8191:0] read_data;
  logic [511:0] read_resp;
  logic [8191:0] read_ruser;
  logic [255:0] read_last_mask;
endinterface
