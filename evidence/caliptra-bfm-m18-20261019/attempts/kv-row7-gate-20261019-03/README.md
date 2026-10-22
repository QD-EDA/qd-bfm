# M18 KeyVault row 7 generated-BFM overlay gate — BLOCKED (job 3025)

The existing hash-guarded generated-KeyVault BFM helper now runs from the shared runner alongside the open-AHB and factory overlays. The resulting filelist compiles cleanly with 76 warnings and no errors. Simulation exits 0 after 20.791 seconds with UVM summary `UVM_ERROR: 0`, `UVM_FATAL: 0`, but no testcase pass/fail marker; the unchanged runner therefore records `BLOCKED` (“simulation ended without a recognized test pass marker”). The run does not justify a PASS without the bench’s existing pass criterion.

The gate used Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and refreshed Icarus source `cae035642e056644274a01e98d4422ce286685b4` (binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`) on DAN-DESKTOP. The unit suite passed all 80 tests before submission.

Raw archive `raw/job-3025.tar.gz` SHA-256 `cf86c00645c05fb473560259664215b220d029d2cbefdb90dd393375e40a136c` matches the remote sidecar. It contains the result JSON, compile and simulation logs, generated overlay manifest/filelist, runtime image, and job metadata.
