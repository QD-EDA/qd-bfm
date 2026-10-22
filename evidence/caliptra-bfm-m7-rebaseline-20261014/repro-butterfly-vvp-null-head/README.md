# Butterfly VVP assertion reduction

The current-main `butterfly_top_tb` run compiles and then aborts in VVP inside `vthread_add_event_wait()` with assertion `head`. Task isolation showed that the failure occurs in `intt_butterfly2x2_div2_test`, while the other test task alone passes.

A reduced fork/clock-loop probe is not a current-main-only failure: the `loop-static-init` and `loop-assignment` variants both compile and abort with the same VVP internal assertion on c339 and current main. The `loop-auto-task` control compiles and exits 0 on both. Per the active milestone, this crash is filed as [issue #596](https://github.com/dsellerbrock/iverilog-uvm/issues/596) with the `from-caliptra-dv` label; the report states that the exact invalid pointer path is not yet known.

The full DUT comparison is constrained: c339 cannot compile the isolated full testbench because its code-generation flag limit is exceeded; current main compiles it and the INTT-only variant aborts. Raw minimized sources, compile/simulation logs, version output, task-isolation sources, filelists, and hashes are retained beside this note. Generated VVP binaries were excluded from the evidence copy.
