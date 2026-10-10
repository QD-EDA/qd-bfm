// SPDX-License-Identifier: Apache-2.0
module tb_axi4_caliptra_random_stalls_distribution;
  reg ACLK = 0;
  reg ARESETn = 0;
  reg enable = 0;
  wire [9:0] stall;
  integer frequency [0:255];
  integer draw;
  integer delay_value;
  integer expected;

  axi4_caliptra_random_stalls #(.CHANNELS(10)) dut (
    .ACLK(ACLK), .ARESETn(ARESETn), .enable(enable), .stall(stall)
  );

  initial begin
    for (delay_value = 0; delay_value < 256; delay_value = delay_value + 1)
      frequency[delay_value] = 0;
    for (draw = 0; draw < 1746; draw = draw + 1) begin
      delay_value = dut.choose_delay_from_draw(draw);
      if (delay_value < 0 || delay_value > 255)
        $fatal(1, "delay draw %0d mapped outside 0..255: %0d", draw, delay_value);
      frequency[delay_value] = frequency[delay_value] + 1;
    end

    for (delay_value = 0; delay_value < 256; delay_value = delay_value + 1) begin
      if (delay_value <= 1)
        expected = 500;
      else if (delay_value <= 7)
        expected = 75;
      else if (delay_value <= 31)
        expected = 3;
      else
        expected = 1;
      if (frequency[delay_value] != expected)
        $fatal(1, "delay %0d has weight %0d, expected %0d",
               delay_value, frequency[delay_value], expected);
    end
    $display("PASS: AXI delay distribution matches Caliptra weights 500/75/3/1");
    $finish;
  end
endmodule
