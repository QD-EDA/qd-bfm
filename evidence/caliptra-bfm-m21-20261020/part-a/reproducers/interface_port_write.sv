interface response_if;
  inout tri ready;
endinterface
module response_driver(response_if bus);
  assign bus.ready = 1'b0;
endmodule
module interface_port_write;
  response_if bus();
  response_driver driver(bus);
  initial begin
    #1;
    if (bus.ready !== 1'b0) $fatal(1, "driver did not drive ready");
    $display("INTERFACE_PORT_WRITE_OK");
    $finish;
  end
endmodule
