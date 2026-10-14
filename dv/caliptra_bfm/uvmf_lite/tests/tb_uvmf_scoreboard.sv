// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

package uvmf_scoreboard_test_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;

  class scoreboard_item extends uvmf_transaction_base;
    int value;
    `uvm_object_utils(scoreboard_item)

    function new(string name = "scoreboard_item");
      super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
      scoreboard_item source;
      if (!$cast(source, rhs)) return;
      super.do_copy(rhs);
      value = source.value;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      scoreboard_item other;
      if (!$cast(other, rhs)) return 0;
      return super.do_compare(rhs, comparer) && value == other.value;
    endfunction
  endclass

  class scoreboard_test extends uvm_test;
    typedef uvmf_in_order_scoreboard #(scoreboard_item) scoreboard_t;
    typedef uvmf_out_of_order_scoreboard #(scoreboard_item) out_of_order_scoreboard_t;
    scoreboard_t scoreboard;
    scoreboard_t actual_only_scoreboard;
    out_of_order_scoreboard_t out_of_order_scoreboard;
    uvm_analysis_port #(scoreboard_item) expected_source;
    uvm_analysis_port #(scoreboard_item) actual_source;
    uvm_analysis_port #(scoreboard_item) actual_only_source;
    uvm_analysis_port #(scoreboard_item) out_of_order_expected_source;
    uvm_analysis_port #(scoreboard_item) out_of_order_actual_source;

    `uvm_component_utils(scoreboard_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      expected_source = new("expected_source", this);
      actual_source = new("actual_source", this);
      actual_only_source = new("actual_only_source", this);
      out_of_order_expected_source = new("out_of_order_expected_source", this);
      out_of_order_actual_source = new("out_of_order_actual_source", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      scoreboard = scoreboard_t::type_id::create("scoreboard", this);
      actual_only_scoreboard = scoreboard_t::type_id::create(
        "actual_only_scoreboard", this);
      out_of_order_scoreboard = out_of_order_scoreboard_t::type_id::create(
        "out_of_order_scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      expected_source.connect(scoreboard.expected_analysis_export);
      actual_source.connect(scoreboard.actual_analysis_export);
      actual_only_source.connect(actual_only_scoreboard.actual_analysis_export);
      out_of_order_expected_source.connect(
        out_of_order_scoreboard.expected_analysis_export);
      out_of_order_actual_source.connect(
        out_of_order_scoreboard.actual_analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
      scoreboard_item expected_item;
      scoreboard_item actual_item;

      phase.raise_objection(this);
      expected_item = scoreboard_item::type_id::create("matched_expected");
      expected_item.value = 32'h1234;
      expected_item.start_time = 64'd100;
      expected_item.end_time = 64'd200;
      expected_source.write(expected_item);
      expected_item.value = 32'hffff;
      expected_item.start_time = 64'd999;
      expected_item.end_time = 64'd999;
      actual_item = scoreboard_item::type_id::create("matched_actual");
      actual_item.value = 32'h1234;
      actual_item.start_time = 64'd100;
      actual_item.end_time = 64'd200;
      actual_source.write(actual_item);

      expected_item = scoreboard_item::type_id::create("mismatch_expected");
      expected_item.value = 32'h10;
      expected_source.write(expected_item);
      actual_item = scoreboard_item::type_id::create("mismatch_actual");
      actual_item.value = 32'h11;
      actual_source.write(actual_item);

      expected_item = scoreboard_item::type_id::create("leftover_expected");
      expected_item.value = 32'h20;
      expected_source.write(expected_item);
      actual_item = scoreboard_item::type_id::create("leftover_actual");
      actual_item.value = 32'h21;
      actual_only_source.write(actual_item);

      expected_item = scoreboard_item::type_id::create("ooo_expected_first");
      expected_item.value = 32'h31;
      out_of_order_expected_source.write(expected_item);
      expected_item = scoreboard_item::type_id::create("ooo_expected_second");
      expected_item.value = 32'h32;
      out_of_order_expected_source.write(expected_item);
      actual_item = scoreboard_item::type_id::create("ooo_actual_second");
      actual_item.value = 32'h32;
      out_of_order_actual_source.write(actual_item);
      actual_item = scoreboard_item::type_id::create("ooo_actual_first");
      actual_item.value = 32'h31;
      out_of_order_actual_source.write(actual_item);

      expected_item = scoreboard_item::type_id::create("ooo_mismatch_expected");
      expected_item.value = 32'h40;
      out_of_order_expected_source.write(expected_item);
      actual_item = scoreboard_item::type_id::create("ooo_mismatch_actual");
      actual_item.value = 32'h41;
      out_of_order_actual_source.write(actual_item);

      if (scoreboard.matched_count != 1 || scoreboard.mismatch_count != 1 ||
          scoreboard.pending_expected_count != 1 || scoreboard.pending_actual_count != 0 ||
          actual_only_scoreboard.pending_expected_count != 0 ||
          actual_only_scoreboard.pending_actual_count != 1 ||
          out_of_order_scoreboard.matched_count != 2 ||
          out_of_order_scoreboard.mismatch_count != 0 ||
          out_of_order_scoreboard.pending_expected_count != 1 ||
          out_of_order_scoreboard.pending_actual_count != 1)
        `uvm_fatal("UVMF_SB_TEST", "Scoreboard pairing or retained-item counts are wrong")

      `uvm_info("UVMF_SB_TEST",
        "PASS: UVMF in-order scoreboard matched, detected mismatch, and retained leftovers",
        UVM_LOW)
      `uvm_info("UVMF_OOO_SB_TEST",
        "PASS: out-of-order scoreboard matched reordered items and retained the mismatch",
        UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module tb_uvmf_scoreboard;
  import uvm_pkg::*;
  import uvmf_scoreboard_test_pkg::*;

  initial run_test("scoreboard_test");
endmodule
