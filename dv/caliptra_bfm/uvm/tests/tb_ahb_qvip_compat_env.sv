// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_ahb_qvip_compat_env;
  import uvm_pkg::*;
  import mvc_pkg::*;
  import mgc_ahb_v2_0_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;
  import qvip_ahb_lite_slave_params_pkg::*;
  import qvip_ahb_lite_slave_pkg::*;
  import uvmf_base_pkg::*;

  reg HCLK = 0;
  reg HRESETn = 0;
  wire [7:0] wait_cycles;
  wire inject_error;

  hdl_qvip_ahb_lite_slave #(
    .UNIQUE_ID("uvm_test_top.qvip_ahb_lite_slave_subenv."),
    .AHB_LITE_SLAVE_0_ACTIVE(1),
    .EXT_CLK_RESET(1)
  ) qvip_hdl();
  assign qvip_hdl.default_clk_gen_CLK = HCLK;
  assign qvip_hdl.default_reset_gen_RESET = HRESETn;
  assign wait_cycles = qvip_hdl.ahb_lite_slave_0_command_bfm.target_wait_cycles;
  assign inject_error = qvip_hdl.ahb_lite_slave_0_command_bfm.inject_target_error;

  hdl_qvip_ahb_lite_slave #(
    .UNIQUE_ID("uvm_test_top.passive_qvip_ahb_lite_slave_subenv."),
    .AHB_LITE_SLAVE_0_ACTIVE(0),
    .EXT_CLK_RESET(1)
  ) passive_qvip_hdl();
  assign passive_qvip_hdl.default_clk_gen_CLK = HCLK;
  assign passive_qvip_hdl.default_reset_gen_RESET = HRESETn;
  assign passive_qvip_hdl.ahb_lite_slave_0_HADDR = qvip_hdl.ahb_lite_slave_0_HADDR;
  assign passive_qvip_hdl.ahb_lite_slave_0_HTRANS = qvip_hdl.ahb_lite_slave_0_HTRANS;
  assign passive_qvip_hdl.ahb_lite_slave_0_HWRITE = qvip_hdl.ahb_lite_slave_0_HWRITE;
  assign passive_qvip_hdl.ahb_lite_slave_0_HSIZE = qvip_hdl.ahb_lite_slave_0_HSIZE;
  assign passive_qvip_hdl.ahb_lite_slave_0_HWDATA = qvip_hdl.ahb_lite_slave_0_HWDATA;
  assign passive_qvip_hdl.ahb_lite_slave_0_HREADY = qvip_hdl.ahb_lite_slave_0_HREADY;
  assign passive_qvip_hdl.ahb_lite_slave_0_HRESP = qvip_hdl.ahb_lite_slave_0_HRESP;
  assign passive_qvip_hdl.ahb_lite_slave_0_HRDATA = qvip_hdl.ahb_lite_slave_0_HRDATA;
  assign passive_qvip_hdl.ahb_lite_slave_0_HSEL = qvip_hdl.ahb_lite_slave_0_HSEL;
  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_memory_subordinate #(
    .ADDR_WIDTH(32), .DATA_WIDTH(AHB_MVC_DATA_WIDTH), .MEMORY_BYTES(65536)
  ) memory (
    .HCLK(HCLK), .HRESETn(HRESETn),
    .HADDR(qvip_hdl.ahb_lite_slave_0_HADDR),
    .HWDATA(qvip_hdl.ahb_lite_slave_0_HWDATA),
    .HSEL(qvip_hdl.ahb_lite_slave_0_HSEL),
    .HWRITE(qvip_hdl.ahb_lite_slave_0_HWRITE),
    .HTRANS(qvip_hdl.ahb_lite_slave_0_HTRANS),
    .HSIZE(qvip_hdl.ahb_lite_slave_0_HSIZE),
    .HREADY(qvip_hdl.ahb_lite_slave_0_HREADYOUT),
    .wait_cycles(wait_cycles), .inject_error(inject_error),
    .HREADYOUT(qvip_hdl.ahb_lite_slave_0_HREADY),
    .HRESP(qvip_hdl.ahb_lite_slave_0_HRESP),
    .HRDATA(qvip_hdl.ahb_lite_slave_0_HRDATA)
  );

  class ahb_qvip_stream_sink extends uvm_subscriber #(mvc_sequence_item_base);
    ahb_lite_caliptra_mvc_transfer last_item;
    int unsigned write_count;
    int unsigned read_count;
    int unsigned burst_write_count;
    int unsigned burst_read_count;

    `uvm_component_utils(ahb_qvip_stream_sink)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(mvc_sequence_item_base base_item);
      if (!$cast(last_item, base_item))
        `uvm_fatal("AHB_QVIP_SINK_TYPE", $sformatf("Got %s instead of the Caliptra AHB item", base_item.get_type_name()))
      if (last_item.data.size() < 1 || last_item.data.size() > AHB_MVC_MAX_BURST_BEATS ||
          last_item.resp.size() != last_item.data.size())
        `uvm_fatal("AHB_QVIP_SINK_ITEM", $sformatf("Unexpected AHB stream item: %s", last_item.convert2string()))
      if (last_item.address == 32'h20) begin
        if (last_item.data.size() != 1 || last_item.size != AHB_MVC_WORD_SIZE ||
            last_item.resp[0] != AHB_OKAY)
          `uvm_fatal("AHB_QVIP_SINK_ITEM", "Unexpected scalar AHB item")
        if (last_item.RnW == AHB_WRITE) begin
          write_count++;
          if (last_item.data[0] != (64'h1122_3344_5566_7788 & AHB_MVC_DATA_MASK))
            `uvm_fatal("AHB_QVIP_SINK_WRITE", "Generated-name stream lost AHB write data")
        end else begin
          read_count++;
          if (last_item.data[0] != (64'h1122_3344_5566_7788 & AHB_MVC_DATA_MASK))
            `uvm_fatal("AHB_QVIP_SINK_READ", "Generated-name stream lost AHB read data")
        end
      end else if (last_item.address == 32'h80) begin
        if (last_item.data.size() != 4 || last_item.size != AHB_MVC_WORD_SIZE ||
            last_item.resp[0] != AHB_OKAY || last_item.resp[1] != AHB_OKAY ||
            last_item.resp[2] != AHB_OKAY || last_item.resp[3] != AHB_OKAY ||
            last_item.data[0] != (64'h0102_0304_0506_0708 & AHB_MVC_DATA_MASK) ||
            last_item.data[1] != (64'h1112_1314_1516_1718 & AHB_MVC_DATA_MASK) ||
            last_item.data[2] != (64'h2122_2324_2526_2728 & AHB_MVC_DATA_MASK) ||
            last_item.data[3] != (64'h3132_3334_3536_3738 & AHB_MVC_DATA_MASK))
          `uvm_fatal("AHB_QVIP_SINK_BURST", "Generated-name stream lost the four-beat AHB burst")
        if (last_item.RnW == AHB_WRITE) begin
          write_count++;
          burst_write_count++;
        end else begin
          read_count++;
          burst_read_count++;
        end
      end else begin
        `uvm_fatal("AHB_QVIP_SINK_ADDRESS", $sformatf("Unexpected AHB address %h", last_item.address))
      end
    endfunction
  endclass

  class ahb_qvip_compat_test extends uvm_test;
    qvip_ahb_lite_slave_env_configuration configuration;
    qvip_ahb_lite_slave_env_configuration passive_configuration;
    qvip_ahb_lite_slave_environment#() qvip_ahb_lite_slave_subenv;
    qvip_ahb_lite_slave_environment#() passive_qvip_ahb_lite_slave_subenv;
    ahb_qvip_stream_sink predictor_sink;
    ahb_qvip_stream_sink scoreboard_sink;
    ahb_qvip_stream_sink coverage_sink;
    ahb_qvip_stream_sink passive_sink;

    `uvm_component_utils(ahb_qvip_compat_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      string interface_names[1];
      string passive_interface_names[1];
      uvmf_active_passive_t interface_activity[1];
      uvmf_active_passive_t passive_interface_activity[1];
      super.build_phase(phase);

      configuration = qvip_ahb_lite_slave_env_configuration::type_id::create(
        "qvip_ahb_lite_slave_subenv_config");
      interface_names[0] = "uvm_test_top.qvip_ahb_lite_slave_subenv.ahb_lite_slave_0";
      interface_activity[0] = ACTIVE;
      configuration.initialize(NA, "uvm_test_top.qvip_ahb_lite_slave_subenv",
                               interface_names, null, interface_activity);

      configuration.ahb_lite_slave_0_cfg.agent_cfg.en_cvg.slave = 1'b1;
      configuration.ahb_lite_slave_0_cfg.agent_cfg.en_cvg.master = 1'b1;
      configuration.ahb_lite_slave_0_cfg.agent_cfg.en_cvg.response = 1'b1;
      void'(configuration.ahb_lite_slave_0_cfg.set_monitor_item(
        "burst_transfer_sb",
        ahb_master_burst_transfer #(
          ahb_lite_slave_0_params::AHB_NUM_MASTERS,
          ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,
          ahb_lite_slave_0_params::AHB_NUM_SLAVES,
          ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,
          ahb_lite_slave_0_params::AHB_WDATA_WIDTH,
          ahb_lite_slave_0_params::AHB_RDATA_WIDTH)::type_id::get()));
      void'(configuration.ahb_lite_slave_0_cfg.set_monitor_item(
        "burst_transfer_cov",
        ahb_master_burst_transfer #(
          ahb_lite_slave_0_params::AHB_NUM_MASTERS,
          ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,
          ahb_lite_slave_0_params::AHB_NUM_SLAVES,
          ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,
          ahb_lite_slave_0_params::AHB_WDATA_WIDTH,
          ahb_lite_slave_0_params::AHB_RDATA_WIDTH)::type_id::get()));

      passive_configuration = qvip_ahb_lite_slave_env_configuration::type_id::create(
        "passive_qvip_ahb_lite_slave_subenv_config");
      passive_interface_names[0] =
        "uvm_test_top.passive_qvip_ahb_lite_slave_subenv.ahb_lite_slave_0";
      passive_interface_activity[0] = PASSIVE;
      passive_configuration.initialize(NA,
        "uvm_test_top.passive_qvip_ahb_lite_slave_subenv",
        passive_interface_names, null, passive_interface_activity);
      void'(passive_configuration.ahb_lite_slave_0_cfg.set_monitor_item(
        "burst_transfer_sb",
        ahb_master_burst_transfer #(
          ahb_lite_slave_0_params::AHB_NUM_MASTERS,
          ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,
          ahb_lite_slave_0_params::AHB_NUM_SLAVES,
          ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,
          ahb_lite_slave_0_params::AHB_WDATA_WIDTH,
          ahb_lite_slave_0_params::AHB_RDATA_WIDTH)::type_id::get()));
      void'(passive_configuration.ahb_lite_slave_0_cfg.set_monitor_item(
        "burst_transfer_cov",
        ahb_master_burst_transfer #(
          ahb_lite_slave_0_params::AHB_NUM_MASTERS,
          ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,
          ahb_lite_slave_0_params::AHB_NUM_SLAVES,
          ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,
          ahb_lite_slave_0_params::AHB_WDATA_WIDTH,
          ahb_lite_slave_0_params::AHB_RDATA_WIDTH)::type_id::get()));

      qvip_ahb_lite_slave_subenv = qvip_ahb_lite_slave_environment#()::type_id::create(
        "qvip_ahb_lite_slave_subenv", this);
      qvip_ahb_lite_slave_subenv.set_config(configuration);
      passive_qvip_ahb_lite_slave_subenv = qvip_ahb_lite_slave_environment#()::type_id::create(
        "passive_qvip_ahb_lite_slave_subenv", this);
      passive_qvip_ahb_lite_slave_subenv.set_config(passive_configuration);
      predictor_sink = ahb_qvip_stream_sink::type_id::create("predictor_sink", this);
      scoreboard_sink = ahb_qvip_stream_sink::type_id::create("scoreboard_sink", this);
      coverage_sink = ahb_qvip_stream_sink::type_id::create("coverage_sink", this);
      passive_sink = ahb_qvip_stream_sink::type_id::create("passive_sink", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.ap["burst_transfer"].connect(
        predictor_sink.analysis_export);
      qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.ap["burst_transfer_sb"].connect(
        scoreboard_sink.analysis_export);
      qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.ap["burst_transfer_cov"].connect(
        coverage_sink.analysis_export);
      passive_qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.ap["burst_transfer"].connect(
        passive_sink.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
      ahb_lite_caliptra_smoke_sequence smoke_seq;
      ahb_rnw_e direction_probe;
      phase.raise_objection(this);
      direction_probe = AHB_READ;
      if (direction_probe != AHB_READ)
        `uvm_fatal("AHB_QVIP_RNW", "AHB_READ enum value did not preserve its type/value")
      direction_probe = AHB_WRITE;
      if (direction_probe != AHB_WRITE)
        `uvm_fatal("AHB_QVIP_RNW", "AHB_WRITE enum value did not preserve its type/value")
      wait (HRESETn === 1'b1);
      qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.mvc_driver.cmd_vif.target_wait_cycles = 2;
      smoke_seq = ahb_lite_caliptra_smoke_sequence::type_id::create("smoke_seq");
      smoke_seq.start(qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.m_sequencer);

      if (predictor_sink.write_count != 2 || predictor_sink.read_count != 2 ||
          predictor_sink.burst_write_count != 1 || predictor_sink.burst_read_count != 1 ||
          scoreboard_sink.write_count != 2 || scoreboard_sink.read_count != 2 ||
          scoreboard_sink.burst_write_count != 1 || scoreboard_sink.burst_read_count != 1 ||
          coverage_sink.write_count != 2 || coverage_sink.read_count != 2 ||
          coverage_sink.burst_write_count != 1 || coverage_sink.burst_read_count != 1)
        `uvm_fatal("AHB_QVIP_COUNTS", "Generated-name analysis streams missed AHB read/write items")
      if (predictor_sink.last_item == scoreboard_sink.last_item ||
          predictor_sink.last_item == coverage_sink.last_item ||
          scoreboard_sink.last_item == coverage_sink.last_item)
        `uvm_fatal("AHB_QVIP_ALIAS", "QVIP-compatible analysis streams shared a mutable item")
      if (passive_sink.write_count != 2 || passive_sink.read_count != 2 ||
          passive_sink.burst_write_count != 1 || passive_sink.burst_read_count != 1)
        `uvm_fatal("AHB_QVIP_PASSIVE", "Passive generated-name monitor missed the bus traffic")
      if (qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.m_sequencer == null)
        `uvm_fatal("AHB_QVIP_SEQUENCER", "Generated-name environment did not create m_sequencer")
      if (passive_qvip_ahb_lite_slave_subenv.ahb_lite_slave_0.m_sequencer != null)
        `uvm_fatal("AHB_QVIP_PASSIVE", "Passive generated-name environment unexpectedly created m_sequencer")
      $display("PASS: generated-name AHB QVIP configuration, environment, sequencer, and analysis streams");
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    #1;
    run_test("ahb_qvip_compat_test");
  end

  initial begin
    repeat (2) @(posedge HCLK);
    @(negedge HCLK);
    HRESETn = 1;
  end
endmodule
