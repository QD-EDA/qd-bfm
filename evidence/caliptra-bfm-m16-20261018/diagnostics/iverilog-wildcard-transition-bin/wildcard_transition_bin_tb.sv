module wildcard_transition_bin_tb;
  logic [31:0] event_value;
  covergroup cg with function sample(input bit [31:0] bus_event);
    cp: coverpoint bus_event {
      wildcard bins set = (32'h0000_0000 => 32'h400?_????);
    }
  endgroup
  cg coverage = new;
endmodule
