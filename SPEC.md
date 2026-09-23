# QD-BFM v0 scope

Build one executable, protocol-aware open-source bus functional model useful to replace a missing Caliptra proprietary VIP dependency for bounded directed tests. It does not replace UVMF/QVIP/Avery verification or prove full DV qualification.

First inspect the pinned Caliptra v2.1.2 source at /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl (read-only) and identify the simplest actual externally driven bus (AHB-Lite or AXI-Lite/AXI4). Select ONE protocol and direction for v0; record the release interface/ports and protocol source in README. Implement a standalone SystemVerilog BFM with read/write transactions, reset, valid/ready or HREADY stalls, error response, timeout, and explicit protocol assertions. For AXI, do not claim full AXI4 if only AXI-Lite is implemented. Ensure no checker is an empty stub and no pass banner can appear after a protocol error.

Provide an independent tiny DUT/testbench that runs on installed Icarus or Verilator, with positive, stall, error, and timeout/negative cases. Optional Caliptra hookup only if it works without modifying pinned application sources; keep adapters/examples in this repo. No proprietary code or pasted Caliptra testbench. Add README, Apache-2.0 license, and test command. Own only this repo; no commit/push/remote creation.

## Reset-cancellation slice

Cancel active tasks on reset at every blocking wait, including stopped-clock,
startup, response-timeout and post-handshake cleanup windows. Clear request VALID
and response READY outputs asynchronously. Require a released-reset rising edge
before launching a new transaction. Preserve successful transfers, error responses
and request-timeout VALID retention; reset the target before reuse after timeout.
Independent target/monitor tests must reject held/early VALID and prove successful
post-reset recovery. Qualify only the documented directed configuration; four-state
controls and real application integration remain separate roadmap work.
