package config_pkg;
  typedef struct packed {
    logic [3:0] ICCM_NUM_BANKS;
    logic [3:0] DCCM_NUM_BANKS;
  } el2_param_t;
  localparam el2_param_t DEFAULT_PT = '{ICCM_NUM_BANKS: 4'd2, DCCM_NUM_BANKS: 4'd3};
endpackage

interface el2_mem_if #(parameter config_pkg::el2_param_t pt = config_pkg::DEFAULT_PT) ();
  logic clk;
  logic [pt.ICCM_NUM_BANKS-1:0][31:0] iccm_bank_dout;
  logic [pt.DCCM_NUM_BANKS-1:0][31:0] dccm_bank_dout;
  logic [pt.ICCM_NUM_BANKS-1:0] iccm_clken;
  modport veer_sram_src(output clk, iccm_clken, input iccm_bank_dout, dccm_bank_dout);
endinterface

module relay(input logic clk, el2_mem_if.veer_sram_src mem_export);
  el2_mem_if mem_export_local();
  assign mem_export_local.clk = clk;
  assign mem_export.clk = clk;
  assign mem_export_local.iccm_bank_dout = mem_export.iccm_bank_dout;
  assign mem_export_local.dccm_bank_dout = mem_export.dccm_bank_dout;
  assign mem_export.iccm_clken = mem_export_local.iccm_clken;
  initial mem_export_local.iccm_clken = '1;
endmodule

module interface_variable_assign;
  logic clk = 1'b0;
  el2_mem_if mem_export();
  relay u_relay(.clk(clk), .mem_export(mem_export));
  assign mem_export.iccm_bank_dout = '1;
  assign mem_export.dccm_bank_dout = '0;
  initial begin
    #1;
    if (mem_export.iccm_clken !== '1) $fatal(1, "interface bridge mismatch");
    $display("INTERFACE_BRIDGE_PASS");
    $finish;
  end
endmodule
