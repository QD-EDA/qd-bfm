# M18 ML-DSA row 77 gate — invalid staging attempt

Slurm job 3010 did not reach compilation or simulation. The selective source snapshot omitted `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f`, which the open-AHB overlay builder reads to assemble its support-source filelist. The runner emitted `BLOCKED` during setup in 0.632 s, with 43,828 KiB maximum RSS; this is a harness staging failure, not a row result and is not used to update the 108-row matrix.

The raw job archive and its original remote SHA-256 sidecar are in `raw/`; the archive hash was independently matched locally. The incomplete source snapshot is preserved with its checksum. A corrected one-row gate is recorded separately.
