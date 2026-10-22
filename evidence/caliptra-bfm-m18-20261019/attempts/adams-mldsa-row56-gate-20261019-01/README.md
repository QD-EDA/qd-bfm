# M18 authored ML-DSA row 56 gate

Runs `rej_rand_test` at authored Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` with Icarus main `82023726be90ab269d6e0ef5e755ebb69e6f648c`. The gate tests the filelist overlay mapping the removed `mldsa_top` names to their upstream-renamed `abr_top` sources from commit `0a45a695`; it uses the pinned `abr_config_defines.svh` and `abr_params_pkg.sv`, plus the existing `abr_reg_pkg.sv`. No configuration values, RTL, firmware, expected output, or pass criteria are changed.

Resources: 1 CPU, 4 GiB, 15-minute Slurm wall limit, 600-second per-row timeout.

Source snapshot SHA-256: `0f824ded23b823264fe99e426fa5c6532214e4539fedc220dd43509d365fb9b6`. File hashes are in `source-files.sha256`.
