# Row 4 SoC-IFC wildcard-coverage overlay gate

This is the one-row gate for the new coverage syntax overlay before any array run. It stages the pinned Caliptra top-level `caliptra_top_rom_test` (row 4) and invokes the M20 runner with the per-run AAXI and wildcard-coverage overlays. Source snapshot SHA-256: `352fddead2b8fa45be98b6916b77cccb5f2cc0cc05e0ea5117a30d49fa154ef9`.

The job requests one CPU, 12 GiB, and two hours, with a 3,600-second per-row runner timeout. The 12 GiB request is 1.25x the earlier 8 GiB SoC-IFC compile peak (8,381,044 KiB). It uses the clean protected Caliptra source pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and the pinned Icarus c339 binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330` with matching `vvp` SHA-256 `979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309`.

The immutable submission script is `run.sbatch`, SHA-256 `d31a6ca6445621bddc982d86fbdfa067996b0752fa735128629df578205faba4`. No row verdict is recorded until its result JSON, testcase markers, and archive checksum are verified.

Submitted as job `3276` from `/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-wildcard-row4-gate-20261020-01`; the first scheduler check showed it pending behind the cluster's full CPU allocation. Submission record SHA-256: `a7432d8c7a8af34391b8a045c931ba81ffbcd99000f205d855b0461a5a7ae869`.

Terminal job 3276 archive SHA-256 `2968a2c3781e8cdaec6742e36ce622289c1e0af6b7e84bc73863b5da5c645fc8` matches its remote sidecar. Status is compile-blocked; no simulation or firmware verdict. After copying and verifying the archive, the 1,614,140-byte remote run tree was deleted.
