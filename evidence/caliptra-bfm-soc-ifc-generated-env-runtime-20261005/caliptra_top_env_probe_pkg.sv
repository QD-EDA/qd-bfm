// SPDX-License-Identifier: Apache-2.0
// Runtime probe for Caliptra's generated top environment around soc_ifc.
package caliptra_top_env_probe_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import caliptra_top_env_pkg::*;
  `include "uvm_macros.svh"

  class caliptra_top_env_probe_test extends uvm_test;
    caliptra_top_env_configuration top_configuration;
    caliptra_top_environment top_environment;
    string interface_names[];
    uvmf_active_passive_t interface_activity[];

    `uvm_component_utils(caliptra_top_env_probe_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      top_configuration = caliptra_top_env_configuration::type_id::create("top_configuration");
      interface_names = new[9];
      interface_names[0] = "uvm_test_top.environment.qvip_ahb_lite_slave_subenv.ahb_lite_slave_0";
      interface_names[1] = "uvm_test_top.environment.aaxi_tb.env0.master[0]";
      interface_names[2] = "soc_ifc_ctrl_agent_BFM";
      interface_names[3] = "cptra_ctrl_agent_BFM";
      interface_names[4] = "ss_mode_ctrl_agent_BFM";
      interface_names[5] = "soc_ifc_status_agent_BFM";
      interface_names[6] = "cptra_status_agent_BFM";
      interface_names[7] = "ss_mode_status_agent_BFM";
      interface_names[8] = "mbox_sram_agent_BFM";
      interface_activity = new[9];
      interface_activity[0] = PASSIVE;
      interface_activity[1] = ACTIVE;
      interface_activity[2] = ACTIVE;
      interface_activity[3] = PASSIVE;
      interface_activity[4] = ACTIVE;
      interface_activity[5] = ACTIVE;
      interface_activity[6] = PASSIVE;
      interface_activity[7] = ACTIVE;
      interface_activity[8] = ACTIVE;
      top_configuration.initialize(
        NA, "uvm_test_top.environment", interface_names, null, interface_activity);
      top_environment = caliptra_top_environment::type_id::create("environment", this);
      top_environment.set_config(top_configuration);
      top_environment.set_can_handle_reset(0);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      if (top_environment.soc_ifc_subenv == null || top_environment.vsqr == null ||
          top_configuration.vsqr != top_environment.vsqr)
        `uvm_fatal("CALIPTRA_TOP_ENV", "Generated top environment did not publish its subenvironment and virtual sequencer")

      top_environment.handle_reset("HARD");
      top_configuration.soc_ifc_subenv_config.soc_ifc_ctrl_agent_config.wait_for_num_clocks(20);
      $display("PASS: generated Caliptra top environment dispatched reset to soc_ifc");
      phase.drop_objection(this);
    endtask
  endclass
endpackage
