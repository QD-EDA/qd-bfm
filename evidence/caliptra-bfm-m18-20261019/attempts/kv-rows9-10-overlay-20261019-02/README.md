# M18 KeyVault rows 9 and 10 generated-BFM overlay array — ROWS 9 AND 10 PASS (job 3026)

Row 9 (`kv_rand_test`) passed on DAN-DESKTOP with Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and refreshed Icarus source `cae035642e056644274a01e98d4422ce286685b4` (binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`). The archived simulation log contains `** TESTCASE PASSED`, UVM summary `UVM_ERROR: 0` and `UVM_FATAL: 0`, followed by `$finish`; runtime was 16.615 seconds. The intern's triage matched the raw log.

Row 9 archive: `raw/job-3026_9.tar.gz`; SHA-256 `8523da41a8c11d0bc68ae09804fe92ee8cbbb8fff2c7de50c7f43999d9b14cd6` matches its sidecar. Row 10 (`kv_rand_lock_test`) also passed: the log contains `** TESTCASE PASSED`, zero UVM errors/fatals, and `$finish`; runtime was 121.752 seconds. The intern verified the filtered terminal summary against the raw log. Its archive SHA-256 is `891a846029b02eb2cd0190c2fb26b9eee82c7fcb8d109e1776a2b68bc60b354f`.

The array uses open-AHB, KeyVault factory sequence-base, and hash-guarded generated-BFM overlays. Changes are limited to testbench/BFM/filelist setup; RTL, firmware, stimuli, expected results, and pass criteria remain unchanged.
