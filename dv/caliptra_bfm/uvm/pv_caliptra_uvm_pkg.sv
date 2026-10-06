// SPDX-License-Identifier: Apache-2.0
`include "uvm_macros.svh"

package pv_caliptra_uvm_pkg;
  import uvm_pkg::*;

  class pv_caliptra_transfer extends uvm_sequence_item;
    bit write;
    bit [4:0] entry;
    bit [3:0] offset;
    bit [31:0] data;
    bit request_ok;
    bit success;
    bit response_error;
    bit last;

    `uvm_object_utils(pv_caliptra_transfer)

    function new(string name = "pv_caliptra_transfer");
      super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
      pv_caliptra_transfer source;
      if (!$cast(source, rhs)) begin
        `uvm_error("PV_COPY", "Cannot copy a non-Caliptra PV transfer")
        return;
      end
      super.do_copy(rhs);
      write = source.write;
      entry = source.entry;
      offset = source.offset;
      data = source.data;
      request_ok = source.request_ok;
      success = source.success;
      response_error = source.response_error;
      last = source.last;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      pv_caliptra_transfer other;
      if (!$cast(other, rhs)) return 0;
      return super.do_compare(rhs, comparer) && write == other.write &&
             entry == other.entry && offset == other.offset && data == other.data &&
             request_ok == other.request_ok && success == other.success &&
             response_error == other.response_error && last == other.last;
    endfunction

    function string convert2string();
      return $sformatf("%s entry=%0d offset=%0d data=%08h ok=%0b success=%0b error=%0b last=%0b",
                       write ? "WRITE" : "READ", entry, offset, data,
                       request_ok, success, response_error, last);
    endfunction
  endclass

  class pv_caliptra_sequencer extends uvm_sequencer #(pv_caliptra_transfer);
    `uvm_component_utils(pv_caliptra_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class pv_caliptra_driver extends uvm_driver #(pv_caliptra_transfer);
    virtual pv_caliptra_master_cmd_if cmd_vif;
    `uvm_component_utils(pv_caliptra_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual pv_caliptra_master_cmd_if)::get(
            this, "", "cmd_vif", cmd_vif))
        `uvm_fatal("PV_CMD_VIF", "Missing Caliptra PCRVault command interface")
    endfunction

    task run_phase(uvm_phase phase);
      pv_caliptra_transfer req;
      forever begin
        seq_item_port.get_next_item(req);
        wait (cmd_vif.rst_n === 1'b1);
        cmd_vif.request_write = req.write;
        cmd_vif.request_entry = req.entry;
        cmd_vif.request_offset = req.offset;
        cmd_vif.request_data = req.data;
        cmd_vif.request_valid = 1;
        wait (cmd_vif.response_valid === 1'b1);
        req.request_ok = cmd_vif.response_request_ok;
        req.success = cmd_vif.response_success;
        req.response_error = cmd_vif.response_error;
        req.last = cmd_vif.response_last;
        if (!req.write) req.data = cmd_vif.response_data;
        cmd_vif.request_valid = 0;
        wait (cmd_vif.response_valid === 1'b0);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class pv_caliptra_monitor extends uvm_monitor;
    virtual pv_caliptra_master_cmd_if cmd_vif;
    uvm_analysis_port #(pv_caliptra_transfer) ap;
    `uvm_component_utils(pv_caliptra_monitor)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual pv_caliptra_master_cmd_if)::get(
            this, "", "cmd_vif", cmd_vif))
        `uvm_fatal("PV_MON_VIF", "Missing Caliptra PCRVault command interface")
    endfunction

    task run_phase(uvm_phase phase);
      pv_caliptra_transfer item;
      forever begin
        wait (cmd_vif.response_valid === 1'b1);
        if (cmd_vif.rst_n === 1'b1) begin
          item = pv_caliptra_transfer::type_id::create("observed_transfer");
          item.write = cmd_vif.request_write;
          item.entry = cmd_vif.request_entry;
          item.offset = cmd_vif.request_offset;
          item.data = cmd_vif.request_write ? cmd_vif.request_data :
                                                cmd_vif.response_data;
          item.request_ok = cmd_vif.response_request_ok;
          item.success = cmd_vif.response_success;
          item.response_error = cmd_vif.response_error;
          item.last = cmd_vif.response_last;
          ap.write(item);
        end
        wait (cmd_vif.response_valid === 1'b0);
      end
    endtask
  endclass

  class pv_caliptra_uvm_agent extends uvm_agent;
    pv_caliptra_sequencer sequencer;
    pv_caliptra_driver driver;
    pv_caliptra_monitor monitor;
    uvm_analysis_port #(pv_caliptra_transfer) ap;
    `uvm_component_utils(pv_caliptra_uvm_agent)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = pv_caliptra_monitor::type_id::create("monitor", this);
      if (is_active == UVM_ACTIVE) begin
        sequencer = pv_caliptra_sequencer::type_id::create("sequencer", this);
        driver = pv_caliptra_driver::type_id::create("driver", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      monitor.ap.connect(ap);
      if (is_active == UVM_ACTIVE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass
endpackage
