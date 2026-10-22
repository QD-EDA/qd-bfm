# KeyVault row 6 AHB unknown-signal trace, attempt 08

Diagnostic one-row rerun of `kv_rand_lock_test` after job 2806 reached runtime but reported 1,076 AHB checker code-1 errors. The BFM checker now has an opt-in `+KV_AHB_TRACE` trace capped at 12 samples; each sample prints reset plus HREADY/HRESP/HSEL/HTRANS/HWRITE/HSIZE/HADDR/HWDATA and pending-write state. With the plusarg absent the checker behavior is unchanged. The runner keeps the same failure gates.

- Target: KeyVault row 6 (`kv_rand_lock_test`), firmware commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Host/toolchain: DAN-DESKTOP; Python 3.14.4; Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Instrumented BFM checker SHA-256: `e385f7164cdaffa7accddfa2ed1a5610108e9d28b65449355bf94d4ae770adeb`.
- Overlay source SHA-256: `37e154a29add8448e0765d914e8438b4c67bd3b273b551ad2a3340765921f2a3`.
- Runner source SHA-256: `d0a8a0e31316be3cf58e54e7ed511b711addb725b46808482300669c6c182e7e`.
- Source archive SHA-256: `fd3f134d1221ac3f24b5940e63f7b04219a1e4bf5069ac5a1e676e997eec10e5`.
- Slurm script SHA-256: `5f044a8e5b2f6eab22964fd458b1a58b71922c2d3223587958da5930cd9fffad`.

Job 2812 was submitted to DAN-DESKTOP on 2026-10-18 at 22:34:39 UTC. It requested 1 CPU and 4 GiB, with a 30-minute Slurm cap and a 600-second simulator timeout.

**FAIL, diagnostic only.** The completed-job output reported runner exit 1, 1,076 UVM errors, no UVM fatals, and `$finish` at 2,254,640,000 (1 ps). The 12 captured unknown-signal samples all showed `HSEL=x`; the other sampled AHB signals were known. Runtime wall time was 1:46.64 and peak RSS was 634,792 KiB. The run directory was no longer present on DAN-DESKTOP when collection was attempted, so the raw log archive could not be recovered; the observation is retained here from the completed-job output, not as an archived trace.

The trace and source snapshots localize the cause: generated `hdl_top.sv` assigns the active wrapper's `ahb_lite_slave_0_HSEL` net to `1'b0`, while `ahb_lite_caliptra_uvm_master_proxy` drives the same net from the active AHB manager. That produces X during selected transfers. The fix is to remove this generated tie-off on all KeyVault runs; row 8's burst-smoke path already did so. A fresh row-6 runtime gate without the tie-off is recorded in the next attempt.
