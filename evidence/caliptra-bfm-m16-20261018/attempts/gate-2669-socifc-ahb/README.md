# SoC-IFC AHB MVC filelist gate: row 45

Job 2669 ran pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, row 45 (`soc_ifc_cmdline_test`), with pinned Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` and binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. The new AHB/MVC overlay was generated, but compilation stopped before the generated packages: the pinned filelist references vendor Avery sources through unset `AVERY_AXI`/`AVERY_SIM` variables and a proprietary `CALIPTRA_AXI4PC_DIR/Axi4PC.sv` checker. The repository placeholder intentionally raises a syntax error when that checker is not available. Result: **BLOCKED**, no simulation.

The filelist overlay does not remove the AXI checker or vendor source entries; doing so would hide a verification dependency. The existing M13 generated SoC-IFC runtime evidence does pass its generated AHB mailbox flow, but it uses a separate curated source list and does not validate this stock row's complete filelist.

Preserved here: row result, compile command/log/resource, overlay list and manifest, Slurm log, job metadata, batch script, and staged source archive. Archive SHA256: `137891799072c9eb02e208d0ebe01079ac5d6e5cfc757b22113f1bb8d2a9d6e5`.

Resources were 1 CPU, 3 GiB, 20-minute Slurm cap, and 600-second per-row timeout. The completed 2.4 MiB remote run directory was removed after capture.
