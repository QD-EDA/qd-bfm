// SPDX-License-Identifier: Apache-2.0
// Record-level boundary between the pin monitor and the UVM analysis adapter.
// The AXI protocol monitor drives these fields; UVM samples them on ACLK's
// falling edge after the monitor's nonblocking updates have settled.
interface axi4_caliptra_record_if(input wire ACLK);
  // Icarus requires procedural monitor outputs to drive interface variables.
  logic ARESETn;

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
