// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
// Caliptra v2.1.2 axi_if adapter. Call driver.write_one / driver.read_one.
// Both interfaces and the BFM must share clk/rst_n and identical AW/DW/IW/UW.
// This adapter must be the only manager of wr/rd: do not also call axi_if's
// own manager tasks (rst_mgr, axi_read, axi_write, ...) on these interfaces.
module qd_caliptra_axi_single_master #(
  parameter AW=32, DW=32, IW=8, TIMEOUT=16,
  parameter integer RESPONSE_DELAY=0, parameter UW=32
) (
  input logic clk, rst_n,
  axi_if.w_mgr wr,
  axi_if.r_mgr rd
);
  initial begin
    if ($bits(wr.awaddr)!=AW || $bits(rd.araddr)!=AW ||
        $bits(wr.wdata)!=DW || $bits(rd.rdata)!=DW ||
        $bits(wr.awid)!=IW || $bits(wr.bid)!=IW ||
        $bits(rd.arid)!=IW || $bits(rd.rid)!=IW ||
        $bits(wr.awuser)!=UW || $bits(wr.wuser)!=UW || $bits(rd.aruser)!=UW)
      $fatal(1,"Caliptra adapter/interface width mismatch");
  end
  // axi_if's manager signals are variables that its own manager tasks write
  // procedurally, so they are driven here procedurally too (IEEE 1800-2023
  // 6.5, 23.3.3.2), the way Caliptra's axi_mgr_rd/axi_mgr_wr drive them: the
  // BFM's outputs land in local variables and one always_comb copies them out.
  logic [AW-1:0] araddr, awaddr;
  logic [7:0] arlen, awlen;
  logic [2:0] arsize, awsize;
  logic [1:0] arburst, awburst;
  logic [IW-1:0] arid, awid;
  logic [UW-1:0] aruser, awuser, wuser;
  logic [DW-1:0] wdata;
  logic [DW/8-1:0] wstrb;
  logic arvalid, rready, awvalid, wlast, wvalid, bready;
  always_comb begin
    rd.araddr=araddr; rd.arlen=arlen; rd.arsize=arsize; rd.arburst=arburst;
    rd.arid=arid; rd.aruser=aruser; rd.arlock=1'b0; rd.arvalid=arvalid;
    rd.rready=rready;
    wr.awaddr=awaddr; wr.awlen=awlen; wr.awsize=awsize; wr.awburst=awburst;
    wr.awid=awid; wr.awuser=awuser; wr.awlock=1'b0; wr.awvalid=awvalid;
    wr.wdata=wdata; wr.wstrb=wstrb; wr.wuser=wuser; wr.wlast=wlast; wr.wvalid=wvalid;
    wr.bready=bready;
  end
  // Response user metadata is deliberately not interpreted by this API.
  qd_axi4_single_master #(.AW(AW),.DW(DW),.IW(IW),.UW(UW),.TIMEOUT(TIMEOUT),.RESPONSE_DELAY(RESPONSE_DELAY)) driver (
    .clk(clk),.rst_n(rst_n),
    .araddr(araddr),.arlen(arlen),.arsize(arsize),.arburst(arburst),
    .arid(arid),.aruser(aruser),.arvalid(arvalid),.arready(rd.arready),
    .rdata(rd.rdata),.rresp(rd.rresp),.rid(rd.rid),.rlast(rd.rlast),
    .rvalid(rd.rvalid),.rready(rready),
    .awaddr(awaddr),.awlen(awlen),.awsize(awsize),.awburst(awburst),
    .awid(awid),.awuser(awuser),.awvalid(awvalid),.awready(wr.awready),
    .wdata(wdata),.wstrb(wstrb),.wuser(wuser),.wlast(wlast),.wvalid(wvalid),.wready(wr.wready),
    .bresp(wr.bresp),.bid(wr.bid),.bvalid(wr.bvalid),.bready(bready)
  );
endmodule
