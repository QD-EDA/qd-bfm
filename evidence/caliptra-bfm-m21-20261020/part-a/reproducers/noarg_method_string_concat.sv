module noarg_method_string_concat;
  class child_config;
    function string convert2string();
      return "child";
    endfunction
  endclass

  class env_config;
    child_config child;
    function string convert2string();
      return {"prefix:", child.convert2string};
    endfunction
  endclass

  initial begin
    env_config cfg = new();
    cfg.child = new();
    if (cfg.convert2string() != "prefix:child") $fatal(1, "unexpected string result");
    $display("NOARG_METHOD_STRING_CONCAT_OK");
    $finish;
  end
endmodule
