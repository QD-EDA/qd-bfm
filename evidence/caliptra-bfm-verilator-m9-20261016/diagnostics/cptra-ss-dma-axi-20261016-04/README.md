# DMA status and interrupt trace

Diagnostic job 1769 ran only `cptra_ss_test_rom`, seed 1, on DAN-DESKTOP. It used Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator `5.052 2026-09-05 rev v5.052`, and the logging-only overlay captured by the archive. The model SHA-256 is `2bc4a8c818dade5b49767f669116ae1998ae7a478c61068164b214be380562bf`; the combined filelist/overlay SHA-256 is `054374c303998bf5182bc46ebfe47745f504db1fba591d0534ac8ff712583c64`.

## Result

The firmware build passed. The diagnostic simulation hit its separate 600-second cap (`sim_exit=124`, 600.004 seconds); the wrapper finished after 602.508 seconds. It produced no firmware PASS/FAIL marker or final mcycle. The official M9 row remains `TIMEOUT` at 6,873 seconds; the pinned c339 row also timed out without a terminal result. This diagnostic does not replace either row.

## Evidence

- The trace contains 18 `STATUS0` samples at offset `0x2200c`; the final sample at `t=5975000` is `0x00010001` (busy=1, error=0). There are no later `STATUS0` samples, and the monitor's 128-read cap was not reached.
- At `t=5974000`, the outstanding AXI write returns `BRESP=11` (DECERR). At `t=5975000`, `AXIERR=1` and the DMA FSM enters state 3 (`DMA_ERROR`). The sampled word-15 value `0x67120ad3` had already been accepted with `fifo_ready=1`; this is not a FIFO-full stall.
- After the error transition, the CPU trace contains 4,157 reads of DMA notification register offset `0x22818`, each followed by a W1C write of `0x1`, through `t=115733000`. The earlier error handler reads offset `0x22814` and writes `0x4`; the first notification handler pass writes `0x1` and `0x2`.
- The trace logs request fields and W1C writes, not the read-return data for `0x22818`. In the pinned ISR, W1C `0x1` is emitted only when `NOTIF_TXN_DONE` is set in the preceding read. The repeated clear sequence therefore supports, but does not directly capture, repeated transaction-done status.

The test firmware writes to DMA destination `0x21200000`, outside the pinned top testbench's configured 256 KiB SRAM window at `0x0001_2344_0000` and FIFO window at `0x0000_fa57_0000`. The RTL keeps `NOTIF_TXN_DONE` hardware-set while the controller is in `DMA_DONE` or `DMA_ERROR`; generated CSR logic gives that hardware set priority over software W1C, and `DMA_ERROR` stays active until firmware writes `CTRL_FLUSH`. The trace shows repeated notification servicing but no later `STATUS0` poll. This strongly supports an interrupt-retrigger loop preventing the mainline wait/flush path from running; the diagnostic did not capture the CPU PC.

Source links and the full root-cause chain are in [`root-causes.md`](../../root-causes.md). The transfer archive contains the full staged source snapshot, overlay, run scripts, filelist and build metadata, and raw logs. Its SHA-256 was verified against the remote copy: `563778ddf38d6cc0b680298def2184743c4dbff74a57d9094b643e9240ed09b2`. Extracted logs and resource records are under [`raw/`](raw/).
