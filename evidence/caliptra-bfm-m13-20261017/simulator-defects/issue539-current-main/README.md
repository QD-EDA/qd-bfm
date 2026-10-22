# Issue #539 reproducer on M13 current main

The current-main `sigencode_z_tb` overlay run produced 3,072 expected-versus-X
comparison errors. This small existing reproducer isolates the packed-struct
assignment-pattern behavior already tracked by the closed, `from-caliptra-dv`
issue [#539](https://github.com/dsellerbrock/iverilog-uvm/issues/539). This
probe checks whether the exact M13 Icarus SHA still shows that behavior; it does
not create or reopen an issue.

The source is the existing
[`self-contained.sv`](../../../caliptra-bfm-environment-matrix-20261011/reproducers/icarus-struct-assignment-width/self-contained.sv).
The Slurm probe uses 1 CPU, 3 GiB, and a 600-second cap for each compile and
simulation stage. Job 2269 was submitted on DAN-DESKTOP in
`/home/dsell/slurm-runs/caliptra-bfm/a2/m13-issue539-current-main-20261017-01`.
Raw logs, hashes, tool versions, resource records, and result will be archived
here after the probe finishes.
