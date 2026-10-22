# ML-DSA row 93 controller-state trace

The row 93 pin trace establishes that all result reads are zero at the DUT pins and match the sequence readbacks. This one-row run uses the same observation-only controller/sampler trace that produced runtime markers on row 97: program counter, next state, controller FSM, decoded opcode, sampler mode/start, subcomponent busy inputs, and verify/norm-check completion.

The run uses the pinned Caliptra and Adams Bridge sources and c339 Icarus. It changes no RTL decisions, firmware, stimulus, expected values, assertions, or pass criteria. Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds.
