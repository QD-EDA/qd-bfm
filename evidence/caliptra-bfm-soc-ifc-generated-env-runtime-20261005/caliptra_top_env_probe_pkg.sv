// SPDX-License-Identifier: Apache-2.0
// Runtime probe for Caliptra's generated top environment around soc_ifc.
package caliptra_top_env_probe_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import caliptra_top_env_pkg::*;
  import soc_ifc_ctrl_pkg::*;
  import aaxi_uvm_pkg::*;
  `include "uvm_macros.svh"

  class caliptra_top_env_reset_sequence extends uvm_sequence #(soc_ifc_ctrl_transaction);
    `uvm_object_utils(caliptra_top_env_reset_sequence)
    bit release_initial_reset_only;

    function new(string name = "caliptra_top_env_reset_sequence");
      super.new(name);
    endfunction

    task automatic drive(bit set_pwrgood, bit assert_rst, int unsigned wait_cycles);
      soc_ifc_ctrl_transaction req;
      req = soc_ifc_ctrl_transaction::type_id::create("req");
      start_item(req);
      req.set_pwrgood = set_pwrgood;
      req.assert_rst = assert_rst;
      req.security_state = 3'b111;
      req.wait_cycles = wait_cycles;
      finish_item(req);
    endtask

    task body();
      if (!release_initial_reset_only)
        drive(1'b0, 1'b1, 10);
      drive(1'b1, 1'b1, 10);
      drive(1'b1, 1'b0, 0);
    endtask
  endclass

  class caliptra_top_env_axi_user_readback_sequence extends uvm_sequence;
    soc_ifc_reg_model_top_pkg::soc_ifc_reg_model_top reg_model;
    uvm_object axi_user_extension;

    `uvm_object_utils(caliptra_top_env_axi_user_readback_sequence)

    function new(string name = "caliptra_top_env_axi_user_readback_sequence");
      super.new(name);
    endfunction

    task body();
      uvm_status_e status;
      uvm_reg_data_t value;
      reg_model.soc_ifc_reg_rm.CPTRA_MBOX_VALID_AXI_USER[0].read(
          status, value, UVM_FRONTDOOR, reg_model.soc_ifc_AXI_map, this,
          .extension(axi_user_extension));
      if (status != UVM_IS_OK || value != 32'hc0de_0000)
        `uvm_fatal("CALIPTRA_TOP_ENV_AXI_USER_READ", $sformatf("MBOX AXI USER readback failed: status=%0d value=0x%0h", status, value))
    endtask
  endclass

  class caliptra_top_env_axi_user_observer extends uvm_component;
    uvm_analysis_imp #(aaxi_master_tr, caliptra_top_env_axi_user_observer) read_export;
    bit check_readback;
    int readback_count;

    `uvm_component_utils(caliptra_top_env_axi_user_observer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      read_export = new("read_export", this);
    endfunction

    function void write(aaxi_master_tr item);
      if (!check_readback) return;
      if (!item.is_read() || item.addr != 48'h3_0048 || item.aruser != 32'hc0de_0000 ||
          !item.transport_success || item.resp != 2'b00 || item.beatQ.size() != 1 ||
          item.respQ.size() != 1 || item.respQ[0] != 2'b00 || item.beatQ[0] != 32'hc0de_0000)
        `uvm_fatal("CALIPTRA_TOP_ENV_AXI_USER_MON", $sformatf("AXI USER readback monitor mismatch (ARUSER=0x%08h, expected=0xc0de0000): %s", item.aruser, item.convert2string()))
      readback_count++;
    endfunction
  endclass

  class caliptra_top_env_probe_test extends uvm_test;
    caliptra_top_env_configuration top_configuration;
    caliptra_top_environment top_environment;
    caliptra_top_env_axi_user_observer axi_user_observer;
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
      axi_user_observer = caliptra_top_env_axi_user_observer::type_id::create("axi_user_observer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      top_environment.soc_ifc_subenv.aaxi_tb.env0.master[0].read_done_export.connect(
          axi_user_observer.read_export);
    endfunction

    task run_phase(uvm_phase phase);
      caliptra_top_env_reset_sequence reset_sequence;
      caliptra_top_env_axi_user_readback_sequence readback_sequence;
      soc_ifc_env_pkg::soc_ifc_env_axi_user_init_sequence_t axi_user_init_sequence;
      phase.raise_objection(this);
      if (top_environment.soc_ifc_subenv == null || top_environment.vsqr == null ||
          top_configuration.vsqr != top_environment.vsqr)
        `uvm_fatal("CALIPTRA_TOP_ENV", "Generated top environment did not publish its subenvironment and virtual sequencer")

      top_configuration.soc_ifc_subenv_config.soc_ifc_ctrl_agent_config.wait_for_num_clocks(2);
      reset_sequence = caliptra_top_env_reset_sequence::type_id::create("power_on_sequence");
      reset_sequence.release_initial_reset_only = 1;
      reset_sequence.start(top_configuration.soc_ifc_subenv_config.soc_ifc_ctrl_agent_config.sequencer);
      top_configuration.soc_ifc_subenv_config.soc_ifc_ctrl_agent_config.wait_for_num_clocks(20);

      top_environment.set_can_handle_reset(1);
      fork
        forever top_environment.detect_reset();
      join_none
      top_configuration.soc_ifc_subenv_config.soc_ifc_ctrl_agent_config.wait_for_num_clocks(1);
      reset_sequence = caliptra_top_env_reset_sequence::type_id::create("hard_reset_sequence");
      reset_sequence.start(top_configuration.soc_ifc_subenv_config.soc_ifc_ctrl_agent_config.sequencer);
      top_configuration.soc_ifc_subenv_config.soc_ifc_ctrl_agent_config.wait_for_num_clocks(20);
      if ($test$plusargs("CALIPTRA_GENERATED_AXI_USER_INIT")) begin
        axi_user_init_sequence = soc_ifc_env_pkg::soc_ifc_env_axi_user_init_sequence_t::type_id::create("axi_user_init_sequence");
        axi_user_init_sequence.soc_ifc_status_agent_rsp_seq =
            soc_ifc_status_pkg::soc_ifc_status_agent_responder_seq_t::type_id::create("soc_ifc_status_agent_rsp_seq");
        for (int i = 0; i < 5; i++)
          axi_user_init_sequence.mbox_valid_users[i] = 32'hc0de_0000 | i;
        axi_user_init_sequence.trng_valid_user = 32'hbeef_0001;
        axi_user_init_sequence.start(top_configuration.soc_ifc_subenv_config.vsqr);
        for (int i = 0; i < 5; i++) begin
          if (top_configuration.soc_ifc_subenv_config.soc_ifc_rm.soc_ifc_reg_rm.CPTRA_MBOX_VALID_AXI_USER[i].get_mirrored_value() != (32'hc0de_0000 | i) ||
              top_configuration.soc_ifc_subenv_config.soc_ifc_rm.soc_ifc_reg_rm.CPTRA_MBOX_AXI_USER_LOCK[i].get_mirrored_value() != 1)
            `uvm_fatal("CALIPTRA_TOP_ENV_AXI_USER", $sformatf("MBOX AXI USER RAL mirror mismatch at slot %0d", i))
        end
        if (top_configuration.soc_ifc_subenv_config.soc_ifc_rm.soc_ifc_reg_rm.CPTRA_TRNG_VALID_AXI_USER.get_mirrored_value() != 32'hbeef_0001 ||
            top_configuration.soc_ifc_subenv_config.soc_ifc_rm.soc_ifc_reg_rm.CPTRA_TRNG_AXI_USER_LOCK.get_mirrored_value() != 1)
          `uvm_fatal("CALIPTRA_TOP_ENV_AXI_USER", "TRNG AXI USER RAL mirror mismatch")
        $display("PASS: generated Caliptra top environment completed AXI USER initialization");
        readback_sequence = caliptra_top_env_axi_user_readback_sequence::type_id::create("axi_user_readback_sequence");
        readback_sequence.reg_model = top_configuration.soc_ifc_subenv_config.soc_ifc_rm;
        axi_user_init_sequence.axi_user_obj.set_addr_user(32'hc0de_0000);
        readback_sequence.axi_user_extension = axi_user_init_sequence.axi_user_obj;
        axi_user_observer.readback_count = 0;
        axi_user_observer.check_readback = 1;
        readback_sequence.start(top_configuration.soc_ifc_subenv_config.vsqr);
        axi_user_observer.check_readback = 0;
        if (axi_user_observer.readback_count != 1)
          `uvm_fatal("CALIPTRA_TOP_ENV_AXI_USER_MON", $sformatf("Expected one monitored AXI USER readback, observed %0d", axi_user_observer.readback_count))
        $display("PASS: generated Caliptra top environment completed AXI USER readback");
      end
      $display("PASS: generated Caliptra top environment completed real reset");
      phase.drop_objection(this);
    endtask
  endclass
endpackage
