package mvc_pkg;
  virtual class mvc_sequence_item_base;
  endclass
endpackage

package mgc_ahb_v2_0_pkg;
  class ahb_master_burst_transfer #(
    parameter int NUM_MASTERS = 1,
    parameter int MASTER_BITS = 1,
    parameter int NUM_SLAVES = 1,
    parameter int ADDRESS_WIDTH = 32,
    parameter int WDATA_WIDTH = 32,
    parameter int RDATA_WIDTH = 32
  ) extends mvc_pkg::mvc_sequence_item_base;
  endclass
endpackage

package qvip_ahb_lite_slave_params_pkg;
  class ahb_lite_slave_0_params;
    localparam int AHB_NUM_MASTERS = 1;
    localparam int AHB_NUM_MASTER_BITS = 1;
    localparam int AHB_NUM_SLAVES = 1;
    localparam int AHB_ADDRESS_WIDTH = 32;
    localparam int AHB_WDATA_WIDTH = 32;
    localparam int AHB_RDATA_WIDTH = 32;
  endclass
endpackage

package ahb_lite_caliptra_uvm_pkg;
  import mgc_ahb_v2_0_pkg::*;
  localparam int AHB_MVC_DATA_WIDTH = 32;
  typedef ahb_master_burst_transfer #(1, 1, 1, 32,
                                      AHB_MVC_DATA_WIDTH,
                                      AHB_MVC_DATA_WIDTH)
    ahb_lite_caliptra_mvc_transfer;
endpackage

package mldsa_env_pkg;
  import mvc_pkg::*;
  import mgc_ahb_v2_0_pkg::*;
  import qvip_ahb_lite_slave_params_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;

  function automatic bit generated_cast(mvc_sequence_item_base base_item);
    ahb_master_burst_transfer #(
      ahb_lite_slave_0_params::AHB_NUM_MASTERS,
      ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,
      ahb_lite_slave_0_params::AHB_NUM_SLAVES,
      ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,
      ahb_lite_slave_0_params::AHB_WDATA_WIDTH,
      ahb_lite_slave_0_params::AHB_RDATA_WIDTH
    ) target;
    return $cast(target, base_item);
  endfunction
endpackage

module tb;
  mvc_pkg::mvc_sequence_item_base base_item;
  ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer alias_item;
  bit alias_cast;
  bit generated_style_cast;

  initial begin
    alias_item = new;
    base_item = alias_item;
    alias_cast = $cast(alias_item, base_item);
    generated_style_cast = mldsa_env_pkg::generated_cast(base_item);
    $display("RESULT alias_cast=%0d generated_cast=%0d", alias_cast, generated_style_cast);
    $finish;
  end
endmodule
