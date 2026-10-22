# M19 queue trace reruns, rows 62/69/71

This fresh current-c339 array reruns the remaining queue-underflow rows with the corrected observation helper. Row 56 passed the same trace-helper gate separately at `../queue-trace-row56-gate-20261019-02/`.

- Rows 62, 69, 71; throttle 3, 1 CPU / 2 GiB each, 600-second row cap.
- Pinned Adams Bridge: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; pinned Icarus: `cae035642e056644274a01e98d4422ce286685b4`.
- Observation-only trace captures valid, zeroize, output count, and expected queue depth at the checker clock edge and after settled updates. It changes no DUT, firmware, expected values, or pass criteria.

Result: pending.
