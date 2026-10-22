// SPDX-License-Identifier: Apache-2.0
// Bounded request/response mailboxes for the UVM driver and AXI task proxy.
interface axi4_caliptra_master_cmd_if(input wire ACLK);
  parameter integer COMMAND_SLOTS = 4;
  wire ARESETn;

  logic stall_b_control = 0;
  logic stall_r_control = 0;
  logic inject_target_error = 0;
  logic request_valid [0:COMMAND_SLOTS-1];
  logic request_ack [0:COMMAND_SLOTS-1];
  logic request_write [0:COMMAND_SLOTS-1];
  logic [47:0] request_addr [0:COMMAND_SLOTS-1];
  logic [7:0] request_len [0:COMMAND_SLOTS-1];
  logic [2:0] request_size [0:COMMAND_SLOTS-1];
  logic [1:0] request_burst [0:COMMAND_SLOTS-1];
  logic [7:0] request_id [0:COMMAND_SLOTS-1];
  logic [31:0] request_user [0:COMMAND_SLOTS-1];
  logic request_lock [0:COMMAND_SLOTS-1];
  logic [8191:0] request_write_data [0:COMMAND_SLOTS-1];
  logic [1023:0] request_write_strb [0:COMMAND_SLOTS-1];
  logic [8191:0] request_write_user [0:COMMAND_SLOTS-1];

  logic response_valid [0:COMMAND_SLOTS-1];
  logic response_ready [0:COMMAND_SLOTS-1];
  logic response_success [0:COMMAND_SLOTS-1];
  logic [7:0] response_id [0:COMMAND_SLOTS-1];
  logic [1:0] response_code [0:COMMAND_SLOTS-1];
  logic [31:0] response_user [0:COMMAND_SLOTS-1];
  logic [8191:0] response_read_data [0:COMMAND_SLOTS-1];
  logic [8191:0] response_read_user [0:COMMAND_SLOTS-1];
  logic [511:0] response_read_code [0:COMMAND_SLOTS-1];
endinterface
