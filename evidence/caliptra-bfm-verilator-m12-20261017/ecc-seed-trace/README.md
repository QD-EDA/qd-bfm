# M12 ECC seed trace gate

Slurm job 2106 traced `smoke_test_ecc_keygen` (`2f1b875490838662`) on DAN-DESKTOP with pinned QD-BFM `ffc12ab427e961f40354f32a8e7a147e5d4e5764`, Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052, assertions enabled, and the M10b AXI overlay. The diagnostic ECC source overlay hash is `0cd3eadb4db5febe89cfe5a43b939ecd745525f0785087221267663f43bc663a`; model hash is `a081cbacf2cf9146d015c1c4b9a214846c6a16a7f02736de2fb778b8797850f6`.

The simulation failed at `ERR_ECC_SEED_NOT_STABLE` after 536.5 seconds. The captured transition at 78,353,000 changes `seed_reg` from nonzero to zero; the sampled history shows `zeroize_reg` and `SEED.hwclr` asserted in the preceding sampled cycle, with no software/KV write, present-reset, or read-fail control. Firmware compilation succeeded, but the test did not reach firmware PASS. The verified root cause and assertion-guard follow-up are in [`ecc-seed-guard/`](../ecc-seed-guard/README.md).

The archived gate output is in [`generated/job-2106/gate-results/2f1b875490838662/`](generated/job-2106/gate-results/2f1b875490838662/). `FILE-SHA256SUMS` validates the copied log and result files. Build logs, resource reports, model hash, tool versions, and generated diagnostic overlay are alongside it. The model binary and transient native-vector work directory were not retained locally.
