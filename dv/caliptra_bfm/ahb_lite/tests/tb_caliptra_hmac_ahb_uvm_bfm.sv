// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "caliptra_reg_defines.svh"
`include "caliptra_reg_field_defines.svh"
`include "kv_macros.svh"

module tb_caliptra_hmac_ahb_uvm_bfm;
  import uvm_pkg::*;
  import mvc_pkg::*;
  import mgc_ahb_v2_0_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;
  import qvip_ahb_lite_slave_pkg::*;
  import kv_defines_pkg::*;

  localparam [511:0] TEST_KEY = {4{128'h0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b}};
  localparam [1023:0] TEST_BLOCK = 1024'h4869205468657265800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000440;
  localparam [511:0] EXPECTED_TAG = 512'h637edc6e01dce7e6742a99451aae82df23da3e92439e590e43e761b33e910fb8ac2878ebd5803f6f0b61dbce5e251ff8789a4722c1be65aea45fd464e89f8f5b;
  localparam [383:0] TEST_KEY_384 = {48{8'h0b}};
  localparam [511:0] TEST_KEY_384_PADDED = {TEST_KEY_384, 128'b0};
  localparam [511:0] EXPECTED_TAG_384 = {384'hb6a8d5636f5c6a7224f9977dcf7ee6c7fb6d0c48cbdee9737a959796489bddbc4c5df61d5b3297b4fb68dab9f1b582c2, 128'b0};
  localparam [511:0] TEST_KEY_DOUBLE = 512'he1b52c4ff8ce9c4b60bd8ec785ab7bf3dffc7023f7c51588f96b94eeba80ca3b9b9ed05ab2ac8797bb7039d681f2e41fcfe6dddab2e95122d9c716c2b8406bd4;
  localparam [1023:0] TEST_BLOCK_FIRST = 1024'h5468697320697320612074657374207573696e672061206c6172676572207468616e20626c6f636b2d73697a65206b657920616e642061206c6172676572207468616e20626c6f636b2d73697a6520646174612e20546865206b6579206e6565647320746f20626520686173686564206265666f7265206265696e6720757365;
  localparam [1023:0] TEST_BLOCK_FINAL = 1024'h642062792074686520484d414320616c676f726974686d2e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008C0;
  localparam [511:0] EXPECTED_TAG_DOUBLE = 512'he37b6a775dc87dbaa4dfa9f96e5e3ffddebd71f8867289865df5a32d20cdc944b6022cac3c4982b10d5eeb55c3e4de15134676fb6de0446065c97440fa8c6a58;
  localparam [383:0] TEST_SEED = 384'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff;
  localparam [31:0] SHA512_INIT =
    (32'h1 << `HMAC_REG_HMAC512_CTRL_MODE_LOW) |
    `HMAC_REG_HMAC512_CTRL_INIT_MASK;
  localparam [31:0] SHA512_NEXT =
    (32'h1 << `HMAC_REG_HMAC512_CTRL_MODE_LOW) |
    `HMAC_REG_HMAC512_CTRL_NEXT_MASK;
  localparam [31:0] SHA384_INIT = `HMAC_REG_HMAC512_CTRL_INIT_MASK;
  localparam [31:0] CTRL_ZEROIZE = `HMAC_REG_HMAC512_CTRL_ZEROIZE_MASK;
  localparam [31:0] RAL_KEY0_VALUE = 32'hd3a5c9e7;
  localparam integer HMAC_KEY_WORD_COUNT = 16;
  localparam integer HMAC_BLOCK_WORD_COUNT = 32;
  localparam integer HMAC_SEED_WORD_COUNT = 12;
  localparam integer HMAC_TAG_WORD_COUNT = 16;
  localparam integer HMAC_BLOCK_FIRST_INDEX = HMAC_KEY_WORD_COUNT;
  localparam integer HMAC_SEED_FIRST_INDEX = HMAC_BLOCK_FIRST_INDEX + HMAC_BLOCK_WORD_COUNT;
  localparam integer HMAC_CTRL_INDEX = HMAC_SEED_FIRST_INDEX + HMAC_SEED_WORD_COUNT;
  localparam integer HMAC_STATUS_INDEX = HMAC_CTRL_INDEX + 1;
  localparam integer HMAC_TAG_FIRST_INDEX = HMAC_STATUS_INDEX + 1;
  localparam integer HMAC_REGISTER_COUNT = HMAC_TAG_FIRST_INDEX + HMAC_TAG_WORD_COUNT;

  reg HCLK = 0;
  reg HRESETn = 0;
  wire HSEL, HWRITE, HRESP, HREADY, HREADYOUT;
  wire [31:0] HADDR, HWDATA, HRDATA;
  wire [2:0] HSIZE;
  wire [1:0] HTRANS;
  wire hmac_busy, hmac_error;
  ahb_lite_caliptra_master_cmd_if cmd_if(HCLK);
  ahb_lite_caliptra_record_if record_if(HCLK);
  kv_read_t [1:0] kv_read;
  kv_write_t kv_write;
  kv_rd_resp_t [1:0] kv_rd_resp = '0;
  kv_wr_resp_t kv_wr_resp = '0;
  reg [`CLP_CSR_HMAC_KEY_DWORDS-1:0][31:0] cptra_csr_hmac_key = '0;
  int unsigned expected_transfer_count = 0;

  assign cmd_if.HRESETn = HRESETn;
  assign HREADY = HREADYOUT;
  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_uvm_master_proxy #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) master_proxy (
    .cmd_if(cmd_if), .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADY),
    .HRESP(HRESP), .HRDATA(HRDATA), .HSEL(HSEL), .HADDR(HADDR),
    .HWDATA(HWDATA), .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS)
  );

  ahb_lite_caliptra_pin_monitor_adapter #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) monitor_adapter (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADY), .HRESP(HRESP), .HRDATA(HRDATA), .record_if(record_if)
  );

  hmac_ctrl #(.AHB_ADDR_WIDTH(32), .AHB_DATA_WIDTH(32)) dut (
    .clk(HCLK), .reset_n(HRESETn), .cptra_pwrgood(1'b1),
    .cptra_csr_hmac_key(cptra_csr_hmac_key),
    .haddr_i(HADDR), .hwdata_i(HWDATA), .hsel_i(HSEL), .hwrite_i(HWRITE),
    .hready_i(HREADY), .htrans_i(HTRANS), .hsize_i(HSIZE),
    .hresp_o(HRESP), .hreadyout_o(HREADYOUT), .hrdata_o(HRDATA),
    .kv_read(kv_read), .kv_write(kv_write), .kv_rd_resp(kv_rd_resp),
    .kv_wr_resp(kv_wr_resp), .busy_o(hmac_busy), .error_intr(hmac_error),
    .notif_intr(), .ocp_lock_in_progress(1'b0),
    .debugUnlock_or_scan_mode_switch(1'b0)
  );

  class hmac_ahb_monitor_subscriber extends uvm_subscriber #(ahb_lite_caliptra_transaction);
    int unsigned transfer_count;
    `uvm_component_utils(hmac_ahb_monitor_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(ahb_lite_caliptra_transaction item);
      if (item.protocol_error || item.error)
        `uvm_fatal("HMAC_AHB_MON", $sformatf("Unexpected AHB response: %s", item.convert2string()))
      if (item.size != 2 || item.trans != 2'b10 || item.data[63:32] != 0)
        `uvm_fatal("HMAC_AHB_RECORD", $sformatf("Unexpected HMAC AHB record: %s", item.convert2string()))
      transfer_count++;
    endfunction
  endclass

  class hmac_ahb_env extends uvm_env;
    ahb_lite_caliptra_agent agent;
    hmac_ahb_monitor_subscriber observer;
    `uvm_component_utils(hmac_ahb_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = ahb_lite_caliptra_agent::type_id::create("agent", this);
      agent.is_active = UVM_ACTIVE;
      observer = hmac_ahb_monitor_subscriber::type_id::create("observer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.ap.connect(observer.analysis_export);
    endfunction
  endclass

  class hmac_ahb_smoke_reg extends uvm_reg;
    uvm_reg_field value;
    string access;
    `uvm_object_utils(hmac_ahb_smoke_reg)

    function new(string name = "hmac_ahb_smoke_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
      access = "RW";
    endfunction

    virtual function void build();
      value = uvm_reg_field::type_id::create("value");
      value.configure(this, 32, 0, access, 0, 0, 1, 0, 0);
    endfunction
  endclass

  class hmac_ahb_smoke_block extends uvm_reg_block;
    hmac_ahb_smoke_reg registers[0:HMAC_REGISTER_COUNT-1];
    hmac_ahb_smoke_reg key0;
    hmac_ahb_smoke_reg status_csr;
    hmac_ahb_smoke_reg ctrl;
    `uvm_object_utils(hmac_ahb_smoke_block)

    function new(string name = "hmac_ahb_smoke_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      uvm_reg_addr_t address;
      string access;
      default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN, 1);
      for (int i = 0; i < HMAC_REGISTER_COUNT; i++) begin
        registers[i] = hmac_ahb_smoke_reg::type_id::create($sformatf("reg_%0d", i));
        registers[i].configure(this);
        if (i < HMAC_KEY_WORD_COUNT)
          address = `CLP_HMAC_REG_HMAC512_KEY_0 + i*4;
        else if (i < HMAC_SEED_FIRST_INDEX)
          address = `CLP_HMAC_REG_HMAC512_BLOCK_0 + (i-HMAC_BLOCK_FIRST_INDEX)*4;
        else if (i < HMAC_CTRL_INDEX)
          address = `CLP_HMAC_REG_HMAC512_LFSR_SEED_0 + (i-HMAC_SEED_FIRST_INDEX)*4;
        else if (i == HMAC_CTRL_INDEX)
          address = `CLP_HMAC_REG_HMAC512_CTRL;
        else if (i == HMAC_STATUS_INDEX)
          address = `CLP_HMAC_REG_HMAC512_STATUS;
        else
          address = `CLP_HMAC_REG_HMAC512_TAG_0 + (i-HMAC_TAG_FIRST_INDEX)*4;
        access = (i <= HMAC_CTRL_INDEX) ? "WO" : "RO";
        registers[i].access = access;
        registers[i].build();
        default_map.add_reg(registers[i], address, access);
      end
      key0 = registers[0];
      status_csr = registers[HMAC_STATUS_INDEX];
      ctrl = registers[HMAC_CTRL_INDEX];
      lock_model();
    endfunction
  endclass

  class hmac_ahb_sequence extends uvm_sequence #(ahb_lite_caliptra_transfer);
    int unsigned transfer_count;
    `uvm_object_utils(hmac_ahb_sequence)

    function new(string name = "hmac_ahb_sequence");
      super.new(name);
    endfunction

    task automatic transfer(input bit write, input [31:0] address,
                            input [31:0] write_data, output [31:0] read_data);
      ahb_lite_caliptra_transfer request;
      request = ahb_lite_caliptra_transfer::type_id::create("request");
      start_item(request);
      request.write = write;
      request.address = address;
      request.size = 3'd2;
      request.write_data = write_data;
      finish_item(request);
      if (!request.request_ok || !request.success || request.response_error || request.aborted)
        `uvm_fatal("HMAC_AHB_TRANSFER", $sformatf("AHB transfer failed: %s", request.convert2string()))
      read_data = request.read_data[31:0];
      transfer_count++;
    endtask

    task automatic write_word(input [31:0] address, input [31:0] value);
      reg [31:0] unused;
      transfer(1'b1, address, value, unused);
    endtask

    task automatic read_word(input [31:0] address, output reg [31:0] value);
      transfer(1'b0, address, 32'b0, value);
    endtask

    task automatic write_key_block_seed(input [511:0] key,
                                        input [1023:0] block);
      int unsigned i;
      for (i = 0; i < 16; i++)
        write_word(`CLP_HMAC_REG_HMAC512_KEY_0 + i*4, key[511-i*32 -: 32]);
      for (i = 0; i < 32; i++)
        write_word(`CLP_HMAC_REG_HMAC512_BLOCK_0 + i*4, block[1023-i*32 -: 32]);
      for (i = 0; i < 12; i++)
        write_word(`CLP_HMAC_REG_HMAC512_LFSR_SEED_0 + i*4, TEST_SEED[383-i*32 -: 32]);
    endtask

    task automatic wait_ready();
      reg [31:0] status;
      bit ready_seen;
      int unsigned polls;
      ready_seen = 0;
      for (polls = 0; polls < 10000 && !ready_seen; polls++) begin
        read_word(`CLP_HMAC_REG_HMAC512_STATUS, status);
        ready_seen = (status != 0);
      end
      if (!ready_seen)
        `uvm_fatal("HMAC_AHB_TIMEOUT", "HMAC did not become ready within 10000 status polls")
    endtask

    task automatic read_digest(output reg [511:0] digest);
      reg [31:0] word;
      int unsigned i;
      digest = '0;
      for (i = 0; i < 16; i++) begin
        read_word(`CLP_HMAC_REG_HMAC512_TAG_0 + i*4, word);
        digest[511-i*32 -: 32] = word;
      end
    endtask

    task automatic run_single_block(input [511:0] key,
                                    input [31:0] ctrl_init,
                                    input [511:0] expected_tag);
      reg [511:0] observed_tag;
      write_key_block_seed(key, TEST_BLOCK);
      write_word(`CLP_HMAC_REG_HMAC512_CTRL, ctrl_init);
      wait_ready();
      read_digest(observed_tag);
      if (observed_tag !== expected_tag)
        `uvm_fatal("HMAC_AHB_KAT", $sformatf("HMAC known-answer mismatch: got %0128x expected %0128x", observed_tag, expected_tag))
      if (hmac_busy || hmac_error)
        `uvm_fatal("HMAC_AHB_STATUS", "HMAC status is busy/error after digest completion")

      write_word(`CLP_HMAC_REG_HMAC512_CTRL, CTRL_ZEROIZE);
    endtask

    task automatic run_double_block();
      reg [511:0] observed_tag;
      int unsigned i;
      write_key_block_seed(TEST_KEY_DOUBLE, TEST_BLOCK_FIRST);
      write_word(`CLP_HMAC_REG_HMAC512_CTRL, SHA512_INIT);
      wait_ready();
      for (i = 0; i < 32; i++)
        write_word(`CLP_HMAC_REG_HMAC512_BLOCK_0 + i*4, TEST_BLOCK_FINAL[1023-i*32 -: 32]);
      write_word(`CLP_HMAC_REG_HMAC512_CTRL, SHA512_NEXT);
      wait_ready();
      read_digest(observed_tag);
      if (observed_tag !== EXPECTED_TAG_DOUBLE)
        `uvm_fatal("HMAC_AHB_DOUBLE_KAT", $sformatf("HMAC double-block mismatch: got %0128x expected %0128x", observed_tag, EXPECTED_TAG_DOUBLE))
      if (hmac_busy || hmac_error)
        `uvm_fatal("HMAC_AHB_STATUS", "HMAC status is busy/error after double-block digest")
      write_word(`CLP_HMAC_REG_HMAC512_CTRL, CTRL_ZEROIZE);
    endtask

    task body();
      run_single_block(TEST_KEY, SHA512_INIT, EXPECTED_TAG);
      run_single_block(TEST_KEY_384_PADDED, SHA384_INIT, EXPECTED_TAG_384);
      run_double_block();
    endtask
  endclass

  class hmac_ahb_uvm_test extends uvm_test;
    hmac_ahb_env env;
    hmac_ahb_smoke_block ral_model;
    ahb_lite_caliptra_native_reg_adapter ral_adapter;
    ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer) ral_predictor;
    `uvm_component_utils(hmac_ahb_uvm_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = hmac_ahb_env::type_id::create("env", this);
      ral_model = hmac_ahb_smoke_block::type_id::create("ral_model");
      ral_model.build();
      ral_adapter = ahb_lite_caliptra_native_reg_adapter::type_id::create("ral_adapter");
      ral_adapter.set_bus_data_width(32);
      ral_predictor = ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer)::type_id::create(
        "ral_predictor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      ral_model.default_map.set_sequencer(env.agent.sequencer, ral_adapter);
      ral_model.default_map.set_auto_predict(0);
      env.agent.burst_transfer_ap.connect(ral_predictor.bus_item_export);
      ral_predictor.map = ral_model.default_map;
      ral_predictor.adapter = ral_adapter;
    endfunction

    task run_phase(uvm_phase phase);
      hmac_ahb_sequence hmac_seq;
      uvm_status_e ral_status;
      uvm_reg_data_t ral_value;
      int unsigned expected_monitor_count;
      phase.raise_objection(this);
      hmac_seq = hmac_ahb_sequence::type_id::create("hmac_seq");
      hmac_seq.start(env.agent.sequencer);
      fork
        begin
          wait (env.observer.transfer_count == hmac_seq.transfer_count);
        end
        begin
          #2000000;
          `uvm_fatal("HMAC_AHB_TIMEOUT", "Timed out waiting for HMAC AHB monitor records")
        end
      join_any
      disable fork;
      if (hmac_seq.transfer_count != env.observer.transfer_count)
        `uvm_fatal("HMAC_AHB_COUNT", $sformatf("Sequence issued %0d transfers; monitor observed %0d",
          hmac_seq.transfer_count, env.observer.transfer_count))
      ral_model.key0.write(ral_status, RAL_KEY0_VALUE, UVM_FRONTDOOR, ral_model.default_map);
      if (ral_status != UVM_IS_OK)
        `uvm_fatal("HMAC_AHB_RAL_WRITE", "RAL frontdoor write to HMAC key CSR failed")
      ral_model.status_csr.read(ral_status, ral_value, UVM_FRONTDOOR, ral_model.default_map);
      if (ral_status != UVM_IS_OK)
        `uvm_fatal("HMAC_AHB_RAL_READ", "RAL frontdoor read from HMAC status CSR failed")
      ral_model.ctrl.write(ral_status, CTRL_ZEROIZE, UVM_FRONTDOOR, ral_model.default_map);
      if (ral_status != UVM_IS_OK)
        `uvm_fatal("HMAC_AHB_RAL_WRITE", "RAL frontdoor write to HMAC control CSR failed")
      expected_monitor_count = hmac_seq.transfer_count + 3;
      fork
        begin
          wait (env.observer.transfer_count == expected_monitor_count);
        end
        begin
          #2000;
          `uvm_fatal("HMAC_AHB_RAL_TIMEOUT", "Timed out waiting for HMAC RAL frontdoor monitor records")
        end
      join_any
      disable fork;
      if (env.observer.transfer_count != expected_monitor_count)
        `uvm_fatal("HMAC_AHB_RAL_COUNT", "Native AHB agent missed a RAL frontdoor transfer")
      if (ral_model.key0.get_mirrored_value() !== RAL_KEY0_VALUE ||
          ral_model.status_csr.get_mirrored_value() !== ral_value ||
          ral_model.ctrl.get_mirrored_value() !== CTRL_ZEROIZE)
        `uvm_fatal("HMAC_AHB_RAL_PREDICT", "Observed HMAC RAL frontdoor traffic did not update its register mirrors")
      expected_transfer_count = expected_monitor_count;
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::set(
      null, "uvm_test_top.env.agent.driver", "cmd_vif", cmd_if);
    uvm_config_db#(virtual ahb_lite_caliptra_record_if)::set(
      null, "uvm_test_top.env.agent.monitor", "vif", record_if);
    run_test("hmac_ahb_uvm_test");
  end

  initial begin
    repeat (4) @(posedge HCLK);
    @(negedge HCLK);
    HRESETn = 1;
  end

  final begin
    if (record_if.checker_error !== 1'b0 || record_if.checker_error_count !== 0 ||
        record_if.protocol_error !== 1'b0 || record_if.protocol_error_count !== 0 ||
        record_if.address_count !== expected_transfer_count ||
        record_if.transfer_count !== expected_transfer_count || record_if.transfer_error !== 1'b0 ||
        record_if.transfer_fire !== 1'b1 || record_if.transfer_write !== 1'b1 ||
        record_if.transfer_addr !== `CLP_HMAC_REG_HMAC512_CTRL ||
        record_if.transfer_data[31:0] !== CTRL_ZEROIZE)
      $fatal(1, "Caliptra HMAC AHB UVM checker/monitor did not report clean transfers");
    $display("PASS: Caliptra HMAC-SHA-384/512 single/double-block tests through native UVM AHB agent (%0d transfers)", record_if.transfer_count);
    $finish;
  end
endmodule
