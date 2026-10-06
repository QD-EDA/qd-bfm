`timescale 1ns/1ps
// SPDX-License-Identifier: Apache-2.0
// Clean-room replacement for Caliptra's generated QVIP HDL wrapper.
// It preserves the hierarchy/wires used by Caliptra hdl_top.sv, not QVIP internals.
module ahb_lite_caliptra_default_clk_gen(output reg CLK);
  initial begin
    CLK = 0;
    forever #5 CLK = ~CLK;
  end
endmodule

module ahb_lite_caliptra_default_reset_gen(
  input wire CLK_IN,
  output reg RESET
);
  initial begin
    RESET = 0;
    repeat (2) @(posedge CLK_IN);
    RESET = 1;
  end
endmodule

module hdl_qvip_ahb_lite_slave #(
  parameter string UNIQUE_ID = "",
  parameter bit AHB_LITE_SLAVE_0_ACTIVE = 1'b1,
  parameter bit EXT_CLK_RESET = 1'b0
);
  import uvm_pkg::*;
  import qvip_ahb_lite_slave_params_pkg::*;
  import uvmf_base_pkg::*;

  wire default_clk_gen_CLK;
  wire default_reset_gen_RESET;
  wire [ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH-1:0] ahb_lite_slave_0_HADDR;
  wire [1:0] ahb_lite_slave_0_HTRANS;
  wire ahb_lite_slave_0_HWRITE;
  wire [2:0] ahb_lite_slave_0_HSIZE;
  wire [ahb_lite_slave_0_params::AHB_WDATA_WIDTH-1:0] ahb_lite_slave_0_HWDATA;
  wire [2:0] ahb_lite_slave_0_HBURST;
  wire [6:0] ahb_lite_slave_0_HPROT;
  wire ahb_lite_slave_0_HMASTLOCK;
  wire ahb_lite_slave_0_HREADYOUT;
  wire [ahb_lite_slave_0_params::AHB_RDATA_WIDTH-1:0] ahb_lite_slave_0_HRDATA;
  wire ahb_lite_slave_0_HREADY;
  wire ahb_lite_slave_0_HRESP;
  wire ahb_lite_slave_0_HSEL;
  wire ahb_lite_slave_0_HNONSEC;
  wire [63:0] ahb_lite_slave_0_HAUSER;
  wire [63:0] ahb_lite_slave_0_HWUSER;
  wire [63:0] ahb_lite_slave_0_HRUSER;
  wire [15:0] ahb_lite_slave_0_mult_HSEL;
  wire ahb_lite_slave_0_HEXCL;
  wire [15:0] ahb_lite_slave_0_HMASTER;
  wire ahb_lite_slave_0_HEXOKAY;

  generate
    if (EXT_CLK_RESET == 0) begin : generate_internal_clk_rst
      ahb_lite_caliptra_default_clk_gen default_clk_gen (
        .CLK(default_clk_gen_CLK)
      );
      ahb_lite_caliptra_default_reset_gen default_reset_gen (
        .CLK_IN(default_clk_gen_CLK), .RESET(default_reset_gen_RESET)
      );
    end
  endgenerate

  ahb_lite_caliptra_record_if ahb_lite_slave_0_record_bfm(default_clk_gen_CLK);
  ahb_lite_caliptra_master_cmd_if ahb_lite_slave_0_command_bfm(default_clk_gen_CLK);
  assign ahb_lite_slave_0_command_bfm.HRESETn = default_reset_gen_RESET;

  initial begin
    uvm_config_db#(ahb_lite_slave_0_bfm_t)::set(
      null, UVMF_VIRTUAL_INTERFACES,
      {UNIQUE_ID, "ahb_lite_slave_0"}, ahb_lite_slave_0_record_bfm);
    uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::set(
      null, UVMF_VIRTUAL_INTERFACES,
      {UNIQUE_ID, "ahb_lite_slave_0.cmd"}, ahb_lite_slave_0_command_bfm);
  end

  ahb_lite_caliptra_pin_monitor_adapter #(
    .ADDR_WIDTH(ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH),
    .DATA_WIDTH(ahb_lite_slave_0_params::AHB_RDATA_WIDTH)
  ) ahb_lite_slave_0_monitor (
    .HCLK(default_clk_gen_CLK), .HRESETn(default_reset_gen_RESET),
    .HADDR(ahb_lite_slave_0_HADDR), .HWDATA(ahb_lite_slave_0_HWDATA),
    .HSEL(ahb_lite_slave_0_HSEL), .HWRITE(ahb_lite_slave_0_HWRITE),
    .HTRANS(ahb_lite_slave_0_HTRANS), .HSIZE(ahb_lite_slave_0_HSIZE),
    .HREADY(ahb_lite_slave_0_HREADY), .HRESP(ahb_lite_slave_0_HRESP),
    .HRDATA(ahb_lite_slave_0_HRDATA), .record_if(ahb_lite_slave_0_record_bfm)
  );

  generate
    if (AHB_LITE_SLAVE_0_ACTIVE != 0) begin : generate_active_manager
      ahb_lite_caliptra_uvm_master_proxy #(
        .ADDR_WIDTH(ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH),
        .DATA_WIDTH(ahb_lite_slave_0_params::AHB_WDATA_WIDTH)
      ) ahb_lite_slave_0_manager (
        .cmd_if(ahb_lite_slave_0_command_bfm),
        .HCLK(default_clk_gen_CLK), .HRESETn(default_reset_gen_RESET),
        .HREADY(ahb_lite_slave_0_HREADY), .HRESP(ahb_lite_slave_0_HRESP),
        .HRDATA(ahb_lite_slave_0_HRDATA),
        .HSEL(ahb_lite_slave_0_HSEL), .HADDR(ahb_lite_slave_0_HADDR),
        .HWDATA(ahb_lite_slave_0_HWDATA), .HWRITE(ahb_lite_slave_0_HWRITE),
        .HSIZE(ahb_lite_slave_0_HSIZE), .HTRANS(ahb_lite_slave_0_HTRANS)
      );

      // In the generated single-target SoC-IFC harness, the active manager
      // returns the target's completion-ready signal to the DUT's HREADY input.
      assign ahb_lite_slave_0_HREADYOUT = ahb_lite_slave_0_HREADY;
      assign ahb_lite_slave_0_HBURST = 3'b0;
      assign ahb_lite_slave_0_HPROT = 7'b0;
      assign ahb_lite_slave_0_HMASTLOCK = 1'b0;
      assign ahb_lite_slave_0_HNONSEC = 1'b0;
      assign ahb_lite_slave_0_HAUSER = '0;
      assign ahb_lite_slave_0_HWUSER = '0;
      assign ahb_lite_slave_0_HRUSER = '0;
      assign ahb_lite_slave_0_mult_HSEL = '0;
      assign ahb_lite_slave_0_HEXCL = 1'b0;
      assign ahb_lite_slave_0_HMASTER = '0;
      assign ahb_lite_slave_0_HEXOKAY = 1'b0;
    end
    else begin : generate_passive_monitor
      // Caliptra hdl_top supplies the raw pin nets through this hierarchy.
      // The passive replacement only samples them and does not drive the bus.
    end
  endgenerate
endmodule
