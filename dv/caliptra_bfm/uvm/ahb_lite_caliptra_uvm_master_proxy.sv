// SPDX-License-Identifier: Apache-2.0
// Bridges UVM commands to the standalone task-based AHB-Lite manager.
module ahb_lite_caliptra_uvm_master_proxy #(
  parameter integer ADDR_WIDTH = 32,
  parameter integer DATA_WIDTH = 64,
  parameter integer MAX_WAIT_CYCLES = 1024,
  parameter integer MAX_BURST_BEATS = 256
) (
  ahb_lite_caliptra_master_cmd_if cmd_if,
  input wire HCLK,
  input wire HRESETn,
  input wire HREADY,
  input wire HRESP,
  input wire [DATA_WIDTH-1:0] HRDATA,
  output wire HSEL,
  output wire [ADDR_WIDTH-1:0] HADDR,
  output wire [DATA_WIDTH-1:0] HWDATA,
  output wire HWRITE,
  output wire [2:0] HSIZE,
  output wire [1:0] HTRANS
);
  wire busy;
  wire poisoned;
  reg request_ok;
  reg success;
  reg response_error;
  reg [DATA_WIDTH-1:0] read_data;
  reg [MAX_BURST_BEATS*DATA_WIDTH-1:0] burst_read_data;
  reg [MAX_BURST_BEATS-1:0] burst_beat_error;
  integer completed_beats;

  ahb_lite_caliptra_master #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
    .MAX_WAIT_CYCLES(MAX_WAIT_CYCLES),
    .MAX_BURST_BEATS(MAX_BURST_BEATS)
  ) pin_manager (
    .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADY), .HRESP(HRESP),
    .HRDATA(HRDATA), .HSEL(HSEL), .HADDR(HADDR), .HWDATA(HWDATA),
    .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS),
    .busy(busy), .poisoned(poisoned)
  );

  initial begin
    cmd_if.response_valid = 0;
    cmd_if.response_request_ok = 0;
    cmd_if.response_success = 0;
    cmd_if.response_error = 0;
    cmd_if.response_read_data = 0;
    cmd_if.response_completed_beats = 0;
    cmd_if.response_beat_error = '0;
    cmd_if.response_burst_read_data = '0;
    forever begin
      wait (cmd_if.request_valid === 1'b1);
      read_data = 0;
      burst_read_data = '0;
      burst_beat_error = '0;
      completed_beats = 0;
      if ((cmd_if.request_burst_count >= 1) &&
          (cmd_if.request_burst_count <= MAX_BURST_BEATS)) begin
        if (cmd_if.request_burst_count == 1) begin
          if (cmd_if.request_write) begin
            pin_manager.write_one(
              cmd_if.request_address, cmd_if.request_size,
              cmd_if.request_write_data, request_ok, success, response_error);
          end else begin
            pin_manager.read_one(
              cmd_if.request_address, cmd_if.request_size,
              request_ok, success, response_error, read_data);
          end
          burst_read_data[0 +: DATA_WIDTH] = read_data;
          burst_beat_error[0] = response_error;
          completed_beats = (success || response_error) ? 1 : 0;
        end else begin
          pin_manager.transfer_incr_burst(
            cmd_if.request_address, cmd_if.request_write,
            cmd_if.request_size, cmd_if.request_burst_count,
            cmd_if.request_burst_data, request_ok, success,
            response_error, burst_read_data, burst_beat_error,
            completed_beats);
          read_data = burst_read_data[0 +: DATA_WIDTH];
        end
      end else begin
        request_ok = 0;
        success = 0;
        response_error = 1;
      end
      cmd_if.response_request_ok = request_ok;
      cmd_if.response_success = success;
      cmd_if.response_error = response_error;
      cmd_if.response_read_data = read_data;
      cmd_if.response_completed_beats = completed_beats;
      cmd_if.response_beat_error = burst_beat_error;
      cmd_if.response_burst_read_data = burst_read_data;
      cmd_if.response_valid = 1;
      wait (cmd_if.request_valid === 1'b0);
      cmd_if.response_valid = 0;
    end
  end
endmodule
