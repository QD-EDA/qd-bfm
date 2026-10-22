`include "uvm_macros.svh"

package mvc_pkg;
  import uvm_pkg::*;

  class mvc_sequence_item_base extends uvm_pkg::uvm_sequence_item;
    `uvm_object_utils(mvc_sequence_item_base)

    function new(string name = "mvc_sequence_item_base");
      super.new(name);
    endfunction
  endclass
endpackage

package mgc_ahb_v2_0_pkg;
  import uvm_pkg::*;

  class ahb_master_burst_transfer #(
    parameter int NUM_MASTERS = 1,
    parameter int MASTER_BITS = 1,
    parameter int NUM_SLAVES = 1,
    parameter int ADDRESS_WIDTH = 32,
    parameter int WDATA_WIDTH = 32,
    parameter int RDATA_WIDTH = 32
  ) extends mvc_pkg::mvc_sequence_item_base;
    `uvm_object_param_utils(ahb_master_burst_transfer #(NUM_MASTERS, MASTER_BITS,
      NUM_SLAVES, ADDRESS_WIDTH, WDATA_WIDTH, RDATA_WIDTH))

    function new(string name = "ahb_master_burst_transfer");
      super.new(name);
    endfunction
  endclass
endpackage

package ahb_lite_caliptra_uvm_pkg;
  typedef mgc_ahb_v2_0_pkg::ahb_master_burst_transfer #(1, 1, 1, 32, 32, 32)
    ahb_lite_caliptra_mvc_transfer;
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

package mldsa_env_pkg;
  typedef mgc_ahb_v2_0_pkg::ahb_master_burst_transfer #(
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_NUM_MASTERS,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_NUM_SLAVES,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_WDATA_WIDTH,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_RDATA_WIDTH
  ) generated_transfer_t;
endpackage

module tb;
  mvc_pkg::mvc_sequence_item_base base_item;
  ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer alias_item;
  mldsa_env_pkg::generated_transfer_t generated_item;
  bit alias_cast;
  bit generated_cast;

  initial begin
    generated_item = mldsa_env_pkg::generated_transfer_t::type_id::create("item");
    base_item = generated_item;
    alias_cast = $cast(alias_item, base_item);
    generated_cast = $cast(generated_item, base_item);
    $display("RESULT type=%s alias_wrapper_match=%0d generated_wrapper_match=%0d alias_cast=%0d generated_cast=%0d",
      base_item.get_type_name(),
      base_item.get_object_type() == ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer::type_id::get(),
      base_item.get_object_type() == mldsa_env_pkg::generated_transfer_t::type_id::get(),
      alias_cast, generated_cast);
    $finish;
  end
endmodule
