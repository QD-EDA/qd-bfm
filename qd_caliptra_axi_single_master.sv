// SPDX-License-Identifier: Apache-2.0
// Caliptra v2.1.2 axi_if adapter. Call driver.write_one / driver.read_one.
// Both interfaces and the BFM must share clk/rst_n and identical AW/DW/IW.
module qd_caliptra_axi_single_master #(
  parameter AW=32, DW=32, IW=8, TIMEOUT=16
) (
  input logic clk, rst_n,
  axi_if.w_mgr wr,
  axi_if.r_mgr rd
);
  initial begin
    if ($bits(wr.awaddr)!=AW || $bits(rd.araddr)!=AW ||
        $bits(wr.wdata)!=DW || $bits(rd.rdata)!=DW ||
        $bits(wr.awid)!=IW || $bits(wr.bid)!=IW ||
        $bits(rd.arid)!=IW || $bits(rd.rid)!=IW)
      $fatal(1,"Caliptra adapter/interface width mismatch");
  end
  assign wr.awuser='0;
  assign wr.wuser='0;
  assign wr.awlock=1'b0;
  assign rd.aruser='0;
  assign rd.arlock=1'b0;
  // Response user metadata is deliberately not interpreted by this API.
  qd_axi4_single_master #(.AW(AW),.DW(DW),.IW(IW),.TIMEOUT(TIMEOUT)) driver (
    .clk(clk),.rst_n(rst_n),
    .araddr(rd.araddr),.arlen(rd.arlen),.arsize(rd.arsize),.arburst(rd.arburst),
    .arid(rd.arid),.arvalid(rd.arvalid),.arready(rd.arready),
    .rdata(rd.rdata),.rresp(rd.rresp),.rid(rd.rid),.rlast(rd.rlast),
    .rvalid(rd.rvalid),.rready(rd.rready),
    .awaddr(wr.awaddr),.awlen(wr.awlen),.awsize(wr.awsize),.awburst(wr.awburst),
    .awid(wr.awid),.awvalid(wr.awvalid),.awready(wr.awready),
    .wdata(wr.wdata),.wstrb(wr.wstrb),.wlast(wr.wlast),.wvalid(wr.wvalid),.wready(wr.wready),
    .bresp(wr.bresp),.bid(wr.bid),.bvalid(wr.bvalid),.bready(wr.bready)
  );
endmodule
