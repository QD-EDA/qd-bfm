// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_axi4_caliptra_uvm_axi_if;
  import uvm_pkg::*;
  import axi_pkg::*;
  import axi4_caliptra_uvm_pkg::*;

  reg ACLK = 0;
  reg ARESETn = 0;
  wire [31:0] fifo_level;
  wire fifo_push_event, fifo_pop_event, recovery_data_avail;

  axi_if #(.AW(48), .DW(32), .IW(8), .UW(32)) m_axi_if (
    .clk(ACLK), .rst_n(ARESETn)
  );
  axi4_caliptra_master_cmd_if cmd_if(ACLK);
  axi4_caliptra_record_if record_if(ACLK);

  assign cmd_if.ARESETn = ARESETn;
  always #5 ACLK = ~ACLK;

  axi4_caliptra_uvm_master_proxy proxy (
    .cmd_if(cmd_if), .ACLK(ACLK), .ARESETn(ARESETn),
    .AWID(m_axi_if.awid), .AWADDR(m_axi_if.awaddr), .AWLEN(m_axi_if.awlen),
    .AWSIZE(m_axi_if.awsize), .AWBURST(m_axi_if.awburst),
    .AWLOCK(m_axi_if.awlock), .AWUSER(m_axi_if.awuser),
    .AWVALID(m_axi_if.awvalid), .AWREADY(m_axi_if.awready),
    .WDATA(m_axi_if.wdata), .WSTRB(m_axi_if.wstrb), .WUSER(m_axi_if.wuser),
    .WLAST(m_axi_if.wlast), .WVALID(m_axi_if.wvalid), .WREADY(m_axi_if.wready),
    .BID(m_axi_if.bid), .BRESP(m_axi_if.bresp), .BUSER(m_axi_if.buser),
    .BVALID(m_axi_if.bvalid), .BREADY(m_axi_if.bready),
    .ARID(m_axi_if.arid), .ARADDR(m_axi_if.araddr), .ARLEN(m_axi_if.arlen),
    .ARSIZE(m_axi_if.arsize), .ARBURST(m_axi_if.arburst),
    .ARLOCK(m_axi_if.arlock), .ARUSER(m_axi_if.aruser),
    .ARVALID(m_axi_if.arvalid), .ARREADY(m_axi_if.arready),
    .RID(m_axi_if.rid), .RDATA(m_axi_if.rdata), .RRESP(m_axi_if.rresp),
    .RUSER(m_axi_if.ruser), .RLAST(m_axi_if.rlast), .RVALID(m_axi_if.rvalid),
    .RREADY(m_axi_if.rready)
  );

  axi4_caliptra_dma_if_subordinate #(.RECOVERY_MODE(2)) dma_target (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .fifo_clear(1'b0), .auto_fifo_push(1'b0), .auto_fifo_pop(1'b0),
    .use_dma_gen_sequence(1'b0), .dma_gen_done(1'b0),
    .dma_gen_block_size_bytes(1200'b0), .en_recovery_emulation(1'b0),
    .recovery_threshold_words(32'd2), .recovery_block_words(32'd8),
    .inject_error(cmd_if.inject_target_error),
    .stall_sram_aw(1'b0), .stall_sram_w(1'b0), .stall_sram_b(1'b0),
    .stall_sram_ar(1'b0), .stall_sram_r(1'b0),
    .stall_fifo_aw(1'b0), .stall_fifo_w(1'b0), .stall_fifo_b(1'b0),
    .stall_fifo_ar(1'b0), .stall_fifo_r(1'b0),
    .fifo_level(fifo_level), .fifo_push_event(fifo_push_event),
    .fifo_pop_event(fifo_pop_event), .recovery_data_avail(recovery_data_avail)
  );

  axi4_caliptra_dma_if_monitor transaction_monitor (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .record_if(record_if)
  );

  class axi4_caliptra_if_scoreboard extends uvm_subscriber #(axi4_caliptra_transaction);
    int sram_write_count;
    int sram_read_count;
    int fifo_write_count;
    int fifo_read_count;
    int long_write_count;
    int long_read_count;
    int error_read_count;
    event received;

    `uvm_component_utils(axi4_caliptra_if_scoreboard)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(axi4_caliptra_transaction item);
      if (item.protocol_error)
        `uvm_fatal("AXI_IF_MONITOR", $sformatf("Monitor flagged protocol error: %s", item.convert2string()))

      case (item.addr)
        CALIPTRA_DMA_SRAM_BASE + 48'h20: begin
          if (item.is_write()) begin
            if (item.id != 8'h31 || item.lock || item.awuser != 32'h1122_3344 ||
                item.beatQ.size() != 2 || item.beatQ[0] != 32'ha5a5_5a5a ||
                item.beatQ[1] != 32'h1357_9bdf || item.resp != 0)
              `uvm_fatal("AXI_IF_SRAM_WRITE", "Unexpected UVM monitor record for SRAM write")
            sram_write_count++;
          end else if (item.is_read()) begin
            if (item.id == 8'h43) begin
              if (item.aruser != 32'hface_cafe || item.len != 0 ||
                  item.beatQ.size() != 1 || item.respQ.size() != 1 ||
                  item.resp != 2'b10 || item.respQ[0] != 2'b10)
                `uvm_fatal("AXI_IF_SRAM_SLVERR", "Unexpected UVM monitor record for injected SLVERR read")
              error_read_count++;
            end else begin
              if (item.id != 8'h42 || item.aruser != 32'h89ab_cdef ||
                  item.beatQ.size() != 2 || item.beatQ[0] != 32'ha5a5_5a5a ||
                  item.beatQ[1] != 32'h1357_9bdf || item.respQ.size() != 2 ||
                  item.respQ[0] != 0 || item.respQ[1] != 0)
                `uvm_fatal("AXI_IF_SRAM_READ", "Unexpected UVM monitor record for SRAM read")
              sram_read_count++;
            end
          end
        end
        CALIPTRA_DMA_FIFO_BASE: begin
          if (item.is_write()) begin
            if (item.id != 8'h51 || item.beatQ.size() != 2 ||
                item.beatQ[0] != 32'hc001_0001 || item.beatQ[1] != 32'hc001_0002)
              `uvm_fatal("AXI_IF_FIFO_WRITE", "Unexpected UVM monitor record for FIFO write")
            fifo_write_count++;
          end else if (item.is_read()) begin
            if (item.id != 8'h52 || item.beatQ.size() != 2 ||
                item.beatQ[0] != 32'hc001_0001 || item.beatQ[1] != 32'hc001_0002)
              `uvm_fatal("AXI_IF_FIFO_READ", "Unexpected UVM monitor record for FIFO read")
            fifo_read_count++;
          end
        end
        CALIPTRA_DMA_SRAM_BASE + 48'h1000: begin
          if (item.is_write()) begin
            if (item.id != 8'h60 || item.len != 8'hff || item.beatQ.size() != 256 ||
                item.beatQ[255] != (32'hd00d_0000 ^ 255) || item.lastQ.size() != 256 ||
                !item.lastQ[255] || item.resp != 0)
              `uvm_fatal("AXI_IF_LONG_WRITE", "Unexpected UVM monitor record for 256-beat write")
            long_write_count++;
          end else if (item.is_read()) begin
            if (item.id != 8'h61 || item.len != 8'hff || item.beatQ.size() != 256 ||
                item.beatQ[255] != (32'hd00d_0000 ^ 255) || item.respQ.size() != 256 ||
                item.respQ[255] != 0 || item.lastQ.size() != 256 || !item.lastQ[255])
              `uvm_fatal("AXI_IF_LONG_READ", "Unexpected UVM monitor record for 256-beat read")
            long_read_count++;
          end
        end
        default:
          `uvm_fatal("AXI_IF_ADDR", $sformatf("Unexpected completed address %012h", item.addr))
      endcase
      -> received;
    endfunction
  endclass

  class axi4_caliptra_if_error_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_if_error_sequence)

    function new(string name = "axi4_caliptra_if_error_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;
      req = axi4_caliptra_uvm_transfer::type_id::create("slverr_read_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h20;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h43;
      req.user = 32'hface_cafe;
      finish_item(req);
      if (req.success || req.read_response[0 +: 2] != 2'b10)
        `uvm_fatal("AXI_IF_SLVERR", "UVM driver did not preserve injected SLVERR status")
    endtask
  endclass

  class axi4_caliptra_if_env extends uvm_env;
    axi4_caliptra_uvm_agent agent;
    axi4_caliptra_if_scoreboard scoreboard;

    `uvm_component_utils(axi4_caliptra_if_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = axi4_caliptra_uvm_agent::type_id::create("agent", this);
      scoreboard = axi4_caliptra_if_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.ap.connect(scoreboard.analysis_export);
    endfunction
  endclass

  class axi4_caliptra_uvm_axi_if_test extends uvm_test;
    axi4_caliptra_if_env env;
    `uvm_component_utils(axi4_caliptra_uvm_axi_if_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = axi4_caliptra_if_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      axi4_caliptra_uvm_smoke_sequence smoke;
      axi4_caliptra_if_error_sequence error_seq;
      axi4_caliptra_fifo_uvm_sequence fifo;
      axi4_caliptra_full_range_uvm_sequence full_range;
      phase.raise_objection(this);
      wait (ARESETn === 1'b1);

      smoke = axi4_caliptra_uvm_smoke_sequence::type_id::create("smoke");
      smoke.start(env.agent.sequencer);
      env.agent.driver.cmd_vif.inject_target_error = 1'b1;
      error_seq = axi4_caliptra_if_error_sequence::type_id::create("error_seq");
      error_seq.start(env.agent.sequencer);
      env.agent.driver.cmd_vif.inject_target_error = 1'b0;
      fifo = axi4_caliptra_fifo_uvm_sequence::type_id::create("fifo");
      fifo.start(env.agent.sequencer);
      full_range = axi4_caliptra_full_range_uvm_sequence::type_id::create("full_range");
      full_range.start(env.agent.sequencer);

      fork
        begin
          while (env.scoreboard.sram_write_count == 0 || env.scoreboard.sram_read_count == 0 ||
                 env.scoreboard.fifo_write_count == 0 || env.scoreboard.fifo_read_count == 0 ||
                 env.scoreboard.long_write_count == 0 || env.scoreboard.long_read_count == 0 ||
                 env.scoreboard.error_read_count == 0)
            @env.scoreboard.received;
        end
        begin
          #20000;
          `uvm_fatal("AXI_IF_TIMEOUT", "Timed out waiting for actual axi_if UVM monitor records")
        end
      join_any
      disable fork;
      $display("PASS: UVM AXI agent, DMA target and monitor completed SRAM/FIFO, SLVERR and 256-beat traffic through Caliptra axi_if");
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    uvm_config_db#(virtual axi4_caliptra_master_cmd_if)::set(
      null, "uvm_test_top.env.agent.driver", "cmd_vif", cmd_if);
    uvm_config_db#(virtual axi4_caliptra_record_if)::set(
      null, "uvm_test_top.env.agent.monitor", "vif", record_if);
    run_test("axi4_caliptra_uvm_axi_if_test");
  end

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK);
    ARESETn = 1;
  end
endmodule
