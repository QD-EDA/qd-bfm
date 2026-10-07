// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

interface uvmf_lite_toy_dut_if(input logic clk);
  logic request_valid = 0;
  integer request_value = 0;
  logic response_valid;
  integer response_value;
endinterface

module uvmf_lite_toy_dut(
  input logic request_valid,
  input integer request_value,
  output logic response_valid,
  output integer response_value
);
  always_comb begin
    response_valid = request_valid;
    response_value = request_value + 1;
  end
endmodule

interface uvmf_lite_driver_bfm_if(uvmf_lite_toy_dut_if bus);
  import uvm_pkg::*;
  uvm_object proxy;
  int access_count;

  task access(inout int value);
    if (proxy == null) $fatal(1, "driver proxy was not installed");
    access_count++;
    @(negedge bus.clk);
    bus.request_value = value;
    bus.request_valid = 1;
    do @(posedge bus.clk); while (!bus.response_valid);
    value = bus.response_value;
    @(negedge bus.clk);
    bus.request_valid = 0;
  endtask
endinterface

interface uvmf_lite_monitor_bfm_if(uvmf_lite_toy_dut_if bus);
  import uvm_pkg::*;
  uvm_object proxy;
  int start_count;

  task start_monitoring();
    if (proxy == null) $fatal(1, "monitor proxy was not installed");
    start_count++;
  endtask

  task wait_for_response(output int value);
    do @(posedge bus.clk); while (!bus.response_valid);
    value = bus.response_value;
  endtask

  task wait_for_request(output int value);
    do @(posedge bus.clk); while (!bus.request_valid);
    value = bus.request_value;
  endtask
endinterface

package uvmf_lite_agent_test_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;

  class agent_item extends uvmf_transaction_base;
    int value;
    `uvm_object_utils(agent_item)
    function new(string name = "agent_item"); super.new(name); endfunction
    virtual function void do_copy(uvm_object rhs);
      agent_item source;
      if (!$cast(source, rhs)) begin
        `uvm_error("AGENT_ITEM_COPY", "Cannot copy a non-agent item")
        return;
      end
      super.do_copy(rhs);
      value = source.value;
    endfunction
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      agent_item other;
      if (!$cast(other, rhs) || !super.do_compare(rhs, comparer)) return 0;
      return value == other.value;
    endfunction
    virtual function void do_print(uvm_printer printer);
      super.do_print(printer);
      printer.print_field_int("value", value, $bits(value), UVM_DEC);
    endfunction
  endclass

  class agent_config extends uvmf_parameterized_agent_configuration_base #(
    virtual uvmf_lite_driver_bfm_if,
    virtual uvmf_lite_monitor_bfm_if
  );
    uvm_sequencer #(agent_item) sequencer;
    `uvm_object_utils(agent_config)
    function new(string name = "agent_config"); super.new(name); endfunction
    virtual function void initialize(
      uvmf_active_passive_t activity, string agent_path, string interface_name);
      super.initialize(activity, agent_path, interface_name);
      uvm_config_db #(agent_config)::set(
        null, agent_path, UVMF_AGENT_CONFIG, this);
      uvm_config_db #(agent_config)::set(
        null, UVMF_CONFIGURATIONS, interface_name, this);
    endfunction
  endclass

  class agent_environment_configuration extends uvmf_environment_configuration_base;
    typedef uvmf_virtual_sequencer_base #(agent_environment_configuration) virtual_sequencer_t;
    agent_config active_agent_configuration;
    agent_config passive_agent_configuration;
    virtual_sequencer_t vsqr;
    `uvm_object_utils(agent_environment_configuration)
    function new(string name = "agent_environment_configuration");
      super.new(name);
      active_agent_configuration = agent_config::type_id::create("active_agent_configuration");
      passive_agent_configuration = agent_config::type_id::create("passive_agent_configuration");
      active_agent_configuration.initiator_responder = INITIATOR;
      passive_agent_configuration.initiator_responder = RESPONDER;
    endfunction
    virtual function void initialize(
      uvmf_sim_level_t sim_level, string environment_path, string interface_names[],
      uvm_reg_block register_model = null,
      uvmf_active_passive_t interface_activity[] = {});
      super.initialize(sim_level, environment_path, interface_names,
                       register_model, interface_activity);
      active_agent_configuration.has_coverage = 0;
      active_agent_configuration.initialize(
        interface_activity[0], {environment_path, ".active_agent"}, interface_names[0]);
      passive_agent_configuration.has_coverage = 1;
      passive_agent_configuration.initialize(
        interface_activity[1], {environment_path, ".passive_agent"}, interface_names[1]);
      uvm_config_db #(agent_environment_configuration)::set(
        null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", this);
    endfunction
    virtual function void set_vsqr(virtual_sequencer_t vsqr);
      this.vsqr = vsqr;
    endfunction
  endclass
  typedef uvmf_virtual_sequencer_base #(agent_environment_configuration) agent_environment_vsqr_t;

  class agent_driver extends uvmf_driver_base #(
    agent_config, virtual uvmf_lite_driver_bfm_if, agent_item, agent_item
  );
    `uvm_component_utils(agent_driver)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function void set_bfm_proxy_handle(); bfm.proxy = this; endfunction
    virtual task access(inout agent_item txn);
      bfm.access(txn.value);
    endtask
  endclass

  class agent_monitor extends uvmf_monitor_base #(
    agent_config, virtual uvmf_lite_monitor_bfm_if, agent_item
  );
    `uvm_component_utils(agent_monitor)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function void set_bfm_proxy_handle(); bfm.proxy = this; endfunction
    virtual task run_phase(uvm_phase phase);
      bfm.start_monitoring();
      forever begin
        int observed_value;
        if (configuration.interface_name == "input_if")
          bfm.wait_for_request(observed_value);
        else
          bfm.wait_for_response(observed_value);
        trans = agent_item::type_id::create("observed");
        trans.value = observed_value;
        analyze(trans);
      end
    endtask
  endclass

  class agent_predictor extends uvm_component;
    uvm_analysis_imp #(agent_item, agent_predictor) request_export;
    uvm_analysis_port #(agent_item) expected_ap;
    static int request_count;
    `uvm_component_utils(agent_predictor)
    function new(string name, uvm_component parent);
      super.new(name, parent);
      request_export = new("request_export", this);
      expected_ap = new("expected_ap", this);
    endfunction
    virtual function void write(agent_item request);
      agent_item expected;
      if (request == null) `uvm_fatal("UVMF_PREDICTOR", "Predictor received a null request")
      request_count++;
      expected = agent_item::type_id::create("expected_response");
      expected.value = request.value +
        ($test$plusargs("BFM_LITE_EXPECT_MISMATCH") ? 2 : 1);
      expected_ap.write(expected);
    endfunction
  endclass

  class agent_coverage extends uvm_component;
    uvm_analysis_imp #(agent_item, agent_coverage) analysis_export;
    static int sample_count;
    static int sampled_value;
    `uvm_component_utils(agent_coverage)
    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction
    virtual function void write(agent_item item);
      if (item == null) `uvm_fatal("UVMF_COVERAGE", "Coverage received a null transaction")
      sample_count++;
      sampled_value = item.value;
    endfunction
  endclass

  class agent_observer extends uvm_component;
    uvm_analysis_imp #(agent_item, agent_observer) analysis_export;
    static int item_count;
    static int last_value;
    `uvm_component_utils(agent_observer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction
    virtual function void write(agent_item item);
      item_count++;
      last_value = item.value;
    endfunction
  endclass

  class agent extends uvmf_parameterized_agent #(
    agent_config, agent_driver, agent_monitor, agent_coverage, agent_item
  );
    static agent_driver active_driver;
    static agent_monitor active_monitor;
    static agent_monitor passive_monitor;
    `uvm_component_utils(agent)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (configuration.active_passive == ACTIVE) begin
        configuration.sequencer = sequencer;
        active_driver = driver;
        active_monitor = monitor;
      end else begin
        passive_monitor = monitor;
      end
    endfunction
  endclass

  class agent_override extends agent;
    static int build_count;
    `uvm_component_utils(agent_override)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      build_count++;
    endfunction
  endclass

  class agent_environment extends uvmf_environment_base #(agent_environment_configuration);
    agent active_agent;
    agent passive_agent;
    agent_monitor shared_passive_monitor;
    agent_environment_vsqr_t vsqr;
    agent_predictor predictor;
    uvmf_in_order_scoreboard #(agent_item) response_scoreboard;
    `uvm_component_utils(agent_environment)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      active_agent = agent::type_id::create("active_agent", this);
      active_agent.set_config(configuration.active_agent_configuration);
      uvm_config_db #(agent_config)::set(
        this, "shared_passive_monitor", UVMF_AGENT_CONFIG,
        configuration.passive_agent_configuration);
      shared_passive_monitor = agent_monitor::type_id::create(
        "shared_passive_monitor", this);
      uvm_config_db #(agent_monitor)::set(
        this, "passive_agent", "monitor", shared_passive_monitor);
      passive_agent = agent::type_id::create("passive_agent", this);
      passive_agent.set_config(configuration.passive_agent_configuration);
      vsqr = agent_environment_vsqr_t::type_id::create("vsqr", this);
      vsqr.set_config(configuration);
      configuration.set_vsqr(vsqr);
      predictor = agent_predictor::type_id::create("predictor", this);
      response_scoreboard = uvmf_in_order_scoreboard #(agent_item)::type_id::create(
        "response_scoreboard", this);
    endfunction
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      active_agent.monitored_ap.connect(predictor.request_export);
      predictor.expected_ap.connect(response_scoreboard.expected_analysis_export);
      passive_agent.monitored_ap.connect(response_scoreboard.actual_analysis_export);
    endfunction
  endclass

  class agent_sequence extends uvmf_sequence_base #(
    .REQ(agent_item), .RSP(agent_item)
  );
    static int completed_value;
    `uvm_object_utils(agent_sequence)
    function new(string name = "agent_sequence"); super.new(name); endfunction
    virtual task body();
      agent_item item = agent_item::type_id::create("item");
      start_item(item);
      item.value = 41;
      finish_item(item);
      completed_value = item.value;
    endtask
  endclass

  class agent_environment_sequence extends uvmf_virtual_sequence_base #(
    agent_environment_configuration
  );
    `uvm_object_utils(agent_environment_sequence)
    function new(string name = "agent_environment_sequence"); super.new(name); endfunction
    virtual task body();
      agent_sequence sequence_item;
      sequence_item = agent_sequence::type_id::create("sequence_item");
      sequence_item.start(configuration.active_agent_configuration.sequencer);
    endtask
  endclass

  class agent_bench_sequence extends uvmf_sequence_base #(uvm_sequence_item);
    agent_environment_configuration top_configuration;
    agent_config active_agent_configuration;
    agent_config passive_agent_configuration;
    `uvm_object_utils(agent_bench_sequence)
    function new(string name = "agent_bench_sequence");
      super.new(name);
      if (!uvm_config_db #(agent_environment_configuration)::get(
            null, UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG", top_configuration))
        `uvm_fatal("UVMF_TEST_CONFIG", "Bench sequence cannot find TOP_ENV_CONFIG")
      if (!uvm_config_db #(agent_config)::get(
            null, UVMF_CONFIGURATIONS, "input_if", active_agent_configuration))
        `uvm_fatal("UVMF_TEST_CONFIG", "Bench sequence cannot find the input agent configuration")
      if (active_agent_configuration != top_configuration.active_agent_configuration)
        `uvm_fatal("UVMF_TEST_CONFIG", "Top and input config-DB handles do not match")
      if (!uvm_config_db #(agent_config)::get(
            null, UVMF_CONFIGURATIONS, "output_if", passive_agent_configuration))
        `uvm_fatal("UVMF_TEST_CONFIG", "Bench sequence cannot find the output agent configuration")
      if (passive_agent_configuration != top_configuration.passive_agent_configuration)
        `uvm_fatal("UVMF_TEST_CONFIG", "Top and output config-DB handles do not match")
    endfunction
    virtual task body();
      agent_environment_sequence environment_sequence;
      environment_sequence = agent_environment_sequence::type_id::create("environment_sequence");
      environment_sequence.start(top_configuration.vsqr);
    endtask
  endclass

  class agent_test extends uvmf_test_base #(
    agent_environment_configuration, agent_environment, agent_bench_sequence
  );
    agent_observer observer;
    uvm_sequencer #(agent_item) published_sequencer;
    virtual uvmf_lite_driver_bfm_if driver_bfm;
    virtual uvmf_lite_monitor_bfm_if input_monitor_bfm;
    virtual uvmf_lite_monitor_bfm_if output_monitor_bfm;
    string interface_names[];
    uvmf_active_passive_t interface_activity[];
    bit expect_scoreboard_mismatch;
    `uvm_component_utils(agent_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      interface_names = new[2];
      interface_activity = new[2];
      interface_names[0] = "input_if";
      interface_names[1] = "output_if";
      interface_activity[0] = uvmf_base_pkg_hdl::ACTIVE;
      interface_activity[1] = uvmf_base_pkg_hdl::PASSIVE;
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      expect_scoreboard_mismatch = $test$plusargs("BFM_LITE_EXPECT_MISMATCH");
      if (!uvm_config_db #(virtual uvmf_lite_driver_bfm_if)::get(
            null, UVMF_VIRTUAL_INTERFACES, "input_if", driver_bfm) ||
          !uvm_config_db #(virtual uvmf_lite_monitor_bfm_if)::get(
            null, UVMF_VIRTUAL_INTERFACES, "input_if", input_monitor_bfm) ||
          !uvm_config_db #(virtual uvmf_lite_monitor_bfm_if)::get(
            null, UVMF_VIRTUAL_INTERFACES, "output_if", output_monitor_bfm))
        `uvm_fatal("UVMF_TEST_CONFIG", "Top did not register the active and passive BFMs")

      configuration.initialize(NA, "uvm_test_top.environment", interface_names,
                               null, interface_activity);
      observer = agent_observer::type_id::create("observer", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      environment.passive_agent.monitored_ap.connect(observer.analysis_export);
    endfunction

    virtual function void check_phase(uvm_phase phase);
      agent_item base_probe;
      agent_item base_copy;
      uvm_object base_clone;

      super.check_phase(phase);
      base_probe = new("base_probe");
      base_probe.value = 11;
      base_probe.start_time = 64'h1234;
      base_probe.end_time = 64'h5678;
      base_probe.transaction_view_h = 9;
      base_clone = base_probe.clone();
      if (!$cast(base_copy, base_clone) || !base_copy.compare(base_probe) ||
          base_copy.start_time != base_probe.start_time ||
          base_copy.end_time != base_probe.end_time ||
          base_copy.transaction_view_h != base_probe.transaction_view_h)
        `uvm_fatal("UVMF_TXN_BASE", "UVMF transaction clone lost base fields")
      base_copy.start_time++;
      base_copy.end_time++;
      if (!base_copy.compare(base_probe))
        `uvm_fatal("UVMF_TXN_BASE", "Timestamp metadata affected transaction comparison")
      base_copy.value++;
      if (base_copy.compare(base_probe))
        `uvm_fatal("UVMF_TXN_BASE", "Transaction comparison ignored derived fields")

      if (!uvm_config_db #(uvm_sequencer #(agent_item))::get(
            null, UVMF_SEQUENCERS, "input_if", published_sequencer))
        `uvm_fatal("UVMF_AGENT_TEST", "Agent sequencer was not published")
      if (driver_bfm.access_count != 1 || input_monitor_bfm.start_count != 1 ||
          output_monitor_bfm.start_count != 1 ||
          agent_override::build_count != 2 ||
          published_sequencer != configuration.active_agent_configuration.sequencer ||
          environment.passive_agent.sequencer != null ||
          environment.passive_agent.driver != null ||
          environment.passive_agent.monitor != environment.shared_passive_monitor ||
          configuration.active_agent_configuration.initiator_responder !=
            INITIATOR ||
          configuration.passive_agent_configuration.initiator_responder !=
            RESPONDER ||
          agent_sequence::completed_value != 42 ||
          agent_observer::item_count != 1 || agent_observer::last_value != 42 ||
          agent_coverage::sample_count != 1 || agent_coverage::sampled_value != 42 ||
          driver_bfm.proxy != agent::active_driver ||
          input_monitor_bfm.proxy != agent::active_monitor ||
          output_monitor_bfm.proxy != agent::passive_monitor ||
          agent_predictor::request_count != 1 ||
          environment.response_scoreboard.matched_count != (expect_scoreboard_mismatch ? 0 : 1) ||
          environment.response_scoreboard.mismatch_count != (expect_scoreboard_mismatch ? 1 : 0) ||
          environment.response_scoreboard.pending_expected_count != 0 ||
          environment.response_scoreboard.pending_actual_count != 0)
        `uvm_fatal("UVMF_AGENT_TEST", $sformatf(
          "path failed: access=%0d input_monitor=%0d output_monitor=%0d sequenced=%0d observed_count=%0d observed=%0d coverage_count=%0d coverage_value=%0d predictor=%0d matched=%0d mismatched=%0d pending_expected=%0d pending_actual=%0d active_driver_proxy=%0b input_monitor_proxy=%0b output_monitor_proxy=%0b",
          driver_bfm.access_count, input_monitor_bfm.start_count, output_monitor_bfm.start_count,
          agent_sequence::completed_value,
          agent_observer::item_count, agent_observer::last_value,
          agent_coverage::sample_count, agent_coverage::sampled_value,
          agent_predictor::request_count,
          environment.response_scoreboard.matched_count,
          environment.response_scoreboard.mismatch_count,
          environment.response_scoreboard.pending_expected_count,
          environment.response_scoreboard.pending_actual_count,
          driver_bfm.proxy == agent::active_driver,
          input_monitor_bfm.proxy == agent::active_monitor,
          output_monitor_bfm.proxy == agent::passive_monitor))
      `uvm_info("UVMF_AGENT_TEST", "PASS: active/passive factory BFM path and scoreboard control", UVM_LOW)
    endfunction
  endclass
endpackage

module tb_uvmf_agent;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import uvmf_lite_agent_test_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;
  uvmf_lite_toy_dut_if toy_bus(clk);
  uvmf_lite_driver_bfm_if input_driver_bfm(toy_bus);
  uvmf_lite_monitor_bfm_if input_monitor_bfm(toy_bus);
  uvmf_lite_monitor_bfm_if output_monitor_bfm(toy_bus);

  uvmf_lite_toy_dut dut(
    .request_valid(toy_bus.request_valid),
    .request_value(toy_bus.request_value),
    .response_valid(toy_bus.response_valid),
    .response_value(toy_bus.response_value)
  );

  initial begin
    agent::type_id::set_type_override(agent_override::get_type());
    uvm_config_db #(virtual uvmf_lite_driver_bfm_if)::set(
      null, UVMF_VIRTUAL_INTERFACES, "input_if", input_driver_bfm);
    uvm_config_db #(virtual uvmf_lite_monitor_bfm_if)::set(
      null, UVMF_VIRTUAL_INTERFACES, "input_if", input_monitor_bfm);
    uvm_config_db #(virtual uvmf_lite_monitor_bfm_if)::set(
      null, UVMF_VIRTUAL_INTERFACES, "output_if", output_monitor_bfm);
    run_test("agent_test");
  end
endmodule
