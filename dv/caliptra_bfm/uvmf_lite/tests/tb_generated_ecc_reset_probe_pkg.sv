// SPDX-License-Identifier: Apache-2.0
package ecc_reset_probe_pkg;
  import uvm_pkg::*;
  import ECC_in_pkg::*;
  import ECC_sequences_pkg::*;
  import ECC_tests_pkg::*;
  `include "uvm_macros.svh"

  class ecc_reset_only_input_sequence extends ECC_in_sequence_base #(32, 32);
    `uvm_object_utils(ecc_reset_only_input_sequence)
    function new(string name = "ecc_reset_only_input_sequence");
      super.new(name);
    endfunction
    virtual task body();
      req.test = ecc_reset_test;
      req.op = key_gen;
      start_item(req);
      finish_item(req);
    endtask
  endclass

  class ecc_reset_only_bench_sequence extends ECC_bench_sequence_base;
    `uvm_object_utils(ecc_reset_only_bench_sequence)
    function new(string name = "ecc_reset_only_bench_sequence");
      super.new(name);
    endfunction
    virtual task body();
      ecc_reset_only_input_sequence input_sequence;
      input_sequence = ecc_reset_only_input_sequence::type_id::create("input_sequence");
      fork
        ECC_in_agent_config.wait_for_reset();
        ECC_out_agent_config.wait_for_reset();
      join
      input_sequence.start(ECC_in_agent_sequencer);
      fork
        ECC_in_agent_config.wait_for_num_clocks(250);
        ECC_out_agent_config.wait_for_num_clocks(250);
      join
    endtask
  endclass

  class ecc_reset_only_test extends test_top;
    `uvm_component_utils(ecc_reset_only_test)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    virtual task run_phase(uvm_phase phase);
      ecc_reset_only_bench_sequence reset_seq;
      phase.raise_objection(this);
      reset_seq = ecc_reset_only_bench_sequence::type_id::create("reset_seq");
      reset_seq.start(null);
      if (environment.ECC_sb.expected_received_count != 1 ||
          environment.ECC_sb.actual_received_count != 1 ||
          environment.ECC_sb.mismatch_count != 0 ||
          environment.ECC_sb.pending_expected_count != 0 ||
          environment.ECC_sb.pending_actual_count != 0 ||
          environment.ECC_sb.matched_count != 1)
        `uvm_fatal("ECC_PROBE", $sformatf(
          "scoreboard counts expected=%0d actual=%0d matched=%0d mismatched=%0d pending_expected=%0d pending_actual=%0d",
          environment.ECC_sb.expected_received_count,
          environment.ECC_sb.actual_received_count,
          environment.ECC_sb.matched_count,
          environment.ECC_sb.mismatch_count,
          environment.ECC_sb.pending_expected_count,
          environment.ECC_sb.pending_actual_count))
      reset_seq.ECC_in_agent_config.driver_bfm.write_single_word(32'h0000_0804, 32'h0000_0001);
      reset_seq.ECC_in_agent_config.driver_bfm.read_single_word(32'h0000_0804);
      if (reset_seq.ECC_in_agent_config.driver_bfm.hrdata_i !== 32'h0000_0001)
        `uvm_fatal("ECC_PROBE", $sformatf("IRQ_EN readback mismatch: %h",
          reset_seq.ECC_in_agent_config.driver_bfm.hrdata_i))
      `uvm_info("ECC_PROBE", "PASS: generated reset scoreboard and ECC IRQ_EN AHB readback matched", UVM_NONE)
      phase.drop_objection(this);
    endtask
  endclass
endpackage
