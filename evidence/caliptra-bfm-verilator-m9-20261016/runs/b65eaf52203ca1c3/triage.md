# `smoke_test_kv_ecc_flow1` firmware build triage

The row ended as `FIRMWARE_BUILD_FAIL` after 0.877 seconds, before simulation, with no mcycle. The intern identified the first compiler error; I verified `firmware.log` reports `smoke_test_kv_ecc_flow1.c:197:5: error: implicit declaration of function 'srand'`. The pinned RTL source at commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` calls `srand(time)` at line 197 but its include block does not include `<stdlib.h>`. The run produced no simulation log. This is an upstream test-source build defect; no source or pass criterion was changed.

Evidence: `result.json`, `firmware.log`, `task.resource`, and `FILE-SHA256SUMS` in this directory.
