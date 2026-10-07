// SPDX-License-Identifier: Apache-2.0
module tb_request_args;
  logic clk=0, rst_n=0;
  always #5 clk=~clk;
  logic [31:0] addr=0, data=32'h12345678, result;
  logic [7:0] id=8'h42;
  logic [3:0] strb=4'hf;
  logic ok;
  logic [1:0] resp;
  logic unknown_bit;
  reg [8*16-1:0] field;
  // Static response pins are sufficient for argument-boundary tests only.
  qd_axi4_single_master bfm(.clk(clk),.rst_n(rst_n),
    .awready(1'b1),.wready(1'b1),.bvalid(1'b1),.bid(8'h42),.bresp(2'b00),
    .arready(1'b1),.rvalid(1'b1),.rid(8'h42),.rresp(2'b00),.rlast(1'b1),.rdata(32'h12345678));
  initial begin
    if (!$value$plusargs("FIELD=%s",field)) $fatal(1,"missing FIELD");
    unknown_bit=$test$plusargs("Z") ? 1'bz : 1'bx;
    case(field)
      "ADDR": addr[8]=unknown_bit;
      "ID": id[2]=unknown_bit;
      "STRB": strb[1]=unknown_bit;
      "DATA": data[17]=unknown_bit;
      "MASKED": begin data[23:16]={8{unknown_bit}};strb=4'b1011; end
      "ZERO_STRB": begin data={32{unknown_bit}};strb=0; end
      "KNOWN": begin end
      default: $fatal(1,"bad FIELD");
    endcase
    repeat(2) @(posedge clk); rst_n<=1;
    @(negedge clk);
    $display("INJECTED: %0s",field);
    if ($test$plusargs("READ")) bfm.read_one(addr,id,ok,result,resp);
    else bfm.write_one(addr,data,strb,id,ok,resp);
    if (field=="ADDR" || field=="ID" || field=="STRB" || field=="DATA")
      $fatal(1,"invalid argument was not rejected before transaction");
    if (ok !== 1'b1) $fatal(1,"valid boundary did not complete");
    $display("PASS: request argument boundary %0s",field);
    $finish;
  end
  // Invalid calls must fail before they place anything on the bus.
  always @(posedge bfm.awvalid or posedge bfm.arvalid or posedge bfm.wvalid)
    if (field=="ADDR" || field=="ID" || field=="STRB" || field=="DATA")
      $fatal(1,"invalid argument reached request pins");
  initial begin #2000; $fatal(1,"argument watchdog expired"); end
endmodule
