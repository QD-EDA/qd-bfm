interface axi_if_min(input logic clk, input logic rst_n);
  logic [31:0] araddr;
  logic arvalid;
  logic arready;
  logic rvalid;
  logic rready;
  logic [31:0] awaddr;
  logic awvalid;
  logic awready;
  logic [31:0] wdata;
  logic wvalid;
  logic wready;
  logic bvalid;
  logic bready;
  modport r_sub(input araddr, arvalid, rready, output arready, rvalid);
  modport w_sub(input awaddr, awvalid, wdata, wvalid, bready, output awready, wready, bvalid);
endinterface

module axi_sub_wr(axi_if_min.w_sub axi_if);
  logic axi_out_of_rst = 1'b1;
  logic axi_awready_q = 1'b1;
  logic axi_awvalid_q;
  logic txn_wvalid;
  logic txn_wready = 1'b1;

  assign axi_awvalid_q = axi_if.awvalid & axi_out_of_rst;
  assign axi_if.awready = axi_awready_q & axi_out_of_rst;
  assign txn_wvalid = axi_if.wvalid;
  assign axi_if.wready = txn_wready;
  assign axi_if.bvalid = axi_if.bready;
endmodule

module axi_sub_rd(axi_if_min.r_sub axi_if);
  assign axi_if.arready = 1'b1;
  assign axi_if.rvalid = 1'b1;
endmodule

module axi_sub(axi_if_min.r_sub r_if, axi_if_min.w_sub w_if);
  axi_sub_rd rd(.axi_if(r_if));
  axi_sub_wr wr(.axi_if(w_if));
endmodule

module caliptra_axi_sram(axi_if_min.r_sub r_if, axi_if_min.w_sub w_if);
  axi_sub sub(.r_if(r_if), .w_if(w_if));
endmodule

module force_release_two_axi_interfaces;
  timeunit 1ns;
  timeprecision 1ps;

  logic core_clk = 1'b0;
  logic rand_delays = 1'b1;
  axi_if_min axi_sram_if(core_clk, 1'b1);
  axi_if_min axi_fifo_if(core_clk, 1'b1);
  caliptra_axi_sram dut(.r_if(axi_sram_if.r_sub), .w_if(axi_sram_if.w_sub));
  caliptra_axi_sram i_axi_fifo(.r_if(axi_fifo_if.r_sub), .w_if(axi_fifo_if.w_sub));

  assign axi_sram_if.araddr = 32'h1000;
  assign axi_sram_if.arvalid = 1'b1;
  assign axi_sram_if.rready = 1'b1;
  assign axi_sram_if.awaddr = 32'h2000;
  assign axi_sram_if.awvalid = 1'b1;
  assign axi_sram_if.wdata = 32'h12345678;
  assign axi_sram_if.wvalid = 1'b1;
  assign axi_sram_if.bready = 1'b1;
  assign axi_fifo_if.araddr = 32'h1000;
  assign axi_fifo_if.arvalid = 1'b1;
  assign axi_fifo_if.rready = 1'b1;
  assign axi_fifo_if.awaddr = 32'h2000;
  assign axi_fifo_if.awvalid = 1'b1;
  assign axi_fifo_if.wdata = 32'h12345678;
  assign axi_fifo_if.wvalid = 1'b1;
  assign axi_fifo_if.bready = 1'b1;

  always #5ns core_clk = ~core_clk;

  `define GENERIC_2SIG_DLY_TEMPLATE(GEN_NAME, cnt_var, rdy_sig_path, vld_sig_path) \
    logic [11:0] cnt_var; \
    bit GEN_NAME``_past_shake_stall; \
    always @(posedge core_clk) \
      GEN_NAME``_past_shake_stall <= vld_sig_path && !rdy_sig_path; \
    initial begin: GEN_NAME \
      cnt_var = 1; \
      forever begin \
        @(negedge core_clk); \
        if (rand_delays) begin \
          if (|cnt_var && !GEN_NAME``_past_shake_stall) begin \
            cnt_var = cnt_var - 1; \
            force rdy_sig_path = 1'b0; \
            force vld_sig_path = 1'b0; \
          end else begin \
            release rdy_sig_path; \
            release vld_sig_path; \
          end \
        end else begin \
          release rdy_sig_path; \
          release vld_sig_path; \
        end \
      end \
    end: GEN_NAME

  `GENERIC_2SIG_DLY_TEMPLATE(AR_DLY, ar_count, axi_sram_if.arready, axi_sram_if.arvalid)
  `GENERIC_2SIG_DLY_TEMPLATE(R_DLY, r_count, axi_sram_if.rready, axi_sram_if.rvalid)
  `GENERIC_2SIG_DLY_TEMPLATE(AW_DLY, aw_count, dut.sub.wr.axi_awready_q, dut.sub.wr.axi_awvalid_q)
  `GENERIC_2SIG_DLY_TEMPLATE(W_DLY, w_count, dut.sub.wr.txn_wready, dut.sub.wr.txn_wvalid)
  `GENERIC_2SIG_DLY_TEMPLATE(FIFO_AR_DLY, fifo_ar_count, axi_fifo_if.arready, axi_fifo_if.arvalid)
  `GENERIC_2SIG_DLY_TEMPLATE(FIFO_R_DLY, fifo_r_count, axi_fifo_if.rready, axi_fifo_if.rvalid)
  `GENERIC_2SIG_DLY_TEMPLATE(FIFO_AW_DLY, fifo_aw_count, i_axi_fifo.sub.wr.axi_awready_q, i_axi_fifo.sub.wr.axi_awvalid_q)
  `GENERIC_2SIG_DLY_TEMPLATE(FIFO_W_DLY, fifo_w_count, i_axi_fifo.sub.wr.txn_wready, i_axi_fifo.sub.wr.txn_wvalid)

  initial begin
    #12ns;
    rand_delays = 1'b0;
    #10ns;
    if (axi_sram_if.awvalid !== 1'b1 || axi_sram_if.wvalid !== 1'b1 || axi_fifo_if.awvalid !== 1'b1 || axi_fifo_if.wvalid !== 1'b1)
      $fatal(1, "release did not restore continuous interface assignments");
    $display("PASS: macro force/release across two nested AXI interfaces");
    $finish;
  end
endmodule
