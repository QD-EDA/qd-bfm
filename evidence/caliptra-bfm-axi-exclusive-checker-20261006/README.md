> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra AXI checker exclusive-request evidence

## Scope

The passive Caliptra AXI checker accepts legal exclusive read/write request
shapes and rejects misaligned addresses, bursts longer than 16 transfers, and
non-power-of-two byte counts. The constraints follow Arm AMBA AXI Protocol
Specification IHI 0022L §A6.3.3:
[official specification](https://documentation-service.arm.com/static/68b03beb01ae952d9559f9eb).
The checker is a Caliptra-profile checker, not a full Axi4PC replacement.

The subordinate integration testbench was missing the two response-ID wires
now exposed by its task-based manager's wildcard connection. Declaring those
ports restored compilation without changing the test behavior.

## Results

The checker, manager, SRAM subordinate/queue, and Caliptra AXI complex BFM
regressions all passed under Icarus 13.0-devel. Each memory guard reported a
minimum of 77% free memory against the 60% floor.

- `run-checker.log`: valid ordinary, reordered, and exclusive traffic passed;
  fifteen injected protocol violations were rejected.
- `run-master.log`: manager burst, USER/LOCK, stall, timeout, reset, and
  fail-stop cases passed.
- `run-subordinate.log`: SRAM bursts, stalls, USER, errors, exclusives, and
  bounded multi-ID queues passed.
- `run-caliptra-axi-complex.log`: SRAM/FIFO traffic, error injection, FIFO
  controls, recovery availability, and randomized stalls passed.

Reproduce from the repository root with:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/axi/tests/run_checker.sh
```

The other captured runner commands are the corresponding scripts under
`dv/caliptra_bfm/axi/tests/` with the same environment variables.

## All-channel backpressure checks — 2026-10-07

The focused checker regression now injects payload changes while AW, W, B, AR,
and R are each stalled. All five stability checks reject the corrupted
payloads; the complete suite accepts its valid reorder/exclusive/narrow cases
and rejects all forty injected protocol violations. The 2026-10-07 run used a
40% free-memory floor and observed 59% minimum free RAM.

## SHA-256

| File | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/axi4_caliptra_checker.sv` | `e5be951cb9a2600e8d743d6d36d828463de3c581366d547a359b3d4a4d5cf4fe` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_checker.sv` | `078b071239816a52dcb90768058298bd229d53d375ea678f3ac8ea6396b16b9a` |
| `dv/caliptra_bfm/axi/tests/run_checker.sh` | `79171f6a65a13866eacd368139dacce026524c495fc4a29aa884e7bf65b39809` |
| historical `dv/caliptra_bfm/axi/tests/run_checker.sh` | `f889cb6b7c6d4fc9ad36553c51d71b754e3a75b798e10781d14698edf23a15b1` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv` | `5e3d4777a9c54940f38bf3455999bf10caefb8bb164b78c267ec6cb947d5a225` |
| `docs/conformance/caliptra_bfm_research_2026-10-03.md` | `b70861f68a6e8cf4f5477f8c56275504095ebbad88474e5bbaf1301ba2b48c84` |
| `run-checker.log` | `4751bbc31a808c8c5c7334c1682bd83333222e100cd8a119c542351a53836bf1` |
| `run-master.log` | `f7554a6d80508953c117f345c580110bdbb16ece11173029a94c0652cee83bb5` |
| `run-subordinate.log` | `f3ec48a95256378341a44a6d563ecaa86c55d253e09b9850e695137a1b830cfd` |
| `run-caliptra-axi-complex.log` | `fc1eb8e73c8ff82efdf10a7f0d3011d85b65798f408a59041476a4c3bf60dc99` |
