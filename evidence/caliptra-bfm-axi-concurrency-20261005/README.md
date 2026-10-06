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
