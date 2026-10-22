// SPDX-License-Identifier: Apache-2.0
// Selects the DMA block size and recovery threshold for each recovery test.
module axi4_caliptra_recovery_sequence #(
  parameter integer DATA_WIDTH = 32,
  parameter integer BLOCK_COUNT = 100
) (
  input wire ACLK,
  input wire ARESETn,
  input wire sequence_enable,
  input wire dma_gen_done,
  input wire en_recovery_emulation,
  input wire [BLOCK_COUNT*12-1:0] dma_gen_block_size_bytes,
  output reg [31:0] block_index,
  output reg [31:0] block_words,
  output reg [31:0] threshold_words,
  output reg sequence_ready,
  output reg sequence_done
);
  localparam integer DATA_BYTES = DATA_WIDTH / 8;

  reg en_recovery_emulation_d;
  task automatic load_block(input integer index);
    reg [11:0] block_bytes;
    integer candidate;
    integer words_in_block;
    reg found_block;
    begin
      found_block = 1'b0;
      for (candidate = index; candidate < BLOCK_COUNT && !found_block;
           candidate = candidate + 1) begin
        block_bytes = dma_gen_block_size_bytes[candidate*12 +: 12];
        if ((^block_bytes) === 1'bx)
          $fatal(1, "DMA block-size array contains unknown bits at index %0d", candidate);
        if (block_bytes != 0) begin
          if ((block_bytes % DATA_BYTES) != 0)
            $fatal(1, "DMA block size %0d bytes is not a whole number of words", block_bytes);
          words_in_block = block_bytes / DATA_BYTES;
          block_index <= candidate;
          block_words <= words_in_block;
          threshold_words <= $urandom_range(words_in_block, 1);
          sequence_ready <= 1'b1;
          found_block = 1'b1;
        end
      end
      if (!found_block) begin
        block_index <= BLOCK_COUNT;
        block_words <= 0;
        threshold_words <= 0;
        sequence_ready <= 1'b0;
        sequence_done <= 1'b1;
      end
    end
  endtask

  initial begin
    if (DATA_WIDTH < 8 || (DATA_WIDTH % 8) != 0 ||
        (DATA_BYTES & (DATA_BYTES - 1)) != 0 || BLOCK_COUNT < 1)
      $fatal(1, "Invalid Caliptra recovery sequence parameters");
    block_index = 0;
    block_words = 0;
    threshold_words = 0;
    sequence_ready = 0;
    sequence_done = 0;
    en_recovery_emulation_d = 0;
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      // The pinned testbench reuses the same block after reset. Keep the index
      // and selected values; re-arm loading so the current entry is selected
      // again after reset release while dma_gen_done remains asserted.
      en_recovery_emulation_d <= 1'b0;
      sequence_ready <= 1'b0;
    end else begin
      en_recovery_emulation_d <= en_recovery_emulation;

      if (sequence_enable === 1'b1) begin
        if (en_recovery_emulation && !dma_gen_done)
          $error("DMA recovery sequence enabled before dma_gen_done");

        if (dma_gen_done && !sequence_ready && !sequence_done) begin
          load_block(block_index);
        end else if (sequence_ready && en_recovery_emulation_d &&
                     !en_recovery_emulation) begin
          load_block(block_index + 1);
        end
      end
    end
  end
endmodule
