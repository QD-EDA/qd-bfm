# Array 799 maintenance cancellations

On 2026-10-13 at 18:42 MDT, the supervisor cancelled array tasks 799_28, 799_30, 799_34, and 799_35 for Slurm maintenance. Tasks 28 and 30 were cancelled by the supervisor; tasks 34 and 35 were cancelled under the user's earlier instruction. The Slurm wrapper logs record jobs 871, 874, 886, and 887 terminated by signal at 18:42:09.

| Array task | Test | Last heartbeat | Outcome |
| --- | --- | --- | --- |
| 799_28 | `smoke_test_ecc_errortrigger4` | wall_s=16800, mcycle=56216 | CANCELLED-FOR-MAINTENANCE |
| 799_30 | `kv_entry_read_err` | wall_s=15000, mcycle=107664 | CANCELLED-FOR-MAINTENANCE |
| 799_34 | `smoke_test_kv_parallel_access` | wall_s=5700, mcycle=40947 | CANCELLED-FOR-MAINTENANCE |
| 799_35 | `smoke_test_ecc_flow2_kv_ocp_progress` | wall_s=5100, mcycle=37091 | CANCELLED-FOR-MAINTENANCE |

Each full simulator log ends at the heartbeat above. The four logs have 57, 51, 20, and 18 heartbeats respectively; no adjacent heartbeat pair repeats the mcycle value. None has a testcase pass/fail marker or `result.json`. `resource.log` and `runner.log` are empty because Slurm terminated the jobs before the wrapper wrote completion data; elapsed runtime, runner exit, and peak RSS are therefore unavailable. These rows are recorded as maintenance cancellations, not test timeouts.

The selected files include each simulator and firmware log, compile log, run provenance and toolchain metadata, empty resource/runner logs, and Slurm wrapper output. The remote archive SHA-256 was `5baf78559d54531811efa9c0af4b8a9bba0cdd314b16c082db1c0066c7b338eb`; the local archive matched before extraction. `SHA256SUMS` covers the extracted evidence files and this README. The temporary archive was removed after verification.

After the cancellations, `squeue` showed only 799_[36-42] pending with reason `JobHeldUser`. Do not release or resubmit those held tasks. Re-run these four cancelled rows with tasks 36–42 after the supervisor announces that Slurm has reopened.

After the archive hash was verified and the outcomes were recorded, the four cancelled run directories were removed from `slurm-runs`. Their measured allocated size was 1,511,620,608 bytes (about 1.41 GiB); `/home/dsell` available space increased by the same amount. Shared toolchains and held-task state were untouched.

The maintenance-cancelled outcomes remain historical. Their fresh rerun results are tracked separately in [`../../cancelled-reruns-c339-20261013-01/README.md`](../../cancelled-reruns-c339-20261013-01/README.md) and its `results.tsv`.
