# First AES/DMA vector diagnostic — Slurm job 301

The no-trace diagnostic completed on the pinned top-level environment. The
runner and simulator exited 0, the log has one `* TESTCASE PASSED`, zero
failure markers, zero bad diagnostics, and normal finish at `minstret=1429`,
`mcycle=3682`. Peak RSS was 1,861,124 KiB; the job requested 1 CPU and 3 GiB.

This is a narrowed diagnostic, not a pass for the complete firmware suite:
it ran only AES case 0 (`--first-aes-case-diagnostic`), used fast TRNG and
diagnostic boot-data preload, quieted routine firmware output, and skipped PQ
vector generation. The inventory row for the full
`smoke_test_dma_aes_gcm_short_1_dword` test therefore remains unverified.

The run used QD snapshot `72d965adc2d7e9bfdbadaa3348add9781319bd1c`, Caliptra
RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` with UVM
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`.

`result.json` records the case YAML digest, runner commands, firmware and
simulation input hashes, pass markers, and simulator provenance. The compiled
VVP image is omitted; its SHA-256 is retained separately.
