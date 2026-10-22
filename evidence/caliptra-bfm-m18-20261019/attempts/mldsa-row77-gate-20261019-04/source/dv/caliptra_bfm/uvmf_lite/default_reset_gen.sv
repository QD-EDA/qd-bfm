// SPDX-License-Identifier: Apache-2.0
// Open reset helper required by Caliptra-generated UVMF HDL tops.
`ifndef CALIPTRA_BFM_EXTERNAL_UVMF
module default_reset_gen(
  input wire CLK_IN,
  output reg RESET
);
  initial begin
    RESET = 1'b0;
    repeat (2) @(posedge CLK_IN);
    RESET = 1'b1;
  end
endmodule
`endif
