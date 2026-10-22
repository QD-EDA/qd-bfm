# AHB QVIP compatibility environment — staging failure

Status: **STAGING-FAIL; no test result**. Slurm job 2764 began and ended at 2026-10-18 21:06:53 UTC. The staged `caliptra_bfm_memory_guard.sh` tried to execute `scripts/run_with_memory_pressure_guard.py`, which was omitted from the source snapshot. The runner exited before Icarus compilation; no environment simulation or PASS/FAIL classification occurred.

The exact scheduler output is in `slurm-2764.out`. `squeue -j 2764` was empty after the run; `sacct` reports that accounting storage is disabled. The incomplete source archive and its SHA256 are preserved to document this staging attempt. The corrected retry uses a fresh run directory and includes the missing helper.
