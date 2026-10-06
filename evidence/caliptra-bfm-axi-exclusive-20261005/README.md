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
