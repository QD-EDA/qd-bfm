module psprintf_control;
  initial begin
    $display("%s", $psprintf("The agent at '%s' uses %s", "agent", "ifname"));
    $finish;
  end
endmodule
