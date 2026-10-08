> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra AXI completed-transaction concurrency evidence

## Scope

This evidence covers bounded concurrent read and write contexts in the
Caliptra AXI transaction monitor. It is a direct module regression, not a full
Avery/UVM agent replacement qualification.

## Results

The guarded command passed:

```sh
sh dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh
```

Output:

```text
memory guard: preflight 82% free; floor 70%
PASS: AXI records, W-before-AW, concurrent reads/writes, and capacity/error checks
memory guard: command exited 0; minimum observed free memory 82%
```

The regression covers W-before-AW capture, independent AW contexts with W
beats paired in AW order, out-of-order B responses across IDs, same-ID B
ordering, interleaved/out-of-order read responses, capacity errors, framing
errors, and response-ID mismatch.

The shared RAM guard checks system-wide free memory before launch, samples
every 0.5 seconds, and terminates the full child process group below a 70%
free-memory floor or after its configured timeout. This run stayed at 82% free.

## Source hashes

| File | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv` | `55ca8e32c1bae316d0babebd1ee9523ad6b77d60c61bd8068cb4f8a8c9c85e7c` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_transaction_monitor.sv` | `037ac4fa3c6e5372d931b264c390b03f65a1760e555986e23c8e16718b3526c4` |
| `dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh` | `7b08d280f89aba0b8180971074f32da7cd8a077d65367171280309d02c211988` |
| `scripts/run_with_memory_pressure_guard.py` | `1695c427d2aff61a205c7062ad487395181c5ec90f6fe28bd090d2ee9708e0aa` |
| `scripts/caliptra_bfm_memory_guard.sh` | `b15f9eeda7b61f036fe28b183a0c51461e7d7507e82252a28a24b756bf1e0593` |

## 2026-10-08 current-state addendum

The transaction-monitor regression now also checks two complete W frames
arriving before either AW, channel-order pairing when the addresses arrive,
out-of-order B responses, an AW arriving during a partial W frame, and a
same-cycle first AW/W handshake. The guarded run passed with published Icarus
Verilog 13.0 (`v13_0`, upstream source commit
`dfeee909ed9f20b4870dd93423156c0170c0e1ff`).

Command:

```sh
env IVERILOG_BIN=/opt/homebrew/bin/iverilog VVP_BIN=/opt/homebrew/bin/vvp sh dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh
```

| Artifact | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv` | `5b0e3b0ff501a943b65d462466d27496a9319d011632e4f6b9e394e185e22e04` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_transaction_monitor.sv` | `cf59b6497b6a80e132b81d1be91ceae0bcddb442538f619dd53ff0ec430e63b1` |
| `dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh` | `8e4ef6ad1f1c83b1f2057e348fe8c1be9175a172af274b8d0d0debceca9ca011` |
| Icarus compiler `/opt/homebrew/bin/iverilog` | `5df81b269e1ff2c965dd00ad5a8071ca17717f416003b3661a18b2dde430e73c` |
| Icarus runtime `/opt/homebrew/bin/vvp` | `1a9bdf1f40102f64f015514f5069f99a5dd9f9f38de343743ef4c169fb358392` |
| Raw log `/private/tmp/caliptra-bfm-axi-concurrency-v13_0-20261008.log` | `afebfb686819919b1d4dba6830ffc0e72e03e07b4ccbb031cde53b5723cd3d31` |

## 2026-10-08 bounded-queue overflow addendum

A follow-up guarded run also passed the capacity boundary: the monitor accepts
exactly `MAX_OUTSTANDING` W-before-AW frames, reports `STATUS_CAPACITY` for the
next frame, and does not pair a later AW after losing write tracking. This
fail-stop behavior prevents overflow from reusing a live context. The run used
the same published Icarus 13.0 (`v13_0`, source commit
`dfeee909ed9f20b4870dd93423156c0170c0e1ff`).

Command:

```sh
env IVERILOG_BIN=/opt/homebrew/bin/iverilog VVP_BIN=/opt/homebrew/bin/vvp sh dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh
```

| Artifact | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv` | `5b0e3b0ff501a943b65d462466d27496a9319d011632e4f6b9e394e185e22e04` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_transaction_monitor.sv` | `4227e2d387f488e46bfe3c3f69b61985897e150b5b40b489902668c843d55c30` |
| `dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh` | `8e4ef6ad1f1c83b1f2057e348fe8c1be9175a172af274b8d0d0debceca9ca011` |
| Icarus compiler `/opt/homebrew/bin/iverilog` | `5df81b269e1ff2c965dd00ad5a8071ca17717f416003b3661a18b2dde430e73c` |
| Icarus runtime `/opt/homebrew/bin/vvp` | `1a9bdf1f40102f64f015514f5069f99a5dd9f9f38de343743ef4c169fb358392` |
| Raw log `/private/tmp/caliptra-bfm-axi-concurrency-v13_0-20261008.log` | `e6781af98bc2422ba96cde8c2d55be102bb9842696f645beb168836a9d52bc1d` |
