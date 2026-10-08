> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra AXI exclusive access evidence

## Scope

The SRAM memory subordinate now implements the AXI4 exclusive monitor for the
Caliptra-visible ID, address, burst length, transfer size, and burst type. It
supports up to 256 IDs (Caliptra uses 5- or 8-bit IDs), stores one reservation
per ID, invalidates reservations when an accepted write touches a monitored
byte, and returns EXOKAY/OKAY according to the exclusive result. A failed
exclusive write does not update memory. The FIFO subordinate remains a target
that does not support exclusives and returns OKAY for LOCKed transactions.

The checks follow Arm AMBA AXI and ACE Protocol Specification IHI 0022H,
§A7.2.3–A7.2.5: [official specification](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf).
The target checks the AXI attributes present in Caliptra's `axi_if`; it does
not implement the complete Arm Axi4PC assertion set.

## Results

Both regressions ran under the 70% free-memory floor. Each observed 75% free
memory before and throughout the run.

```text
PASS: AXI memory subordinate bursts, stalls, USER, errors, and exclusive access
PASS: AXI memory subordinate bounded multi-ID read/write queues
PASS: DMA map, unknown optional controls, autonomous FIFO push/pop, and recovery sequence integration
```

The memory-subordinate case checks a matching single-beat exclusive pair,
multi-beat EXOKAY responses, and a failed store after an intervening write to
the monitored bytes. The latter returns OKAY and preserves the intervening
write's value. The DMA subordinate regression confirms ordinary combined
SRAM/FIFO traffic and recovery behavior still pass.

Replay from this clone with:

```sh
IVERILOG_BIN=./driver/iverilog VVP_BIN=./vvp/vvp \
  sh dv/caliptra_bfm/axi/tests/run_subordinate.sh
IVERILOG_BIN=./driver/iverilog VVP_BIN=./vvp/vvp \
  sh dv/caliptra_bfm/axi/tests/run_dma_subordinate.sh
```

## Limits

The monitor belongs to this single AXI subordinate port; it cannot observe
writes made through another memory port. The model compares the ID, address,
length, size, and burst fields available at the Caliptra interface. It does not
claim full Arm AXI conformance or generated Caliptra UVMF qualification.

## Source hashes

| File | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv` | `9c5abea1072e99510b3aefb61d4c4c796685aeaec46314fb1bc7101144156e54` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv` | `4daaf6fc8b54f54f3af3ea7e3e23dde1fee64f3b3a77254b964ca8a238cfff0a` |
| `dv/caliptra_bfm/axi/tests/run_subordinate.sh` | `d9643a4dcbe1ab919c343ed1dd8e19309c91cd50455bf7949598a6336c4dba72` |
| `dv/caliptra_bfm/axi/tests/run_dma_subordinate.sh` | `caf93bd785ff1d4a7698a2b71c8c281a0668c66f23ade6b191f8ef9a99bcc10f` |

## Current-state addendum — 2026-10-08

The current `run_subordinate.sh` regression passed under upstream Icarus
Verilog 13.0 stable. The installed compiler and runtime report `v13_0`; the
published tag resolves to source commit
`dfeee909ed9f20b4870dd93423156c0170c0e1ff` ([upstream release](https://github.com/steveicarus/iverilog/releases)).
This is a focused AXI subordinate result, not full Caliptra-top or UVMF
qualification.

Both the bursts/stalls/USER/error/exclusive test and the bounded multi-ID
queue test passed. Reproduce with:

```sh
IVERILOG_BIN=/opt/homebrew/bin/iverilog VVP_BIN=/opt/homebrew/bin/vvp \
  sh dv/caliptra_bfm/axi/tests/run_subordinate.sh
```

The raw log is `/private/tmp/caliptra-bfm-axi-subordinate-v13_0.log`.

| Input | SHA-256 |
|---|---|
| Icarus 13.0 compiler binary | `5df81b269e1ff2c965dd00ad5a8071ca17717f416003b3661a18b2dde430e73c` |
| Icarus 13.0 VVP binary | `1a9bdf1f40102f64f015514f5069f99a5dd9f9f38de343ef4c169fb358392` |
| `axi4_caliptra_checker.sv` | `a679cf9b4119ed5a34b260be9d8b800d16b33180aa7b701a2f245bf6c5512245` |
| `axi4_caliptra_master.sv` | `0883329316b1005c50048acfa0a73db8040e043a5d1406e78d8296b57f126844` |
| `axi4_caliptra_memory_subordinate.sv` | `0a59bb61380113bb60115d20b06628da2c55a11360f31a8355ea738cea46bd10` |
| `axi4_caliptra_monitor.sv` | `33ed58d9c3d4b2aac4493740704547169349a28a61b304e5281533f1879529ca` |
| `tb_axi4_caliptra_memory_subordinate.sv` | `9d9e6091683fc940570c1aacafb71f65922a7046b3eac31ebfba9f6607f7a624` |
| `tb_axi4_caliptra_memory_queue.sv` | `b4b715786767206ca151a975a7003748e47eaebad6ed3f0eb18a47a926a482dd` |
| `run_subordinate.sh` | `011a0d1f16e75313f2e0e68d24c7d8b56e199bf65aa5021f6c8a263f3e762a1f` |
| Raw run log | `0d7ed813706c334a4aba162c910baf11ca3cf6e78d14f07321915887fec486aa` |

## Checker follow-up — 2026-10-08

`run_checker.sh` also passed on the same published Icarus 13.0 source commit
and compiler/runtime binaries identified above. It accepted the valid reordered,
same-ID, exclusive, and narrow-transfer cases and rejected all 40 injected
protocol violations with the expected diagnostics. Reproduce with:

```sh
IVERILOG_BIN=/opt/homebrew/bin/iverilog VVP_BIN=/opt/homebrew/bin/vvp \
  sh dv/caliptra_bfm/axi/tests/run_checker.sh
```

This exercises the open Caliptra AXI profile checker; it does not establish
full ARM Axi4PC or full-top qualification.

| Input | SHA-256 |
|---|---|
| `tb_axi4_caliptra_checker.sv` | `031d85710a4533e93d4a4a6e987885828f520a7cb45d1b3f6e65761c43fc95b1` |
| `run_checker.sh` | `6b37b811b2437288d9e3cd98ab4845e6f53923a5cb88a30ffa6df0e8f90f847f` |
| Raw run log | `7d039701d066513fa68e6ea026db558acbb193568e172c7fe48d04a045285719` |
