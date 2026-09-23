# Four-state request argument validation

Previously, the alignment expression `addr % BYTES != 0` could evaluate to X,
causing an unknown address to bypass the guard and reach the bus. Unknown IDs,
write strobes and enabled write-data bytes were also accepted at task entry.
The new independent request-pin monitor reproduces the address bug against the
previous source: it fails when the invalid request reaches the pins.

Both tasks now reject unknown address/ID arguments before waiting or driving a
request. write_one additionally rejects unknown strobes and X/Z in any enabled
byte. Disabled bytes may remain unknown; zero strobes may accompany wholly
unknown data. These are explicit BFM input-policy checks, not new claims of
complete AXI protocol monitoring. Existing alignment/reset errors, task signatures,
handshakes and timeout behavior remain unchanged for supported requests.

## Reproduce and results

```sh
./run.sh
iverilog -g2012 -s tb_request_args -o /tmp/qd-request.vvp qd_axi4_single_master.sv tb_request_args.sv
vvp /tmp/qd-request.vvp +FIELD=ADDR +X
# Expected fatal before request VALID; repeat with +Z and optional +READ.
vvp /tmp/qd-request.vvp +FIELD=MASKED +X
vvp /tmp/qd-request.vvp +FIELD=ZERO_STRB +Z
# Expected successful boundary cases.
python3 run_caliptra_subordinate.py /path/to/clean/caliptra-rtl /tmp/new-caliptra-evidence
# Existing pilot remains UNKNOWN (exit 2).
```

Icarus/vvp 13.0 stable passes the complete regression, including all prior tests,
12 new fatal X/Z cases (write address/ID/strobe/data and read address/ID), and
seven passing cases (known writes, masked/zero-strobe data with X and Z, known
read). Invalid inputs must terminate with the matching BFM argument diagnostic;
a request-pin monitor catches late rejection, and negative cases cannot emit a
pass banner. A watchdog bounds a hung argument test.

The argument fixture uses static response pins to isolate task-entry behavior;
it is not a protocol-compliant subordinate model or independent transaction
oracle. Existing independent memory, reset and response tests remain unchanged.
Four-state checks require Icarus: a two-state Verilator run is not an X/Z oracle.
No additional protocol coverage is inferred from these input checks.

The actual Caliptra axi_sub pilot remains at clean commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, AW/DW/UW=32, IW=8, EX_EN=0, C_LAT=0.
On Verilator 5.050 the upstream-default lane still completes 12 transfers and
24 held component cycles and detects the QD read-data fault. The assertion lane
still rejects five eventually properties, and three upstream interface width
warnings remain visible. No application RTL/DV, assertions or diagnostics were
modified. The overall pilot remains UNKNOWN, not qualification.

Raw before/after argument outputs, exact commands/status/timings, simulator
versions, full regression log and Caliptra evidence are retained locally in
`../evidence/bfm-request-arguments/`; these are not release artifacts. Bursts,
outstanding transactions, full passive monitoring and production DV qualification
remain roadmap work.

A fresh local clone of `662955b` repeated the full Icarus regression and the
actual Caliptra pilot with the same outcomes, including all retained warnings
and assertion-lane failures. This repeats the workspace on the same host/tools;
it does not establish a reproducible compiler build. The isolated argument runs
complete in milliseconds; peak RSS and large-workload throughput were not measured.
