package config_pkg;
  typedef struct packed {
    logic [3:0] width;
  } params_t;
  localparam params_t DEFAULT_PARAMS = '{width: 4'd8};
endpackage

interface bus_if #(parameter config_pkg::params_t pt = config_pkg::DEFAULT_PARAMS) ();
  logic [pt.width-1:0] payload;
  modport source(output payload);
endinterface

module writer(bus_if.source bus);
  logic [7:0] value = 8'hA5;
  assign bus.payload = value;
endmodule

module interface_variable_assign;
  bus_if bus();
  writer u_writer(bus);

  initial begin
    #1;
    if (bus.payload !== 8'hA5) $fatal(1, "interface assignment mismatch");
    $display("INTERFACE_ASSIGN_PASS");
    $finish;
  end
endmodule
