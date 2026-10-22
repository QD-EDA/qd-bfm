// SPDX-License-Identifier: Apache-2.0
// Lower-bound signal interface matching the AXI channels wired by Caliptra's
// generated SoC-IFC hdl_top.sv.
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
interface aaxi_intf #(
  parameter MCB_INPUT = 0,
  parameter MCB_OUTPUT = 0,
  parameter SCB_INPUT = 0,
  parameter SCB_OUTPUT = 0
) (
  input wire ACLK,
  input wire ARESETn,
  output wire CACTIVE,
  input wire CSYSREQ,
  output wire CSYSACK
);
  import aaxi_pkg::*;

  logic CACTIVE_m, CACTIVE_s;
  logic CSYSACK_m, CSYSACK_s;

  logic [AAXI_ADDR_WIDTH-1:0] ARADDR;
  logic [1:0] ARBURST;
  logic [2:0] ARSIZE;
  logic [7:0] ARLEN;
  logic [AAXI_ARUSER_WIDTH-1:0] ARUSER;
  logic [AAXI_ID_WIDTH-1:0] ARID;
  logic ARLOCK, ARVALID, ARREADY;

  logic [AAXI_DATA_WIDTH-1:0] RDATA;
  logic [1:0] RRESP;
  logic [AAXI_ID_WIDTH-1:0] RID;
  logic [AAXI_RUSER_WIDTH-1:0] RUSER;
  logic RLAST, RVALID, RREADY;

  logic [AAXI_ADDR_WIDTH-1:0] AWADDR;
  logic [1:0] AWBURST;
  logic [2:0] AWSIZE;
  logic [7:0] AWLEN;
  logic [AAXI_AWUSER_WIDTH-1:0] AWUSER;
  logic [AAXI_ID_WIDTH-1:0] AWID;
  logic AWLOCK, AWVALID, AWREADY;

  logic [AAXI_DATA_WIDTH-1:0] WDATA;
  logic [AAXI_DATA_WIDTH/8-1:0] WSTRB;
  logic [AAXI_WUSER_WIDTH-1:0] WUSER;
  logic WVALID, WREADY, WLAST;

  logic [1:0] BRESP;
  logic [AAXI_ID_WIDTH-1:0] BID;
  logic [AAXI_BUSER_WIDTH-1:0] BUSER;
  logic BVALID, BREADY;

  // Caliptra's generated bench ties clock-control sidebands inactive.
  assign CACTIVE = 1'b0;
  assign CSYSACK = 1'b0;
endinterface
`endif
