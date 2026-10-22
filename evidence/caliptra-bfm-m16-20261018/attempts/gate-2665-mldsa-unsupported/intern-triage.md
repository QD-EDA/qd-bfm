# Intern log triage, checked

The intern correctly grouped the dynamic-array slice diagnostics at `mldsa_env_configuration.svh:120-121` and nested class-member-path diagnostics at `mldsa_predictor.svh:113` and `mldsa_scoreboard.svh:129` as compiler limitations.

Corrections after source inspection:

- `qvip_ahb_lite_slave_env_configuration` in the QD-BFM AHB compatibility package already defines `virtual function string convert2string()`. The generated line omits parentheses and Icarus reports that member as a non-string. This is not a missing method in the compatibility API.
- The `line.substr(8)` calls are in pinned generated predictor and sequence sources. Icarus reports the one-argument call as requiring two arguments. The intern mislabeled this as a BFM API gap; it does not call a BFM method.

No fix is made to generated sources or the simulator from this triage alone. The next gate uses the smaller KV AHB environment to determine whether the existing open AHB package can run a complete generated environment without MLDSA-specific compiler gaps.
