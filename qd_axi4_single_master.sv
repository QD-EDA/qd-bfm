// SPDX-License-Identifier: Apache-2.0
module qd_axi4_single_master #(
  parameter AW = 32, DW = 32, IW = 8, TIMEOUT = 16,
  parameter integer RESPONSE_DELAY = 0, parameter UW = 32
) (
  input logic clk, rst_n,
  output logic [AW-1:0] araddr, output logic [7:0] arlen,
  output logic [2:0] arsize, output logic [1:0] arburst,
  output logic [IW-1:0] arid, output logic arvalid,
  input logic arready,
  input logic [DW-1:0] rdata, input logic [1:0] rresp,
  input logic [IW-1:0] rid, input logic rlast, rvalid,
  output logic rready,
  output logic [AW-1:0] awaddr, output logic [7:0] awlen,
  output logic [2:0] awsize, output logic [1:0] awburst,
  output logic [IW-1:0] awid, output logic awvalid,
  input logic awready,
  output logic [DW-1:0] wdata, output logic [DW/8-1:0] wstrb,
  output logic wlast, wvalid, input logic wready,
  input logic [1:0] bresp, input logic [IW-1:0] bid, input logic bvalid,
  output logic bready,
  output logic [UW-1:0] aruser, awuser, wuser
);
  localparam BYTES = DW / 8;
  logic ar_stalled, aw_stalled, w_stalled, r_stalled, b_stalled;
  logic [DW+IW+2:0] r_hold;
  logic [IW+1:0] b_hold;
  logic [AW+8+3+2+IW+UW-1:0] ar_hold, aw_hold;
  logic [DW+DW/8+UW:0] w_hold;

  // Simulation driver: asynchronous assertion cancels all active handshakes.
  // Payloads are don't-care during reset; keep the request and ready pins idle.
  always @(negedge rst_n) begin
    arvalid=0; awvalid=0; wvalid=0; rready=0; bready=0;
  end

  // AXI manager must keep each request payload stable until its handshake.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_stalled <= 0; aw_stalled <= 0; w_stalled <= 0;
      ar_hold <= '0; aw_hold <= '0; w_hold <= '0;
      r_stalled <= 0; b_stalled <= 0; r_hold <= '0; b_hold <= '0;
    end else begin
      if (ar_stalled && (!arvalid || {araddr,arlen,arsize,arburst,arid,aruser} !== ar_hold))
        $fatal(1, "AXI AR payload changed while stalled");
      if (aw_stalled && (!awvalid || {awaddr,awlen,awsize,awburst,awid,awuser} !== aw_hold))
        $fatal(1, "AXI AW payload changed while stalled");
      if (w_stalled && (!wvalid || {wdata,wstrb,wlast,wuser} !== w_hold))
        $fatal(1, "AXI W payload changed while stalled");
      if (r_stalled && (rvalid !== 1'b1 || {rdata,rresp,rid,rlast} !== r_hold))
        $fatal(1, "AXI R response changed while stalled");
      if (b_stalled && (bvalid !== 1'b1 || {bresp,bid} !== b_hold))
        $fatal(1, "AXI B response changed while stalled");
      r_stalled <= (rvalid === 1'b1 && rready === 1'b0);
      b_stalled <= (bvalid === 1'b1 && bready === 1'b0);
      r_hold <= {rdata,rresp,rid,rlast};
      b_hold <= {bresp,bid};
      ar_stalled <= arvalid && !arready;
      aw_stalled <= awvalid && !awready;
      w_stalled <= wvalid && !wready;
      ar_hold <= {araddr,arlen,arsize,arburst,arid,aruser};
      aw_hold <= {awaddr,awlen,awsize,awburst,awid,awuser};
      w_hold <= {wdata,wstrb,wlast,wuser};
    end
  end

  initial begin
    if (RESPONSE_DELAY < 0 || (^RESPONSE_DELAY) === 1'bx)
      $fatal(1, "RESPONSE_DELAY must be a known nonnegative integer");
    if (DW < 8 || DW > 1024 || DW % 8 != 0 || (BYTES & (BYTES - 1)) != 0)
      $fatal(1, "DW must be 8..1024 bits in power-of-two bytes");
  end

  task automatic write_one_user(input logic [AW-1:0] addr,
                         input logic [DW-1:0] data,
                         input logic [BYTES-1:0] strb,
                         input logic [IW-1:0] id,
                         input logic [UW-1:0] addr_user, data_user,
                         output logic ok,
                         output logic [1:0] resp);
    integer n;
    logic accepted;
    begin : write_body
      ok = 0; resp = 0;
      if ((^addr) === 1'bx) $fatal(1, "AXI write address argument is unknown");
      if ((^id) === 1'bx) $fatal(1, "AXI write ID argument is unknown");
      if ((^addr_user) === 1'bx) $fatal(1, "AXI AWUSER argument is unknown");
      if ((^data_user) === 1'bx) $fatal(1, "AXI WUSER argument is unknown");
      if ((^strb) === 1'bx) $fatal(1, "AXI write strobe argument is unknown");
      for (n=0; n<BYTES; n=n+1)
        if (strb[n] && (^data[n*8 +: 8]) === 1'bx)
          $fatal(1, "AXI write enabled data byte is unknown");
      if (rst_n !== 1'b1 || addr % BYTES != 0) begin
        $error("AXI single-beat write requires reset released and aligned address");
        disable write_body;
      end
      // Observe a released-reset rising edge, then drive away from sampling.
      @(posedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable write_body;
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable write_body;
      awaddr=addr; awlen=0; awsize=3'($clog2(BYTES)); awburst=2'b00; awid=id; awuser=addr_user; awvalid=1;
      accepted=0;
      for (n=0; n<TIMEOUT && !accepted; n=n+1) begin
        @(posedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable write_body;
        if (awready !== 1'b0 && awready !== 1'b1)
          $fatal(1, "AXI AWREADY is unknown while waiting");
        if (awready) accepted=1;
      end
      if (!accepted) disable write_body; // Hold VALID until handshake or external reset.
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable write_body;
      awvalid=0;

      wdata=data; wstrb=strb; wlast=1; wuser=data_user; wvalid=1;
      accepted=0;
      for (n=0; n<TIMEOUT && !accepted; n=n+1) begin
        @(posedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable write_body;
        if (wready !== 1'b0 && wready !== 1'b1)
          $fatal(1, "AXI WREADY is unknown while waiting");
        if (wready) accepted=1;
      end
      if (!accepted) disable write_body; // Hold VALID until handshake or external reset.
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable write_body;
      wvalid=0;

      for (n=0; n<RESPONSE_DELAY; n=n+1) begin
        @(posedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable write_body;
        // An already-stalled response is checked by the stability monitor.
        if (!b_stalled && bvalid !== 1'b0 && bvalid !== 1'b1)
          $fatal(1, "AXI BVALID is unknown while delaying READY");
        @(negedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable write_body;
      end
      bready=1;
      accepted=0;
      for (n=0; n<TIMEOUT && !accepted; n=n+1) begin
        @(posedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable write_body;
        if (bvalid !== 1'b0 && bvalid !== 1'b1)
          $fatal(1, "AXI BVALID is unknown while waiting");
        if (bvalid) accepted=1;
      end
      if (!accepted) begin
        @(negedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable write_body;
        bready=0;
        disable write_body;
      end
      if (bid !== id) $fatal(1, "AXI B ID mismatch: got %0h expected %0h", bid, id);
      if ((^bresp) === 1'bx) $fatal(1, "AXI BRESP is unknown on response");
      resp=bresp;
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable write_body;
      bready=0;
      ok=(bid === id) && (resp == 2'b00);
    end
  endtask

  task automatic read_one_user(input logic [AW-1:0] addr,
                        input logic [IW-1:0] id,
                        input logic [UW-1:0] addr_user,
                        output logic ok,
                        output logic [DW-1:0] data,
                        output logic [1:0] resp);
    integer n;
    logic accepted;
    begin : read_body
      ok=0; data='0; resp=0;
      if ((^addr) === 1'bx) $fatal(1, "AXI read address argument is unknown");
      if ((^id) === 1'bx) $fatal(1, "AXI read ID argument is unknown");
      if ((^addr_user) === 1'bx) $fatal(1, "AXI ARUSER argument is unknown");
      if (rst_n !== 1'b1 || addr % BYTES != 0) begin
        $error("AXI single-beat read requires reset released and aligned address");
        disable read_body;
      end
      // Observe a released-reset rising edge, then drive away from sampling.
      @(posedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable read_body;
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable read_body;
      araddr=addr; arlen=0; arsize=3'($clog2(BYTES)); arburst=2'b00; arid=id; aruser=addr_user; arvalid=1;
      accepted=0;
      for (n=0; n<TIMEOUT && !accepted; n=n+1) begin
        @(posedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable read_body;
        if (arready !== 1'b0 && arready !== 1'b1)
          $fatal(1, "AXI ARREADY is unknown while waiting");
        if (arready) accepted=1;
      end
      if (!accepted) disable read_body; // Hold VALID until handshake or external reset.
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable read_body;
      arvalid=0;

      for (n=0; n<RESPONSE_DELAY; n=n+1) begin
        @(posedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable read_body;
        // An already-stalled response is checked by the stability monitor.
        if (!r_stalled && rvalid !== 1'b0 && rvalid !== 1'b1)
          $fatal(1, "AXI RVALID is unknown while delaying READY");
        @(negedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable read_body;
      end
      rready=1;
      accepted=0;
      for (n=0; n<TIMEOUT && !accepted; n=n+1) begin
        @(posedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable read_body;
        if (rvalid !== 1'b0 && rvalid !== 1'b1)
          $fatal(1, "AXI RVALID is unknown while waiting");
        if (rvalid) accepted=1;
      end
      if (!accepted) begin
        @(negedge clk or negedge rst_n);
        if (rst_n !== 1'b1) disable read_body;
        rready=0;
        disable read_body;
      end
      if (rid !== id) $fatal(1, "AXI R ID mismatch: got %0h expected %0h", rid, id);
      if (rlast !== 1'b1) $fatal(1, "AXI single-beat read missing RLAST");
      if ((^rresp) === 1'bx) $fatal(1, "AXI RRESP is unknown on response");
      if (rresp == 2'b00 && (^rdata) === 1'bx)
        $fatal(1, "AXI RDATA is unknown on successful response");
      data=rdata; resp=rresp;
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) disable read_body;
      rready=0;
      ok=(rid === id) && (rlast === 1'b1) && (resp == 2'b00);
    end
  endtask

  task automatic write_one(input logic [AW-1:0] addr,
                           input logic [DW-1:0] data,
                           input logic [BYTES-1:0] strb,
                           input logic [IW-1:0] id,
                           output logic ok, output logic [1:0] resp);
    write_one_user(addr, data, strb, id, UW'(0), UW'(0), ok, resp);
  endtask

  task automatic read_one(input logic [AW-1:0] addr,
                          input logic [IW-1:0] id,
                          output logic ok, output logic [DW-1:0] data,
                          output logic [1:0] resp);
    read_one_user(addr, id, UW'(0), ok, data, resp);
  endtask

  initial begin
    araddr='0; arlen=0; arsize=0; arburst=0; arid=0; aruser=0; arvalid=0; rready=0;
    awaddr='0; awlen=0; awsize=0; awburst=0; awid=0; awuser=0; awvalid=0;
    wdata='0; wstrb='0; wuser=0; wlast=0; wvalid=0; bready=0;
  end
endmodule
