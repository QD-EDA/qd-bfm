module dynamic_array_slice_control;
  string interface_names[];
  string qvip_interface_names[];
  initial begin
    interface_names = new[1];
    qvip_interface_names = new[1];
    interface_names[0] = "ahb_if";
    qvip_interface_names[0] = interface_names[0];
    if (qvip_interface_names.size() != 1 || qvip_interface_names[0] != "ahb_if")
      $fatal(1, "element copy failed");
    $display("DYNAMIC_ARRAY_COPY_CONTROL_OK");
    $finish;
  end
endmodule
