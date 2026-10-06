// SPDX-License-Identifier: Apache-2.0
// Request/response mailbox between the UVM driver and the synthesizable
// module-level AXI task manager proxy.
interface axi4_caliptra_master_cmd_if(input wire ACLK);
  wire ARESETn;

  logic request_valid = 0;
  logic request_write = 0;
  logic inject_target_error = 0;
  logic [47:0] request_addr = 0;
  logic [7:0] request_len = 0;
  logic [2:0] request_size = 2;
  logic [1:0] request_burst = 1;
  logic [7:0] request_id = 0;
  logic [31:0] request_user = 0;
  logic request_lock = 0;
  logic [8191:0] request_write_data = 0;
  logic [1023:0] request_write_strb = 0;
  logic [8191:0] request_write_user = 0;

  logic response_valid = 0;
  logic response_success = 0;
  logic [7:0] response_id = 0;
  logic [1:0] response_code = 0;
  logic [31:0] response_user = 0;
  logic [8191:0] response_read_data = 0;
  logic [8191:0] response_read_user = 0;
  logic [511:0] response_read_code = 0;
endinterface
