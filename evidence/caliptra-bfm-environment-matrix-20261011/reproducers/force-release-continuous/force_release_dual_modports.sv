interface axi_if_min;
  logic arvalid;
  logic arready;
  logic [31:0] araddr;
  logic rvalid;
  logic rready;
  logic bvalid;
  logic bready;
  modport r_sub(input arvalid, araddr, rready, output arready, rvalid);
  modport w_sub(input bready, output bvalid);
endinterface

module axi_sub_rd(axi_if_min.r_sub axi_if);
  logic sampled;
  assign sampled = axi_if.arvalid ^ axi_if.araddr[0] ^ axi_if.rready;
  assign axi_if.arready = 1'b1;
  assign axi_if.rvalid = 1'b1;
endmodule

module axi_sub_wr(axi_if_min.w_sub axi_if);
  assign axi_if.bvalid = axi_if.bready;
endmodule

module axi_sub(axi_if_min.r_sub r_if, axi_if_min.w_sub w_if);
  axi_sub_rd rd(.axi_if(r_if));
  axi_sub_wr wr(.axi_if(w_if));
endmodule

module caliptra_axi_sram(axi_if_min.r_sub r_if, axi_if_min.w_sub w_if);
  axi_sub sub(.r_if(r_if), .w_if(w_if));
endmodule

module force_release_dual_modports;
  timeunit 1ns;
  timeprecision 1ps;

  logic core_clk = 1'b0;
  logic source_valid = 1'b1;
  logic source_ready = 1'b1;
  logic rand_delays = 1'b1;
  logic bvalid_force;
  axi_if_min axi_sram_if();

  assign axi_sram_if.arvalid = source_valid;
  assign axi_sram_if.araddr = 32'h1234;
  assign axi_sram_if.rready = source_ready;
  assign axi_sram_if.bready = 1'b1;
  assign bvalid_force = axi_sram_if.bvalid;

  caliptra_axi_sram dut(.r_if(axi_sram_if.r_sub), .w_if(axi_sram_if.w_sub));
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
  `GENERIC_2SIG_DLY_TEMPLATE(B_DLY, b_count, axi_sram_if.bready, bvalid_force)

  initial begin
    #12ns;
    rand_delays = 1'b0;
    #10ns;
    if (axi_sram_if.arvalid !== 1'b1 || axi_sram_if.rready !== 1'b1)
      $fatal(1, "release did not restore continuous interface assignments");
    $display("PASS: macro force/release works through separate nested R/W modports");
    $finish;
  end
endmodule
