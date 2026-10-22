module assoc_array_probe;
  logic [2:0] state[string] = '{
    "UNLOCKED": 3'b000,
    "LOCKED": 3'b001
  };
  initial begin
    if (state["UNLOCKED"] !== 3'b000) $fatal(1, "bad value");
  end
endmodule
