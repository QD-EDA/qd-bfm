module dynamic_array_slice_minimal;
  class cfg;
    int data[];
    function new(input int src[]);
      data = new[1];
      data = src[0:0];
    endfunction
  endclass
  int src[];
  cfg value;
  initial begin
    src = new[1]; src[0] = 42;
    value = new(src);
    $display("DATA=%0d", value.data[0]);
    $finish;
  end
endmodule
