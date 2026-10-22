# M19 queue trace reruns, rows 62 and 71

Rows 62 and 71 had valid M19 FAIL reruns in job 3114, but their observation helper patched copies that the compiler filelist did not use. The corrected helper now replaces the unique testbench source entry in a run-local copy of the pinned filelist, hash-guards the source, and directs Icarus to the traced copy. Row 56 and row 69 traces are preserved in the sibling attempts.

- Rows 62, 71; throttle 2, 1 CPU / 2 GiB each, 600-second row cap.
- Pinned Adams Bridge: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; Icarus: `cae035642e056644274a01e98d4422ce286685b4`.
- Only testbench trace output and its run-local filelist entry change; no DUT, firmware, vectors, expected values, or pass criteria change.

Result: pending.
