package p;
  typedef bit [31:0] dword_t;
  class Transaction;
    rand dword_t data;
  endclass
  class MaskSource;
    function automatic dword_t get_mask(input string name);
      return name == "WO" ? 32'h0000_0001 : 32'h0000_0000;
    endfunction
  endclass
endpackage
module top;
  import p::*;
  Transaction wrtrans;
  MaskSource socregs;
  string rname;
  dword_t wr_mask;
  initial begin
    wrtrans = new();
    socregs = new();
    rname = "WO";
    wr_mask = socregs.get_mask(rname);
    if (!wrtrans.randomize() with { wrtrans.data & wr_mask != 0; }) $fatal(1, "randomize failed");
    if ((wrtrans.data & wr_mask) == 0) $fatal(1, "constraint not met");
  end
endmodule
