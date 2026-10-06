// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_caliptra_axi_dma_top_uvm_bfm;
  import uvm_pkg::*;
  import axi_pkg::*;
  import soc_ifc_pkg::*;
  import kv_defines_pkg::*;
  import caliptra_top_tb_pkg::*;
  import axi4_caliptra_uvm_pkg::*;

  typedef struct packed {
    logic [11:0] block_size;
    logic src_is_fifo;
    logic dst_is_fifo;
    logic use_rd_fixed;
    logic use_wr_fixed;
    logic inject_rand_delays;
    logic inject_rst;
    logic test_block_size;
    dma_transfer_type_e dma_xfer_type;
  } dma_case_type_t;

  localparam integer ADDR_WIDTH = 48;
  localparam integer DATA_WIDTH = 32;
  localparam integer ID_WIDTH = 5;
  localparam integer WORD_COUNT = 65;
  localparam integer MAX_REPLAY_WORD_COUNT = 65536;
  localparam integer MAX_DCCM_PAYLOAD_WORDS = 16384;
  localparam integer MAX_BURST_WORDS = 64;
  localparam integer MAX_FIXED_BURST_WORDS = 16;
  localparam logic [47:0] SRAM_BASE_ADDR = 48'h0001_2344_0000;
  localparam logic [47:0] FIFO_BASE_ADDR = 48'h0000_fa57_0000;
  localparam integer RECOVERY_BLOCK_WORDS = 16;
  localparam logic [31:0] AXUSER = 32'hcafe_1248;
  localparam logic [31:0] DMA_RANDOM_SEED = 32'h00c0_ffee;
  integer active_word_count = WORD_COUNT;
  integer active_read_burst_count = 2;
  integer active_write_burst_count = 2;
  logic [47:0] SRC_ADDR;
  logic [47:0] DST_ADDR;
  logic [31:0] expected_payload [0:MAX_REPLAY_WORD_COUNT-1];
  logic [31:0] mailbox_mem [0:MAX_REPLAY_WORD_COUNT-1];
  integer source_word_index;
  integer destination_word_index;

  logic clk = 0;
  logic rst_n = 0;
  logic enable_random_stalls = 0;
  wire [9:0] random_stall;
  integer randomized_stall_cycles = 0;
  wire randomized_target_stall =
      (random_stall[0] && !dma_target.bfm.aw_to_fifo && m_axi_if.awvalid && !m_axi_if.awready) ||
      (random_stall[5] &&  dma_target.bfm.aw_to_fifo && m_axi_if.awvalid && !m_axi_if.awready) ||
      (random_stall[1] && dma_target.bfm.wr_route_count != 0 &&
       !dma_target.bfm.wr_route_fifo_q[dma_target.bfm.wr_route_head] &&
       m_axi_if.wvalid && !m_axi_if.wready) ||
      (random_stall[6] && dma_target.bfm.wr_route_count != 0 &&
       dma_target.bfm.wr_route_fifo_q[dma_target.bfm.wr_route_head] &&
       m_axi_if.wvalid && !m_axi_if.wready) ||
      (random_stall[2] && dma_target.bfm.i_sram.b_count != 0 && !m_axi_if.bvalid) ||
      (random_stall[7] && dma_target.bfm.i_fifo.b_pending && !m_axi_if.bvalid) ||
      (random_stall[3] && !dma_target.bfm.ar_to_fifo && m_axi_if.arvalid && !m_axi_if.arready) ||
      (random_stall[8] &&  dma_target.bfm.ar_to_fifo && m_axi_if.arvalid && !m_axi_if.arready) ||
      (random_stall[4] && dma_target.bfm.i_sram.rd_count != 0 && !m_axi_if.rvalid) ||
      (random_stall[9] && dma_target.bfm.i_fifo.rd_active &&
       dma_target.bfm.i_fifo.fifo_count != 0 && !m_axi_if.rvalid);
  logic cptra_pwrgood = 0;
  logic dv = 0;
  soc_ifc_req_t req_data;
  wire hold;
  wire [SOC_IFC_DATA_W-1:0] rdata;
  wire error;
  wire [31:0] fifo_level;
  wire fifo_push_event, fifo_pop_event, recovery_data_avail;
  logic run_done = 0;
  integer generated_case_index = 0;
  integer auto_fifo_source_push_count = 0;
  integer auto_fifo_source_pop_count = 0;
  dma_transfer_type_e generated_dma_xfer_type;
  bit generated_route_ready = 0;
  bit mailbox_case = 0;
  bit mailbox_read_case = 0;
  bit ahb2axi_case = 0;
  bit axi2ahb_case = 0;
  bit sram2fifo_case = 0;
  bit auto_fifo_source_case = 0;
  integer mailbox_word_index = 0;
  integer mailbox_hold_cycles = 0;

  axi_if #(.AW(ADDR_WIDTH), .DW(DATA_WIDTH), .IW(ID_WIDTH), .UW(32)) m_axi_if (
    .clk(clk), .rst_n(rst_n)
  );
  axi4_caliptra_record_if record_if(clk);

  kv_rd_resp_t kv_rd_resp;
  kv_read_t kv_read;
  wire aes_req_dv;
  wire mb_dv;
  logic mb_hold;
  logic [DATA_WIDTH-1:0] mb_rdata;
  wire soc_ifc_req_t mb_data;
  wire notif_intr, error_intr;
  logic inject_error = 1'b0;
  bit expect_dma_error = 1'b0;
  bit fifo_recovery_case = 1'b0;
  logic recovery_emulation = 1'b0;
  logic [99:0][11:0] dma_gen_block_size_bytes = '0;
  logic testcase_preload_done = 1'b0;
  logic testcase_generator_done;
  logic [99:0][11:0] testcase_generator_block_sizes;
  localparam logic [31:0] DCCM_BASE_ADDR = 32'h5000_0000;
  localparam logic [31:0] DCCM_END_ADDR = 32'h5003_ffff;
  localparam integer DCCM_WORDS = 65536;
  logic [38:0] dccm_shadow [0:DCCM_WORDS-1];

  always #5 clk = ~clk;

  axi4_caliptra_random_stalls #(.CHANNELS(10)) i_random_stalls (
    .ACLK(clk), .ARESETn(rst_n), .enable(enable_random_stalls), .stall(random_stall)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      randomized_stall_cycles <= 0;
    else if (enable_random_stalls && randomized_target_stall)
      randomized_stall_cycles <= randomized_stall_cycles + 1;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      auto_fifo_source_push_count <= 0;
      auto_fifo_source_pop_count <= 0;
    end else begin
      if (auto_fifo_source_case && fifo_push_event) begin
        if (auto_fifo_source_push_count >= active_word_count)
          $fatal(1, "FIFO source producer exceeded %0d words", active_word_count);
        auto_fifo_source_push_count <= auto_fifo_source_push_count + 1;
      end
      if (auto_fifo_source_case && fifo_pop_event) begin
        if (auto_fifo_source_pop_count >= active_word_count)
          $fatal(1, "FIFO source consumer exceeded %0d words", active_word_count);
        expected_payload[auto_fifo_source_pop_count] <=
            dma_target.bfm.i_fifo.fifo_mem[dma_target.bfm.i_fifo.fifo_read_ptr];
        auto_fifo_source_pop_count <= auto_fifo_source_pop_count + 1;
      end
    end
  end

  always_comb begin
    mb_hold = (mailbox_case || mailbox_read_case) && mb_dv && (mailbox_hold_cycles == 0);
    mb_rdata = (mailbox_read_case && mailbox_word_index < active_word_count) ?
               mailbox_mem[mailbox_word_index] : DATA_WIDTH'(0);
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mailbox_word_index <= 0;
      mailbox_hold_cycles <= 0;
    end else if ((!mailbox_case && !mailbox_read_case) || !mb_dv) begin
      mailbox_hold_cycles <= 0;
    end else if (mb_hold) begin
      mailbox_hold_cycles <= mailbox_hold_cycles + 1;
    end else begin
      mailbox_hold_cycles <= 0;
      if (mailbox_word_index >= active_word_count)
        $fatal(1, "Mailbox route emitted more than %0d requests", active_word_count);
      if (mb_data.soc_req || (mb_data.id !== '1) || (mb_data.user !== '0) ||
          (mb_data.wstrb !== '1))
        $fatal(1, "Mailbox request had invalid metadata: %p", mb_data);
      if (mailbox_case) begin
        if (!mb_data.write ||
            mb_data.addr !== SOC_IFC_ADDR_W'(DST_ADDR + 48'(mailbox_word_index * 4)) ||
            mb_data.wdata !== expected_payload[mailbox_word_index])
          $fatal(1, "AXI2MBOX word %0d mismatch: addr=%08h data=%08h",
                 mailbox_word_index, mb_data.addr, mb_data.wdata);
        mailbox_mem[mailbox_word_index] <= mb_data.wdata;
      end else if (mb_data.write ||
                   mb_data.addr !== SOC_IFC_ADDR_W'(SRC_ADDR + 48'(mailbox_word_index * 4)) ||
                   mb_rdata !== mailbox_mem[mailbox_word_index] ||
                   mb_rdata !== expected_payload[mailbox_word_index]) begin
        $fatal(1, "MBOX2AXI word %0d mismatch: addr=%08h data=%08h",
               mailbox_word_index, mb_data.addr, mb_rdata);
      end
      mailbox_word_index <= mailbox_word_index + 1;
    end
  end

  dma_testcase_generator i_dma_testcase_generator (
    .preload_dccm_done(testcase_preload_done),
    .dma_gen_done(testcase_generator_done),
    .dma_gen_block_size(testcase_generator_block_sizes)
  );

  task automatic slam_dccm_ram(input logic [31:0] addr, input logic [38:0] data);
    integer word_index;
    begin
      if ((addr < DCCM_BASE_ADDR) || (addr > DCCM_END_ADDR) || (addr[1:0] != 0))
        $fatal(1, "DMA testcase generator wrote invalid DCCM address %08h", addr);
      word_index = int'((addr - DCCM_BASE_ADDR) >> 2);
      dccm_shadow[word_index] = data;
    end
  endtask

  function automatic logic [6:0] riscv_ecc32(input logic [31:0] data);
    logic [6:0] synd;
    synd[0] = ^(data & 32'h56aa_ad5b);
    synd[1] = ^(data & 32'h9b33_366d);
    synd[2] = ^(data & 32'he3c3_c78e);
    synd[3] = ^(data & 32'h03fc_07f0);
    synd[4] = ^(data & 32'h03ff_f800);
    synd[5] = ^(data & 32'hfc00_0000);
    synd[6] = ^{data, synd[5:0]};
    return synd;
  endfunction

  function automatic bit valid_dccm_word(input logic [38:0] data);
    return (data[31:0] == 0) ? (data[38:32] == 0) : (data[38:32] == riscv_ecc32(data[31:0]));
  endfunction

  function automatic integer axi_incr_burst_count(input logic [47:0] start_addr,
                                                   input integer word_count);
    logic [47:0] addr;
    integer remaining;
    integer burst_words;
    integer count;
    begin
      addr = start_addr;
      remaining = word_count;
      count = 0;
      while (remaining > 0) begin
        burst_words = MAX_BURST_WORDS - int'(addr[7:2]);
        if (burst_words > remaining)
          burst_words = remaining;
        remaining = remaining - burst_words;
        addr = addr + (48'(burst_words) << 2);
        count++;
      end
      return count;
    end
  endfunction

  axi_dma_top #(
    .AW(ADDR_WIDTH), .DW(DATA_WIDTH), .UW(32), .IW(ID_WIDTH)
  ) dma (
    .clk(clk), .cptra_pwrgood(cptra_pwrgood), .rst_n(rst_n),
    .recovery_data_avail(recovery_data_avail),
    .recovery_image_activated(recovery_emulation),
    .mbox_lock(mailbox_case || mailbox_read_case), .sha_lock(1'b0),
    .debugUnlock_or_scan_mode_switch(1'b0), .ocp_lock_in_progress(1'b0),
    .key_release_addr(64'b0), .key_release_size(16'b0),
    .aes_input_ready(1'b0), .aes_output_valid(1'b0), .aes_status_idle(1'b1),
    .aes_req_dv(aes_req_dv), .aes_req_hold(1'b0), .aes_req_data(),
    .aes_rdata(DATA_WIDTH'(0)), .aes_err(1'b0),
    .kv_read(kv_read), .kv_rd_resp(kv_rd_resp), .axuser(AXUSER),
    .m_axi_w_if(m_axi_if.w_mgr), .m_axi_r_if(m_axi_if.r_mgr),
    .dv(dv), .req_data(req_data), .hold(hold), .rdata(rdata), .error(error),
    .mb_dv(mb_dv), .mb_hold(mb_hold), .mb_error(1'b0), .mb_data(mb_data),
    .mb_rdata(mb_rdata), .notif_intr(notif_intr), .error_intr(error_intr)
  );

  axi4_caliptra_dma_if_subordinate #(.ID_WIDTH(ID_WIDTH), .RECOVERY_MODE(2)) dma_target (
    .ACLK(clk), .ARESETn(rst_n),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .fifo_clear(1'b0),
    .auto_fifo_push(recovery_emulation ||
                    (auto_fifo_source_case &&
                     auto_fifo_source_push_count < active_word_count &&
                     !(fifo_push_event &&
                       auto_fifo_source_push_count == active_word_count - 1))),
    .auto_fifo_pop(1'b0),
    .use_dma_gen_sequence(fifo_recovery_case), .dma_gen_done(fifo_recovery_case),
    .dma_gen_block_size_bytes(dma_gen_block_size_bytes),
    .en_recovery_emulation(recovery_emulation),
    .recovery_threshold_words(32'd2), .recovery_block_words(32'd8),
    .inject_error(inject_error),
    .stall_sram_aw(random_stall[0]), .stall_sram_w(random_stall[1]),
    .stall_sram_b(random_stall[2]), .stall_sram_ar(random_stall[3]),
    .stall_sram_r(random_stall[4]), .stall_fifo_aw(random_stall[5]),
    .stall_fifo_w(random_stall[6]), .stall_fifo_b(random_stall[7]),
    .stall_fifo_ar(random_stall[8]), .stall_fifo_r(random_stall[9]),
    .fifo_level(fifo_level), .fifo_push_event(fifo_push_event),
    .fifo_pop_event(fifo_pop_event), .recovery_data_avail(recovery_data_avail)
  );

  axi4_caliptra_dma_if_monitor transaction_monitor (
    .ACLK(clk), .ARESETn(rst_n),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .record_if(record_if)
  );

  task automatic write_reg(input logic [11:0] addr, input logic [31:0] value);
    begin
      @(negedge clk);
      req_data = '0;
      req_data.addr = addr;
      req_data.wdata = value;
      req_data.wstrb = '1;
      req_data.write = 1'b1;
      dv = 1'b1;
      @(posedge clk);
      @(negedge clk);
      dv = 1'b0;
      req_data = '0;
    end
  endtask

  task automatic read_status(output logic [31:0] value);
    begin
      @(negedge clk);
      req_data = '0;
      req_data.addr = 12'h00c;
      req_data.write = 1'b0;
      dv = 1'b1;
      #1;
      if (hold !== 1'b0 || error !== 1'b0)
        $fatal(1, "DMA status read failed: hold=%b error=%b", hold, error);
      value = rdata;
      @(negedge clk);
      dv = 1'b0;
      req_data = '0;
    end
  endtask

  task automatic read_component_data(output logic [31:0] value);
    begin
      @(negedge clk);
      req_data = '0;
      req_data.addr = 12'h030;
      req_data.write = 1'b0;
      dv = 1'b1;
      #1;
      if (hold !== 1'b0 || error !== 1'b0)
        $fatal(1, "DMA component data read failed: hold=%b error=%b", hold, error);
      value = rdata;
      @(posedge clk);
      @(negedge clk);
      dv = 1'b0;
      req_data = '0;
    end
  endtask

  class axi_dma_top_bfm_scoreboard extends uvm_subscriber #(axi4_caliptra_transaction);
    int write_count;
    int read_count;
    int read_word_offset;
    int write_word_offset;
    bit expect_error;
    bit expect_fifo_recovery;
    bit expect_fifo_source;
    bit expect_fifo_write;

    `uvm_component_utils(axi_dma_top_bfm_scoreboard)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(bit)::get(this, "", "expect_error", expect_error))
        expect_error = 1'b0;
      if (!uvm_config_db#(bit)::get(this, "", "expect_fifo_recovery", expect_fifo_recovery))
        expect_fifo_recovery = 1'b0;
      if (!uvm_config_db#(bit)::get(this, "", "expect_fifo_source", expect_fifo_source))
        expect_fifo_source = 1'b0;
      if (!uvm_config_db#(bit)::get(this, "", "expect_fifo_write", expect_fifo_write))
        expect_fifo_write = 1'b0;
    endfunction

    function logic [31:0] source_word(input int index);
      return expected_payload[index];
    endfunction

    function void write(axi4_caliptra_transaction item);
      int beats;
      int beat;
      int expected_beats;
      int boundary_beats;
      logic [1:0] expected_resp;
      expected_resp = expect_error ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
      if (item.id != 0 || item.size != 2 || item.lock || item.protocol_error)
        `uvm_fatal("DMA_TOP_RECORD", $sformatf("Bad DMA AXI transaction: %s", item.convert2string()))
      beats = item.len + 1;
      if (beats > MAX_BURST_WORDS)
        `uvm_fatal("DMA_TOP_BURST_SIZE", $sformatf("DMA burst exceeds 64 beats: %s", item.convert2string()))

      if (item.is_read()) begin
        expected_beats = active_word_count - read_word_offset;
        if (expect_fifo_recovery || expect_fifo_source) begin
          if (expect_fifo_recovery && expected_beats > RECOVERY_BLOCK_WORDS)
            expected_beats = RECOVERY_BLOCK_WORDS;
          else if (expect_fifo_source && expected_beats > MAX_FIXED_BURST_WORDS)
            expected_beats = MAX_FIXED_BURST_WORDS;
          if (item.burst != AXI_BURST_FIXED || item.addr != SRC_ADDR)
            `uvm_fatal("DMA_TOP_FIFO_READ_PROFILE", $sformatf("DMA FIFO read was not a fixed stream burst: %s", item.convert2string()))
        end else begin
          boundary_beats = MAX_BURST_WORDS - int'(item.addr[7:2]);
          if (expected_beats > boundary_beats) expected_beats = boundary_beats;
          if (item.burst != AXI_BURST_INCR ||
              item.addr != SRC_ADDR + 48'(read_word_offset * 4))
            `uvm_fatal("DMA_TOP_READ_PROFILE", $sformatf("DMA SRAM read address/burst mismatch: %s", item.convert2string()))
        end
        if (item.aruser != AXUSER || item.resp != expected_resp ||
            beats != expected_beats ||
            item.beatQ.size() != beats || item.beat_userQ.size() != beats ||
            item.respQ.size() != beats || item.lastQ.size() != beats)
          `uvm_fatal("DMA_TOP_READ", $sformatf("DMA source read mismatch: %s", item.convert2string()))
        if (expect_fifo_source && auto_fifo_source_pop_count < read_word_offset + beats)
          `uvm_fatal("DMA_TOP_FIFO_SOURCE_ORDER", "FIFO target popped data before source capture completed")
        for (beat = 0; beat < beats; beat++) begin
          if ((expect_fifo_source && (^item.beatQ[beat] === 1'bx)) ||
              (!expect_fifo_recovery &&
               item.beatQ[beat] != source_word(read_word_offset + beat)) ||
              item.beat_userQ[beat] != AXUSER || item.respQ[beat] != expected_resp ||
              item.lastQ[beat] != (beat == beats - 1))
            `uvm_fatal("DMA_TOP_READ_BEAT", $sformatf("DMA read beat %0d mismatch in burst %0d", beat, read_count))
          if (expect_fifo_recovery)
            expected_payload[read_word_offset + beat] = item.beatQ[beat];
        end
        read_word_offset += beats;
        read_count++;
      end else if (item.is_write()) begin
        boundary_beats = MAX_BURST_WORDS - int'(item.addr[7:2]);
        expected_beats = active_word_count - write_word_offset;
        if (expect_fifo_write) begin
          if (expected_beats > RECOVERY_BLOCK_WORDS)
            expected_beats = RECOVERY_BLOCK_WORDS;
          if (item.addr != DST_ADDR || item.burst != AXI_BURST_FIXED)
            `uvm_fatal("DMA_TOP_FIFO_WRITE_PROFILE", $sformatf("DMA FIFO write was not a fixed stream burst: %s", item.convert2string()))
        end else begin
          if (expected_beats > boundary_beats) expected_beats = boundary_beats;
          if (item.addr != DST_ADDR + 48'(write_word_offset * 4) ||
              item.burst != AXI_BURST_INCR)
            `uvm_fatal("DMA_TOP_WRITE_PROFILE", $sformatf("DMA SRAM write address/burst mismatch: %s", item.convert2string()))
        end
        if (expect_fifo_recovery && expected_beats > RECOVERY_BLOCK_WORDS)
          expected_beats = RECOVERY_BLOCK_WORDS;
        if (item.awuser != AXUSER ||
            item.buser != AXUSER || item.resp != expected_resp ||
            beats != expected_beats ||
            item.beatQ.size() != beats || item.strbQ.size() != beats ||
            item.beat_userQ.size() != beats || item.lastQ.size() != beats)
          `uvm_fatal("DMA_TOP_WRITE", $sformatf("DMA destination write mismatch: %s", item.convert2string()))
        for (beat = 0; beat < beats; beat++) begin
          if (item.beatQ[beat] != source_word(write_word_offset + beat) ||
              item.strbQ[beat] != 4'hf || item.beat_userQ[beat] != AXUSER ||
              item.lastQ[beat] != (beat == beats - 1))
            `uvm_fatal("DMA_TOP_WRITE_BEAT", $sformatf("DMA write beat %0d mismatch in burst %0d", beat, write_count))
        end
        write_word_offset += beats;
        write_count++;
      end else begin
        `uvm_fatal("DMA_TOP_KIND", "Unknown DMA AXI transaction direction")
      end
    endfunction
  endclass

  class axi_dma_top_bfm_env extends uvm_env;
    axi4_caliptra_uvm_agent agent;
    axi_dma_top_bfm_scoreboard scoreboard;
    `uvm_component_utils(axi_dma_top_bfm_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = axi4_caliptra_uvm_agent::type_id::create("agent", this);
      scoreboard = axi_dma_top_bfm_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.ap.connect(scoreboard.analysis_export);
    endfunction
  endclass

  class axi_dma_top_uvm_bfm_test extends uvm_test;
    axi_dma_top_bfm_env env;
    `uvm_component_utils(axi_dma_top_uvm_bfm_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = axi_dma_top_bfm_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      int expected_read_prefix;
      int expected_write_prefix;
      phase.raise_objection(this);
      fork
        begin
          if (expect_dma_error) begin
            wait (run_done && env.scoreboard.read_count == 1 && env.scoreboard.write_count == 1);
            expected_read_prefix = MAX_BURST_WORDS - int'(SRC_ADDR[7:2]);
            expected_write_prefix = MAX_BURST_WORDS - int'(DST_ADDR[7:2]);
            if (env.scoreboard.read_word_offset != expected_read_prefix ||
                env.scoreboard.write_word_offset != expected_write_prefix)
              `uvm_fatal("DMA_TOP_ERROR_PREFIX", $sformatf("Unexpected partial error transfer: read=%0d write=%0d expected=%0d/%0d",
                         env.scoreboard.read_word_offset, env.scoreboard.write_word_offset,
                         expected_read_prefix, expected_write_prefix))
            for (int word = 0; word < WORD_COUNT; word++) begin
              if (word < expected_write_prefix) begin
                if (dma_target.bfm.i_sram.word_at(destination_word_index + word) !== expected_payload[word])
                  `uvm_fatal("DMA_TOP_ERROR_DATA", $sformatf("Partial destination word %0d mismatch", word))
              end else if (dma_target.bfm.i_sram.word_at(destination_word_index + word) !== 32'b0) begin
                `uvm_fatal("DMA_TOP_ERROR_TAIL", $sformatf("Unexpected destination write after error at word %0d", word))
              end
            end
          end else if ($test$plusargs("AXI2MBOX_CASE") || $test$plusargs("MBOX2AXI_CASE")) begin
            if ($test$plusargs("AXI2MBOX_CASE")) begin
              wait (run_done && env.scoreboard.read_count == 2 &&
                    env.scoreboard.read_word_offset == WORD_COUNT &&
                    mailbox_word_index == WORD_COUNT);
              if (env.scoreboard.write_count != 0)
                `uvm_fatal("DMA_TOP_MBOX_AXI_WRITE", "AXI2MBOX unexpectedly issued an AXI write")
            end else begin
              wait (run_done && env.scoreboard.read_count == 0 &&
                    env.scoreboard.write_count == 2 &&
                    env.scoreboard.write_word_offset == WORD_COUNT &&
                    mailbox_word_index == WORD_COUNT);
            end
          end else if ($test$plusargs("AHB2AXI_CASE")) begin
            wait (run_done && env.scoreboard.read_count == 0 &&
                  env.scoreboard.write_count == 2 &&
                  env.scoreboard.write_word_offset == WORD_COUNT);
          end else if ($test$plusargs("AXI2AHB_CASE")) begin
            wait (run_done && env.scoreboard.read_count == 2 &&
                  env.scoreboard.read_word_offset == WORD_COUNT &&
                  env.scoreboard.write_count == 0);
          end else if ($test$plusargs("SRAM2FIFO_CASE")) begin
            wait (run_done && env.scoreboard.read_count == 2 &&
                  env.scoreboard.read_word_offset == WORD_COUNT &&
                  env.scoreboard.write_count == 5 &&
                  env.scoreboard.write_word_offset == WORD_COUNT);
          end else if (env.scoreboard.expect_fifo_recovery) begin
            wait (run_done && env.scoreboard.write_count == 5 && env.scoreboard.read_count == 5 &&
                  env.scoreboard.write_word_offset == WORD_COUNT &&
                  env.scoreboard.read_word_offset == WORD_COUNT);
          end else if ($test$plusargs("GENERATED_CASE")) begin
            wait (generated_route_ready);
            case (generated_dma_xfer_type)
              AXI2AXI: wait (run_done && env.scoreboard.write_count == active_write_burst_count &&
                             env.scoreboard.read_count == active_read_burst_count &&
                             env.scoreboard.write_word_offset == active_word_count &&
                             env.scoreboard.read_word_offset == active_word_count);
              AXI2MBOX: wait (run_done && env.scoreboard.write_count == 0 &&
                              env.scoreboard.read_count == active_read_burst_count &&
                              env.scoreboard.read_word_offset == active_word_count &&
                              mailbox_word_index == active_word_count);
              MBOX2AXI: wait (run_done && env.scoreboard.write_count == active_write_burst_count &&
                              env.scoreboard.write_word_offset == active_word_count &&
                              env.scoreboard.read_count == 0 &&
                              mailbox_word_index == active_word_count);
              AHB2AXI: wait (run_done && env.scoreboard.write_count == active_write_burst_count &&
                             env.scoreboard.write_word_offset == active_word_count &&
                             env.scoreboard.read_count == 0);
              AXI2AHB: wait (run_done && env.scoreboard.read_count == active_read_burst_count &&
                             env.scoreboard.read_word_offset == active_word_count &&
                             env.scoreboard.write_count == 0);
              default: `uvm_fatal("DMA_TOP_GENERATED_ROUTE", "Unsupported generated DMA route")
            endcase
            if ($test$plusargs("FIFO_SOURCE_STREAM")) begin
              #1;
              if (auto_fifo_source_push_count != active_word_count ||
                  auto_fifo_source_pop_count != active_word_count || fifo_level != 0)
                `uvm_fatal("DMA_TOP_FIFO_SOURCE_COUNT", $sformatf(
                  "FIFO source stream pushed/popped %0d/%0d and %0d/%0d words, level %0d",
                  auto_fifo_source_push_count, active_word_count,
                  auto_fifo_source_pop_count, active_word_count, fifo_level))
              for (int word = 0; word < active_word_count; word++)
                if (dma_target.bfm.i_sram.word_at(destination_word_index + word) !==
                    expected_payload[word])
                  `uvm_fatal("DMA_TOP_FIFO_SOURCE_DATA", $sformatf(
                    "FIFO source stream destination word %0d mismatch", word))
              $display("INFO: FIFO source stream supplied %0d words; FIFO drained",
                       active_word_count);
            end
          end else begin
            wait (run_done && env.scoreboard.write_count == 2 && env.scoreboard.read_count == 2 &&
                  env.scoreboard.write_word_offset == WORD_COUNT &&
                  env.scoreboard.read_word_offset == WORD_COUNT);
          end
        end
        begin
          #(100000 + (MAX_REPLAY_WORD_COUNT * 100));
          `uvm_fatal("DMA_TOP_TIMEOUT", $sformatf(
            "Timed out: run_done=%0b AXI reads=%0d/%0d writes=%0d mailbox writes=%0d",
            run_done, env.scoreboard.read_count, env.scoreboard.read_word_offset,
            env.scoreboard.write_count, mailbox_word_index))
        end
      join_any
      disable fork;
      if (expect_dma_error)
        $display("PASS: actual Caliptra axi_dma_top propagated injected AXI SLVERR to DMA_ERROR after the aligned partial write");
      else if (env.scoreboard.expect_fifo_recovery)
        $display("PASS: actual Caliptra axi_dma_top moved 65 auto-generated FIFO words through five recovery-sized fixed reads and SRAM writes");
      else if ($test$plusargs("GENERATED_CASE"))
        $display("PASS: generated DCCM record index=%0d route=%0d replayed through axi_dma_top",
                 generated_case_index, generated_dma_xfer_type);
      else if (mailbox_case)
        $display("PASS: actual Caliptra axi_dma_top read 65 SRAM words and wrote them through the mailbox request interface");
      else if (mailbox_read_case)
        $display("PASS: actual Caliptra axi_dma_top read 65 mailbox words and wrote them to SRAM");
      else if (ahb2axi_case)
        $display("PASS: actual Caliptra axi_dma_top sent 65 component-register words to SRAM");
      else if (axi2ahb_case)
        $display("PASS: actual Caliptra axi_dma_top sent 65 SRAM words through the component data register");
      else if (sram2fifo_case)
        $display("PASS: actual Caliptra axi_dma_top moved 65 SRAM words to the FIFO through randomized stalls and fixed write bursts");
      else
        $display("PASS: actual Caliptra axi_dma_top copied 65 randomized payload words in boundary-limited INCR bursts through the open DMA target and UVM monitor");
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    req_data = '0;
    kv_rd_resp = '0;
    uvm_config_db#(uvm_active_passive_enum)::set(
      null, "uvm_test_top.env.agent", "is_active", UVM_PASSIVE);
    uvm_config_db#(virtual axi4_caliptra_record_if)::set(
      null, "uvm_test_top.env.agent.monitor", "vif", record_if);
    expect_dma_error = $test$plusargs("INJECT_ERROR");
    fifo_recovery_case = $test$plusargs("FIFO_RECOVERY");
    if (expect_dma_error && fifo_recovery_case)
      $fatal(1, "INJECT_ERROR and FIFO_RECOVERY cases cannot run together");
    inject_error = expect_dma_error;
    uvm_config_db#(bit)::set(
      null, "uvm_test_top.env.scoreboard", "expect_error", expect_dma_error);
    uvm_config_db#(bit)::set(
      null, "uvm_test_top.env.scoreboard", "expect_fifo_recovery", fifo_recovery_case);
    uvm_config_db#(bit)::set(
      null, "uvm_test_top.env.scoreboard", "expect_fifo_source",
      $test$plusargs("FIFO_SOURCE_STREAM"));
    uvm_config_db#(bit)::set(
      null, "uvm_test_top.env.scoreboard", "expect_fifo_write", $test$plusargs("SRAM2FIFO_CASE"));
    run_test("axi_dma_top_uvm_bfm_test");
  end

  initial begin
    dma_transfer_randomizer#(16384) scenario;
    logic [31:0] status;
    logic [31:0] generated_case_count;
    logic [31:0] generated_word_count;
    logic [31:0] generated_src_offset;
    logic [31:0] generated_dst_offset;
    logic [31:0] record_size;
    logic [31:0] record_src_offset;
    logic [31:0] record_dst_offset;
    dma_case_type_t generated_type;
    dma_case_type_t record_type;
    bit record_is_large_fifo;
    integer generated_record_word;
    integer generated_payload_word_count;
    integer record_payload_word_count;
    integer record_cursor;
    integer record_index;
    integer poll;
    integer dma_poll_limit;
    integer word_index;
    #1;
    mailbox_case = $test$plusargs("AXI2MBOX_CASE");
    mailbox_read_case = $test$plusargs("MBOX2AXI_CASE");
    ahb2axi_case = $test$plusargs("AHB2AXI_CASE");
    axi2ahb_case = $test$plusargs("AXI2AHB_CASE");
    sram2fifo_case = $test$plusargs("SRAM2FIFO_CASE");
    auto_fifo_source_case = $test$plusargs("FIFO_SOURCE_STREAM");
    if (auto_fifo_source_case && !$test$plusargs("GENERATED_CASE"))
      $fatal(1, "FIFO_SOURCE_STREAM requires a generated DCCM replay record");
    scenario = new(MAX_REPLAY_WORD_COUNT, 0);
    if ($test$plusargs("GENERATED_CASE")) begin
      generated_case_index = 0;
      if (!$value$plusargs("CALIPTRA_BFM_DUT_REPLAY_INDEX=%d", generated_case_index))
        generated_case_index = 0;
      testcase_preload_done = 1'b1;
      wait (testcase_generator_done === 1'b1);
      generated_case_count = dccm_shadow[DCCM_WORDS-1][31:0];
      if ((generated_case_count < 1) || (generated_case_count > 100))
        $fatal(1, "Generated DCCM testcase count is invalid: %0d", generated_case_count);
      if ((generated_case_index < 0) || (generated_case_index >= generated_case_count))
        $fatal(1, "Generated DCCM testcase index %0d is outside count %0d",
               generated_case_index, generated_case_count);

      record_cursor = DCCM_WORDS - 2;
      generated_record_word = -1;
      for (record_index = 0; record_index < generated_case_count; record_index++) begin
        for (integer metadata_word = 0; metadata_word < 4; metadata_word++)
          if (!valid_dccm_word(dccm_shadow[record_cursor-metadata_word]))
            $fatal(1, "Generated testcase %0d DCCM metadata ECC mismatch at word %0d",
                   record_index, metadata_word);
        record_type = dccm_shadow[record_cursor][31:0];
        record_size = dccm_shadow[record_cursor-1][31:0];
        record_src_offset = dccm_shadow[record_cursor-2][31:0];
        record_dst_offset = dccm_shadow[record_cursor-3][31:0];
        record_is_large_fifo = (record_size > MAX_DCCM_PAYLOAD_WORDS);
        record_payload_word_count = record_is_large_fifo ? 0 : int'(record_size);
        if ((record_size < 1) || (record_size > MAX_REPLAY_WORD_COUNT))
          $fatal(1, "Generated testcase %0d has unsupported transfer size %0d",
                 record_index, record_size);
        case (record_type.dma_xfer_type)
          AHB2AXI, MBOX2AXI, AXI2AXI, AXI2MBOX, AXI2AHB: begin end
          default: $fatal(1, "Generated testcase %0d has unknown DMA route %0d",
                          record_index, record_type.dma_xfer_type);
        endcase
        if (record_is_large_fifo) begin
          if ((record_size != MAX_REPLAY_WORD_COUNT) ||
              (record_type.dma_xfer_type != AXI2AXI) || !record_type.src_is_fifo ||
              record_type.dst_is_fifo || !record_type.use_rd_fixed ||
              record_type.use_wr_fixed || record_type.inject_rst ||
              record_type.test_block_size || (record_type.block_size != 0) ||
              (record_src_offset != 0) || (record_dst_offset != 0))
            $fatal(1, "Generated testcase %0d has an unsupported large FIFO stream profile", record_index);
        end else if (record_type.dst_is_fifo) begin
          if ((generated_case_count != 27) || (record_index != 25) ||
              (record_size != WORD_COUNT) || (record_type.dma_xfer_type != AXI2AXI) ||
              record_type.src_is_fifo || !record_type.use_wr_fixed ||
              record_type.use_rd_fixed || record_type.inject_rst ||
              !record_type.inject_rand_delays || record_type.test_block_size ||
              (record_type.block_size != 0) || (record_dst_offset != 0) ||
              (record_src_offset < 32'h0000_1000 || record_src_offset > 32'h0000_1ffc))
            $fatal(1, "Generated testcase %0d has an unsupported FIFO-destination profile", record_index);
        end else if (record_type.test_block_size) begin
          if ((generated_case_count != 27) || (record_index != 26) ||
              (record_size != WORD_COUNT) || (record_type.dma_xfer_type != AXI2AXI) ||
              !record_type.src_is_fifo || record_type.dst_is_fifo ||
              !record_type.use_rd_fixed || record_type.use_wr_fixed ||
              record_type.inject_rand_delays || record_type.inject_rst ||
              (record_type.block_size != 12'd64) ||
              (record_src_offset != 0) || (record_dst_offset != 32'h0000_4000))
            $fatal(1, "Generated testcase %0d has an unsupported FIFO block-size profile", record_index);
        end else begin
          if (record_type.src_is_fifo || record_type.dst_is_fifo ||
              record_type.use_rd_fixed || record_type.use_wr_fixed ||
              record_type.inject_rst || record_type.test_block_size ||
              (record_type.block_size != 0))
            $fatal(1, "Generated testcase %0d is outside the supported short non-FIFO profile", record_index);
          if ((record_type.dma_xfer_type == MBOX2AXI &&
               (record_src_offset < 32'h0000_1000 || record_src_offset > 32'h0000_1efc)) ||
              (record_type.dma_xfer_type != MBOX2AXI &&
               (record_src_offset < 32'h0000_1000 || record_src_offset > 32'h0000_1ffc)) ||
              (record_type.dma_xfer_type == AXI2MBOX &&
               (record_dst_offset < 32'h0000_1000 || record_dst_offset > 32'h0000_1efc)) ||
              (record_type.dma_xfer_type != AXI2MBOX &&
               (record_dst_offset < 32'h0000_4000 || record_dst_offset > 32'h0000_4ffc)))
            $fatal(1, "Generated testcase %0d has an endpoint offset outside its route profile", record_index);
        end
        for (word_index = 0; word_index < record_payload_word_count; word_index++)
          if (!valid_dccm_word(dccm_shadow[record_cursor-4-word_index]))
            $fatal(1, "Generated testcase %0d payload ECC mismatch at word %0d",
                   record_index, word_index);
        if (record_index == generated_case_index) begin
          generated_record_word = record_cursor;
          generated_type = record_type;
          generated_word_count = record_size;
          generated_payload_word_count = record_payload_word_count;
          generated_src_offset = record_src_offset;
          generated_dst_offset = record_dst_offset;
        end
        record_cursor = record_cursor - record_payload_word_count - 4;
      end
      if (generated_record_word < 0)
        $fatal(1, "Generated DCCM testcase index %0d was not found", generated_case_index);
      scenario.dma_xfer_type = generated_type.dma_xfer_type;
      scenario.xfer_size = generated_word_count;
      active_word_count = generated_word_count;
      scenario.src_offset = generated_src_offset;
      scenario.dst_offset = generated_dst_offset;
      scenario.src_is_fifo = generated_type.src_is_fifo;
      scenario.dst_is_fifo = generated_type.dst_is_fifo;
      scenario.use_rd_fixed = generated_type.use_rd_fixed;
      scenario.use_wr_fixed = generated_type.use_wr_fixed;
      scenario.inject_rst = generated_type.inject_rst;
      scenario.inject_rand_delays = generated_type.inject_rand_delays;
      scenario.test_block_size = generated_type.test_block_size;
      scenario.block_size = generated_type.block_size;
      if (generated_type.dst_is_fifo)
        sram2fifo_case = 1'b1;
      generated_dma_xfer_type = generated_type.dma_xfer_type;
      mailbox_case = (generated_dma_xfer_type == AXI2MBOX);
      mailbox_read_case = (generated_dma_xfer_type == MBOX2AXI);
      ahb2axi_case = (generated_dma_xfer_type == AHB2AXI);
      axi2ahb_case = (generated_dma_xfer_type == AXI2AHB);
      scenario.payload_data = new[generated_payload_word_count];
      for (word_index = 0; word_index < generated_payload_word_count; word_index++)
        scenario.payload_data[word_index] = dccm_shadow[generated_record_word-4-word_index][31:0];
      if (scenario.src_is_fifo && !auto_fifo_source_case && !fifo_recovery_case)
        $fatal(1, "Generated FIFO source replay requires +FIFO_SOURCE_STREAM or +FIFO_RECOVERY");
      if (auto_fifo_source_case &&
          (scenario.dma_xfer_type != AXI2AXI || !scenario.src_is_fifo ||
           scenario.dst_is_fifo || !scenario.use_rd_fixed ||
           active_word_count != MAX_REPLAY_WORD_COUNT))
        $fatal(1, "+FIFO_SOURCE_STREAM selected a record outside the maximum FIFO-to-SRAM profile");
      $display("INFO: replaying generated DCCM testcase %0d of %0d cases",
               generated_case_index, generated_case_count);
    end else if (mailbox_case) begin
      scenario.srandom(DMA_RANDOM_SEED);
      if (!scenario.randomize() with {
        dma_xfer_type == AXI2MBOX;
        src_is_fifo == 0;
        dst_is_fifo == 0;
        use_rd_fixed == 0;
        use_wr_fixed == 0;
        test_block_size == 0;
        inject_rst == 0;
        inject_rand_delays == 0;
        xfer_size == WORD_COUNT;
        src_offset inside {[32'h0000_0300:32'h0000_03fc]};
        dst_offset inside {[32'h0000_1000:32'h0000_1ffc]};
      }) $fatal(1, "Pinned Caliptra DMA randomizer did not produce the constrained AXI2MBOX case");
    end else if (mailbox_read_case) begin
      scenario.srandom(DMA_RANDOM_SEED);
      if (!scenario.randomize() with {
        dma_xfer_type == MBOX2AXI;
        src_is_fifo == 0;
        dst_is_fifo == 0;
        use_rd_fixed == 0;
        use_wr_fixed == 0;
        test_block_size == 0;
        inject_rst == 0;
        inject_rand_delays == 0;
        xfer_size == WORD_COUNT;
        src_offset inside {[32'h0000_1000:32'h0000_1ffc]};
        dst_offset inside {[32'h0000_0300:32'h0000_03fc]};
      }) $fatal(1, "Pinned Caliptra DMA randomizer did not produce the constrained MBOX2AXI case");
    end else if (ahb2axi_case) begin
      scenario.srandom(DMA_RANDOM_SEED);
      if (!scenario.randomize() with {
        dma_xfer_type == AHB2AXI;
        src_is_fifo == 0;
        dst_is_fifo == 0;
        use_rd_fixed == 0;
        use_wr_fixed == 0;
        test_block_size == 0;
        inject_rst == 0;
        inject_rand_delays == 0;
        xfer_size == WORD_COUNT;
        dst_offset inside {[32'h0000_0600:32'h0000_06fc]};
      }) $fatal(1, "Pinned Caliptra DMA randomizer did not produce the constrained AHB2AXI case");
    end else if (axi2ahb_case) begin
      scenario.srandom(DMA_RANDOM_SEED);
      if (!scenario.randomize() with {
        dma_xfer_type == AXI2AHB;
        src_is_fifo == 0;
        dst_is_fifo == 0;
        use_rd_fixed == 0;
        use_wr_fixed == 0;
        test_block_size == 0;
        inject_rst == 0;
        inject_rand_delays == 0;
        xfer_size == WORD_COUNT;
        src_offset inside {[32'h0000_0300:32'h0000_03fc]};
        dst_offset inside {[32'h0000_0600:32'h0000_06fc]};
      }) $fatal(1, "Pinned Caliptra DMA randomizer did not produce the constrained AXI2AHB case");
    end else if (sram2fifo_case) begin
      scenario.srandom(DMA_RANDOM_SEED);
      if (!scenario.randomize() with {
        dma_xfer_type == AXI2AXI;
        src_is_fifo == 0;
        dst_is_fifo == 1;
        use_rd_fixed == 0;
        use_wr_fixed == 1;
        test_block_size == 0;
        inject_rst == 0;
        inject_rand_delays == 1;
        xfer_size == WORD_COUNT;
        src_offset inside {[32'h0000_0300:32'h0000_03fc]};
        dst_offset == 0;
      }) $fatal(1, "Pinned Caliptra DMA randomizer did not produce the constrained SRAM2FIFO case");
    end else begin
      scenario.srandom(DMA_RANDOM_SEED);
      if (!scenario.randomize() with {
        dma_xfer_type == AXI2AXI;
        src_is_fifo == 0;
        dst_is_fifo == 0;
        use_rd_fixed == 0;
        use_wr_fixed == 0;
        test_block_size == 0;
        inject_rst == 0;
        xfer_size == WORD_COUNT;
        src_offset inside {[32'h300:32'h3ff]};
        dst_offset inside {[32'h600:32'h6ff]};
      }) $fatal(1, "Pinned Caliptra DMA randomizer did not produce the constrained AXI2AXI case");
    end
    if (fifo_recovery_case && $test$plusargs("GENERATED_CASE")) begin
      if (!scenario.test_block_size || !scenario.src_is_fifo)
        $fatal(1, "Generated FIFO recovery replay requires a FIFO block-size record");
      dma_gen_block_size_bytes = testcase_generator_block_sizes;
      SRC_ADDR = FIFO_BASE_ADDR + 48'(scenario.src_offset);
      DST_ADDR = SRAM_BASE_ADDR + 48'(scenario.dst_offset);
    end else if (fifo_recovery_case) begin
      // Icarus rejects the pinned class constraints for this recovery tuple.
      scenario.src_is_fifo = 1'b1;
      scenario.use_rd_fixed = 1'b1;
      scenario.test_block_size = 1'b1;
      scenario.block_size = 12'd64;
      scenario.dst_offset = 32'h640;
      SRC_ADDR = FIFO_BASE_ADDR;
      DST_ADDR = SRAM_BASE_ADDR + 48'(scenario.dst_offset);
      dma_gen_block_size_bytes[0] = 12'(scenario.block_size);
    end else if (scenario.src_is_fifo) begin
      SRC_ADDR = FIFO_BASE_ADDR + 48'(scenario.src_offset);
      DST_ADDR = SRAM_BASE_ADDR + 48'(scenario.dst_offset);
    end else if (mailbox_case) begin
      SRC_ADDR = SRAM_BASE_ADDR + 48'(scenario.src_offset);
      // The firmware helper programs the mailbox-side route with a local offset.
      DST_ADDR = 48'(scenario.dst_offset);
    end else if (mailbox_read_case) begin
      SRC_ADDR = 48'(scenario.src_offset);
      DST_ADDR = SRAM_BASE_ADDR + 48'(scenario.dst_offset);
    end else if (ahb2axi_case) begin
      SRC_ADDR = '0;
      DST_ADDR = SRAM_BASE_ADDR + 48'(scenario.dst_offset);
    end else if (axi2ahb_case) begin
      SRC_ADDR = SRAM_BASE_ADDR + 48'(scenario.src_offset);
      DST_ADDR = '0;
    end else if (sram2fifo_case) begin
      SRC_ADDR = SRAM_BASE_ADDR + 48'(scenario.src_offset);
      DST_ADDR = FIFO_BASE_ADDR + 48'(scenario.dst_offset);
    end else begin
      SRC_ADDR = SRAM_BASE_ADDR + 48'(scenario.src_offset);
      DST_ADDR = SRAM_BASE_ADDR + 48'(scenario.dst_offset);
    end
    if ($test$plusargs("GENERATED_CASE")) begin
      active_read_burst_count = scenario.use_rd_fixed ?
          ((active_word_count + MAX_FIXED_BURST_WORDS - 1) / MAX_FIXED_BURST_WORDS) :
          axi_incr_burst_count(SRC_ADDR, active_word_count);
      active_write_burst_count = scenario.use_wr_fixed ?
          ((active_word_count + MAX_FIXED_BURST_WORDS - 1) / MAX_FIXED_BURST_WORDS) :
          axi_incr_burst_count(DST_ADDR, active_word_count);
      generated_route_ready = 1'b1;
    end
    enable_random_stalls = scenario.inject_rand_delays;
    source_word_index = scenario.src_offset / 4;
    destination_word_index = scenario.dst_offset / 4;
    if ($test$plusargs("GENERATED_CASE"))
      $display("INFO: Caliptra DCCM case type=%0d words=%0d src_off=%08h dst_off=%08h src_fifo=%0b dst_fifo=%0b fixed_read=%0b fixed_write=%0b inject_rand_delays=%0b block_bytes=%0d",
               scenario.dma_xfer_type, scenario.xfer_size, scenario.src_offset,
               scenario.dst_offset, scenario.src_is_fifo, scenario.dst_is_fifo,
               scenario.use_rd_fixed, scenario.use_wr_fixed,
               scenario.inject_rand_delays, scenario.block_size);
    else if (fifo_recovery_case)
      $display("INFO: directed Caliptra DMA recovery tuple words=%0d block_bytes=%0d src=%012h dst=%012h",
               scenario.xfer_size, scenario.block_size, SRC_ADDR, DST_ADDR);
    else
      $display("INFO: Caliptra DMA randomizer seed=%08h words=%0d block_bytes=%0d src=%012h dst=%012h",
               DMA_RANDOM_SEED, scenario.xfer_size, scenario.block_size, SRC_ADDR, DST_ADDR);
    if (!fifo_recovery_case && !scenario.src_is_fifo) begin
      // Seed the open SRAM model before reset release; the DMA performs the copy.
      for (word_index = 0; word_index < active_word_count; word_index++) begin
        expected_payload[word_index] = scenario.payload_data[word_index];
        if (mailbox_read_case)
          mailbox_mem[word_index] = expected_payload[word_index];
        else if (!ahb2axi_case)
          dma_target.bfm.i_sram.ram[source_word_index + word_index] = expected_payload[word_index];
      end
    end

    repeat (2) @(posedge clk);
    @(negedge clk);
    cptra_pwrgood = 1'b1;
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    write_reg(12'h014, SRC_ADDR[31:0]);
    write_reg(12'h018, {24'b0, SRC_ADDR[39:32]});
    write_reg(12'h01c, DST_ADDR[31:0]);
    write_reg(12'h020, {24'b0, DST_ADDR[39:32]});
    write_reg(12'h028, 32'(scenario.block_size));
    write_reg(12'h024, 32'(active_word_count * 4));
    if (fifo_recovery_case) begin
      @(negedge clk);
      recovery_emulation = 1'b1;
      wait (recovery_data_avail === 1'b1);
    end
    write_reg(12'h008, mailbox_case ? 32'h0001_0001 :
              mailbox_read_case ? 32'h0100_0001 :
              ahb2axi_case ? 32'h0200_0001 :
              axi2ahb_case ? 32'h0002_0001 :
              (32'h0303_0001 |
               (scenario.use_rd_fixed ? 32'h0010_0000 : 32'b0) |
               (scenario.use_wr_fixed ? 32'h1000_0000 : 32'b0)));

    if (ahb2axi_case)
      for (word_index = 0; word_index < active_word_count; word_index++)
        write_reg(12'h02c, expected_payload[word_index]);
    if (axi2ahb_case) begin
      for (word_index = 0; word_index < active_word_count; word_index++) begin
        status = '0;
        poll = 0;
        while ((status[15:4] == 0) && (poll < 1000)) begin
          read_status(status);
          poll++;
        end
        if (status[15:4] == 0)
          $fatal(1, "DMA component FIFO stayed empty before word %0d", word_index);
        read_component_data(status);
        if (status !== expected_payload[word_index])
          $fatal(1, "DMA component read word %0d mismatch: got=%08h expected=%08h",
                 word_index, status, expected_payload[word_index]);
      end
    end

    dma_poll_limit = 1000 + (active_word_count * 8);
    status = '1;
    if (expect_dma_error) begin
      for (poll = 0; poll < 1000 && status[17:16] !== 2'b11; poll++)
        read_status(status);
      if (status[0] !== 1'b1 || status[1] !== 1'b1 || status[17:16] !== 2'b11)
        $fatal(1, "Caliptra DMA did not report injected AXI error: status0=%08h", status);
    end else begin
      for (poll = 0; poll < dma_poll_limit &&
           ((status[0] !== 1'b0) || (status[1] !== 1'b0) || (status[17:16] !== 2'b00)); poll++)
        read_status(status);
      if (status[0] !== 1'b0 || status[1] !== 1'b0 || status[17:16] !== 2'b00)
        $fatal(1, "Caliptra DMA did not return idle without error: status0=%08h", status);
    end
    if ((mailbox_case || mailbox_read_case) && mailbox_word_index != active_word_count)
      $fatal(1, "Mailbox route completed %0d of %0d requests", mailbox_word_index, active_word_count);
    if (!expect_dma_error && !mailbox_case && !axi2ahb_case && !sram2fifo_case &&
        !auto_fifo_source_case) begin
      for (word_index = 0; word_index < active_word_count; word_index++)
        if (dma_target.bfm.i_sram.word_at(destination_word_index + word_index) !== expected_payload[word_index]) begin
          $fatal(1, "DMA destination SRAM word %0d mismatch: %08h",
                 word_index, dma_target.bfm.i_sram.word_at(destination_word_index + word_index));
        end
    end
    if (sram2fifo_case) begin
      if (randomized_stall_cycles == 0)
        $fatal(1, "SRAM2FIFO randomized delay profile did not assert target backpressure");
      if (fifo_level != active_word_count)
        $fatal(1, "SRAM2FIFO left %0d words in the endpoint FIFO; expected %0d", fifo_level, active_word_count);
      for (word_index = 0; word_index < active_word_count; word_index++)
        if (dma_target.bfm.i_fifo.fifo_mem[word_index] !== expected_payload[word_index])
          $fatal(1, "SRAM2FIFO FIFO word %0d mismatch: got=%08h expected=%08h",
                 word_index, dma_target.bfm.i_fifo.fifo_mem[word_index], expected_payload[word_index]);
      $display("INFO: randomized AXI target stalls observed for %0d clock cycles", randomized_stall_cycles);
    end
    if ($test$plusargs("GENERATED_CASE") && scenario.inject_rand_delays) begin
      if (randomized_stall_cycles == 0)
        $fatal(1, "Generated testcase %0d requested random delays but asserted no target backpressure",
               generated_case_index);
      $display("INFO: generated DCCM testcase %0d applied random stalls for %0d clock cycles",
               generated_case_index, randomized_stall_cycles);
    end
    run_done = 1'b1;
  end
endmodule
