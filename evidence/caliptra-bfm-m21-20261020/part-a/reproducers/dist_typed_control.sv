module dist_typed_control;
  class item;
    rand bit valid;
    constraint weighted_valid { valid dist {1 :/ 1000, 0 :/ 1}; }
  endclass
  item value;
  initial begin
    value = new();
    if (!value.randomize()) $fatal(1, "randomize failed");
    $display("DIST_TYPED_CONTROL_OK");
    $finish;
  end
endmodule
