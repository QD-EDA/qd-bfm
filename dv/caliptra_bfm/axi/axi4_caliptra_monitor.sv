// SPDX-License-Identifier: Apache-2.0
// Emits one-cycle records for each accepted AXI channel beat.
module axi4_caliptra_monitor #(
  parameter integer ADDR_WIDTH = 19,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32
) (
  input wire ACLK,
  input wire ARESETn,
  input wire [ID_WIDTH-1:0] AWID,
  input wire [ADDR_WIDTH-1:0] AWADDR,
  input wire [7:0] AWLEN,
  input wire [2:0] AWSIZE,
  input wire [1:0] AWBURST,
  input wire AWLOCK,
  input wire [USER_WIDTH-1:0] AWUSER,
  input wire AWVALID,
  input wire AWREADY,
  input wire [DATA_WIDTH-1:0] WDATA,
  input wire [DATA_WIDTH/8-1:0] WSTRB,
  input wire [USER_WIDTH-1:0] WUSER,
  input wire WLAST,
  input wire WVALID,
  input wire WREADY,
  input wire [ID_WIDTH-1:0] BID,
  input wire [1:0] BRESP,
  input wire [USER_WIDTH-1:0] BUSER,
  input wire BVALID,
  input wire BREADY,
  input wire [ID_WIDTH-1:0] ARID,
  input wire [ADDR_WIDTH-1:0] ARADDR,
  input wire [7:0] ARLEN,
  input wire [2:0] ARSIZE,
  input wire [1:0] ARBURST,
  input wire ARLOCK,
  input wire [USER_WIDTH-1:0] ARUSER,
  input wire ARVALID,
  input wire ARREADY,
  input wire [ID_WIDTH-1:0] RID,
  input wire [DATA_WIDTH-1:0] RDATA,
  input wire [1:0] RRESP,
  input wire [USER_WIDTH-1:0] RUSER,
  input wire RLAST,
  input wire RVALID,
  input wire RREADY,
  output reg aw_fire,
  output reg [ID_WIDTH+ADDR_WIDTH+8+3+2+1+USER_WIDTH-1:0] aw_record,
  output reg w_fire,
  output reg [DATA_WIDTH+DATA_WIDTH/8+USER_WIDTH:0] w_record,
  output reg b_fire,
  output reg [ID_WIDTH+1+1+USER_WIDTH-1:0] b_record,
  output reg ar_fire,
  output reg [ID_WIDTH+ADDR_WIDTH+8+3+2+1+USER_WIDTH-1:0] ar_record,
  output reg r_fire,
  output reg [ID_WIDTH+DATA_WIDTH+1+1+1+USER_WIDTH-1:0] r_record,
  output reg [63:0] cycle_count,
  output reg [31:0] aw_count,
  output reg [31:0] w_count,
  output reg [31:0] b_count,
  output reg [31:0] ar_count,
  output reg [31:0] r_count
);
  always @(posedge ACLK) begin
    if (!ARESETn) begin
      aw_fire <= 0; w_fire <= 0; b_fire <= 0; ar_fire <= 0; r_fire <= 0;
      cycle_count <= 0; aw_count <= 0; w_count <= 0; b_count <= 0;
      ar_count <= 0; r_count <= 0;
      aw_record <= 0; w_record <= 0; b_record <= 0; ar_record <= 0; r_record <= 0;
    end else begin
      cycle_count <= cycle_count + 1'b1;
      aw_fire <= AWVALID && AWREADY;
      w_fire <= WVALID && WREADY;
      b_fire <= BVALID && BREADY;
      ar_fire <= ARVALID && ARREADY;
      r_fire <= RVALID && RREADY;
      if (AWVALID && AWREADY) begin
        aw_count <= aw_count + 1'b1;
        aw_record <= {AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWUSER};
      end
      if (WVALID && WREADY) begin
        w_count <= w_count + 1'b1;
        w_record <= {WDATA, WSTRB, WUSER, WLAST};
      end
      if (BVALID && BREADY) begin
        b_count <= b_count + 1'b1;
        b_record <= {BID, BRESP, BUSER};
      end
      if (ARVALID && ARREADY) begin
        ar_count <= ar_count + 1'b1;
        ar_record <= {ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARUSER};
      end
      if (RVALID && RREADY) begin
        r_count <= r_count + 1'b1;
        r_record <= {RID, RDATA, RRESP, RUSER, RLAST};
      end
    end
  end
endmodule
