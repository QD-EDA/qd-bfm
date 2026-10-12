# pkdecode source-base correction

Job 539 ran the copied Adams Bridge testbench and RTL on DAN-DESKTOP with Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`). It retained the run-local `#539` address casts and removed the stale `MEM_ADDR_WIDTH` override. The only additional testbench change was the second call's source base: `pkdecode_test('h40, 'h20)` became `pkdecode_test('h40, 'h0)`.

The testbench had been writing the second input vector at address `0x20`, but `src_base_addr_tb` is not connected to `pkdecode`; the DUT starts its `API_rd_address` at zero. The testbench's source-base parameter therefore did not affect DUT reads. Job 539 compared both 2,048-word invocations with zero mismatch lines; compile and simulation exited 0. `sim.log` has no explicit PASS marker, so the evidence is the comparison loop's zero diagnostics plus successful simulation exit.

The source-base patch and run artifacts are retained here. Job 537 is a harness-edit attempt that stopped before compile when it reapplied an already-present compatibility patch; it is not test evidence.
