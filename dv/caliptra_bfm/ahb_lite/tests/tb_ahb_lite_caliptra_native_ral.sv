// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_ahb_lite_caliptra_native_ral;
  import uvm_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;
  import qvip_ahb_lite_slave_pkg::*;

`ifdef CALIPTRA_BFM_AHB_32BIT
  localparam integer DATA_WIDTH = 32;
`else
  localparam integer DATA_WIDTH = 64;
`endif
  localparam integer BUS_BYTES = DATA_WIDTH / 8;
  localparam [31:0] BYTE_ADDRESS = BUS_BYTES - 1;
  localparam [31:0] HALFWORD_ADDRESS = BUS_BYTES - 2;

  reg HCLK = 0;
  reg HRESETn = 0;
  wire HSEL, HWRITE, HRESP, HREADY, HREADYOUT;
  wire [31:0] HADDR;
  wire [DATA_WIDTH-1:0] HWDATA, HRDATA;
  wire [2:0] HSIZE;
  wire [1:0] HTRANS;
  ahb_lite_caliptra_master_cmd_if cmd_if(HCLK);
  ahb_lite_caliptra_record_if record_if(HCLK);

  assign cmd_if.HRESETn = HRESETn;
  assign HREADY = HREADYOUT;
  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_uvm_master_proxy #(.DATA_WIDTH(DATA_WIDTH)) master_proxy (
    .cmd_if(cmd_if), .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADY),
    .HRESP(HRESP), .HRDATA(HRDATA), .HSEL(HSEL), .HADDR(HADDR),
    .HWDATA(HWDATA), .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS)
  );

  ahb_lite_caliptra_memory_subordinate #(
    .ADDR_WIDTH(32), .DATA_WIDTH(DATA_WIDTH), .MEMORY_BYTES(256)
  ) memory (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADY), .wait_cycles(cmd_if.target_wait_cycles),
    .inject_error(cmd_if.inject_target_error), .HREADYOUT(HREADYOUT),
    .HRESP(HRESP), .HRDATA(HRDATA)
  );

  ahb_lite_caliptra_pin_monitor_adapter #(.ADDR_WIDTH(32), .DATA_WIDTH(DATA_WIDTH)) monitor_adapter (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADY), .HRESP(HRESP), .HRDATA(HRDATA), .record_if(record_if)
  );

  class native_ral_observer extends uvm_subscriber #(ahb_lite_caliptra_transaction);
    int unsigned transfer_count;
    int unsigned write_count;
    int unsigned read_count;
    int unsigned error_count;
    `uvm_component_utils(native_ral_observer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(ahb_lite_caliptra_transaction item);
      transfer_count++;
      if (item.protocol_error)
        `uvm_fatal("AHB_NATIVE_RAL_MON", "Monitor marked legal native RAL traffic malformed")
      if (item.error) begin
        error_count++;
        if (item.address != BYTE_ADDRESS || item.write || item.size != 0)
          `uvm_fatal("AHB_NATIVE_RAL_ERROR", "Unexpected AHB error transfer")
      end else if (item.write) begin
        write_count++;
        if (item.address == BYTE_ADDRESS &&
            (item.size != 0 || item.data[BYTE_ADDRESS*8 +: 8] != 8'h5a))
          `uvm_fatal("AHB_NATIVE_RAL_BYTE", "Byte write did not use the highest bus lane")
        if (item.address == HALFWORD_ADDRESS &&
            (item.size != 1 || item.data[HALFWORD_ADDRESS*8 +: 16] != 16'hcafe))
          `uvm_fatal("AHB_NATIVE_RAL_HALF", "Halfword write did not use the top two bus lanes")
      end else begin
        read_count++;
      end
    endfunction
  endclass

  class native_ral_reg extends uvm_reg;
    int unsigned width;
    uvm_reg_field value;
    `uvm_object_utils(native_ral_reg)

    function new(string name = "native_ral_reg", int unsigned n_bits = 32);
      super.new(name, n_bits, UVM_NO_COVERAGE);
      width = n_bits;
    endfunction

    virtual function void build();
      value = uvm_reg_field::type_id::create("value");
      value.configure(this, width, 0, "RW", 0, 0, 1, 0, 0);
    endfunction
  endclass

  class native_ral_block extends uvm_reg_block;
    native_ral_reg byte_reg;
    native_ral_reg halfword_reg;
    `uvm_object_utils(native_ral_block)

    function new(string name = "native_ral_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      default_map = create_map("default_map", 0, BUS_BYTES, UVM_LITTLE_ENDIAN, 1);
      byte_reg = new("byte_reg", 8);
      byte_reg.configure(this);
      byte_reg.build();
      default_map.add_reg(byte_reg, BYTE_ADDRESS, "RW");
      halfword_reg = new("halfword_reg", 16);
      halfword_reg.configure(this);
      halfword_reg.build();
      default_map.add_reg(halfword_reg, HALFWORD_ADDRESS, "RW");
      lock_model();
    endfunction
  endclass

  class native_ral_smoke_test extends uvm_test;
    ahb_lite_caliptra_agent agent;
    ahb_lite_caliptra_native_reg_adapter adapter;
    ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer) predictor;
    native_ral_observer observer;
    native_ral_block ral_model;
    `uvm_component_utils(native_ral_smoke_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = ahb_lite_caliptra_agent::type_id::create("agent", this);
      agent.is_active = UVM_ACTIVE;
      adapter = ahb_lite_caliptra_native_reg_adapter::type_id::create("adapter");
      adapter.set_bus_data_width(DATA_WIDTH);
      predictor = ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer)::type_id::create(
        "predictor", this);
      observer = native_ral_observer::type_id::create("observer", this);
      ral_model = native_ral_block::type_id::create("ral_model");
      ral_model.build();
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.ap.connect(observer.analysis_export);
      agent.burst_transfer_ap.connect(predictor.bus_item_export);
      predictor.map = ral_model.default_map;
      predictor.adapter = adapter;
      ral_model.default_map.set_sequencer(agent.sequencer, adapter);
      ral_model.default_map.set_auto_predict(0);
    endfunction

    task run_phase(uvm_phase phase);
      uvm_status_e status;
      uvm_reg_data_t read_value;
      phase.raise_objection(this);

      ral_model.byte_reg.write(status, 8'h5a, UVM_FRONTDOOR, ral_model.default_map);
      if (status != UVM_IS_OK)
        `uvm_fatal("AHB_NATIVE_RAL_BYTE_WRITE", "Native RAL byte write failed")
      ral_model.byte_reg.read(status, read_value, UVM_FRONTDOOR, ral_model.default_map);
      if (status != UVM_IS_OK || read_value[7:0] != 8'h5a)
        `uvm_fatal("AHB_NATIVE_RAL_BYTE_READ", "Native RAL byte readback failed")

      ral_model.halfword_reg.write(status, 16'hcafe, UVM_FRONTDOOR, ral_model.default_map);
      if (status != UVM_IS_OK)
        `uvm_fatal("AHB_NATIVE_RAL_HALF_WRITE", "Native RAL halfword write failed")
      ral_model.halfword_reg.read(status, read_value, UVM_FRONTDOOR, ral_model.default_map);
      if (status != UVM_IS_OK || read_value[15:0] != 16'hcafe)
        `uvm_fatal("AHB_NATIVE_RAL_HALF_READ", "Native RAL halfword readback failed")

      agent.driver.cmd_vif.inject_target_error = 1;
      ral_model.byte_reg.read(status, read_value, UVM_FRONTDOOR, ral_model.default_map);
      agent.driver.cmd_vif.inject_target_error = 0;
      if (status != UVM_NOT_OK)
        `uvm_fatal("AHB_NATIVE_RAL_ERROR", "Native RAL read accepted an injected AHB ERROR")

      fork
        begin
          wait (observer.transfer_count == 5);
        end
        begin
          #2000;
          `uvm_fatal("AHB_NATIVE_RAL_TIMEOUT", "Timed out waiting for native AHB RAL monitor records")
        end
      join_any
      disable fork;
      if (observer.transfer_count != 5 || observer.write_count != 2 ||
          observer.read_count != 2 || observer.error_count != 1)
        `uvm_fatal("AHB_NATIVE_RAL_COUNT", $sformatf(
          "Native AHB counts: transfers=%0d writes=%0d successful reads=%0d errors=%0d",
          observer.transfer_count, observer.write_count, observer.read_count,
          observer.error_count))
      if (ral_model.byte_reg.get_mirrored_value() !== 8'h5a ||
          ral_model.halfword_reg.get_mirrored_value() !== 16'hcafe)
        `uvm_fatal("AHB_NATIVE_RAL_PREDICT", "Monitor prediction did not update subword RAL mirrors")
      $display("PASS: native AHB RAL byte/halfword frontdoors, monitor prediction, and ERROR status");
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::set(
      null, "uvm_test_top.agent.driver", "cmd_vif", cmd_if);
    uvm_config_db#(virtual ahb_lite_caliptra_record_if)::set(
      null, "uvm_test_top.agent.monitor", "vif", record_if);
    run_test("native_ral_smoke_test");
  end

  initial begin
    repeat (4) @(posedge HCLK);
    @(negedge HCLK);
    HRESETn = 1;
  end
endmodule
