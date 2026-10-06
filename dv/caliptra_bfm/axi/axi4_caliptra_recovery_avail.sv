// SPDX-License-Identifier: Apache-2.0
// Models Caliptra's recovery_data_avail policy over a FIFO endpoint's events.
module axi4_caliptra_recovery_avail #(
  // 0 selects by plusarg or uniform random choice; 1/2/3 select a fixed mode.
  parameter integer MODE = 0
) (
  input wire ACLK,
  input wire ARESETn,
  input wire en_recovery_emulation,
  input wire [31:0] fifo_level,
  input wire fifo_push_event,
  input wire fifo_pop_event,
  input wire [31:0] threshold_words,
  input wire [31:0] block_words,
  output wire recovery_data_avail,
  output reg [1:0] selected_mode,
  output reg recovery_data_avail_pulse,
  output reg [31:0] writes_since_enable,
  output reg [31:0] reads_since_enable,
  output reg [31:0] writes_since_avail,
  output reg [31:0] deassert_at_read_count
);
  localparam [1:0] MODE_NOT_EMPTY = 2'd1;
  localparam [1:0] MODE_THRESHOLD = 2'd2;
  localparam [1:0] MODE_PULSE = 2'd3;

  reg en_recovery_emulation_d;
  reg recovery_data_avail_d;
  wire recovery_data_avail_rise = recovery_data_avail && !recovery_data_avail_d;

  assign recovery_data_avail =
      ((selected_mode == MODE_NOT_EMPTY) && (fifo_level != 0)) ||
      ((selected_mode == MODE_THRESHOLD) && (fifo_level >= threshold_words)) ||
      ((selected_mode == MODE_PULSE) && en_recovery_emulation &&
       recovery_data_avail_pulse);

  initial begin
    if (MODE < 0 || MODE > 3)
      $fatal(1, "MODE must be 0 (plusarg/random), 1 (not-empty), 2 (threshold), or 3 (pulse)");
    if (MODE != 0) begin
      selected_mode = MODE;
    end else if ($test$plusargs("CLP_DMA_TB_MODE_NOT_EMPTY")) begin
      selected_mode = MODE_NOT_EMPTY;
    end else if ($test$plusargs("CLP_DMA_TB_MODE_THRESH")) begin
      selected_mode = MODE_THRESHOLD;
    end else if ($test$plusargs("CLP_DMA_TB_MODE_PULSE")) begin
      selected_mode = MODE_PULSE;
    end else begin
      case ($urandom_range(2, 0))
        0: selected_mode = MODE_NOT_EMPTY;
        1: selected_mode = MODE_THRESHOLD;
        default: selected_mode = MODE_PULSE;
      endcase
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      en_recovery_emulation_d <= 1'b0;
      recovery_data_avail_d <= 1'b0;
      recovery_data_avail_pulse <= 1'b0;
      writes_since_enable <= 0;
      reads_since_enable <= 0;
      writes_since_avail <= 0;
      deassert_at_read_count <= 0;
    end else begin
      en_recovery_emulation_d <= en_recovery_emulation;
      recovery_data_avail_d <=
          (selected_mode == MODE_PULSE) && en_recovery_emulation &&
          recovery_data_avail_pulse;

      if (en_recovery_emulation && !en_recovery_emulation_d && fifo_level != 0)
        $error("Caliptra recovery emulation must begin with an empty FIFO");

      if (!en_recovery_emulation) begin
        recovery_data_avail_pulse <= 1'b0;
        writes_since_enable <= 0;
        reads_since_enable <= 0;
        writes_since_avail <= 0;
        deassert_at_read_count <= 0;
      end else begin
        if (fifo_push_event)
          writes_since_enable <= writes_since_enable + 1'b1;
        if (fifo_pop_event)
          reads_since_enable <= reads_since_enable + 1'b1;

        if (selected_mode != MODE_PULSE) begin
          recovery_data_avail_pulse <= 1'b0;
          writes_since_avail <= 0;
          deassert_at_read_count <= 0;
        end else if (block_words == 0) begin
          $error("block_words must be nonzero in pulse mode");
          recovery_data_avail_pulse <= 1'b0;
        end else begin
          if (writes_since_avail >= block_words)
            recovery_data_avail_pulse <= 1'b1;
          else if (fifo_pop_event &&
                   (reads_since_enable == (deassert_at_read_count - 1'b1)))
            recovery_data_avail_pulse <= 1'b0;

          if (recovery_data_avail_rise) begin
            if (deassert_at_read_count == 0)
              deassert_at_read_count <= 1;
            else
              deassert_at_read_count <= deassert_at_read_count + block_words;
          end

          case ({fifo_push_event, recovery_data_avail_rise})
            2'b01: writes_since_avail <= writes_since_avail - block_words;
            2'b10: writes_since_avail <= writes_since_avail + 1'b1;
            2'b11: writes_since_avail <= writes_since_avail + 1'b1 - block_words;
            default: writes_since_avail <= writes_since_avail;
          endcase
        end
      end
    end
  end
endmodule
