// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_caliptra_aaxi_compat;
  import uvm_pkg::*;
  import axi_pkg::*;
  import axi4_caliptra_uvm_pkg::*;
  import aaxi_uvm_pkg::*;
  import caliptra_aaxi_uvmf_compat_pkg::*;

  reg ACLK = 0;
  reg ARESETn = 0;
  wire [31:0] fifo_level;
  wire fifo_push_event, fifo_pop_event, recovery_data_avail;

  axi_if #(.AW(48), .DW(32), .IW(8), .UW(32)) m_axi_if (
    .clk(ACLK), .rst_n(ARESETn)
  );
  aaxi_intf generated_ports (
    .ACLK(ACLK), .ARESETn(ARESETn), .CACTIVE(), .CSYSREQ(1'b0), .CSYSACK()
  );

  aaxi_monitor_wrapper generated_aaxi_bfm(generated_ports);
  defparam generated_aaxi_bfm.ID_WIDTH = 8;
  defparam generated_aaxi_bfm.BUS_DATA_WIDTH = 32;
  defparam generated_aaxi_bfm.USER_SUPPORT = 5'b11111;
  defparam generated_aaxi_bfm.VER = "AXI4";

  always #5 ACLK = ~ACLK;

  always @(posedge ACLK) begin
    if (ARESETn && generated_ports.AWVALID === 1'b1 &&
        generated_ports.AWADDR[63:48] !== 16'b0)
      $fatal(1, "Caliptra AXI manager must zero-extend AWADDR above bit 47");
    if (ARESETn && generated_ports.ARVALID === 1'b1 &&
        generated_ports.ARADDR[63:48] !== 16'b0)
      $fatal(1, "Caliptra AXI manager must zero-extend ARADDR above bit 47");
  end

  // Connect the generated AAXI signal interface to Caliptra's actual AXI pins.
  always_comb begin
    generated_ports.CACTIVE_m = 1'b0;
    generated_ports.CACTIVE_s = 1'b0;
    generated_ports.CSYSACK_m = 1'b0;
    generated_ports.CSYSACK_s = 1'b0;
    m_axi_if.araddr = generated_ports.ARADDR[47:0];
    m_axi_if.arburst = generated_ports.ARBURST;
    m_axi_if.arsize = generated_ports.ARSIZE;
    m_axi_if.arlen = generated_ports.ARLEN;
    m_axi_if.aruser = generated_ports.ARUSER;
    m_axi_if.arid = generated_ports.ARID;
    m_axi_if.arlock = generated_ports.ARLOCK;
    m_axi_if.arvalid = generated_ports.ARVALID;
    generated_ports.ARREADY = m_axi_if.arready;
    generated_ports.RDATA = m_axi_if.rdata;
    generated_ports.RRESP = m_axi_if.rresp;
    generated_ports.RID = m_axi_if.rid;
    generated_ports.RUSER = m_axi_if.ruser;
    generated_ports.RLAST = m_axi_if.rlast;
    generated_ports.RVALID = m_axi_if.rvalid;
    m_axi_if.rready = generated_ports.RREADY;
    m_axi_if.awaddr = generated_ports.AWADDR[47:0];
    m_axi_if.awburst = generated_ports.AWBURST;
    m_axi_if.awsize = generated_ports.AWSIZE;
    m_axi_if.awlen = generated_ports.AWLEN;
    m_axi_if.awuser = generated_ports.AWUSER;
    m_axi_if.awid = generated_ports.AWID;
    m_axi_if.awlock = generated_ports.AWLOCK;
    m_axi_if.awvalid = generated_ports.AWVALID;
    generated_ports.AWREADY = m_axi_if.awready;
    m_axi_if.wdata = generated_ports.WDATA;
    m_axi_if.wstrb = generated_ports.WSTRB;
    m_axi_if.wuser = generated_ports.WUSER;
    m_axi_if.wvalid = generated_ports.WVALID;
    m_axi_if.wlast = generated_ports.WLAST;
    generated_ports.WREADY = m_axi_if.wready;
    generated_ports.BRESP = m_axi_if.bresp;
    generated_ports.BID = m_axi_if.bid;
    generated_ports.BUSER = m_axi_if.buser;
    generated_ports.BVALID = m_axi_if.bvalid;
    m_axi_if.bready = generated_ports.BREADY;
  end

  axi4_caliptra_dma_if_subordinate #(.RECOVERY_MODE(2)) target (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .fifo_clear(1'b0), .auto_fifo_push(1'b0), .auto_fifo_pop(1'b0),
    .use_dma_gen_sequence(1'b0), .dma_gen_done(1'b0),
    .dma_gen_block_size_bytes(1200'b0), .en_recovery_emulation(1'b0),
    .recovery_threshold_words(32'd2), .recovery_block_words(32'd8),
    .inject_error(1'b0),
    .stall_sram_aw(1'b0), .stall_sram_w(1'b0), .stall_sram_b(1'b0),
    .stall_sram_ar(1'b0), .stall_sram_r(1'b0),
    .stall_fifo_aw(1'b0), .stall_fifo_w(1'b0), .stall_fifo_b(1'b0),
    .stall_fifo_ar(1'b0), .stall_fifo_r(1'b0),
    .fifo_level(fifo_level), .fifo_push_event(fifo_push_event),
    .fifo_pop_event(fifo_pop_event), .recovery_data_avail(recovery_data_avail)
  );

  class aaxi_compat_observer extends uvm_component;
    uvm_analysis_imp #(aaxi_master_tr, aaxi_compat_observer) completed_export;
    int write_count;
    int read_count;
    time write_done_time;
    time read_done_time;
    event completed;

    `uvm_component_utils(aaxi_compat_observer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      completed_export = new("completed_export", this);
    endfunction

    function void write(aaxi_master_tr item);
      if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 ||
          item.id != 8'h31 || item.resp != 2'b00 || !item.transport_success)
        `uvm_fatal("AAXI_MONITOR", $sformatf("Unexpected completed item: %s", item.convert2string()))
      if (item.is_write()) begin
        if (item.beatQ.size() != 1 || item.beatQ[0] != 32'ha55a_c33c ||
            item.strbQ.size() != 1 || item.strbQ[0] != 4'hf)
          `uvm_fatal("AAXI_WRITE", "Monitor lost the completed write payload")
        write_count++;
        write_done_time = $time;
      end else begin
        if (item.beatQ.size() != 1 || item.beatQ[0] != 32'ha55a_c33c ||
            item.respQ.size() != 1 || item.respQ[0] != 2'b00 ||
            item.aruser != 32'h5566_7788)
          `uvm_fatal("AAXI_READ", "Monitor lost the completed read payload")
        read_count++;
        read_done_time = $time;
      end
      -> completed;
    endfunction
  endclass

  class aaxi_write_request_observer extends uvm_component;
    uvm_analysis_imp #(aaxi_master_tr, aaxi_write_request_observer) analysis_export;
    int write_count;
    time write_request_time;

    `uvm_component_utils(aaxi_write_request_observer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction

    function void write(aaxi_master_tr item);
      if (!item.is_write() || item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 ||
          item.id != 8'h31 || item.beatQ.size() != 1 ||
          item.beatQ[0] != 32'ha55a_c33c || item.strbQ.size() != 1 ||
          item.strbQ[0] != 4'hf || item.awuser != 32'h1122_3344)
        `uvm_fatal("AAXI_REQUEST", $sformatf("Unexpected write request: %s", item.convert2string()))
      write_count++;
      write_request_time = $time;
    endfunction
  endclass

  class aaxi_read_valid_observer extends uvm_component;
    uvm_analysis_imp #(aaxi_master_tr, aaxi_read_valid_observer) analysis_export;
    int read_count;
    time read_valid_time;

    `uvm_component_utils(aaxi_read_valid_observer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction

    function void write(aaxi_master_tr item);
      if (!item.is_read() || item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 ||
          item.id != 8'h31 || item.aruser != 32'h5566_7788 ||
          item.beatQ.size() != 1 || item.beatQ[0] != 32'ha55a_c33c ||
          item.respQ.size() != 1 || item.respQ[0] != 2'b00)
        `uvm_fatal("AAXI_READ_VALID", $sformatf("Unexpected read-valid item: %s", item.convert2string()))
      read_count++;
      read_valid_time = $time;
      // Other exports must receive independent transaction snapshots.
      item.beatQ[0] = '0;
    endfunction
  endclass

  class aaxi_channel_observer extends uvm_subscriber #(axi4_caliptra_channel_transaction);
    int channel_count[0:4];

    `uvm_component_utils(aaxi_channel_observer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      foreach (channel_count[i]) channel_count[i] = 0;
    endfunction

    function void write(axi4_caliptra_channel_transaction item);
      if (item.cycle == 0)
        `uvm_fatal("AAXI_CHANNEL", "Channel item has no cycle stamp")
      case (item.channel)
        AXI4_CHANNEL_AW: begin
          if (item.id != 8'h31 || item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 ||
              item.user != 32'h1122_3344 || item.len != 0 || item.size != 2 ||
              item.burst != 1)
            `uvm_fatal("AAXI_AW", $sformatf("Unexpected AW item: %s", item.convert2string()))
        end
        AXI4_CHANNEL_W: begin
          if (item.data != 32'ha55a_c33c || item.strb != 4'hf || !item.last)
            `uvm_fatal("AAXI_W", $sformatf("Unexpected W item: %s", item.convert2string()))
        end
        AXI4_CHANNEL_B: begin
          if (item.id != 8'h31 || item.response != 0)
            `uvm_fatal("AAXI_B", $sformatf("Unexpected B item: %s", item.convert2string()))
        end
        AXI4_CHANNEL_AR: begin
          if (item.id != 8'h31 || item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 ||
              item.user != 32'h5566_7788 || item.len != 0 || item.size != 2 ||
              item.burst != 1)
            `uvm_fatal("AAXI_AR", $sformatf("Unexpected AR item: %s", item.convert2string()))
        end
        AXI4_CHANNEL_R: begin
          if (item.id != 8'h31 || item.data != 32'ha55a_c33c || item.response != 0 ||
              !item.last)
            `uvm_fatal("AAXI_R", $sformatf("Unexpected R item: %s", item.convert2string()))
        end
        default: `uvm_fatal("AAXI_CHANNEL", "Unknown AXI channel item")
      endcase
      channel_count[item.channel]++;
    endfunction
  endclass

  class aaxi_compat_sequence extends uvm_sequence #(aaxi_master_tr);
    `uvm_object_utils(aaxi_compat_sequence)

    function new(string name = "aaxi_compat_sequence");
      super.new(name);
    endfunction

    task body();
      aaxi_master_tr req;
      req = aaxi_master_tr::type_id::create("write_req");
      start_item(req);
      req.kind = AAXI_WRITE;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h20;
      req.id = 8'h31;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.awuser = 32'h1122_3344;
      req.beatQ.push_back(32'ha55a_c33c);
      req.strbQ.push_back(4'hf);
      finish_item(req);
      if (!req.transport_success || req.resp != 2'b00 || req.response_id != req.id)
        `uvm_fatal("AAXI_WRITE", "Generated-path AAXI driver write failed")

      req = aaxi_master_tr::type_id::create("read_req");
      start_item(req);
      req.kind = AAXI_READ;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h20;
      req.id = 8'h31;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.aruser = 32'h5566_7788;
      finish_item(req);
      if (!req.transport_success || req.resp != 2'b00 ||
          req.response_id != req.id || req.beatQ.size() != 1 ||
          req.beatQ[0] != 32'ha55a_c33c)
        `uvm_fatal("AAXI_READ", "Generated-path AAXI driver read failed")
    endtask
  endclass

  class aaxi_compat_test extends uvm_test;
    aaxi_uvm_testbench aaxi_tb;
    aaxi_compat_observer observer;
    aaxi_compat_observer passive_observer;
    aaxi_write_request_observer request_observer;
    aaxi_read_valid_observer read_valid_observer;
    aaxi_channel_observer channel_observer;
    aaxi_channel_observer passive_channel_observer;

    `uvm_component_utils(aaxi_compat_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      aaxi_tb = aaxi_uvm_testbench::type_id::create("aaxi_tb", this);
      observer = aaxi_compat_observer::type_id::create("observer", this);
      passive_observer = aaxi_compat_observer::type_id::create("passive_observer", this);
      request_observer = aaxi_write_request_observer::type_id::create("request_observer", this);
      read_valid_observer = aaxi_read_valid_observer::type_id::create("read_valid_observer", this);
      channel_observer = aaxi_channel_observer::type_id::create("channel_observer", this);
      passive_channel_observer = aaxi_channel_observer::type_id::create("passive_channel_observer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      aaxi_tb.env0.master[0].write_done_export.connect(observer.completed_export);
      aaxi_tb.env0.master[0].read_done_export.connect(observer.completed_export);
      aaxi_tb.env0.master[0].ms_tx_AW_W_export.connect(request_observer.analysis_export);
      aaxi_tb.env0.master[0].ms_rx_rvalid_export.connect(read_valid_observer.analysis_export);
      aaxi_tb.env0.master[0].channel_ap.connect(channel_observer.analysis_export);
      aaxi_tb.env0.psv_master[0].write_done_export.connect(passive_observer.completed_export);
      aaxi_tb.env0.psv_master[0].read_done_export.connect(passive_observer.completed_export);
      aaxi_tb.env0.psv_master[0].channel_ap.connect(passive_channel_observer.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
      aaxi_compat_sequence seq_inst;
      phase.raise_objection(this);
      wait (ARESETn === 1'b1);
      if (aaxi_tb.env0.psv_master[0].monitor == null ||
          aaxi_tb.env0.psv_master[0].sequencer != null ||
          aaxi_tb.env0.psv_master[0].driver.bfm_driver != null ||
          !aaxi_tb.env0.psv_master[0].driver.cfg_info.passive_mode)
        `uvm_fatal("AAXI_PASSIVE", "Passive AAXI agent must monitor without creating a sequencer or driver")
      seq_inst = aaxi_compat_sequence::type_id::create("seq_inst");
      seq_inst.start(aaxi_tb.env0.master[0].sequencer);

      if (request_observer.write_count != 1 || observer.write_count != 1 ||
          request_observer.write_request_time >= observer.write_done_time)
        `uvm_fatal("AAXI_EVENT_ORDER", "Write request export must precede write_done_export")
      if (read_valid_observer.read_count != 1 ||
          read_valid_observer.read_valid_time != observer.read_done_time)
        `uvm_fatal("AAXI_EVENT_ORDER", "Read-valid export must publish the completed read independently with read_done_export")

      fork
        begin
          while (observer.write_count != 1 || observer.read_count != 1 ||
                 channel_observer.channel_count[AXI4_CHANNEL_AW] != 1 ||
                 channel_observer.channel_count[AXI4_CHANNEL_W] != 1 ||
                 channel_observer.channel_count[AXI4_CHANNEL_B] != 1 ||
                 channel_observer.channel_count[AXI4_CHANNEL_AR] != 1 ||
                 channel_observer.channel_count[AXI4_CHANNEL_R] != 1)
            @observer.completed;
          while (passive_observer.write_count != 1 || passive_observer.read_count != 1 ||
                 passive_channel_observer.channel_count[AXI4_CHANNEL_AW] != 1 ||
                 passive_channel_observer.channel_count[AXI4_CHANNEL_W] != 1 ||
                 passive_channel_observer.channel_count[AXI4_CHANNEL_B] != 1 ||
                 passive_channel_observer.channel_count[AXI4_CHANNEL_AR] != 1 ||
                 passive_channel_observer.channel_count[AXI4_CHANNEL_R] != 1)
            @passive_observer.completed;
        end
        begin
          #10000;
          `uvm_fatal("AAXI_MONITOR", "Timed out waiting for completed AAXI records")
        end
      join_any
      disable fork;

      if (aaxi_tb.env0.master[0].driver.cfg_info.data_bus_bytes != 4)
        `uvm_fatal("AAXI_CONFIG", "Generated-path driver configuration was not retained")
      $display("PASS: SoC-IFC-compatible AAXI hierarchy drove SRAM write/read; active and passive monitors observed all AXI channels");
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    repeat (3) @(posedge ACLK);
    @(negedge ACLK); ARESETn = 1'b1;
  end

  initial run_test("aaxi_compat_test");
endmodule
