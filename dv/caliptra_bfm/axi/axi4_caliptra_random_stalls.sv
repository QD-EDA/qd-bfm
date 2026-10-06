// SPDX-License-Identifier: Apache-2.0
// Independent AXI channel backpressure with Caliptra's weighted delay profile.
module axi4_caliptra_random_stalls #(
  parameter integer CHANNELS = 10
) (
  input wire ACLK,
  input wire ARESETn,
  input wire enable,
  output reg [CHANNELS-1:0] stall
);
  reg [11:0] remaining [0:CHANNELS-1];
  integer init_channel;
  integer channel;

  // Equivalent integer weights for dist {0..1 :/ 500, 2..7 :/ 75,
  // 8..31 :/ 3, 32..255 :/ 1}.
  function automatic [7:0] choose_delay;
    integer draw;
    begin
      draw = $urandom_range(129695, 0);
      if (draw < 56000)
        choose_delay = 0;
      else if (draw < 112000)
        choose_delay = 1;
      else if (draw < 128800)
        choose_delay = 2 + ((draw - 112000) / 2800);
      else if (draw < 129472)
        choose_delay = 8 + ((draw - 128800) / 28);
      else
        choose_delay = 32 + (draw - 129472);
    end
  endfunction

  initial begin
    if (CHANNELS < 1)
      $fatal(1, "CHANNELS must be positive");
    stall = 0;
    for (init_channel = 0; init_channel < CHANNELS; init_channel = init_channel + 1)
      remaining[init_channel] = 0;
  end

  always @(negedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      stall <= 0;
      for (channel = 0; channel < CHANNELS; channel = channel + 1)
        remaining[channel] <= 0;
    end else if (enable !== 1'b1) begin
      stall <= 0;
      for (channel = 0; channel < CHANNELS; channel = channel + 1)
        remaining[channel] <= 0;
    end else begin
      for (channel = 0; channel < CHANNELS; channel = channel + 1) begin
        if (remaining[channel] != 0) begin
          stall[channel] <= 1'b1;
          remaining[channel] <= remaining[channel] - 1'b1;
        end else begin
          stall[channel] <= 1'b0;
          remaining[channel] <= choose_delay();
        end
      end
    end
  end
endmodule
