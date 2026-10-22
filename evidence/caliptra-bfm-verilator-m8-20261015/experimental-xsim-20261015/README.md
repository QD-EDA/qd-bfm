# Experimental Verilator 4-state top-level pilot

The planned pilot was to build the QD-BFM `caliptra_top_tb` model using the
experimental Verilator PR #7176 `--x-sim` mode, then run all six Icarus-PASS
comparison cases under a 120-second simulation cap per case, using their
recorded c339 outcomes and cycles as references. It uses the full QD-BFM source
commit `dd6d43d` and checks for the source filelist and all six native-vector
inputs before building or running.

This assessment pins experimental commit `27d3c20`; it is not part of stable Verilator 5.052. Upstream [closed PR #7176](https://github.com/verilator/verilator/pull/7176) on 2026-09-17 and said the work was proceeding under [#7193](https://github.com/verilator/verilator/issues/7193), so results here describe that pinned prototype only.

The toolchain is protected at `/home/dsell/toolchains/verilator-pr7176-27d3c20/`; the model and run logs go under fresh Slurm root 11. Build request: 4 CPUs, 8 GiB, 2 hours. Pilot request: 1 CPU, 3 GiB, 45 minutes. Submit only when the active M8 arrays free enough memory.

The top-model build failed before simulation. Verilator 5.045 devel reported
`Unsupported: 4-state numbers in this context` at
`caliptra_prim_fifo_sync.sv:135:37` while selecting `storage[fifo_rptr]` from
an X-valued 385-bit FIFO word; it then raised an internal error. Build logs and
resource evidence are in [`build1377`](build1377/README.md). The dependent
six-case pilot did not run, so no four-state pass, cycle, wall-time, speed, or
top-level queue coverage was measured.

Coverage assessment: packed FIFO array selection with an X-valued word blocks
the model build; queue support remains untested because elaboration stopped
first. The independent scalar scheduler probe compiled but produced no output
within 20 seconds; generated C++ shows a loop bound of
`0x18446744073709551613ULL` instead of the stable control's `1U` (details in
the [probe record](../pr7176-xsim-probe/README.md)). This prototype therefore
does not provide a usable top-level four-state path for the current model.
