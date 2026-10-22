typedef enum bit {UVMF_PASSIVE, UVMF_ACTIVE} uvmf_active_passive_t;

class generated_env_configuration;
  string qvip_interface_names[];
  uvmf_active_passive_t qvip_interface_activity[];

  function void initialize(
    string interface_names[],
    uvmf_active_passive_t interface_activity[] = {}
  );
    qvip_interface_names = new[1];
    qvip_interface_activity = new[1];
    qvip_interface_names = interface_names[0:0];
    qvip_interface_activity = interface_activity[0:0];
  endfunction
endclass

module dynamic_array_slice_class;
  string interface_names[];
  uvmf_active_passive_t interface_activity[];
  generated_env_configuration cfg;

  initial begin
    interface_names = new[2];
    interface_activity = new[2];
    interface_names[0] = "ahb_if";
    interface_names[1] = "local_if";
    interface_activity[0] = UVMF_ACTIVE;
    interface_activity[1] = UVMF_PASSIVE;
    cfg = new;
    cfg.initialize(interface_names, interface_activity);
    if (cfg.qvip_interface_names.size() != 1 ||
        cfg.qvip_interface_names[0] != "ahb_if" ||
        cfg.qvip_interface_activity.size() != 1 ||
        cfg.qvip_interface_activity[0] != UVMF_ACTIVE)
      $fatal(1, "dynamic-array class-property slice copy failed");
    $display("DYNAMIC_ARRAY_CLASS_SLICE_OK");
    $finish;
  end
endmodule
