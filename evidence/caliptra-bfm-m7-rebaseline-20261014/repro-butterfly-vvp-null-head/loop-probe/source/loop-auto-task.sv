module tb;
  logic clk = 1'b0;
  integer a;
  integer test_cnt;
  always #5 clk = ~clk;

  task automatic run_test;
    fork
      begin
        for (int j = 0; j < 64; j++) begin
          int k1 = 3;
          int k2 = 2;
          int k3 = 1;
          a = k1 + k2 + k3;
          @(posedge clk);
        end
      end
      begin
        for (int j = 0; j < 64+11; j++) begin
          if (j >= 11 && test_cnt < 256) begin
            test_cnt++;
            a = j - 11;
          end
          @(posedge clk);
        end
      end
    join
    @(posedge clk);
  endtask

  initial begin
    test_cnt = 0;
    run_test();
    $display("MRE_PASS");
    $finish;
  end
endmodule
