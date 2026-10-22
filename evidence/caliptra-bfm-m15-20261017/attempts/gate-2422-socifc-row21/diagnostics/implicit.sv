package p;
  class C;
    extern function lock_fuses();
  endclass
  function C::lock_fuses();
  endfunction
endpackage
module top;
  import p::*;
  initial begin C c = new(); c.lock_fuses(); end
endmodule
