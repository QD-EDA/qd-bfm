// SPDX-License-Identifier: Apache-2.0
// Bridges UVM commands to the standalone task-based PCRVault client BFM.
module pv_caliptra_uvm_master_proxy (
  pv_caliptra_master_cmd_if cmd_if,
  input wire clk,
  input wire rst_n,
  output pv_defines_pkg::pv_read_t [pv_defines_pkg::PV_NUM_READ-1:0] pv_read,
  input pv_defines_pkg::pv_rd_resp_t [pv_defines_pkg::PV_NUM_READ-1:0] pv_rd_resp,
  output pv_defines_pkg::pv_write_t [pv_defines_pkg::PV_NUM_WRITE-1:0] pv_write,
  input pv_defines_pkg::pv_wr_resp_t [pv_defines_pkg::PV_NUM_WRITE-1:0] pv_wr_resp
);
  import pv_defines_pkg::*;

  reg request_ok;
  reg success;
  reg response_error;
  reg response_last;
  reg [PV_DATA_W-1:0] response_data;

  pv_caliptra_master pin_manager (
    .clk(clk), .rst_n(rst_n), .pv_read(pv_read), .pv_rd_resp(pv_rd_resp),
    .pv_write(pv_write), .pv_wr_resp(pv_wr_resp)
  );

  initial begin
    cmd_if.response_valid = 0;
    cmd_if.response_request_ok = 0;
    cmd_if.response_success = 0;
    cmd_if.response_error = 0;
    cmd_if.response_last = 0;
    cmd_if.response_data = 0;
    if ($bits(cmd_if.request_entry) != PV_ENTRY_ADDR_W ||
        $bits(cmd_if.request_offset) != PV_ENTRY_SIZE_WIDTH ||
        $bits(cmd_if.request_data) != PV_DATA_W)
      $fatal(1, "PV command interface widths do not match pv_defines_pkg");

    forever begin
      wait (cmd_if.request_valid === 1'b1);
      if (cmd_if.request_write) begin
        pin_manager.write_one(
          cmd_if.request_entry, cmd_if.request_offset, cmd_if.request_data,
          request_ok, success, response_error);
        response_last = 0;
        response_data = 0;
      end else begin
        pin_manager.read_one(
          cmd_if.request_entry, cmd_if.request_offset,
          request_ok, success, response_error, response_last, response_data);
      end
      cmd_if.response_request_ok = request_ok;
      cmd_if.response_success = success;
      cmd_if.response_error = response_error;
      cmd_if.response_last = response_last;
      cmd_if.response_data = response_data;
      cmd_if.response_valid = 1;
      wait (cmd_if.request_valid === 1'b0);
      cmd_if.response_valid = 0;
    end
  end
endmodule
