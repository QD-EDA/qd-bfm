// SPDX-License-Identifier: Apache-2.0
module tb_axi4_caliptra_random_stalls_distribution;
  reg ACLK = 0;
  reg ARESETn = 0;
  reg enable = 0;
  wire [9:0] stall;
  integer channel_stall_frequency [0:255];
  integer fifo_auto_frequency [0:255];
  integer draw;
  integer channel_delay;
  integer fifo_delay;
  integer value;
  integer expected;

  axi4_caliptra_random_stalls #(.CHANNELS(10)) dut (
    .ACLK(ACLK), .ARESETn(ARESETn), .enable(enable), .stall(stall)
  );
  axi4_caliptra_fifo_subordinate fifo_dut();

  initial begin
    for (value = 0; value < 256; value = value + 1) begin
      channel_stall_frequency[value] = 0;
      fifo_auto_frequency[value] = 0;
    end
    for (draw = 0; draw < 129696; draw = draw + 1) begin
      channel_delay = dut.choose_delay_from_draw(draw);
      fifo_delay = fifo_dut.choose_auto_stall_count_from_draw(draw);
      if (channel_delay < 0 || channel_delay > 255 ||
          fifo_delay < 0 || fifo_delay > 255)
        $fatal(1, "delay draw %0d mapped outside 0..255: channel=%0d fifo=%0d",
               draw, channel_delay, fifo_delay);
      channel_stall_frequency[channel_delay] = channel_stall_frequency[channel_delay] + 1;
      fifo_auto_frequency[fifo_delay] = fifo_auto_frequency[fifo_delay] + 1;
    end

    for (value = 0; value < 256; value = value + 1) begin
      if (value <= 1)
        expected = 56000;
      else if (value <= 7)
        expected = 2800;
      else if (value <= 31)
        expected = 28;
      else
        expected = 1;
      if (channel_stall_frequency[value] != expected ||
          fifo_auto_frequency[value] != expected)
        $fatal(1, "delay %0d has channel/FIFO weights %0d/%0d, expected %0d",
               value, channel_stall_frequency[value], fifo_auto_frequency[value], expected);
    end
    $display("PASS: AXI channel and FIFO auto delays match Caliptra range weights 500/75/3/1");
    $finish;
  end
endmodule
