// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_caliptra_axi_mgr_uvm_bfm;
  import uvm_pkg::*;
  import axi_pkg::*;
  import axi4_caliptra_uvm_pkg::*;

  localparam integer ADDR_WIDTH = 48;
  localparam integer DATA_WIDTH = 32;
  localparam integer ID_WIDTH = 5;
  localparam logic [31:0] AXUSER = 32'hcafe_1248;

  logic clk = 0;
  logic rst_n = 0;
  logic write_valid = 0;
  logic [31:0] write_data = 0;
  wire write_ready;
  wire read_valid;
  wire [31:0] read_data;
  logic read_ready = 1;
  logic run_done = 0;
  wire [31:0] fifo_level;
  wire fifo_push_event, fifo_pop_event, recovery_data_avail;

  axi_if #(.AW(ADDR_WIDTH), .DW(DATA_WIDTH), .IW(ID_WIDTH), .UW(32)) m_axi_if (
    .clk(clk), .rst_n(rst_n)
  );
  axi_dma_req_if #(.AW(ADDR_WIDTH)) wr_req_if(.clk(clk), .rst_n(rst_n));
  axi_dma_req_if #(.AW(ADDR_WIDTH)) rd_req_if(.clk(clk), .rst_n(rst_n));
  axi4_caliptra_record_if record_if(clk);

  always #5 clk = ~clk;

  axi_mgr_wr #(.AW(ADDR_WIDTH), .DW(DATA_WIDTH), .UW(32), .IW(ID_WIDTH)) caliptra_write_manager (
    .clk(clk), .rst_n(rst_n), .m_axi_if(m_axi_if.w_mgr), .req_if(wr_req_if.snk),
    .axuser(AXUSER), .valid_i(write_valid), .data_i(write_data), .ready_o(write_ready)
  );

  axi_mgr_rd #(.AW(ADDR_WIDTH), .DW(DATA_WIDTH), .UW(32), .IW(ID_WIDTH)) caliptra_read_manager (
    .clk(clk), .rst_n(rst_n), .m_axi_if(m_axi_if.r_mgr), .req_if(rd_req_if.snk),
    .axuser(AXUSER), .ready_i(read_ready), .valid_o(read_valid), .data_o(read_data)
  );

  axi4_caliptra_dma_if_subordinate #(.ID_WIDTH(ID_WIDTH), .RECOVERY_MODE(2)) dma_target (
    .ACLK(clk), .ARESETn(rst_n),
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

  axi4_caliptra_dma_if_monitor transaction_monitor (
    .ACLK(clk), .ARESETn(rst_n),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .record_if(record_if)
  );

  task automatic issue_write;
    begin
      @(negedge clk);
      wr_req_if.addr = CALIPTRA_DMA_SRAM_BASE + 48'h200;
      wr_req_if.byte_len = 4; // Two 32-bit beats encode AXI LEN=1.
      wr_req_if.fixed = 0;
      // This is an ordinary burst; exclusive stores require a matching read.
      wr_req_if.lock = 0;
      wr_req_if.valid = 1;
      do @(posedge clk); while (wr_req_if.ready !== 1'b1);
      @(negedge clk);
      wr_req_if.valid = 0;

      for (int beat = 0; beat < 2; beat++) begin
        @(negedge clk);
        write_data = 32'hb10c_0000 | beat;
        write_valid = 1;
        do @(posedge clk); while (write_ready !== 1'b1);
      end
      @(negedge clk);
      write_valid = 0;

      do @(posedge clk); while (wr_req_if.resp_valid !== 1'b1);
      if (wr_req_if.resp != AXI_RESP_OKAY)
        $fatal(1, "Caliptra AXI write manager received response %0b", wr_req_if.resp);
    end
  endtask

  task automatic issue_read;
    integer beat;
    begin
      beat = 0;
      @(negedge clk);
      rd_req_if.addr = CALIPTRA_DMA_SRAM_BASE + 48'h200;
      rd_req_if.byte_len = 4;
      rd_req_if.fixed = 0;
      rd_req_if.lock = 0;
      rd_req_if.valid = 1;
      do @(posedge clk); while (rd_req_if.ready !== 1'b1);
      @(negedge clk);
      rd_req_if.valid = 0;

      while (beat < 2) begin
        @(posedge clk);
        if (read_valid && read_ready) begin
          if (read_data != (32'hb10c_0000 | beat))
            $fatal(1, "Caliptra AXI read manager data mismatch at beat %0d: %08h",
                   beat, read_data);
          beat++;
        end
      end
      do @(posedge clk); while (rd_req_if.resp_valid !== 1'b1);
      if (rd_req_if.resp != AXI_RESP_OKAY)
        $fatal(1, "Caliptra AXI read manager received response %0b", rd_req_if.resp);
      run_done = 1;
    end
  endtask

  class axi_mgr_bfm_scoreboard extends uvm_subscriber #(axi4_caliptra_transaction);
    int write_count;
    int read_count;
    event received;

    `uvm_component_utils(axi_mgr_bfm_scoreboard)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(axi4_caliptra_transaction item);
      if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h200 || item.id != 0 ||
          item.len != 1 || item.size != 2 || item.burst != AXI_BURST_INCR ||
          item.protocol_error)
        `uvm_fatal("AXI_MGR_RECORD", $sformatf("Bad actual-manager transaction: %s", item.convert2string()))

      if (item.is_write()) begin
        if (item.lock || item.awuser != AXUSER || item.buser != AXUSER ||
            item.resp != AXI_RESP_OKAY || item.beatQ.size() != 2 ||
            item.beatQ[0] != 32'hb10c_0000 || item.beatQ[1] != 32'hb10c_0001 ||
            item.strbQ.size() != 2 || item.strbQ[0] != 4'hf || item.strbQ[1] != 4'hf ||
            item.beat_userQ.size() != 2 || item.beat_userQ[0] != AXUSER ||
            item.beat_userQ[1] != AXUSER || item.lastQ.size() != 2 ||
            item.lastQ[0] != 0 || item.lastQ[1] != 1)
          `uvm_fatal("AXI_MGR_WRITE", "Monitor did not capture the real manager's complete write")
        write_count++;
      end else if (item.is_read()) begin
        if (item.lock || item.aruser != AXUSER || item.resp != AXI_RESP_OKAY ||
            item.beatQ.size() != 2 || item.beatQ[0] != 32'hb10c_0000 ||
            item.beatQ[1] != 32'hb10c_0001 || item.respQ.size() != 2 ||
            item.respQ[0] != AXI_RESP_OKAY || item.respQ[1] != AXI_RESP_OKAY ||
            item.beat_userQ.size() != 2 || item.beat_userQ[0] != AXUSER ||
            item.beat_userQ[1] != AXUSER || item.lastQ.size() != 2 ||
            item.lastQ[0] != 0 || item.lastQ[1] != 1)
          `uvm_fatal("AXI_MGR_READ", "Monitor did not capture the real manager's complete read")
        read_count++;
      end else begin
        `uvm_fatal("AXI_MGR_KIND", "Unknown actual-manager transaction direction")
      end
      -> received;
    endfunction
  endclass

  class axi_mgr_bfm_env extends uvm_env;
    axi4_caliptra_uvm_agent agent;
    axi_mgr_bfm_scoreboard scoreboard;
    `uvm_component_utils(axi_mgr_bfm_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = axi4_caliptra_uvm_agent::type_id::create("agent", this);
      scoreboard = axi_mgr_bfm_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.ap.connect(scoreboard.analysis_export);
    endfunction
  endclass

  class axi_mgr_uvm_bfm_test extends uvm_test;
    axi_mgr_bfm_env env;
    `uvm_component_utils(axi_mgr_uvm_bfm_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = axi_mgr_bfm_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      fork
        begin
          wait (run_done && env.scoreboard.write_count == 1 && env.scoreboard.read_count == 1);
        end
        begin
          #10000;
          `uvm_fatal("AXI_MGR_TIMEOUT", "Timed out waiting for actual Caliptra manager records")
        end
      join_any
      disable fork;
      $display("PASS: Caliptra AXI read/write managers completed monitored traffic through the open DMA target and UVM BFM adapter");
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    wr_req_if.valid = 0;
    wr_req_if.addr = 0;
    wr_req_if.byte_len = 0;
    wr_req_if.fixed = 0;
    wr_req_if.lock = 0;
    rd_req_if.valid = 0;
    rd_req_if.addr = 0;
    rd_req_if.byte_len = 0;
    rd_req_if.fixed = 0;
    rd_req_if.lock = 0;
    uvm_config_db#(uvm_active_passive_enum)::set(
      null, "uvm_test_top.env.agent", "is_active", UVM_PASSIVE);
    uvm_config_db#(virtual axi4_caliptra_record_if)::set(
      null, "uvm_test_top.env.agent.monitor", "vif", record_if);
    run_test("axi_mgr_uvm_bfm_test");
  end

  initial begin
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    wait (rst_n === 1'b1);
    issue_write();
    issue_read();
  end
endmodule
