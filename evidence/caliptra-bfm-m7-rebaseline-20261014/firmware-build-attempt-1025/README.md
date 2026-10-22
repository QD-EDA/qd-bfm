# Firmware overlay harness attempt 1025

This attempt is setup evidence, not a firmware build result. All six tasks
stopped in the pinned Makefile's RISC-V toolchain preflight before compiling.
The harness passed the absolute path with its trailing prefix dash as
`GCC_PREFIX`; the Makefile appends `-gcc`, so it searched for an invalid
double-dash executable name. The compiler is present at the recorded
`riscv-none-elf-gcc` path and reports version 15.2.0.

The intern's triage correctly identified the shared Makefile preflight error
and that the overlay was not reached. Direct verification narrowed the cause to
the malformed prefix, rather than a missing compiler. This attempt is excluded
from all pinned-only/overlay outcomes. Its task logs and the original harness
are retained here; generated build directories were deleted by each task.
