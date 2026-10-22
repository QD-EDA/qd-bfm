module flat_member_control;
  class child_config;
    function string convert2string();
      return "child";
    endfunction
  endclass

  class env_config;
    child_config child;
    function string convert2string();
      child_config local_child;
      local_child = child;
      return {"prefix:", local_child.convert2string()};
    endfunction
  endclass

  initial begin
    env_config cfg = new();
    cfg.child = new();
    if (cfg.convert2string() != "prefix:child") $fatal(1, "unexpected string result");
    $display("FLAT_MEMBER_CONTROL_OK");
    $finish;
  end
endmodule
