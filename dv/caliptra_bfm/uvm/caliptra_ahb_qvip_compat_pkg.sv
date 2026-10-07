// SPDX-License-Identifier: Apache-2.0
// Clean-room lower-bound API for the QVIP AHB types consumed by Caliptra.
// This is not a copy or implementation of Siemens/Mentor QVIP or UVMF.
`ifndef CALIPTRA_BFM_EXTERNAL_AHB_QVIP
package qvip_ahb_lite_slave_params_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import mvc_pkg::*;
  import mgc_ahb_v2_0_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;

  class ahb_lite_slave_0_params;
    localparam int AHB_NUM_MASTERS = 1;
    localparam int AHB_NUM_MASTER_BITS = 1;
    localparam int AHB_NUM_SLAVES = 1;
    localparam int AHB_ADDRESS_WIDTH = 32;
    localparam int AHB_WDATA_WIDTH = AHB_MVC_DATA_WIDTH;
    localparam int AHB_RDATA_WIDTH = AHB_MVC_DATA_WIDTH;
  endclass

  typedef ahb_lite_caliptra_mvc_transfer ahb_lite_slave_0_transfer_t;
  typedef ahb_lite_caliptra_qvip_compat_agent ahb_lite_slave_0_agent_t;
  typedef virtual ahb_lite_caliptra_record_if ahb_lite_slave_0_bfm_t;

  typedef struct {
    bit master;
    bit slave;
    bit response;
  } ahb_lite_slave_0_coverage_config_t;

  class ahb_lite_slave_0_agent_config extends uvm_object;
    int unsigned is_active;
    ahb_lite_slave_0_coverage_config_t en_cvg;

    `uvm_object_utils(ahb_lite_slave_0_agent_config)

    function new(string name = "ahb_lite_slave_0_agent_config");
      super.new(name);
      is_active = 0;
      en_cvg = '{default: 0};
    endfunction
  endclass

  class ahb_lite_slave_0_config extends uvm_object;
    ahb_lite_slave_0_agent_config agent_cfg;
    virtual ahb_lite_caliptra_record_if m_bfm;
    virtual ahb_lite_caliptra_master_cmd_if m_command_bfm;
    uvm_object_wrapper monitor_item_types[string];

    bit publish_burst_transfer = 1;
    bit publish_burst_transfer_sb;
    bit publish_burst_transfer_cov;

    `uvm_object_utils(ahb_lite_slave_0_config)

    function new(string name = "ahb_lite_slave_0_config");
      super.new(name);
      agent_cfg = ahb_lite_slave_0_agent_config::type_id::create("agent_cfg");
    endfunction

    function bit set_monitor_item(string port_name, uvm_object_wrapper item_type);
      if (item_type != ahb_lite_caliptra_mvc_transfer::type_id::get()) begin
        `uvm_error("AHB_QVIP_ITEM", $sformatf("Unsupported item type for %s", port_name))
        return 0;
      end

      case (port_name)
        "burst_transfer": publish_burst_transfer = 1;
        "burst_transfer_sb": publish_burst_transfer_sb = 1;
        "burst_transfer_cov": publish_burst_transfer_cov = 1;
        default: begin
          `uvm_error("AHB_QVIP_PORT", $sformatf("Unsupported Caliptra AHB analysis port %s", port_name))
          return 0;
        end
      endcase
      monitor_item_types[port_name] = item_type;
      return 1;
    endfunction

    function void set_bfms(virtual ahb_lite_caliptra_record_if record_bfm,
                           virtual ahb_lite_caliptra_master_cmd_if command_bfm = null);
      m_bfm = record_bfm;
      m_command_bfm = command_bfm;
    endfunction

    function string convert2string();
      return $sformatf("AHB active=%0d streams={burst:%0d,sb:%0d,cov:%0d} record_vif=%0d command_vif=%0d",
                       agent_cfg.is_active, publish_burst_transfer,
                       publish_burst_transfer_sb, publish_burst_transfer_cov,
                       m_bfm != null, m_command_bfm != null);
    endfunction
  endclass

  typedef ahb_lite_slave_0_config ahb_lite_slave_0_cfg_t;
endpackage

package qvip_ahb_lite_slave_pkg;
  import uvm_pkg::*;
  import mvc_pkg::*;
  import qvip_ahb_lite_slave_params_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;
  import uvmf_base_pkg::*;
  `include "uvm_macros.svh"

  // Caliptra's generated PV and KeyVault environments use this QVIP adapter
  // shape for scalar RAL accesses. The native adapter owns the actual
  // address, lane, transfer-size, and response conversion.
  class reg2ahb_adapter #(
    type T = ahb_lite_caliptra_mvc_transfer,
    parameter int AHB_NUM_MASTERS = 1,
    parameter int AHB_NUM_MASTER_BITS = 1,
    parameter int AHB_NUM_SLAVES = 1,
    parameter int AHB_ADDRESS_WIDTH = 32,
    parameter int AHB_WDATA_WIDTH = AHB_MVC_DATA_WIDTH,
    parameter int AHB_RDATA_WIDTH = AHB_MVC_DATA_WIDTH
  ) extends ahb_lite_caliptra_reg_adapter;
    bit en_n_bits;

    `uvm_object_param_utils(reg2ahb_adapter #(T, AHB_NUM_MASTERS,
      AHB_NUM_MASTER_BITS, AHB_NUM_SLAVES, AHB_ADDRESS_WIDTH,
      AHB_WDATA_WIDTH, AHB_RDATA_WIDTH))

    function new(string name = "reg2ahb_adapter");
      super.new(name);
      en_n_bits = 0;
      set_bus_data_width(AHB_WDATA_WIDTH);
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      if (!en_n_bits && rw.n_bits != AHB_WDATA_WIDTH) begin
        `uvm_fatal("AHB_RAL_N_BITS",
          $sformatf("Caliptra AHB RAL adapter requires en_n_bits for %0d-bit access on a %0d-bit bus",
                    rw.n_bits, AHB_WDATA_WIDTH))
        return null;
      end
      // The type parameter is retained for generated-QVIP source compatibility.
      // Construction and field conversion stay in the concrete native adapter;
      // casting that returned class through generic T is not portable in Icarus.
      return super.reg2bus(rw);
    endfunction
  endclass

  // The generated predictor consumes the same completed MVC item stream as
  // the native adapter. UVM supplies map lookup, adapter conversion, and
  // mirror prediction; the PV specialization retains its custom write filter.
  class ahb_reg_predictor #(
    type T = ahb_lite_caliptra_mvc_transfer,
    parameter int AHB_NUM_MASTERS = 1,
    parameter int AHB_NUM_MASTER_BITS = 1,
    parameter int AHB_NUM_SLAVES = 1,
    parameter int AHB_ADDRESS_WIDTH = 32,
    parameter int AHB_WDATA_WIDTH = AHB_MVC_DATA_WIDTH,
    parameter int AHB_RDATA_WIDTH = AHB_MVC_DATA_WIDTH
  ) extends uvm_reg_predictor #(mvc_sequence_item_base);

    uvm_analysis_export #(mvc_sequence_item_base) bus_item_export;

    `uvm_component_param_utils(ahb_reg_predictor #(T, AHB_NUM_MASTERS,
      AHB_NUM_MASTER_BITS, AHB_NUM_SLAVES, AHB_ADDRESS_WIDTH,
      AHB_WDATA_WIDTH, AHB_RDATA_WIDTH))

    function new(string name, uvm_component parent);
      super.new(name, parent);
      bus_item_export = new("bus_item_export", this);
      bus_item_export.connect(bus_in);
    endfunction
  endclass

  class qvip_ahb_lite_slave_env_configuration
    extends uvmf_environment_configuration_base;
    ahb_lite_slave_0_cfg_t ahb_lite_slave_0_cfg;
    string interface_name;

    `uvm_object_utils(qvip_ahb_lite_slave_env_configuration)

    function new(string name = "qvip_ahb_lite_slave_env_configuration");
      super.new(name);
      ahb_lite_slave_0_cfg = ahb_lite_slave_0_cfg_t::type_id::create("ahb_lite_slave_0_cfg");
    endfunction

    virtual function void initialize(
      uvmf_sim_level_t sim_level,
      string environment_path,
      string interface_names[],
      uvm_reg_block register_model = null,
      uvmf_active_passive_t interface_activity[] = {}
    );
      super.initialize(sim_level, environment_path, interface_names,
                       register_model, interface_activity);

      if ($size(interface_names) == 0) begin
        `uvm_error("AHB_QVIP_CONFIG", "Caliptra AHB configuration requires one interface name")
        return;
      end
      interface_name = interface_names[0];

      if (!uvm_config_db#(ahb_lite_slave_0_bfm_t)::get(
            null, UVMF_VIRTUAL_INTERFACES, interface_name,
            ahb_lite_slave_0_cfg.m_bfm)) begin
        `uvm_warning("AHB_QVIP_VIF", $sformatf("No clean-room AHB record interface registered for '%s'; call set_bfms before build", interface_name))
      end
      if (!uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::get(
            null, UVMF_VIRTUAL_INTERFACES, {interface_name, ".cmd"},
            ahb_lite_slave_0_cfg.m_command_bfm)) begin
        ahb_lite_slave_0_cfg.m_command_bfm = null;
      end

      if ($size(interface_activity) > 0)
        ahb_lite_slave_0_cfg.agent_cfg.is_active =
          (interface_activity[0] == ACTIVE);
      else
        ahb_lite_slave_0_cfg.agent_cfg.is_active = 0;
    endfunction

    virtual function string convert2string();
      return {"qvip_ahb_lite_slave_env_configuration:",
              ahb_lite_slave_0_cfg.convert2string()};
    endfunction
  endclass

  class qvip_ahb_lite_slave_environment #(parameter int INSTANCE_ID = 0)
    extends uvmf_environment_base #(
      .CONFIG_T(qvip_ahb_lite_slave_env_configuration));
    ahb_lite_caliptra_qvip_compat_agent ahb_lite_slave_0;

    `uvm_component_param_utils(qvip_ahb_lite_slave_environment #(INSTANCE_ID))

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (configuration == null || configuration.ahb_lite_slave_0_cfg == null) begin
        `uvm_fatal("AHB_QVIP_CONFIG", "Call set_config with an initialized AHB configuration before build")
        return;
      end
      if (configuration.ahb_lite_slave_0_cfg.m_bfm == null) begin
        `uvm_fatal("AHB_QVIP_VIF", "Clean-room AHB environment needs ahb_lite_caliptra_record_if; the generated QVIP HDL interface is not a compatible record interface")
        return;
      end
      if (configuration.ahb_lite_slave_0_cfg.agent_cfg.is_active != 0 &&
          configuration.ahb_lite_slave_0_cfg.m_command_bfm == null) begin
        `uvm_fatal("AHB_QVIP_CMD_VIF", "Active clean-room AHB agent needs ahb_lite_caliptra_master_cmd_if")
        return;
      end
      if (configuration.ahb_lite_slave_0_cfg.agent_cfg.en_cvg.master ||
          configuration.ahb_lite_slave_0_cfg.agent_cfg.en_cvg.slave ||
          configuration.ahb_lite_slave_0_cfg.agent_cfg.en_cvg.response)
        `uvm_warning("AHB_QVIP_CVG", "Internal QVIP covergroups are not recreated; configured burst_transfer_cov still publishes monitored records to the environment coverage consumer")

      uvm_config_db#(virtual ahb_lite_caliptra_record_if)::set(
        this, "ahb_lite_slave_0.agent.monitor", "vif",
        configuration.ahb_lite_slave_0_cfg.m_bfm);
      if (configuration.ahb_lite_slave_0_cfg.agent_cfg.is_active != 0)
        uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::set(
          this, "ahb_lite_slave_0.mvc_driver", "cmd_vif",
          configuration.ahb_lite_slave_0_cfg.m_command_bfm);

      ahb_lite_slave_0 = ahb_lite_caliptra_qvip_compat_agent::type_id::create(
        "ahb_lite_slave_0", this);
      ahb_lite_slave_0.is_active =
        configuration.ahb_lite_slave_0_cfg.agent_cfg.is_active ? UVM_ACTIVE : UVM_PASSIVE;
      ahb_lite_slave_0.publish_burst_transfer =
        configuration.ahb_lite_slave_0_cfg.publish_burst_transfer;
      ahb_lite_slave_0.publish_burst_transfer_sb =
        configuration.ahb_lite_slave_0_cfg.publish_burst_transfer_sb;
      ahb_lite_slave_0.publish_burst_transfer_cov =
        configuration.ahb_lite_slave_0_cfg.publish_burst_transfer_cov;
    endfunction
  endclass
endpackage
`endif
