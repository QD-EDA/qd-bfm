# Generated ECC UVMF on clean Icarus `c339b9f2` — 2026-10-10

Slurm job 206 reproduced the generated ECC compile failure using clean
published Icarus main `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` and clean
Caliptra v2.1.2 `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The guarded
`run_generated_ecc_reset_monitor.sh` runner stopped during its IEEE 2017
compile phase, before VVP or a UVM test started. Icarus reported `syntax
error` followed by `Invalid module item` at the package-qualified,
parameterized proxy class handles in the generated input/output BFM
interfaces. This is the same failure shape previously observed on published
Icarus `4b3f3424`, now reproduced on `c339b9f2`.

No QD-BFM compatibility edits were made for these declarations, and the
pinned Caliptra/Icarus checkouts were read-only and clean. The bundled UVM
version is Accellera UVM 2020.3.1.

## Resources and artifacts

The job requested 1 CPU and 1 GiB as a first memory-measured pilot; the process
group was guarded at 750,000,000 bytes with a 6,000,000,000-byte system
reserve. It stopped in 0.54 seconds at 75,944 KiB MaxRSS, with a 0.06 GiB
process-group peak and 14.50 GiB minimum available. Slurm accounting storage
is disabled, so scheduler MaxRSS was unavailable; `/usr/bin/time -v` recorded
the peak RSS.

- [`job.sbatch`](job.sbatch) and [`qd-bfm-source.tar.gz`](qd-bfm-source.tar.gz)
  preserve the command and exact QD inputs.
- [`logs/runner.log`](logs/runner.log) preserves the compile diagnostics.
- [`logs/resource.log`](logs/resource.log) preserves time and RSS.
- [`logs/source-commits.txt`](logs/source-commits.txt),
  [`logs/source-files.sha256`](logs/source-files.sha256), and
  [`logs/iverilog-version.txt`](logs/iverilog-version.txt) pin the tool and
  source inputs.

This confirms the latest tested published Icarus still cannot compile this
generated ECC interface shape. Generated ECC UVMF runtime remains blocked at
compile; standalone UVMF-lite tests and other Caliptra BFM integrations are
separate paths.
