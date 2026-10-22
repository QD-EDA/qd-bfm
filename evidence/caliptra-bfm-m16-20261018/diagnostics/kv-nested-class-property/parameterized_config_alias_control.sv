class kv_write_sequencer;
  int observed;
endclass

class kv_write_agent_config;
  kv_write_sequencer sequencer;
endclass

class kv_env_configuration;
  kv_write_agent_config kv_hmac_write_agent_config;
endclass

class uvmf_virtual_sequence_base #(type CONFIG_T);
  CONFIG_T configuration;
endclass

class kv_env_sequence_base #(type CONFIG_T)
  extends uvmf_virtual_sequence_base#(.CONFIG_T(CONFIG_T));
  kv_env_configuration kv_cfg;
  int completed;

  virtual task body();
    if (!$cast(kv_cfg, configuration))
      $fatal(1, "configuration cast failed");
    if (kv_cfg.kv_hmac_write_agent_config.sequencer != null) begin
      kv_cfg.kv_hmac_write_agent_config.sequencer.observed = 1;
      completed = 1;
    end
  endtask
endclass

module top;
  kv_env_configuration cfg;
  kv_write_agent_config agent_cfg;
  kv_write_sequencer seqr;
  kv_env_sequence_base#(kv_env_configuration) seq_handle;

  initial begin
    cfg = new;
    agent_cfg = new;
    seqr = new;
    agent_cfg.sequencer = seqr;
    cfg.kv_hmac_write_agent_config = agent_cfg;
    seq_handle = new;
    seq_handle.configuration = cfg;
    seq_handle.body();
    if (!seq_handle.completed || seqr.observed != 1)
      $fatal(1, "concrete config alias path failed");
    $display("PARAMETERIZED_CONFIG_ALIAS_OK");
    $finish;
  end
endmodule
