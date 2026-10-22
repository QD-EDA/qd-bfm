module top;
  logic signal = 0;
  initial begin
    #2 signal = 1;
    #10 $finish;
  end
  initial forever @($changed(signal)) $display("changed at %0t", $time);
endmodule
