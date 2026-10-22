# ML-DSA row 97 controller-state trace, retry 4

Retry 3 confirmed that row 97 enters verification but the sampler/SHA3 boundary remains idle and no verify-result register write occurs. This retry adds observation-only traces of the controller program counter, next state, controller FSM, decoded instruction opcode, sampler mode/start outputs, subcomponent busy inputs, and verify/norm-check completion signals. It runs the same row 97 testcase and does not change RTL decisions, firmware, stimulus, expected values, assertions, or pass criteria.

One-row gate after trace-helper change: row 97. Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds.
