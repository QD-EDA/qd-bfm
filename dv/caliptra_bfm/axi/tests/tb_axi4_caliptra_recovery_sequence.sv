// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_axi4_caliptra_recovery_sequence;
  reg ACLK = 0;
  reg ARESETn = 0;
  reg sequence_enable = 1;
  reg dma_gen_done = 0;
  reg en_recovery_emulation = 0;
  reg [99:0][11:0] dma_gen_block_size = '0;

  wire [31:0] block_index;
  wire [31:0] block_words;
  wire [31:0] threshold_words;
  wire sequence_ready;
  wire sequence_done;
  reg [99:0][11:0] empty_block_sizes = '0;
  wire [31:0] empty_block_index;
  wire [31:0] empty_block_words;
  wire [31:0] empty_threshold_words;
  wire empty_sequence_ready;
  wire empty_sequence_done;

  always #5 ACLK = ~ACLK;

  axi4_caliptra_recovery_sequence #(
    .DATA_WIDTH(32),
    .BLOCK_COUNT(100)
  ) dut (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .sequence_enable(sequence_enable),
    .dma_gen_done(dma_gen_done),
    .en_recovery_emulation(en_recovery_emulation),
    .dma_gen_block_size_bytes(dma_gen_block_size),
    .block_index(block_index),
    .block_words(block_words),
    .threshold_words(threshold_words),
    .sequence_ready(sequence_ready),
    .sequence_done(sequence_done)
  );

  axi4_caliptra_recovery_sequence #(
    .DATA_WIDTH(32),
    .BLOCK_COUNT(100)
  ) empty_dut (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .sequence_enable(sequence_enable),
    .dma_gen_done(dma_gen_done),
    .en_recovery_emulation(1'b0),
    .dma_gen_block_size_bytes(empty_block_sizes),
    .block_index(empty_block_index),
    .block_words(empty_block_words),
    .threshold_words(empty_threshold_words),
    .sequence_ready(empty_sequence_ready),
    .sequence_done(empty_sequence_done)
  );

  task automatic expect_block(input [31:0] expected_index,
                              input [31:0] expected_words);
    begin
      if (!sequence_ready || block_index != expected_index ||
          block_words != expected_words || threshold_words < 1 ||
          threshold_words > expected_words)
        $fatal(1, "Unexpected recovery sequence: ready=%0b index=%0d block=%0d threshold=%0d",
               sequence_ready, block_index, block_words, threshold_words);
    end
  endtask

  initial begin
    dma_gen_block_size[0] = 12'd0;
    dma_gen_block_size[1] = 12'd64;
    dma_gen_block_size[2] = 12'd0;
    dma_gen_block_size[3] = 12'd128;
    dma_gen_block_size[4] = 12'd0;

    repeat (2) @(posedge ACLK);
    @(negedge ACLK);
    ARESETn = 1;
    dma_gen_done = 1;
    repeat (2) @(negedge ACLK);
    expect_block(1, 16);
    if (!empty_sequence_done || empty_sequence_ready ||
        empty_block_index != 100 || empty_block_words != 0 ||
        empty_threshold_words != 0)
      $fatal(1, "An all-zero block-size list did not complete cleanly");

    en_recovery_emulation = 1;
    @(negedge ACLK);
    en_recovery_emulation = 0;
    @(negedge ACLK);
    expect_block(3, 32);

    en_recovery_emulation = 1;
    @(negedge ACLK);
    ARESETn = 0;
    en_recovery_emulation = 0;
    #1;
    if (block_index != 3 || sequence_ready)
      $fatal(1, "Reset did not retain and re-arm the active recovery block");
    @(negedge ACLK);
    ARESETn = 1;
    repeat (2) @(negedge ACLK);
    expect_block(3, 32);

    en_recovery_emulation = 1;
    @(negedge ACLK);
    en_recovery_emulation = 0;
    @(negedge ACLK);
    if (!sequence_done || sequence_ready || block_index != 100)
      $fatal(1, "Recovery sequence did not stop after the final entry");

    $display("PASS: recovery block sequencing, zero-entry skipping, thresholds, reset retry, and end-of-list");
    $finish;
  end
endmodule
