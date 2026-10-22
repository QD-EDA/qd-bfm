# M18 row 64 compressor gate diagnostic

The address-based one-cycle memory model was added, but the testbench still sampled `compress_done` with an event-sensitive wait. That wait observed a transient delta-cycle pulse and advanced after one read. The failure archive is `raw/first-failure.tar.gz`; see the diagnostic attempt for the trace.

These attempts are diagnostic failures and do not replace the final row result. The passing, current-main gate is recorded in sibling attempt 03.
