// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_axi4_caliptra_uvm_adapter;
  import uvm_pkg::*;
  import axi4_caliptra_uvm_pkg::*;

  reg ACLK = 0;
  reg ARESETn = 0;
  reg [7:0] AWID = 0;
  reg [47:0] AWADDR = 0;
  reg [7:0] AWLEN = 0;
  reg [2:0] AWSIZE = 2;
  reg [1:0] AWBURST = 1;
  reg AWLOCK = 0;
  reg [31:0] AWUSER = 0;
  reg AWVALID = 0;
  reg AWREADY = 1;
  reg [31:0] WDATA = 0;
  reg [3:0] WSTRB = 0;
  reg [31:0] WUSER = 0;
  reg WLAST = 0;
  reg WVALID = 0;
  reg WREADY = 1;
  reg [7:0] BID = 0;
  reg [1:0] BRESP = 0;
  reg [31:0] BUSER = 0;
  reg BVALID = 0;
  reg BREADY = 1;
  reg [7:0] ARID = 0;
  reg [47:0] ARADDR = 0;
  reg [7:0] ARLEN = 0;
  reg [2:0] ARSIZE = 2;
  reg [1:0] ARBURST = 1;
  reg ARLOCK = 0;
  reg [31:0] ARUSER = 0;
  reg ARVALID = 0;
  reg ARREADY = 1;
  reg [7:0] RID = 0;
  reg [31:0] RDATA = 0;
  reg [1:0] RRESP = 0;
  reg [31:0] RUSER = 0;
  reg RLAST = 0;
  reg RVALID = 0;
  reg RREADY = 1;

  axi4_caliptra_record_if record_if(ACLK);
  assign record_if.ARESETn = ARESETn;
  always #5 ACLK = ~ACLK;

  axi4_caliptra_transaction_monitor monitor_dut (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
    .AWVALID(AWVALID), .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB),
    .WUSER(WUSER), .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY),
    .BID(BID), .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
    .ARVALID(ARVALID), .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA),
    .RRESP(RRESP), .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID),
    .RREADY(RREADY),
    .write_complete(record_if.write_complete),
    .write_request_complete(record_if.write_request_complete),
    .write_request_error(record_if.write_request_error),
    .write_request_status(record_if.write_request_status),
    .write_request_id(record_if.write_request_id),
    .write_request_addr(record_if.write_request_addr),
    .write_request_len(record_if.write_request_len),
    .write_request_size(record_if.write_request_size),
    .write_request_burst(record_if.write_request_burst),
    .write_request_lock(record_if.write_request_lock),
    .write_request_awuser(record_if.write_request_awuser),
    .write_request_beat_count(record_if.write_request_beat_count),
    .write_request_data(record_if.write_request_data),
    .write_request_strb(record_if.write_request_strb),
    .write_request_wuser(record_if.write_request_wuser),
    .write_request_last_mask(record_if.write_request_last_mask),
    .write_error(record_if.write_error),
    .write_status(record_if.write_status), .write_id(record_if.write_id),
    .write_addr(record_if.write_addr), .write_len(record_if.write_len),
    .write_size(record_if.write_size), .write_burst(record_if.write_burst),
    .write_lock(record_if.write_lock), .write_awuser(record_if.write_awuser),
    .write_beat_count(record_if.write_beat_count), .write_data(record_if.write_data),
    .write_strb(record_if.write_strb), .write_wuser(record_if.write_wuser),
    .write_last_mask(record_if.write_last_mask),
    .write_response_id(record_if.write_response_id),
    .write_response(record_if.write_response), .write_buser(record_if.write_buser),
    .read_complete(record_if.read_complete), .read_error(record_if.read_error),
    .read_status(record_if.read_status), .read_id(record_if.read_id),
    .read_addr(record_if.read_addr), .read_len(record_if.read_len),
    .read_size(record_if.read_size), .read_burst(record_if.read_burst),
    .read_lock(record_if.read_lock), .read_aruser(record_if.read_aruser),
    .read_beat_count(record_if.read_beat_count), .read_data(record_if.read_data),
    .read_resp(record_if.read_resp), .read_ruser(record_if.read_ruser),
    .read_last_mask(record_if.read_last_mask)
  );

  class axi4_caliptra_uvm_subscriber extends uvm_subscriber #(axi4_caliptra_transaction);
    int write_count;
    int read_count;
    event received;

    `uvm_component_utils(axi4_caliptra_uvm_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      write_count = 0;
      read_count = 0;
    endfunction

    function void write(axi4_caliptra_transaction item);
      axi4_caliptra_transaction copied;
      string summary;
      copied = axi4_caliptra_transaction::type_id::create("copied_item");
      copied.copy(item);
      if (!copied.compare(item)) $fatal(1, "UVM transaction copy/compare failed");
      summary = item.sprint();
      if (summary.len() == 0 || item.convert2string().len() == 0)
        $fatal(1, "UVM transaction print method returned no text");

      if (item.is_write()) begin
        write_count++;
        if (item.addr != 48'h1234 || item.id != 8'h31 ||
            item.data != 32'ha5a5_5a5a || item.beatQ.size() != 1 ||
            item.beatQ[0] != 32'ha5a5_5a5a || item.strbQ[0] != 4'h5 ||
            item.awuser != 32'h1122_3344 || item.buser != 32'hdead_beef ||
            item.resp != 2'b00 || item.protocol_error)
          $fatal(1, "UVM write transaction fields mismatch: %s", item.convert2string());
      end else if (item.is_read()) begin
        read_count++;
        if (item.addr != 48'h5678 || item.id != 8'h42 ||
            item.data != 32'hface_1234 || item.beatQ.size() != 1 ||
            item.beatQ[0] != 32'hface_1234 || item.aruser != 32'h89ab_cdef ||
            item.resp != 2'b10 || item.respQ[0] != 2'b10 ||
            item.beat_userQ[0] != 32'h1357_9bdf || item.protocol_error)
          $fatal(1, "UVM read transaction fields mismatch: %s", item.convert2string());
      end else begin
        $fatal(1, "UVM adapter published unknown transaction kind");
      end
      -> received;
    endfunction
  endclass

  class axi4_caliptra_uvm_env extends uvm_env;
    axi4_caliptra_uvm_monitor mon;
    axi4_caliptra_uvm_subscriber sub;
    `uvm_component_utils(axi4_caliptra_uvm_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon = axi4_caliptra_uvm_monitor::type_id::create("mon", this);
      sub = axi4_caliptra_uvm_subscriber::type_id::create("sub", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      mon.ap.connect(sub.analysis_export);
    endfunction
  endclass

  class axi4_caliptra_uvm_test extends uvm_test;
    axi4_caliptra_uvm_env env;
    `uvm_component_utils(axi4_caliptra_uvm_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = axi4_caliptra_uvm_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      fork
        begin
          while (env.sub.write_count == 0 || env.sub.read_count == 0)
            @env.sub.received;
        end
        begin
          #1000;
          `uvm_fatal("AXI_TIMEOUT", "Timed out waiting for read/write analysis items")
        end
      join_any
      disable fork;
      $display("PASS: UVM AXI analysis adapter published read/write transactions");
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    uvm_config_db#(virtual axi4_caliptra_record_if)::set(
      null, "uvm_test_top.env.mon", "vif", record_if);
    run_test("axi4_caliptra_uvm_test");
  end

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK);
    ARESETn = 1;

    AWID = 8'h31;
    AWADDR = 48'h1234;
    AWLEN = 0;
    AWLOCK = 1;
    AWUSER = 32'h1122_3344;
    AWVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    AWVALID = 0;
    WDATA = 32'ha5a5_5a5a;
    WSTRB = 4'h5;
    WUSER = 32'h5566_7788;
    WLAST = 1;
    WVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    WVALID = 0;
    BID = 8'h31;
    BRESP = 2'b00;
    BUSER = 32'hdead_beef;
    BVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    BVALID = 0;

    ARID = 8'h42;
    ARADDR = 48'h5678;
    ARLEN = 0;
    ARUSER = 32'h89ab_cdef;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARVALID = 0;
    RID = 8'h42;
    RDATA = 32'hface_1234;
    RRESP = 2'b10;
    RUSER = 32'h1357_9bdf;
    RLAST = 1;
    RVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    RVALID = 0;
  end
endmodule
