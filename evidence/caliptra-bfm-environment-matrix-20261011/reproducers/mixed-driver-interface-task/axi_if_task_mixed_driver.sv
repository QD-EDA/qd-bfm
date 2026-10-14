interface axi_if_min;
  logic arvalid;
  logic [31:0] araddr;

  `ifndef SYNTHESIS
  task automatic rst_mgr();
    arvalid = 1'b0;
    araddr = '0;
  endtask
  `endif

  modport r_sub(input arvalid, araddr);
endinterface

module subordinate(axi_if_min.r_sub axi);
  logic sampled;
  always_comb sampled = axi.arvalid ^ axi.araddr[0];
endmodule

module axi_if_task_mixed_driver;
  logic source_valid = 1'b1;
  logic [31:0] source_addr = 32'h1234;
  axi_if_min axi();
  subordinate dut(.axi(axi.r_sub));

  assign axi.arvalid = source_valid;
  assign axi.araddr = source_addr;

  initial begin
    #1ns;
    force axi.arvalid = 1'b0;
    #1ns;
    release axi.arvalid;
    #1ns;
    $finish;
  end
endmodule
