module psprintf_empty_arg;
  initial begin
    $display("%s", $psprintf("The agent at '%s' uses %s", "agent", "ifname", ));
    $finish;
  end
endmodule
