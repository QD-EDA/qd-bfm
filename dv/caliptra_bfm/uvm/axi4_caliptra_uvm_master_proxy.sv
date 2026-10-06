// SPDX-License-Identifier: Apache-2.0
// Bridges UVM command records to the existing task-based pin-level manager.
module axi4_caliptra_uvm_master_proxy #(
  parameter integer ADDR_WIDTH = 48,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter integer MAX_BEATS = 256,
  parameter integer TIMEOUT_CYCLES = 1024
) (
  axi4_caliptra_master_cmd_if cmd_if,
  input wire ACLK,
  input wire ARESETn,
  output wire [ID_WIDTH-1:0] AWID,
  output wire [ADDR_WIDTH-1:0] AWADDR,
  output wire [7:0] AWLEN,
  output wire [2:0] AWSIZE,
  output wire [1:0] AWBURST,
  output wire AWLOCK,
  output wire [USER_WIDTH-1:0] AWUSER,
  output wire AWVALID,
  input wire AWREADY,
  output wire [DATA_WIDTH-1:0] WDATA,
  output wire [DATA_WIDTH/8-1:0] WSTRB,
  output wire [USER_WIDTH-1:0] WUSER,
  output wire WLAST,
  output wire WVALID,
  input wire WREADY,
  input wire [ID_WIDTH-1:0] BID,
  input wire [1:0] BRESP,
  input wire [USER_WIDTH-1:0] BUSER,
  input wire BVALID,
  output wire BREADY,
  output wire [ID_WIDTH-1:0] ARID,
  output wire [ADDR_WIDTH-1:0] ARADDR,
  output wire [7:0] ARLEN,
  output wire [2:0] ARSIZE,
  output wire [1:0] ARBURST,
  output wire ARLOCK,
  output wire [USER_WIDTH-1:0] ARUSER,
  output wire ARVALID,
  input wire ARREADY,
  input wire [ID_WIDTH-1:0] RID,
  input wire [DATA_WIDTH-1:0] RDATA,
  input wire [1:0] RRESP,
  input wire [USER_WIDTH-1:0] RUSER,
  input wire RLAST,
  input wire RVALID,
  output wire RREADY
);
  reg write_success;
  wire [ID_WIDTH-1:0] write_response_id;
  reg [1:0] write_response;
  reg [USER_WIDTH-1:0] write_response_user;
  reg read_success;
  wire [ID_WIDTH-1:0] read_response_id;
  reg [DATA_WIDTH*MAX_BEATS-1:0] read_data;
  reg [USER_WIDTH*MAX_BEATS-1:0] read_user;
  reg [2*MAX_BEATS-1:0] read_response;
  reg [USER_WIDTH-1:0] read_response_user;

  axi4_caliptra_master #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .MAX_BEATS(MAX_BEATS),
    .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
  ) pin_manager (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER), .AWVALID(AWVALID),
    .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB), .WUSER(WUSER),
    .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY), .BID(BID),
    .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER), .ARVALID(ARVALID),
    .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA), .RRESP(RRESP),
    .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID), .RREADY(RREADY),
    .write_response_id(write_response_id),
    .read_response_id(read_response_id)
  );

  initial begin
    cmd_if.response_valid = 1'b0;
    cmd_if.response_success = 1'b0;
    cmd_if.response_id = '0;
    cmd_if.response_code = '0;
    cmd_if.response_user = '0;
    cmd_if.response_read_data = '0;
    cmd_if.response_read_user = '0;
    cmd_if.response_read_code = '0;
    forever begin
      wait (cmd_if.request_valid === 1'b1);
      if (cmd_if.request_write) begin
        pin_manager.write_burst(
          cmd_if.request_addr, cmd_if.request_len, cmd_if.request_size,
          cmd_if.request_burst, cmd_if.request_id, cmd_if.request_user,
          cmd_if.request_lock, cmd_if.request_write_data,
          cmd_if.request_write_strb, cmd_if.request_write_user,
          write_success, write_response, write_response_user);
        cmd_if.response_success = write_success;
        cmd_if.response_id = write_response_id;
        cmd_if.response_code = write_response;
        cmd_if.response_user = write_response_user;
        cmd_if.response_read_data = '0;
        cmd_if.response_read_user = '0;
        cmd_if.response_read_code = '0;
      end else begin
        pin_manager.read_burst(
          cmd_if.request_addr, cmd_if.request_len, cmd_if.request_size,
          cmd_if.request_burst, cmd_if.request_id, cmd_if.request_user,
          cmd_if.request_lock, read_success, read_data, read_user,
          read_response, read_response_user);
        cmd_if.response_success = read_success;
        cmd_if.response_id = read_response_id;
        cmd_if.response_code = read_response[1:0];
        cmd_if.response_user = read_response_user;
        cmd_if.response_read_data = read_data;
        cmd_if.response_read_user = read_user;
        cmd_if.response_read_code = read_response;
      end
      cmd_if.response_valid = 1'b1;
      wait (cmd_if.request_valid === 1'b0);
      cmd_if.response_valid = 1'b0;
    end
  end
endmodule
