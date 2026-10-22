KeyVault's generated environment sequence uses a type-parameterized UVMF base class whose `configuration` property has type `CONFIG_T`, then accesses a nested agent's sequencer:

```systemverilog
class uvmf_virtual_sequence_base #(type CONFIG_T);
  CONFIG_T configuration;
endclass

class kv_env_sequence_base #(type CONFIG_T)
  extends uvmf_virtual_sequence_base#(.CONFIG_T(CONFIG_T));
  virtual task body();
    if (configuration.kv_hmac_write_agent_config.sequencer != null)
      configuration.kv_hmac_write_agent_config.sequencer.observed = 1;
  endtask
endclass
```

The full minimized case is in `parameterized_config_path.sv`. Pinned Icarus 13.0 (source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) rejects the nested path at elaboration with `sorry: Nested member path not yet supported for class properties.` Verilator 5.032 compiles and runs the same case, printing `PARAMETERIZED_CONFIG_PATH_OK`.

A paired control casts the inherited `CONFIG_T configuration` property to a concrete `kv_env_configuration kv_cfg` and accesses `kv_cfg.kv_hmac_write_agent_config.sequencer`; it compiles and runs on both tools. The previous non-parameterized nested task-call reproducer also passed both tools, so this reduced case isolates the type-parameterized base-property path.

Slurm job 2797 used one CPU with per-command 60-second limits. Icarus primary compile exits 1; Icarus control compile/run exits 0/0; Verilator primary and control compile/run exit 0/0. Raw logs, commands, source hashes and resource records are in `raw/parameterized-job-2797.tar.gz` (SHA-256 `32afa1ab7b20e2c04a9fdfb1242454f368b32e0bacd34fe5f7ae04b7b00ae4ce`). Please classify and address this Icarus support gap for A3.
