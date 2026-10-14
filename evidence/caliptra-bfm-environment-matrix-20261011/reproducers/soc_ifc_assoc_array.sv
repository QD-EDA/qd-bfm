module t;
  logic [2:0] security_state[string] = {
    "DEBUG_UNLOCKED_UNPROVISIONED": 3'b000,
    "DEBUG_LOCKED_UNPROVISIONED":   3'b100
  };
endmodule
