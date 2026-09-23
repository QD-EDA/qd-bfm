// SPDX-License-Identifier: Apache-2.0
module tb_axi4;
  logic clk=0, rst_n=0;
  always #5 clk=~clk;
  logic [31:0] araddr, awaddr, wdata, rdata;
  logic [7:0] arlen, awlen;
  logic [2:0] arsize, awsize;
  logic [1:0] arburst, awburst, rresp, bresp;
  logic [7:0] arid, awid, rid, bid;
  logic arvalid, arready, rvalid, rready, rlast;
  logic awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic [3:0] wstrb;
  logic [31:0] mem [0:15];
  integer wait_cycles=0;
  integer aw_stalls=0, w_stalls=0, ar_stalls=0;
  logic timeout_read=0, inject_error=0;
  logic inject_bad_rid=0, inject_bad_rlast=0;
  logic [31:0] held_write_addr;

  qd_axi4_single_master #(.AW(32), .DW(32), .IW(8), .TIMEOUT(5)) bfm (.*);

  // One outstanding single-beat target with programmable request latency.
  assign awready = rst_n && wait_cycles == 0;
  assign wready  = rst_n && wait_cycles == 0;
  assign arready = rst_n && !timeout_read && wait_cycles == 0;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wait_cycles <= 0; rvalid <= 0; bvalid <= 0;
      rdata <= 0; rresp <= 0; bresp <= 0; rid <= 0; bid <= 0; rlast <= 1;
    end else begin
      if (wait_cycles != 0) wait_cycles <= wait_cycles - 1;
      if (arvalid && arready) begin
        wait_cycles <= 2;
        rid <= inject_bad_rid ? arid + 8'd1 : arid;
        rlast <= !inject_bad_rlast;
        rdata <= mem[araddr[5:2]];
        rresp <= inject_error ? 2'b10 : 2'b00;
        rvalid <= 1;
      end
      if (rvalid && rready) rvalid <= 0;
      if (awvalid && awready) begin
        held_write_addr <= awaddr;
        bid <= awid;
        wait_cycles <= 2;
      end
      if (wvalid && wready) begin
        if (wlast !== 1'b1) $fatal(1, "target saw missing WLAST");
        mem[held_write_addr[5:2]] <= wdata;
        bresp <= inject_error ? 2'b10 : 2'b00;
        bvalid <= 1;
      end
      if (bvalid && bready) bvalid <= 0;
    end
  end

  always @(posedge clk) if (rst_n) begin
    if (awvalid && !awready) aw_stalls <= aw_stalls + 1;
    if (wvalid && !wready) w_stalls <= w_stalls + 1;
    if (arvalid && !arready) ar_stalls <= ar_stalls + 1;
  end

  task automatic check(input logic condition, input string message);
    if (!condition) $fatal(1, "%s", message);
  endtask

  logic ok;
  logic [1:0] resp;
  logic [31:0] data;
  initial begin
    inject_bad_rid=$test$plusargs("BAD_RID");
    inject_bad_rlast=$test$plusargs("BAD_RLAST");
    foreach (mem[i]) mem[i]=0;
    repeat (2) @(posedge clk);
    rst_n=1;
    @(negedge clk);
    wait_cycles=2;
    bfm.write_one(32'h10, 32'hcafe1234, 4'hf, 8'h21, ok, resp);
    check(ok && resp==0, "write failed");
    check(mem[4]===32'hcafe1234, "write data was not stored");
    inject_error=1;
    bfm.write_one(32'h14, 32'h01234567, 4'hf, 8'h22, ok, resp);
    check(!ok && resp==2'b10, "write error response not reported");
    inject_error=0;
    wait_cycles=2;
    bfm.read_one(32'h10, 8'h32, ok, data, resp);
    check(ok && resp==0 && data===32'hcafe1234, "read failed");
    check(aw_stalls>0 && w_stalls>0 && ar_stalls>0, "ready stalls were not exercised");

    inject_error=1;
    bfm.read_one(32'h10, 8'h33, ok, data, resp);
    check(!ok && resp==2'b10, "error response not reported");
    inject_error=0;

    timeout_read=1;
    bfm.read_one(32'h10, 8'h34, ok, data, resp);
    check(!ok, "read timeout not reported");
    $display("PASS: write/read, request stalls, error response, timeout");
    $finish;
  end
endmodule
