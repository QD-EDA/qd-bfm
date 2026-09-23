# Single-beat response backpressure evidence

This adds directed backpressure for the existing single-outstanding AXI4 manager;
it does not qualify AXI VIP, Caliptra DV or UVM. The protocol oracle is Arm
[AMBA AXI and ACE, IHI 0022H](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf),
whose channel handshake rules require the source to hold VALID and information
until acceptance. An independently implemented local target and its stall
counters exercise that rule; the BFM monitor is not an independent VIP oracle.

## Reproduce

On macOS arm64: Icarus/vvp 13.0 stable (v13_0), Verilator 5.050
(`2026-07-01 rev vUNKNOWN-built20260701`), Python 3.14.7:

```sh
./run.sh
python3 run_caliptra_subordinate.py "$CALIPTRA_ROOT" /tmp/bfm-delay0 --response-delay 0
python3 run_caliptra_subordinate.py "$CALIPTRA_ROOT" /tmp/bfm-delay7 --response-delay 7
```

CALIPTRA_ROOT must be a clean checkout of
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` (v2.1.2). Each pilot archives exact
compiler/simulator argv, raw stdout/stderr, input hashes, exit codes and wall
times. The pilot hashes listed sources/header trees, not a proven include closure.
Use separate output directories for each run. No application RTL/DV is modified.

## Results and boundaries

- Standalone suite: exit 0; 0.92 seconds for one local run including compilation.
  Previous tests remain. Delays 0/1/3/8 use independent exact stall counts for
  two reads and two writes. Delay 8 exceeds TIMEOUT=5 and succeeds because
  deliberate delay is outside the response timeout. This is one measurement,
  not a reference-host performance qualification.
- Twenty seeded violations fail with the stability diagnostic and no PASS:
  X/Z mutations on eight response fields, dropped RVALID/BVALID, and known
  RDATA/BRESP mutations at the accepting edge. Four additional X/Z VALID
  injections before the first offered response fail during the delay.
- Stable unknown error-read data passes; negative and X delay parameters fail.
  The X-parameter fixture emits two Icarus constant-loop warnings, retained in
  the log. The Python runner rejects negative and out-of-range delay arguments.
- All original 30 reset cases pass with default timing. Delay 3 additionally
  exercises reset during stalled R/B responses with running and stopped clocks:
  34 cases, asynchronous output clearing and successful recovery.
- Actual Caliptra axi_sub: AW/DW/UW=32, IW=8, EX_EN=0, C_LAT=0. Both delay 0
  and 7 complete 12 component transfers with 24 component stall cycles and
  detect the seeded data fault. Independent interface counters measure R/B
  stalled cycles as 0/0 and 30/30 respectively. Simulation finishes at 730 ns
  and 1 us; default-lane builds took 3.09 and 3.12 seconds locally.
- Both real pilots exit **2 (UNKNOWN)**: three upstream interface width warnings
  remain; the separate CLP_ASSERT_ON build rejects five `eventually` properties.
  Verilator is two-state, so these runs cannot establish four-state behavior.
  The warnings and failed assertion lane are never converted into a clean pass.

READY delay starts after request cleanup, not after response arrival. TIMEOUT
still bounds subsequent handshake waits. Reset cancels every added wait.
Payload stability applies from a sampled stalled response through acceptance;
this does not validate all idle activity, response user metadata, overlapping
calls, bursts, ordering, independent AW/W scheduling, or full-chip register/DV
flows. These are explicit remaining qualification gaps. CI runs the standalone
suite using the runner's packaged Icarus; it does not run the optional Caliptra
pilot or pin the simulator build. Green CI does not confer production status.
