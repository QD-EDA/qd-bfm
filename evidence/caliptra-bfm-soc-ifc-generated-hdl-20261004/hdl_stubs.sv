// SPDX-License-Identifier: Apache-2.0
// Compile-only stand-ins for generated/licensed simulation helpers.
module default_reset_gen(output reg RESET, input wire CLK_IN);
  initial begin
    RESET = 1'b0;
    repeat (2) @(posedge CLK_IN);
    RESET = 1'b1;
  end
endmodule

module soc_ifc_cov_bind;
endmodule
