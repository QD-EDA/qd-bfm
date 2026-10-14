// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_caliptra_ecc_ahb_uvm_bfm;
  import uvm_pkg::*;
  import mvc_pkg::*;
  import mgc_ahb_v2_0_pkg::*;
  import qvip_ahb_lite_slave_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;
  import kv_defines_pkg::*;

  reg HCLK = 0;
  reg HRESETn = 0;
  wire HSEL, HWRITE, HRESP, HREADY, HREADYOUT;
  wire [31:0] HADDR, HWDATA, HRDATA;
  wire [2:0] HSIZE;
  wire [1:0] HTRANS;
  wire checker_error, monitor_protocol_error;
  wire [3:0] checker_error_code;
  wire [31:0] checker_error_count, monitor_protocol_error_count;
  wire [31:0] address_count, transfer_count;
  wire transfer_fire, transfer_write, transfer_error;
  wire [31:0] transfer_addr, transfer_data;
  kv_read_t [1:0] kv_read;
  kv_write_t kv_write;
  kv_rd_resp_t [1:0] kv_rd_resp = '0;
  kv_wr_resp_t kv_wr_resp = '0;
  pcr_signing_t pcr_signing_data = '0;

  ahb_lite_caliptra_master_cmd_if cmd_if(HCLK);
  ahb_lite_caliptra_record_if record_if(HCLK);

  assign cmd_if.HRESETn = HRESETn;
  assign HREADY = HREADYOUT;
  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_uvm_master_proxy #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) master_proxy (
    .cmd_if(cmd_if), .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADY),
    .HRESP(HRESP), .HRDATA(HRDATA), .HSEL(HSEL), .HADDR(HADDR),
    .HWDATA(HWDATA), .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS)
  );

  ahb_lite_caliptra_checker #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) checker_bfm (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADY), .HRESP(HRESP), .error(checker_error),
    .error_code(checker_error_code), .error_count(checker_error_count)
  );

  ahb_lite_caliptra_pin_monitor_adapter #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) monitor_adapter (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADY), .HRESP(HRESP), .HRDATA(HRDATA), .record_if(record_if)
  );

  ecc_top #(.AHB_ADDR_WIDTH(32), .AHB_DATA_WIDTH(32)) dut (
    .clk(HCLK), .reset_n(HRESETn), .cptra_pwrgood(1'b1),
    .haddr_i(HADDR), .hwdata_i(HWDATA), .hsel_i(HSEL), .hwrite_i(HWRITE),
    .hready_i(HREADY), .htrans_i(HTRANS), .hsize_i(HSIZE),
    .hresp_o(HRESP), .hreadyout_o(HREADYOUT), .hrdata_o(HRDATA),
    .kv_read(kv_read), .kv_write(kv_write), .kv_rd_resp(kv_rd_resp),
    .kv_wr_resp(kv_wr_resp), .pcr_signing_data(pcr_signing_data),
    .ocp_lock_in_progress(1'b0), .busy_o(), .error_intr(), .notif_intr(),
    .debugUnlock_or_scan_mode_switch(1'b0)
  );

  class ecc_ahb_monitor_subscriber extends uvm_subscriber #(ahb_lite_caliptra_transaction);
    int unsigned write_count;
    int unsigned read_count;
    bit [31:0] expected_data = 32'h1;

    `uvm_component_utils(ecc_ahb_monitor_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(ahb_lite_caliptra_transaction item);
      if (item.protocol_error || item.error)
        `uvm_fatal("ECC_AHB_MON", $sformatf("Unexpected AHB response: %s", item.convert2string()))
      if (item.address != 32'h0000_0804 || item.trans != 2'b10 || item.size != 2 ||
          item.data[31:0] != expected_data || item.data[63:32] != 0)
        `uvm_fatal("ECC_AHB_RECORD", $sformatf("Unexpected ECC CSR record: %s", item.convert2string()))
      if (item.write)
        write_count++;
      else
        read_count++;
    endfunction
  endclass

  class ecc_ahb_env extends uvm_env;
    ahb_lite_caliptra_qvip_compat_agent agent;
    ecc_ahb_monitor_subscriber observer;

    `uvm_component_utils(ecc_ahb_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = ahb_lite_caliptra_qvip_compat_agent::type_id::create("agent", this);
      agent.is_active = UVM_ACTIVE;
      observer = ecc_ahb_monitor_subscriber::type_id::create("observer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.agent.ap.connect(observer.analysis_export);
    endfunction
  endclass

  class ecc_ahb_smoke_reg extends uvm_reg;
    uvm_reg_field value;
    `uvm_object_utils(ecc_ahb_smoke_reg)

    function new(string name = "ecc_ahb_smoke_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      value = uvm_reg_field::type_id::create("value");
      value.configure(this, 32, 0, "RW", 0, 0, 1, 0, 0);
    endfunction
  endclass

  class ecc_ahb_smoke_block extends uvm_reg_block;
    ecc_ahb_smoke_reg intr_enable;
    `uvm_object_utils(ecc_ahb_smoke_block)

    function new(string name = "ecc_ahb_smoke_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN, 1);
      intr_enable = ecc_ahb_smoke_reg::type_id::create("intr_enable");
      intr_enable.configure(this);
      intr_enable.build();
      default_map.add_reg(intr_enable, 32'h0000_0804, "RW");
      lock_model();
    endfunction
  endclass

  class ecc_ahb_rw_sequence extends uvm_sequence #(mvc_sequence_item_base);
    `uvm_object_utils(ecc_ahb_rw_sequence)

    function new(string name = "ecc_ahb_rw_sequence");
      super.new(name);
    endfunction

    task body();
      ahb_lite_caliptra_mvc_transfer request;

      request = new("enable_interrupts");
      start_item(request);
      request.RnW = AHB_WRITE;
      request.address = 32'h0000_0804;
      request.size = 2;
      request.data.push_back(64'h1);
      finish_item(request);
      if (request.resp.size() != 1 || request.resp[0] != AHB_OKAY)
        `uvm_fatal("ECC_AHB_WRITE", "UVM AHB write to ECC interrupt-enable CSR failed")

      request = new("read_interrupt_enable");
      start_item(request);
      request.RnW = AHB_READ;
      request.address = 32'h0000_0804;
      request.size = 2;
      request.data.push_back(64'b0);
      finish_item(request);
      if (request.resp.size() != 1 || request.resp[0] != AHB_OKAY ||
          request.data.size() != 1 || request.data[0] != 64'h1)
        `uvm_fatal("ECC_AHB_READ", "UVM AHB readback from ECC interrupt-enable CSR failed")
    endtask
  endclass

  class ecc_ahb_uvm_test extends uvm_test;
    ecc_ahb_env env;
    ecc_ahb_smoke_block ral_model;
    ahb_lite_caliptra_reg_adapter ral_adapter;
    ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer) ral_predictor;

    `uvm_component_utils(ecc_ahb_uvm_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = ecc_ahb_env::type_id::create("env", this);
      ral_model = ecc_ahb_smoke_block::type_id::create("ral_model");
      ral_model.build();
      ral_adapter = ahb_lite_caliptra_reg_adapter::type_id::create("ral_adapter");
      ral_adapter.set_bus_data_width(32);
      ral_predictor = ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer)::type_id::create(
        "ral_predictor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      ral_model.default_map.set_sequencer(env.agent.m_sequencer, ral_adapter);
      ral_model.default_map.set_auto_predict(0);
      if (!$test$plusargs("AHB_NO_RAL_PREDICTOR"))
        env.agent.agent.burst_transfer_ap.connect(ral_predictor.bus_item_export);
      ral_predictor.map = ral_model.default_map;
      ral_predictor.adapter = ral_adapter;
    endfunction

    task run_phase(uvm_phase phase);
      ecc_ahb_rw_sequence rw_seq;
      uvm_status_e status;
      uvm_reg_data_t value;
      phase.raise_objection(this);
      rw_seq = ecc_ahb_rw_sequence::type_id::create("rw_seq");
      rw_seq.start(env.agent.m_sequencer);
      wait (env.observer.write_count == 1 && env.observer.read_count == 1);
      repeat (2) @(negedge HCLK);
      if (ral_model.intr_enable.get_mirrored_value() !== 32'h1)
        `uvm_fatal("ECC_AHB_RAL_PREDICT",
          "Observed ECC AHB write did not update the register mirror")
      env.observer.expected_data = 32'h0;
      ral_model.intr_enable.write(status, 32'h0, UVM_FRONTDOOR, ral_model.default_map);
      if (status != UVM_IS_OK)
        `uvm_fatal("ECC_AHB_RAL_WRITE", "RAL frontdoor write to ECC interrupt-enable CSR failed")
      ral_model.intr_enable.read(status, value, UVM_FRONTDOOR, ral_model.default_map);
      if (status != UVM_IS_OK || value != 32'h0)
        `uvm_fatal("ECC_AHB_RAL_READ", $sformatf("RAL ECC CSR readback failed status=%s value=%08h", status.name(), value))
      fork
        begin
          wait (env.observer.write_count == 2 && env.observer.read_count == 2);
        end
        begin
          #2000;
          `uvm_fatal("ECC_AHB_TIMEOUT", "Timed out waiting for ECC AHB monitor records")
        end
      join_any
      disable fork;
      if (ral_model.intr_enable.get_mirrored_value() !== 32'h0)
        `uvm_fatal("ECC_AHB_RAL_PREDICT",
          "Observed RAL write/read traffic did not update the register mirror")
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::set(
      null, "uvm_test_top.env.agent.mvc_driver", "cmd_vif", cmd_if);
    uvm_config_db#(virtual ahb_lite_caliptra_record_if)::set(
      null, "uvm_test_top.env.agent.agent.monitor", "vif", record_if);
    run_test("ecc_ahb_uvm_test");
  end

  final begin
    if (checker_error || checker_error_count != 0 || monitor_protocol_error ||
        monitor_protocol_error_count != 0 || address_count != 4 || transfer_count != 4 ||
        transfer_write || transfer_error || transfer_addr != 32'h0000_0804 ||
        transfer_data != 32'h1)
      $fatal(1, "Caliptra ECC AHB UVM checker/monitor did not report two clean transfers");
    if (!$test$plusargs("AHB_NO_RAL_PREDICTOR"))
      $display("PASS: Caliptra ECC RTL AHB write/readback through native UVM agent");
    $finish;
  end

  initial begin
    repeat (4) @(posedge HCLK);
    @(negedge HCLK);
    HRESETn = 1;
  end
endmodule
