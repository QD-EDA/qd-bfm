# Row 43 SoC-IFC overlay gate

Slurm job `3233_43` gates the M20 compatibility overlay on `soc_ifc_trng_test`, before any array. It uses pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus c339.

The per-run overlay replaces the generated SoC-IFC UVM register-model include, collapses three nonfunctional fixed-array wildcard coverage groups to one bin each, redirects selector method calls through local strings for Icarus, splits one chained UVM lookup into equivalent local handles, and adds the missing explicit `void` return type to a generated task helper. It does not change DUT RTL, stimulus, register transactions, expected values, assertions, or pass criteria.

Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds. The pinned source and compiler hashes are checked before the run. Logs, result, per-run overlay manifest, tool metadata, resource record, and the terminal archive will be SHA-256 checked before cleanup.

Terminal result: BLOCKED during compile at the additional `case (axs_reg.get_name()) inside` in `soc_ifc_env_mbox_reg_axs_invalid_sequence.svh:173`. Archive `raw/job-3233_43.tar.gz` SHA-256: `00a6e0a6bc1afd697682ae6749b241379e8c4594f0267b36c24f2de4890f60be`. This gate did not reach simulation.
