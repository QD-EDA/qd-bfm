`default_nettype none

// Narrow adapter for Caliptra's fixed ARM Axi4PC instantiation. It preserves
// the protocol checks implemented by axi4_caliptra_checker; it is not an ARM
// VIP replacement. Caliptra ties the unsupported CACHE/PROT/QOS/REGION inputs
// to zero at this instance.
module Axi4PC #(
  parameter integer DATA_WIDTH = 32,
  parameter integer WID_WIDTH = 8,
  parameter integer RID_WIDTH = 8,
  parameter integer ADDR_WIDTH = 19,
  parameter integer AWUSER_WIDTH = 32,
  parameter integer WUSER_WIDTH = 32,
  parameter integer BUSER_WIDTH = 32,
  parameter integer ARUSER_WIDTH = 32,
  parameter integer RUSER_WIDTH = 32,
  parameter integer RecMaxWaitOn = 0
) (
  input wire ACLK,
  input wire ARESETn,
  input wire [WID_WIDTH-1:0] AWID,
  input wire [ADDR_WIDTH-1:0] AWADDR,
  input wire [7:0] AWLEN,
  input wire [2:0] AWSIZE,
  input wire [1:0] AWBURST,
  input wire AWLOCK,
  input wire [3:0] AWCACHE,
  input wire [2:0] AWPROT,
  input wire [3:0] AWQOS,
  input wire [3:0] AWREGION,
  input wire [AWUSER_WIDTH-1:0] AWUSER,
  input wire AWVALID,
  input wire AWREADY,
  input wire [DATA_WIDTH-1:0] WDATA,
  input wire [DATA_WIDTH/8-1:0] WSTRB,
  input wire WLAST,
  input wire [WUSER_WIDTH-1:0] WUSER,
  input wire WVALID,
  input wire WREADY,
  input wire [WID_WIDTH-1:0] BID,
  input wire [1:0] BRESP,
  input wire [BUSER_WIDTH-1:0] BUSER,
  input wire BVALID,
  input wire BREADY,
  input wire [RID_WIDTH-1:0] ARID,
  input wire [ADDR_WIDTH-1:0] ARADDR,
  input wire [7:0] ARLEN,
  input wire [2:0] ARSIZE,
  input wire [1:0] ARBURST,
  input wire ARLOCK,
  input wire [3:0] ARCACHE,
  input wire [2:0] ARPROT,
  input wire [3:0] ARQOS,
  input wire [3:0] ARREGION,
  input wire [ARUSER_WIDTH-1:0] ARUSER,
  input wire ARVALID,
  input wire ARREADY,
  input wire [RID_WIDTH-1:0] RID,
  input wire [DATA_WIDTH-1:0] RDATA,
  input wire [1:0] RRESP,
  input wire [RUSER_WIDTH-1:0] RUSER,
  input wire RLAST,
  input wire RVALID,
  input wire RREADY,
  input wire CACTIVE,
  input wire CSYSREQ,
  input wire CSYSACK
);
  initial begin
    if (WID_WIDTH != RID_WIDTH || AWUSER_WIDTH != WUSER_WIDTH ||
        AWUSER_WIDTH != BUSER_WIDTH || AWUSER_WIDTH != ARUSER_WIDTH ||
        AWUSER_WIDTH != RUSER_WIDTH)
      $fatal(1, "Axi4PC compatibility adapter requires equal Caliptra ID and USER widths");
  end

  axi4_caliptra_checker #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(WID_WIDTH), .USER_WIDTH(AWUSER_WIDTH)
  ) qd_checker (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
    .AWVALID(AWVALID), .AWREADY(AWREADY),
    .WDATA(WDATA), .WSTRB(WSTRB), .WUSER(WUSER), .WLAST(WLAST),
    .WVALID(WVALID), .WREADY(WREADY),
    .BID(BID), .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
    .ARVALID(ARVALID), .ARREADY(ARREADY),
    .RID(RID), .RDATA(RDATA), .RRESP(RRESP), .RUSER(RUSER), .RLAST(RLAST),
    .RVALID(RVALID), .RREADY(RREADY)
  );

endmodule

`default_nettype wire
