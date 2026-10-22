# M17 row 43 AAXI gate after source deduplication

The first AAXI gate (job 2884) exposed duplicate BFM sources: both the open-AHB and open-AAXI lists added `axi4_caliptra_record_if.sv`. The filelist rewrite was updated to reuse sources already present. All 64 unit tests passed after that change.

The one-row rerun, Slurm job 2893, used 1 CPU, 4 GiB, a 20-minute allocation cap, and a 600-second per-row timeout. Pinned Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` / binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; firmware pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; source snapshot SHA-256 `329f49fe1afddd527665f78b4a5fee6d95abdc2139bfd56e4300cad4e8aa8cb4`.

Result: **BLOCKED** after 0.416 seconds at `src/integration/tb/Axi4PC.sv:17`. This pinned file intentionally emits a syntax error to require acquisition of the proprietary ARM checker. It appears in the SoC-IFC `.vf` but is not instantiated in the generated SoC-IFC environment; it is instantiated by the separate full-top testbench, so the overlay will omit it only for SoC-IFC. Intern and direct source inspection confirm the file’s guard and no generated SoC-IFC instantiation.

Raw job archive SHA-256: `89d113c817945b959d0969ee88a35e0ea9fea0d7558dcc3087da44f13845a136`.
