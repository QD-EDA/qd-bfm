# AXI master X/Z control rejection — 2026-10-10

The standalone AXI manager now fails closed when a decisive input control or
response code is unknown. Unknown AWREADY/WREADY/ARREADY during an active
request, BVALID/RVALID while the manager is ready, and X/Z bits in an accepted
BRESP/RRESP poison the manager immediately. Known SLVERR/DECERR responses still
return an unsuccessful transaction without treating the valid error code as an
unknown-control fault.

The new `UNKNOWN_CONTROLS` case runs in the testbench configuration with the
protocol checker disabled, so these behaviors are enforced by the manager
itself. Seven probes inject X and Z on write/read READY, response VALID, and
BRESP/RRESP. Each probe requires fail-stop and output/state cleanup in fewer
than 32 cycles, below the configured 64-cycle ordinary timeout.

## Test evidence

Slurm job 199 is the expected RED run against the old manager: the new test
reproduced an AWREADY=X stall that ended only at the ordinary timeout. Job 200
then exposed a test-fixture mismatch: the new probe used LOCK=0 while its mock
target expected LOCK=1. That fixture was corrected. Job 201 passed the final
suite on QD base commit `29cc2af7b24c89105c3c54663f3b9e812389ea90` plus
`source-patch.patch`:

- 11 standalone manager PASS markers, including the seven X/Z probes and the
  existing burst, reset, malformed-response, and outstanding-write cases.
- 21 cross-simulator PASS markers: nine DATA_WIDTH/ID_WIDTH combinations
  under Icarus, the same nine under Verilator, and three Verilator memory-target
  regressions.
- No FAIL markers. Icarus was clean published main
  `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; Verilator was 5.032.

Verilator emitted non-fatal width and incomplete-case warnings under
`-Wno-fatal`; its results remain two-state evidence. The Icarus X/Z probes
cover these selected manager controls and response codes, not every payload
bit or every four-state simulator/profile.

## Resources and artifacts

Job 201 requested 1 CPU and 1 GiB, based on the prior parameter-matrix peak of
354,072 KiB. The master phase measured 17,688 KiB MaxRSS; the cross-simulator
phase measured 353,816 KiB. The process-group guard reported a 0.39 GiB peak,
12.42 GiB minimum available memory, and exit 0 with a 750,000,000-byte cap and
6 GB system reserve.

- [`logs/red-runner.log`](logs/red-runner.log),
  [`logs/red-time.log`](logs/red-time.log), and
  [`logs/red-slurm-199.out`](logs/red-slurm-199.out): expected pre-fix RED.
- [`logs/fixture-failure-master.log`](logs/fixture-failure-master.log) and
  [`logs/fixture-failure-slurm-200.out`](logs/fixture-failure-slurm-200.out):
  intermediate fixture mismatch and its diagnostic.
- [`logs/master.log`](logs/master.log) and
  [`logs/crosssim.log`](logs/crosssim.log): final passing regressions.
- [`logs/master-time.log`](logs/master-time.log),
  [`logs/crosssim-time.log`](logs/crosssim-time.log),
  [`logs/slurm-201.out`](logs/slurm-201.out), and
  [`logs/source-files.sha256`](logs/source-files.sha256): run and tool data.
- [`job-red.sbatch`](job-red.sbatch), [`job-green.sbatch`](job-green.sbatch),
  and [`run-crosssim.sh`](run-crosssim.sh): submitted commands.
- [`source-archive.tar.gz`](source-archive.tar.gz),
  [`source-patch.patch.gz`](source-patch.patch.gz),
  [`red-source-patch.patch.gz`](red-source-patch.patch.gz), and
  [`fixture-failure-source-patch.patch.gz`](fixture-failure-source-patch.patch.gz):
  the source snapshot and compressed exact diffs. Plain and compressed patch
  hashes are recorded in [`source-revisions.txt`](source-revisions.txt).

This closes selected manager-side unknown-control handling. Full four-state
qualification and full Caliptra/UVMF qualification remain open.
