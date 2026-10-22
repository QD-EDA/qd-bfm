class kv_write_agent_config;
  int observed_clock_count;

  task wait_for_num_clocks(input int count);
    observed_clock_count = count;
  endtask
endclass

class kv_environment_configuration;
  kv_write_agent_config kv_hmac_write_agent_config;
endclass

class kv_write_sequence_base;
  kv_environment_configuration configuration;
  bit completed;

  task body();
    configuration.kv_hmac_write_agent_config.wait_for_num_clocks(100);
    completed = 1;
  endtask
endclass

module tb;
  kv_write_agent_config agent;
  kv_environment_configuration configuration;
  kv_write_sequence_base seq_h;

  initial begin
    agent = new;
    configuration = new;
    configuration.kv_hmac_write_agent_config = agent;
    seq_h = new;
    seq_h.configuration = configuration;
    seq_h.body();
    if (!seq_h.completed || agent.observed_clock_count != 100)
      $fatal(1, "nested configuration task call did not complete");
    $display("NESTED_CLASS_PROPERTY_OK");
    $finish;
  end
endmodule
