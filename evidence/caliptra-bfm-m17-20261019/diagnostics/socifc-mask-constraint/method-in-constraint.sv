package p;
  typedef bit [31:0] dword_t;
  function automatic dword_t get_mask(input string name);
    return name == "WO" ? 32'h0000_0001 : 32'h0000_0000;
  endfunction
  class Transaction;
    rand dword_t data;
  endclass
endpackage
module top;
  import p::*;
  Transaction wrtrans;
  string rname;
  initial begin
    wrtrans = new();
    rname = "WO";
    wrtrans.randomize() with { wrtrans.data & get_mask(rname) != 0; };
    if ((wrtrans.data & get_mask(rname)) == 0) $fatal(1, "constraint not met");
  end
endmodule
