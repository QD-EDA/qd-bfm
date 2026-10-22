module tb;
  logic clk = 1'b0;
  logic ready = 1'b0;
  integer captured;
  always #5 clk = ~clk;

  task run_test;
    integer a;
    integer test_cnt;
    begin
      test_cnt = 0;
      fork
        begin
          ready = 1'b1;
          @(posedge clk);
          ready = 1'b0;
        end
        begin
          for (int j = 0; j < 64; j++) begin
            a = j;
            @(posedge clk);
          end
        end
        begin
          for (int j = 0; j < 75; j++) begin
            if (ready && test_cnt < 256) begin
              test_cnt++;
              a = j - 11;
            end
            @(posedge clk);
          end
        end
      join
      captured = test_cnt;
      $display("join complete, captured=%0d", captured);
    end
  endtask

  initial begin
    run_test();
    run_test();
    $display("MRE_PASS");
    #50 $finish;
  end
endmodule
