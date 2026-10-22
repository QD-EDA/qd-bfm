interface response_if;
  logic ready;
  modport initiator_port(input ready);
endinterface
module response_driver(response_if bus);
  assign bus.ready = 1'b0;
endmodule
module interface_modport_actual;
  response_if bus();
  response_driver driver(bus.initiator_port);
endmodule
