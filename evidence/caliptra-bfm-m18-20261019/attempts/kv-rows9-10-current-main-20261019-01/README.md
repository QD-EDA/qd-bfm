# M18 KeyVault rows 9 and 10 current-main array — BLOCKED

Array job 3016 reran `kv_rand_test` (row 9) and `kv_rand_debug_test` (row 10) with the refreshed Icarus main pin, open-AHB filelist, and hash-guarded KeyVault sequence-base overlay. Both stopped before simulation at generated `kv_rst_configuration.svh:149`, where `$psprintf` is called with missing/empty parameters (compile exit 30; 3.095 s for row 9 and 3.102 s for row 10). The earlier M17 `PASS` records remain in their history columns; current-main M18 results are `BLOCKED`.

The job used two array tasks, one CPU and 4 GiB each, with a 15-minute Slurm cap and 600-second runner timeout. Source and script hashes passed remote preflight. Local archive SHA-256 values matched their remote sidecars:

- row 9, job 3016_0: `59c451ddbebdd49585aff8090f661f581a300e9050b57213f58087ed07c79c6e`
- row 10, job 3016_1: `1004c4f3e0df355229b845715ac188dc2d319cc1dd35ec01965350049f60420d`
