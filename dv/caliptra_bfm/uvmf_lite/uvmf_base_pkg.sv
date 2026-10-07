// SPDX-License-Identifier: Apache-2.0
// Clean-room UVMF base-package surface for pinned Caliptra consumers.
`ifndef CALIPTRA_BFM_EXTERNAL_UVMF
package uvmf_base_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg_hdl::*;
  export uvmf_base_pkg_hdl::*;
  `include "uvm_macros.svh"

  // UVMF generated parameterized sequences invoke this helper after
  // uvm_object_param_utils, which intentionally omits a type-name override.
  `ifndef m_uvm_get_type_name_func
  `define m_uvm_get_type_name_func(T) \
    const static string type_name = `"T`"; \
    virtual function string get_type_name(); \
      return type_name; \
    endfunction
  `endif

  typedef enum { NA } uvmf_sim_level_t;
  // Generated environment packages use these literals from uvmf_base_pkg.
  // Name the exports so they remain the original HDL package items; interface
  // packages may import both base packages without creating duplicate names.
  export uvmf_base_pkg_hdl::ACTIVE;
  export uvmf_base_pkg_hdl::PASSIVE;
  export uvmf_base_pkg_hdl::INITIATOR;
  export uvmf_base_pkg_hdl::RESPONDER;
  localparam string UVMF_AGENT_CONFIG = "UVMF_AGENT_CONFIG";
  localparam string UVMF_CONFIGURATIONS = "UVMF_CONFIGURATIONS";
  localparam string UVMF_SEQUENCERS = "UVMF_SEQUENCERS";

  class uvmf_environment_configuration_base extends uvm_object;
    uvmf_sim_level_t sim_level;
    string environment_path;
    string interface_names[];
    uvm_reg_block register_model;
    uvmf_active_passive_t interface_activity[];
    bit enable_reg_adaptation;
    bit enable_reg_prediction;

    `uvm_object_utils(uvmf_environment_configuration_base)

    function new(string name = "uvmf_environment_configuration_base");
      super.new(name);
    endfunction

    virtual function void initialize(
      uvmf_sim_level_t sim_level,
      string environment_path,
      string interface_names[],
      uvm_reg_block register_model = null,
      uvmf_active_passive_t interface_activity[] = {}
    );
      this.sim_level = sim_level;
      this.environment_path = environment_path;
      this.interface_names = interface_names;
      this.register_model = register_model;
      this.interface_activity = interface_activity;
      this.enable_reg_adaptation = 0;
      this.enable_reg_prediction = 0;
    endfunction
  endclass

  class uvmf_environment_base #(
    type CONFIG_T = uvmf_environment_configuration_base
  ) extends uvm_env;
    CONFIG_T configuration;

    `uvm_component_param_utils(uvmf_environment_base #(CONFIG_T))

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void set_config(CONFIG_T cfg);
      if (cfg == null)
        `uvm_fatal("UVMF_CONFIG", "Environment set_config received a null configuration")
      configuration = cfg;
    endfunction
  endclass

  class uvmf_virtual_sequencer_base #(
    type CONFIG_T = uvmf_environment_configuration_base
  ) extends uvm_sequencer #(uvm_sequence_item);
    CONFIG_T configuration;

    `uvm_component_param_utils(uvmf_virtual_sequencer_base #(CONFIG_T))

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void set_config(CONFIG_T cfg);
      if (cfg == null)
        `uvm_fatal("UVMF_CONFIG", "Virtual sequencer set_config received a null configuration")
      configuration = cfg;
    endfunction
  endclass

  class uvmf_sequence_base #(
    type REQ = uvm_sequence_item,
    type RSP = REQ
  ) extends uvm_sequence #(REQ, RSP);
    `uvm_object_param_utils(uvmf_sequence_base #(REQ, RSP))
    function new(string name = "uvmf_sequence_base");
      super.new(name);
    endfunction
  endclass

  class uvmf_virtual_sequence_base #(
    type CONFIG_T = uvmf_environment_configuration_base
  ) extends uvm_sequence #(uvm_sequence_item);
    CONFIG_T configuration;

    `uvm_object_param_utils(uvmf_virtual_sequence_base #(CONFIG_T))

    function new(string name = "uvmf_virtual_sequence_base");
      super.new(name);
    endfunction

    virtual task pre_body();
      uvmf_virtual_sequencer_base #(CONFIG_T) virtual_sequencer;
      if (!$cast(virtual_sequencer, m_sequencer))
        `uvm_fatal("UVMF_VSEQ", "Virtual sequence must start on a UVMF virtual sequencer")
      configuration = virtual_sequencer.configuration;
      if (configuration == null)
        `uvm_fatal("UVMF_VSEQ", "Virtual sequencer has no environment configuration")
      super.pre_body();
    endtask
  endclass

  class uvmf_test_base #(
    type CONFIG_T = uvmf_environment_configuration_base,
    type ENV_T = uvmf_environment_base #(CONFIG_T),
    type TOP_LEVEL_SEQ_T = uvmf_sequence_base #(uvm_sequence_item)
  ) extends uvm_test;
    CONFIG_T configuration;
    ENV_T environment;
    TOP_LEVEL_SEQ_T top_level_sequence;

    `uvm_component_param_utils(uvmf_test_base #(CONFIG_T, ENV_T, TOP_LEVEL_SEQ_T))

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      configuration = CONFIG_T::type_id::create("configuration");
      if (configuration == null)
        `uvm_fatal("UVMF_TEST_CONFIG", "Could not create the environment configuration")
      if (!configuration.randomize())
        `uvm_warning("UVMF_TEST_CONFIG", "Environment configuration randomization failed")
      uvm_config_db #(CONFIG_T)::set(
        null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", configuration);
      environment = ENV_T::type_id::create("environment", this);
      environment.set_config(configuration);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      top_level_sequence = TOP_LEVEL_SEQ_T::type_id::create("top_level_sequence");
      top_level_sequence.start(null);
      phase.drop_objection(this);
    endtask
  endclass

  class uvmf_parameterized_agent_configuration_base #(
    type DRIVER_BFM_BIND_T = int,
    type MONITOR_BFM_BIND_T = int
  ) extends uvm_object;
    DRIVER_BFM_BIND_T driver_bfm;
    MONITOR_BFM_BIND_T monitor_bfm;
    uvmf_active_passive_t active_passive;
    uvmf_initiator_responder_t initiator_responder;
    string agent_path;
    string interface_name;
    bit return_transaction_response;
    bit has_coverage;

    function new(string name = "uvmf_parameterized_agent_configuration_base");
      super.new(name);
    endfunction

    virtual function void initialize(
      uvmf_active_passive_t activity,
      string agent_path,
      string interface_name
    );
      this.active_passive = activity;
      this.agent_path = agent_path;
      this.interface_name = interface_name;
      this.return_transaction_response = 0;
    endfunction

    virtual function void resolve_bfm_handles();
      // Resolve in connect so later build-phase registrations are visible.
      if (active_passive == ACTIVE &&
          !uvm_config_db #(DRIVER_BFM_BIND_T)::get(
            null, UVMF_VIRTUAL_INTERFACES, interface_name, driver_bfm))
        `uvm_fatal("UVMF_CONFIG",
          $sformatf("Missing driver BFM for active interface '%s'", interface_name))
      if (!uvm_config_db #(MONITOR_BFM_BIND_T)::get(
            null, UVMF_VIRTUAL_INTERFACES, interface_name, monitor_bfm))
        `uvm_fatal("UVMF_CONFIG",
          $sformatf("Missing monitor BFM for interface '%s'", interface_name))
    endfunction
  endclass

  class uvmf_driver_base #(
    type CONFIG_T = uvmf_parameterized_agent_configuration_base #(int, int),
    type BFM_BIND_T = int,
    type REQ = uvm_sequence_item,
    type RSP = REQ
  ) extends uvm_driver #(REQ, RSP);
    CONFIG_T configuration;
    BFM_BIND_T bfm;

    `uvm_component_param_utils(uvmf_driver_base #(CONFIG_T, BFM_BIND_T, REQ, RSP))

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void configure(CONFIG_T cfg);
    endfunction

    virtual function void set_bfm_proxy_handle();
      `uvm_fatal("UVMF_DRIVER", "Derived driver must install its BFM proxy")
    endfunction

    virtual task access(inout REQ txn);
      `uvm_fatal("UVMF_DRIVER", "Derived driver must implement access()")
    endtask

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(CONFIG_T)::get(
            this, "", UVMF_AGENT_CONFIG, configuration))
        `uvm_fatal("UVMF_CONFIG", "Driver cannot find its agent configuration")
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      configuration.resolve_bfm_handles();
      bfm = configuration.driver_bfm;
      configure(configuration);
      set_bfm_proxy_handle();
    endfunction

    virtual task run_phase(uvm_phase phase);
      uvm_object response_copy;
      forever begin
        seq_item_port.get_next_item(req);
        access(req);
        if (configuration.return_transaction_response) begin
          response_copy = req.clone();
          if (!$cast(rsp, response_copy))
            `uvm_fatal("UVMF_DRIVER_RSP", "Request clone is not the configured response type")
          rsp.set_id_info(req);
          seq_item_port.item_done(rsp);
        end else begin
          seq_item_port.item_done();
        end
      end
    endtask
  endclass

  class uvmf_monitor_base #(
    type CONFIG_T = uvm_object,
    type BFM_BIND_T = int,
    type TRANS_T = uvm_sequence_item
  ) extends uvm_monitor;
    CONFIG_T configuration;
    BFM_BIND_T bfm;
    TRANS_T trans;
    time time_stamp;
    uvm_analysis_port #(TRANS_T) analysis_port;

    `uvm_component_param_utils(uvmf_monitor_base #(CONFIG_T, BFM_BIND_T, TRANS_T))

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_port = new("analysis_port", this);
    endfunction

    virtual function void configure(CONFIG_T cfg);
    endfunction

    virtual function void set_bfm_proxy_handle();
      `uvm_fatal("UVMF_MONITOR", "Derived monitor must install its BFM proxy")
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(CONFIG_T)::get(
            this, "", UVMF_AGENT_CONFIG, configuration))
        `uvm_fatal("UVMF_CONFIG", "Monitor cannot find its agent configuration")
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      configuration.resolve_bfm_handles();
      bfm = configuration.monitor_bfm;
      configure(configuration);
      set_bfm_proxy_handle();
    endfunction

    virtual function void analyze(TRANS_T item);
      analysis_port.write(item);
    endfunction
  endclass

  class uvmf_parameterized_agent #(
    type CONFIG_T = uvmf_parameterized_agent_configuration_base #(int, int),
    type DRIVER_T = uvmf_driver_base #(CONFIG_T, int, uvm_sequence_item, uvm_sequence_item),
    type MONITOR_T = uvmf_monitor_base #(CONFIG_T, int, uvm_sequence_item),
    type COVERAGE_T = uvm_subscriber #(uvm_sequence_item),
    type TRANS_T = uvm_sequence_item
  ) extends uvm_agent;
    CONFIG_T configuration;
    DRIVER_T driver;
    MONITOR_T monitor;
    COVERAGE_T coverage;
    uvm_sequencer #(TRANS_T) sequencer;
    uvm_analysis_port #(TRANS_T) monitored_ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      monitored_ap = new("monitored_ap", this);
    endfunction

    virtual function void set_config(CONFIG_T cfg);
      if (cfg == null)
        `uvm_fatal("UVMF_CONFIG", "Agent set_config received a null configuration")
      configuration = cfg;
      uvm_config_db #(CONFIG_T)::set(this, "", UVMF_AGENT_CONFIG, cfg);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(CONFIG_T)::get(
            this, "", UVMF_AGENT_CONFIG, configuration))
        `uvm_fatal("UVMF_CONFIG", "Agent cannot find its configuration")
      if (!uvm_config_db #(MONITOR_T)::get(this, "", "monitor", monitor) ||
          monitor == null) begin
        uvm_config_db #(CONFIG_T)::set(this, "monitor", UVMF_AGENT_CONFIG, configuration);
        monitor = MONITOR_T::type_id::create("monitor", this);
      end
      if (configuration.active_passive == ACTIVE)
        uvm_config_db #(CONFIG_T)::set(this, "driver", UVMF_AGENT_CONFIG, configuration);
      if (configuration.active_passive == ACTIVE) begin
        sequencer = uvm_sequencer #(TRANS_T)::type_id::create("sequencer", this);
        uvm_config_db #(uvm_sequencer #(TRANS_T))::set(
          null, UVMF_SEQUENCERS, configuration.interface_name, sequencer);
        driver = DRIVER_T::type_id::create("driver", this);
      end
      if (configuration.has_coverage)
        coverage = COVERAGE_T::type_id::create("coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      monitor.analysis_port.connect(monitored_ap);
      if (configuration.active_passive == ACTIVE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
      if (configuration.has_coverage)
        monitor.analysis_port.connect(coverage.analysis_export);
    endfunction
  endclass

  class uvmf_transaction_base extends uvm_sequence_item;
    time start_time;
    time end_time;
    int transaction_view_h;
    local int unsigned transaction_key;

    `uvm_object_utils(uvmf_transaction_base)

    function new(string name = "uvmf_transaction_base");
      super.new(name);
    endfunction

    virtual function void set_key(int unsigned key);
      transaction_key = key;
    endfunction

    virtual function int unsigned get_key();
      return transaction_key;
    endfunction

    virtual function void do_copy(uvm_object rhs);
      uvmf_transaction_base source;
      if (!$cast(source, rhs)) begin
        `uvm_error("UVMF_TXN_COPY", "Cannot copy a non-UVMF transaction")
        return;
      end
      super.do_copy(rhs);
      start_time = source.start_time;
      end_time = source.end_time;
      transaction_view_h = source.transaction_view_h;
      transaction_key = source.transaction_key;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      uvmf_transaction_base other;
      return $cast(other, rhs) && super.do_compare(rhs, comparer);
    endfunction

    virtual function void do_print(uvm_printer printer);
      super.do_print(printer);
      printer.print_time("start_time", start_time);
      printer.print_time("end_time", end_time);
    endfunction

    virtual function void add_to_wave(int transaction_viewing_stream_h);
      // Waveform transaction APIs are simulator-specific and optional.
    endfunction
  endclass

  `uvm_analysis_imp_decl(_expected)
  `uvm_analysis_imp_decl(_actual)

  class uvmf_in_order_scoreboard #(type T = uvm_sequence_item)
    extends uvm_scoreboard;
    uvm_analysis_imp_expected #(T, uvmf_in_order_scoreboard #(T))
      expected_analysis_export;
    uvm_analysis_imp_actual #(T, uvmf_in_order_scoreboard #(T))
      actual_analysis_export;
    T expected_q[$];
    T actual_q[$];
    int unsigned expected_received_count;
    int unsigned actual_received_count;
    int unsigned matched_count;
    int unsigned mismatch_count;
    int unsigned pending_expected_count;
    int unsigned pending_actual_count;

    `uvm_component_param_utils(uvmf_in_order_scoreboard #(T))

    function new(string name, uvm_component parent);
      super.new(name, parent);
      expected_analysis_export = new("expected_analysis_export", this);
      actual_analysis_export = new("actual_analysis_export", this);
    endfunction

    function T clone_item(T item);
      uvm_object copy;
      T typed_copy;
      if (item == null) begin
        `uvm_fatal("UVMF_SB_NULL", "Scoreboard received a null transaction")
        return null;
      end
      copy = item.clone();
      if (!$cast(typed_copy, copy)) begin
        `uvm_fatal("UVMF_SB_CLONE", "Transaction clone changed its item type")
        return null;
      end
      return typed_copy;
    endfunction

    function void write_expected(T item);
      expected_q.push_back(clone_item(item));
      expected_received_count++;
      pending_expected_count++;
      compare_ready_pairs();
    endfunction

    function void write_actual(T item);
      actual_q.push_back(clone_item(item));
      actual_received_count++;
      pending_actual_count++;
      compare_ready_pairs();
    endfunction

    function void compare_ready_pairs();
      T expected_item;
      T actual_item;
      while (expected_q.size() != 0 && actual_q.size() != 0) begin
        expected_item = expected_q.pop_front();
        actual_item = actual_q.pop_front();
        pending_expected_count--;
        pending_actual_count--;
        if (expected_item.compare(actual_item)) begin
          matched_count++;
        end else begin
          mismatch_count++;
          `uvm_error("UVMF_SB_MISMATCH",
            $sformatf("In-order mismatch #%0d: expected {%s}, actual {%s}",
              mismatch_count, expected_item.sprint(), actual_item.sprint()))
        end
      end
    endfunction

    virtual function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (pending_expected_count != 0 || pending_actual_count != 0)
        `uvm_error("UVMF_SB_LEFTOVER",
          $sformatf("Unmatched transactions at end: expected=%0d actual=%0d",
            pending_expected_count, pending_actual_count))
    endfunction

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("UVMF_SB_SUMMARY",
        $sformatf("received expected=%0d actual=%0d; matched=%0d mismatched=%0d; pending expected=%0d actual=%0d",
          expected_received_count, actual_received_count, matched_count,
          mismatch_count, pending_expected_count, pending_actual_count), UVM_LOW)
    endfunction
  endclass

  // Use when expected and observed transactions can complete in different
  // orders. Exact matches are removed as they arrive; unmatched items are
  // reported as mismatches or leftovers during check_phase.
  class uvmf_out_of_order_scoreboard #(type T = uvm_sequence_item)
    extends uvm_scoreboard;
    uvm_analysis_imp_expected #(T, uvmf_out_of_order_scoreboard #(T))
      expected_analysis_export;
    uvm_analysis_imp_actual #(T, uvmf_out_of_order_scoreboard #(T))
      actual_analysis_export;
    T expected_q[$];
    T actual_q[$];
    int unsigned expected_received_count;
    int unsigned actual_received_count;
    int unsigned matched_count;
    int unsigned mismatch_count;
    int unsigned pending_expected_count;
    int unsigned pending_actual_count;

    `uvm_component_param_utils(uvmf_out_of_order_scoreboard #(T))

    function new(string name, uvm_component parent);
      super.new(name, parent);
      expected_analysis_export = new("expected_analysis_export", this);
      actual_analysis_export = new("actual_analysis_export", this);
    endfunction

    function T clone_item(T item);
      uvm_object copy;
      T typed_copy;
      if (item == null) begin
        `uvm_fatal("UVMF_OOO_NULL", "Scoreboard received a null transaction")
        return null;
      end
      copy = item.clone();
      if (!$cast(typed_copy, copy)) begin
        `uvm_fatal("UVMF_OOO_CLONE", "Transaction clone changed its item type")
        return null;
      end
      return typed_copy;
    endfunction

    function void write_expected(T item);
      expected_q.push_back(clone_item(item));
      expected_received_count++;
      pending_expected_count++;
      compare_ready_pairs();
    endfunction

    function void write_actual(T item);
      actual_q.push_back(clone_item(item));
      actual_received_count++;
      pending_actual_count++;
      compare_ready_pairs();
    endfunction

    function void compare_ready_pairs();
      int expected_index;
      int actual_index;
      bit found_match;
      T expected_item;
      T actual_item;
      do begin
        found_match = 0;
        for (expected_index = 0;
             expected_index < expected_q.size() && !found_match;
             expected_index++) begin
          for (actual_index = 0;
               actual_index < actual_q.size() && !found_match;
               actual_index++) begin
            expected_item = expected_q[expected_index];
            actual_item = actual_q[actual_index];
            if (expected_item.compare(actual_item)) begin
              expected_q.delete(expected_index);
              actual_q.delete(actual_index);
              pending_expected_count--;
              pending_actual_count--;
              matched_count++;
              found_match = 1;
            end
          end
        end
      end while (found_match);
    endfunction

    virtual function void check_phase(uvm_phase phase);
      int paired_count;
      T expected_item;
      T actual_item;
      super.check_phase(phase);
      paired_count = (expected_q.size() < actual_q.size()) ?
        expected_q.size() : actual_q.size();
      repeat (paired_count) begin
        expected_item = expected_q.pop_front();
        actual_item = actual_q.pop_front();
        pending_expected_count--;
        pending_actual_count--;
        mismatch_count++;
        `uvm_error("UVMF_OOO_MISMATCH",
          $sformatf("Unmatched transactions at end: expected {%s}, actual {%s}",
            expected_item.sprint(), actual_item.sprint()))
      end
      if (pending_expected_count != 0 || pending_actual_count != 0)
        `uvm_error("UVMF_OOO_LEFTOVER",
          $sformatf("Unmatched transactions at end: expected=%0d actual=%0d",
            pending_expected_count, pending_actual_count))
    endfunction

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("UVMF_OOO_SUMMARY",
        $sformatf("received expected=%0d actual=%0d; matched=%0d mismatched=%0d; pending expected=%0d actual=%0d",
          expected_received_count, actual_received_count, matched_count,
          mismatch_count, pending_expected_count, pending_actual_count), UVM_LOW)
    endfunction
  endclass
endpackage
`endif
