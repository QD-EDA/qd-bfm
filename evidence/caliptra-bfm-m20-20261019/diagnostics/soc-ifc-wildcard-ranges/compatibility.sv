module soc_ifc_wildcard_ranges_tb;
  covergroup transition_cg with function sample(input bit [31:0] value);
    cp: coverpoint value {
      bins set32 = (0 => [32'h0000_0000:32'hFFFF_FFFF]);
      bins clr32 = ([32'h0000_0000:32'hFFFF_FFFF] => 0);
      bins set8 = (0 => [8'h00:8'hFF]);
      bins clr8 = ([8'h00:8'hFF] => 0);
      bins set4 = (0 => [4'h0:4'hF]);
      bins clr4 = ([4'h0:4'hF] => 0);
    }
  endgroup

  covergroup vector_cg with function sample(input bit [31:0] address);
    cp: coverpoint address {
      bins ROM [16] = {[32'h0000_0000:32'h0000_FFFF]};
      bins ICCM0 [16] = {[32'h4000_0000:32'h4000_FFFF]};
      bins ICCM1 [16] = {[32'h4001_0000:32'h4001_FFFF]};
    }
  endgroup
endmodule
