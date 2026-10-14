// SPDX-License-Identifier: Apache-2.0
// Typed manager adapter for Caliptra's axi_if and the task-based manager.
module axi4_caliptra_master_if_manager #(
  parameter integer ADDR_WIDTH = 19,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter integer MAX_BEATS = 256,
  parameter integer TIMEOUT_CYCLES = 1024
) (
  input wire ACLK,
  input wire ARESETn,
  axi_if.w_mgr m_axi_w_if,
  axi_if.r_mgr m_axi_r_if,
  output wire [ID_WIDTH-1:0] write_response_id,
  output wire [ID_WIDTH-1:0] read_response_id
);
  axi4_caliptra_master #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .MAX_BEATS(MAX_BEATS),
    .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
  ) manager (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWID(m_axi_w_if.awid),
    .AWADDR(m_axi_w_if.awaddr),
    .AWLEN(m_axi_w_if.awlen),
    .AWSIZE(m_axi_w_if.awsize),
    .AWBURST(m_axi_w_if.awburst),
    .AWLOCK(m_axi_w_if.awlock),
    .AWUSER(m_axi_w_if.awuser),
    .AWVALID(m_axi_w_if.awvalid),
    .AWREADY(m_axi_w_if.awready),
    .WDATA(m_axi_w_if.wdata),
    .WSTRB(m_axi_w_if.wstrb),
    .WUSER(m_axi_w_if.wuser),
    .WLAST(m_axi_w_if.wlast),
    .WVALID(m_axi_w_if.wvalid),
    .WREADY(m_axi_w_if.wready),
    .BID(m_axi_w_if.bid),
    .BRESP(m_axi_w_if.bresp),
    .BUSER(m_axi_w_if.buser),
    .BVALID(m_axi_w_if.bvalid),
    .BREADY(m_axi_w_if.bready),
    .ARID(m_axi_r_if.arid),
    .ARADDR(m_axi_r_if.araddr),
    .ARLEN(m_axi_r_if.arlen),
    .ARSIZE(m_axi_r_if.arsize),
    .ARBURST(m_axi_r_if.arburst),
    .ARLOCK(m_axi_r_if.arlock),
    .ARUSER(m_axi_r_if.aruser),
    .ARVALID(m_axi_r_if.arvalid),
    .ARREADY(m_axi_r_if.arready),
    .RID(m_axi_r_if.rid),
    .RDATA(m_axi_r_if.rdata),
    .RRESP(m_axi_r_if.rresp),
    .RUSER(m_axi_r_if.ruser),
    .RLAST(m_axi_r_if.rlast),
    .RVALID(m_axi_r_if.rvalid),
    .RREADY(m_axi_r_if.rready),
    .write_response_id(write_response_id),
    .read_response_id(read_response_id)
  );

  task automatic reset_master;
    begin
      manager.reset_master();
    end
  endtask

  task automatic write_burst(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst,
    input [ID_WIDTH-1:0] id,
    input [USER_WIDTH-1:0] addr_user,
    input lock,
    input [DATA_WIDTH*MAX_BEATS-1:0] write_data,
    input [(DATA_WIDTH/8)*MAX_BEATS-1:0] write_strb,
    input [USER_WIDTH*MAX_BEATS-1:0] write_user,
    output reg success,
    output reg [1:0] response,
    output reg [USER_WIDTH-1:0] response_user
  );
    begin
      manager.write_burst(
        addr, len, size, burst, id, addr_user, lock,
        write_data, write_strb, write_user,
        success, response, response_user
      );
    end
  endtask

  task automatic read_burst(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst,
    input [ID_WIDTH-1:0] id,
    input [USER_WIDTH-1:0] addr_user,
    input lock,
    output reg success,
    output reg [DATA_WIDTH*MAX_BEATS-1:0] read_data,
    output reg [USER_WIDTH*MAX_BEATS-1:0] read_user,
    output reg [2*MAX_BEATS-1:0] read_response,
    output reg [USER_WIDTH-1:0] response_user
  );
    begin
      manager.read_burst(
        addr, len, size, burst, id, addr_user, lock,
        success, read_data, read_user, read_response, response_user
      );
    end
  endtask
endmodule
