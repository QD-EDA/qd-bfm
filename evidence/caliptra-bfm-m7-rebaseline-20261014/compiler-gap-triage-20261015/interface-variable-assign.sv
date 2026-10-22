interface bus_if;
  logic [7:0] data;
endinterface

module writer(bus_if bus);
  logic [7:0] payload = 8'hA5;
  assign bus.data = payload;
endmodule

module interface_variable_assign;
  bus_if bus();
  writer u_writer(bus);

  initial begin
    #1;
    if (bus.data !== 8'hA5) $fatal(1, "interface assignment mismatch");
    $display("INTERFACE_ASSIGN_PASS");
    $finish;
  end
endmodule
