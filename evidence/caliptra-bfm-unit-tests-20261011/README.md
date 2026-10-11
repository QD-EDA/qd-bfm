# Caliptra block-unit test array — 2026-10-11

## Selection and runtime budget

The array runs the pinned Caliptra `hmac_ctrl_tb`, `sha256_ctrl_tb`, and
`sha512_ctrl_32bit_tb` unit environments. Their 2026-10-03 filelist compiles
exited 0, and these non-generated SystemVerilog benches do not use the
package-qualified parameterized UVMF handles blocked by Icarus issue #533.
The historical HMAC and SHA-512 generated-runtime probes completed within
300- and 600-second guards. Using the slower 600-second result as the
comparable upper bound, each unit test has a 1,200-second process-group timeout
and the Slurm allocation is 40 minutes (about 2x that per-test bound).

Each task requests 1 CPU and 3 GiB. The memory request rounds up 1.25x the
prior full-top peak of 1.86 GiB; the host snapshot showed 17 idle CPUs and
30 GiB available memory before submission, so three concurrent tasks fit.
The harness applies SIGTERM then SIGKILL to the process group at timeout and
keeps compile, simulation, guard, and resource logs per test.

## Inputs and results

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` with
Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. Its clean source tree
is staged as an archive with SHA-256
`65294ca75a79639b4d2bd1b8748a1f972d7c0344ede3499bb4ce1aebad96c3e6`. QD-BFM
source is at the run's recorded commit, and Icarus is clean published
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. Each result requires simulator
exit 0, exactly one `* TESTCASE PASSED`, no `* TESTCASE FAILED`, and no unit
test error marker. The staged Caliptra tree is checked clean, and the three
testbench/filelist pairs and compiler binaries are SHA-256 recorded.
Environment and per-test status matrices will be updated from the retained
results.

Slurm job ID and per-task outcomes will be appended after the array finishes.
