// SPDX-License-Identifier: Apache-2.0
// Clean-room lower-bound component hierarchy used by Caliptra SoC-IFC.
`include "uvm_macros.svh"

`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
package caliptra_aaxi_uvmf_compat_pkg;
  import uvm_pkg::*;
  import aaxi_uvm_pkg::*;
  import axi4_caliptra_uvm_pkg::*;

  class caliptra_aaxi_compat_driver extends uvm_component;
    aaxi_cfg_info cfg_info;
    bit enable_bfm = 1;
    virtual aaxi_intf ports;
    axi4_caliptra_aaxi_driver bfm_driver;

    `uvm_component_utils(caliptra_aaxi_compat_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      cfg_info = aaxi_cfg_info::type_id::create("cfg_info");
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg_info.passive_mode = !enable_bfm;
      if (enable_bfm) begin
        if (!uvm_config_db#(virtual aaxi_intf)::get(this, "", "ports", ports))
          `uvm_fatal("AAXI_PORTS", "Missing generated AAXI ports interface config")
        bfm_driver = axi4_caliptra_aaxi_driver::type_id::create("bfm_driver", this);
        bfm_driver.cfg_info = cfg_info;
        bfm_driver.ports = ports;
      end
    endfunction
  endclass

  class caliptra_aaxi_compat_agent extends uvm_agent;
    caliptra_aaxi_compat_driver driver;
    axi4_caliptra_uvm_monitor monitor;
    aaxi_uvm_sequencer sequencer;
    uvm_analysis_port #(axi4_caliptra_transaction) ap;
    uvm_analysis_port #(aaxi_master_tr) aaxi_ap;
    uvm_analysis_port #(aaxi_master_tr) ms_tx_AW_W_export;
    uvm_analysis_port #(aaxi_master_tr) ms_rx_rvalid_export;
    uvm_analysis_port #(aaxi_master_tr) write_done_export;
    uvm_analysis_port #(aaxi_master_tr) read_done_export;

    `uvm_component_utils(caliptra_aaxi_compat_agent)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
      aaxi_ap = new("aaxi_ap", this);
      ms_tx_AW_W_export = new("ms_tx_AW_W_export", this);
      ms_rx_rvalid_export = new("ms_rx_rvalid_export", this);
      write_done_export = new("write_done_export", this);
      read_done_export = new("read_done_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      driver = caliptra_aaxi_compat_driver::type_id::create("driver", this);
      driver.enable_bfm = (is_active == UVM_ACTIVE);
      monitor = axi4_caliptra_uvm_monitor::type_id::create("monitor", this);
      if (is_active == UVM_ACTIVE) begin
        sequencer = aaxi_uvm_sequencer::type_id::create("sequencer", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      monitor.ap.connect(ap);
      monitor.aaxi_ap.connect(aaxi_ap);
      monitor.ms_tx_AW_W_export.connect(ms_tx_AW_W_export);
      monitor.ms_rx_rvalid_export.connect(ms_rx_rvalid_export);
      monitor.write_done_export.connect(write_done_export);
      monitor.read_done_export.connect(read_done_export);
      if (is_active == UVM_ACTIVE) begin
        driver.bfm_driver.seq_item_port.connect(sequencer.seq_item_export);
        uvm_config_db #(aaxi_uvm_sequencer)::set(
          null, "UVMF_SEQUENCERS", get_full_name(), sequencer);
      end
    endfunction
  endclass

  class caliptra_aaxi_compat_env0 extends uvm_env;
    caliptra_aaxi_compat_agent master[1];
    caliptra_aaxi_compat_agent psv_master[1];
    caliptra_aaxi_compat_agent slave[1];

    `uvm_component_utils(caliptra_aaxi_compat_env0)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      master[0] = caliptra_aaxi_compat_agent::type_id::create("master[0]", this);
      psv_master[0] = caliptra_aaxi_compat_agent::type_id::create("psv_master[0]", this);
      psv_master[0].is_active = UVM_PASSIVE;
      slave[0] = caliptra_aaxi_compat_agent::type_id::create("slave[0]", this);
      slave[0].is_active = UVM_PASSIVE;
    endfunction
  endclass

  class aaxi_uvm_testbench extends uvm_env;
    caliptra_aaxi_compat_env0 env0;

    `uvm_component_utils(aaxi_uvm_testbench)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env0 = caliptra_aaxi_compat_env0::type_id::create("env0", this);
    endfunction
  endclass
endpackage
`endif
