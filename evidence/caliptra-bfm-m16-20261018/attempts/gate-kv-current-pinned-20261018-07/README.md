# KeyVault row 6 full-environment gate, attempt 07

Fresh one-row retry for generated KeyVault row 6 (`kv_rand_lock_test`) on pinned Icarus. The overlay now emits and rewrites `kv_ahb_sequence.svh` in normal runtime mode as well as burst-smoke mode; only the injected four-beat probe remains conditional. This follows job 2805's single compile diagnostic at the upstream AHB sequence path. The test uses the existing AHB BFM and filelist setup, with no RTL, firmware, or pass-criteria changes.

The runner selects the testcase with `CALIPTRA_UVM_TESTNAME=kv_rand_lock_test`; its default remains `kv_rand_wr_rd_test`. It runs `--runtime`, so the row-8-specific four-beat smoke check is not required. A pass requires zero exit, zero UVM errors/fatals, `** TESTCASE PASSED`, and `$finish`.

- Host/toolchain: DAN-DESKTOP, Python 3.14.4; Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Firmware commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; row-6 YAML SHA-256 `17c86f0887cfdb3cb3a3ff4ff25ef65a5c932e1a4a8ad34c40cc36352ea2b66f`.
- Overlay source SHA-256: `37e154a29add8448e0765d914e8438b4c67bd3b273b551ad2a3340765921f2a3`.
- Runner source SHA-256: `d0a8a0e31316be3cf58e54e7ed511b711addb725b46808482300669c6c182e7e`.
- Source archive SHA-256: `1e4f5caec8de46f7b7c720d820518f022ef5f0c560485346fcdbabc7f4757541`.
- Slurm script SHA-256: `973d74c2b221dd65ec875407404d6e703f9d109a1bd7281d2aa47563f4d13483`.

The overlay preflight emitted the ordinary AHB sequence without burst-smoke mode; the prepared sequence has no remaining `configuration.` member path (SHA-256 `ba20a270b0e3a131ac0a393f312b8e828d8c56f6287616e0ebcb13fe7c3234c1`). Job 2806 was submitted to DAN-DESKTOP on 2026-10-18 at 22:25:57 UTC. It requested 1 CPU and 4 GiB, with a 30-minute Slurm cap and a 600-second simulator timeout.

**FAIL at runtime.** Compile succeeded and the test reached `$finish`, but the AHB monitor recorded 1,076 `UVM_ERROR`s, all checker error code 1. In the BFM checker, code 1 means at least one monitored AHB signal is unknown (`HREADY`, `HRESP`, `HSEL`, `HTRANS`, `HWRITE`, `HSIZE`, `HADDR`, or pending `HWDATA`); the log does not identify which signal. Errors begin at 3,015 ns and recur through 2,248,095 ns. `** TESTCASE PASSED` and `$finish` do not qualify the row because the runner requires zero UVM errors and returned 1. No checker was disabled or relaxed.

The full run tree is archived as `raw/job-2806.tar.gz`, SHA-256 `2fa030034035395b52ec6306506594264531809472aa7ad2466ad168ec8db117`. Runtime wall time was 1:43.11 with peak RSS 634,656 KiB. The remote run directory was removed after archive verification.
