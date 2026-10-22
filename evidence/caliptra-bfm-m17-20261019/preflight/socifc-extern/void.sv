package p;
  class C;
    extern function void lock_fuses();
  endclass
  function void C::lock_fuses();
  endfunction
endpackage
module top;
  import p::*;
  initial begin C c = new(); c.lock_fuses(); end
endmodule
