# M18 Adams Bridge row 56 header and stale-PISO gate — BLOCKED

Job 3019 tested the ML-DSA config-header overlay and exact removal of the stale `abr_piso_4.sv` entry. Compilation advanced past both and then stopped at the removed `src/mldsa_sampler_top/rtl/mldsa_sampler_pkg.sv` source. The pinned tree now provides the package as `src/abr_sampler_top/rtl/abr_sampler_pkg.sv`; the testbench still imports the former package name. Compile exit was 1 after 0.019 s, with no simulation. The next overlay gate will redirect the filelist and testbench package reference to the pinned renamed package.

Raw archive SHA-256 `8cb347e811c5c0cc03d4cacb7dcba2b4c84899ce1ca912e2cac1d5eaed780700` matches the remote sidecar. The current package hash is `1fba5ed692e185ee04406e3ab0636dc99c3cd06a1caaec0e24c487d854fa29ae`.
