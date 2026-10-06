// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_caliptra_dma_testcase_generator_bfm;
  import caliptra_top_tb_pkg::*;

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

  localparam logic [31:0] DCCM_BASE_ADDR = 32'h5000_0000;
  localparam logic [31:0] DCCM_END_ADDR = 32'h5003_ffff;
  localparam integer DCCM_WORDS = 65536;

  logic preload_dccm_done = 1'b0;
  logic dma_gen_done;
  logic [99:0][11:0] dma_gen_block_size;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic en_recovery_emulation = 1'b0;
  wire [31:0] block_index;
  wire [31:0] block_words;
  wire [31:0] threshold_words;
  wire sequence_ready;
  wire sequence_done;
  logic [38:0] dccm_mem [0:DCCM_WORDS-1];
  integer dccm_write_count = 0;

  always #5 clk = ~clk;

  dma_testcase_generator i_dma_gen (
    .preload_dccm_done(preload_dccm_done),
    .dma_gen_done(dma_gen_done),
    .dma_gen_block_size(dma_gen_block_size)
  );

  axi4_caliptra_recovery_sequence #(.DATA_WIDTH(32), .BLOCK_COUNT(100)) i_recovery_sequence (
    .ACLK(clk), .ARESETn(rst_n),
    .sequence_enable(1'b1), .dma_gen_done(dma_gen_done),
    .en_recovery_emulation(en_recovery_emulation),
    .dma_gen_block_size_bytes(dma_gen_block_size),
    .block_index(block_index), .block_words(block_words),
    .threshold_words(threshold_words), .sequence_ready(sequence_ready),
    .sequence_done(sequence_done)
  );

  task automatic slam_dccm_ram(input logic [31:0] addr, input logic [38:0] data);
    integer word_index;
    begin
      if ((addr < DCCM_BASE_ADDR) || (addr > DCCM_END_ADDR) || (addr[1:0] != 0))
        $fatal(1, "DMA testcase generator wrote invalid DCCM address %08h", addr);
      word_index = int'((addr - DCCM_BASE_ADDR) >> 2);
      dccm_mem[word_index] = data;
      dccm_write_count++;
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

  initial begin
    integer generated_count;
    integer dccm_record_word;
    integer total_payload_words;
    integer payload_word;
    integer stored_payload_words;
    logic [31:0] record_size;
    dma_case_type_t record_type;
    integer first_index;
    integer next_index;
    repeat (2) @(negedge clk);
    preload_dccm_done = 1'b1;
    fork
      begin
        wait (dma_gen_done === 1'b1);
      end
      begin
        #100000000;
        $fatal(1, "Timed out waiting for dma_testcase_generator");
      end
    join_any
    disable fork;

    generated_count = dccm_mem[DCCM_WORDS-1][31:0];
    if ((generated_count < 1) || (generated_count > 100) || (dccm_write_count < 3))
      $fatal(1, "DMA testcase generator did not stage a valid DCCM testcase count=%0d writes=%0d",
             generated_count, dccm_write_count);
    if (!valid_dccm_word(dccm_mem[DCCM_WORDS-1]))
      $fatal(1, "DMA testcase count DCCM ECC mismatch");

    dccm_record_word = DCCM_WORDS - 2;
    total_payload_words = 0;
    for (integer testcase = 0; testcase < generated_count; testcase++) begin
      for (integer metadata_word = 0; metadata_word < 4; metadata_word++)
        if (!valid_dccm_word(dccm_mem[dccm_record_word-metadata_word]))
          $fatal(1, "DCCM ECC mismatch in testcase %0d metadata word %0d", testcase, metadata_word);
      record_type = dccm_mem[dccm_record_word][31:0];
      record_size = dccm_mem[dccm_record_word-1][31:0];
      if ((record_size == 0) || (record_size > 65536) ||
          (record_type.block_size != dma_gen_block_size[testcase]))
        $fatal(1, "Invalid DCCM testcase %0d size=%0d block=%0d expected=%0d",
               testcase, record_size, record_type.block_size, dma_gen_block_size[testcase]);
      stored_payload_words = (record_size <= 16384) ? int'(record_size) : 0;
      for (payload_word = 0; payload_word < stored_payload_words; payload_word++)
        if (!valid_dccm_word(dccm_mem[dccm_record_word-4-payload_word]))
          $fatal(1, "DCCM ECC mismatch in testcase %0d payload word %0d", testcase, payload_word);
      total_payload_words += stored_payload_words;
      dccm_record_word -= stored_payload_words + 4;
    end
    if (total_payload_words + 4 * generated_count + 2 != dccm_write_count)
      $fatal(1, "DCCM replay size mismatch: payload=%0d cases=%0d writes=%0d",
             total_payload_words, generated_count, dccm_write_count);

    for (integer i = 0; i < generated_count; i++) begin
      if (dma_gen_block_size[i] != 0 &&
          ((dma_gen_block_size[i] & (dma_gen_block_size[i] - 1)) != 0))
        $fatal(1, "Generated recovery block size at index %0d is not one-hot: %0d",
               i, dma_gen_block_size[i]);
    end

    first_index = -1;
    next_index = -1;
    for (integer i = 0; i < generated_count; i++) begin
      if ((first_index < 0) && (dma_gen_block_size[i] != 0))
        first_index = i;
      else if ((first_index >= 0) && (next_index < 0) && (dma_gen_block_size[i] != 0))
        next_index = i;
    end
    if (first_index < 0)
      $fatal(1, "DMA testcase generator produced no recovery-enabled testcase in %0d iterations",
             generated_count);

    @(negedge clk);
    rst_n = 1'b1;
    if (first_index >= 0) begin
      wait (sequence_ready);
      if (block_index != first_index ||
          block_words != (dma_gen_block_size[first_index] / 4) ||
          threshold_words < 1 || threshold_words > block_words)
        $fatal(1, "Recovery sequence did not consume generated entry %0d: index=%0d words=%0d threshold=%0d",
               first_index, block_index, block_words, threshold_words);
      if (next_index >= 0) begin
        @(negedge clk);
        en_recovery_emulation = 1'b1;
        @(negedge clk);
        en_recovery_emulation = 1'b0;
        wait (block_index == next_index && sequence_ready);
        if (block_words != (dma_gen_block_size[next_index] / 4) ||
            threshold_words < 1 || threshold_words > block_words)
          $fatal(1, "Recovery sequence did not advance to generated entry %0d", next_index);
      end
    end else if (!sequence_done) begin
      wait (sequence_done);
    end

    $display("PASS: real dma_testcase_generator staged and ECC-checked %0d DCCM testcases (%0d payload words, %0d writes); recovery sequence consumed entries %0d and %0d",
             generated_count, total_payload_words, dccm_write_count, first_index, next_index);
    $finish;
  end
endmodule
