// SPDX-License-Identifier: Apache-2.0
module tb_response_stalls;
  tb_axi4 #(.RESPONSE_DELAY(3)) base();
  reg [8*16-1:0] field;
  logic is_read;
  initial begin
    if (!$value$plusargs("FIELD=%s",field)) $fatal(1,"FIELD required");
    if (field=="ERROR_RDATA") begin
      wait(base.inject_error && base.arvalid);
      force base.rdata='x;
    end else begin
      is_read=(field=="RDATA" || field=="RID" || field=="RRESP" || field=="RLAST" || field=="RVALID");
      if ($test$plusargs("EARLY")) begin
        if (is_read) wait(base.arvalid);
        else wait(base.wvalid);
      end else begin
        if (is_read) wait(base.rvalid && !base.rready);
        else wait(base.bvalid && !base.bready);
        @(posedge base.clk); // The independent target has offered a stalled response.
        if ($test$plusargs("HANDSHAKE")) begin
          if (is_read) wait(base.rready);
          else wait(base.bready);
        end else @(negedge base.clk);
      end
      $display("INJECTED: %0s",field);
      case (field)
        "RDATA": if ($test$plusargs("HANDSHAKE")) force base.rdata=32'hcafe1235;
                 else if ($test$plusargs("Z")) force base.rdata='z; else force base.rdata='x;
        "RID": if ($test$plusargs("Z")) force base.rid='z; else force base.rid='x;
        "RRESP": if ($test$plusargs("Z")) force base.rresp='z; else force base.rresp='x;
        "RLAST": if ($test$plusargs("Z")) force base.rlast='z; else force base.rlast='x;
        "RVALID": if ($test$plusargs("DROP")) force base.rvalid=0;
                  else if ($test$plusargs("Z")) force base.rvalid='z; else force base.rvalid='x;
        "BID": if ($test$plusargs("Z")) force base.bid='z; else force base.bid='x;
        "BRESP": if ($test$plusargs("HANDSHAKE")) force base.bresp=2'b10;
                 else if ($test$plusargs("Z")) force base.bresp='z; else force base.bresp='x;
        "BVALID": if ($test$plusargs("DROP")) force base.bvalid=0;
                  else if ($test$plusargs("Z")) force base.bvalid='z; else force base.bvalid='x;
        default: $fatal(1,"unknown FIELD");
      endcase
      #10000;
      $fatal(1,"response mutation escaped monitor");
    end
  end
endmodule
