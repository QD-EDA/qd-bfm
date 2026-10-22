# Traced one-row attempt 1801

Host: DAN-DESKTOP. Test: `smoke_test_ahb_mux` (`cadf43c78de6a454`), with a 600-second outer timeout, 1 CPU, and 3 GiB. Build job 1798 compiled trace overlay SHA-256 `61fec13d0c6c036886ab5b406197ef9802ae6e25c8a6eae80d08e5ba98b61bcf`; model SHA-256 is in the build manifest.

The firmware built, then the simulator returned `FAIL` at `AXI_SUB_AW_HSHAKE_ERR` at 4 ns. The trace logged the first AW at bus address `0x30200`, followed by W and B activity, with all printed `$time` values `4000`. These `$time` values do not prove that no precision-level time passed. The complete build and row outputs are archived here; the row archive SHA-256 is `e4a1a4e741b7be1575e0b87de21ae47f41ff5adf600ca54df211f25aed4ed79f`.

This was not a passing overlay result. A new diagnostic build adds event-level AW/W/B changes with `$realtime`, while the candidate now uses nonblocking AW drives and keeps the W/B tasks unchanged.
