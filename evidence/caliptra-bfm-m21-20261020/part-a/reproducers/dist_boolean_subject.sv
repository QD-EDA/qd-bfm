module dist_boolean_subject;
  class item;
    rand bit valid;
    constraint weighted_valid { (valid inside {1'b1}) dist {1 :/ 1000, 0 :/ 1}; }
  endclass
  item value;
  initial begin
    value = new();
    if (!value.randomize()) $fatal(1, "randomize failed");
    $display("DIST_BOOLEAN_SUBJECT_OK");
    $finish;
  end
endmodule
