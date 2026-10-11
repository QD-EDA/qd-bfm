# Traced `smoke_test_dma` timeout — Slurm job 289

This follow-up ran the same pinned `smoke_test_dma` case with `--trace-axi`.
Compilation and simulation startup succeeded, but the 7,000-second process
timeout expired before a testcase marker or result JSON. Runner exit was `124`;
the resource report records 1,859,876 KiB peak RSS against a 3 GiB request.

The trace confirms that the fuse-ready status poll deasserted after one read,
`BootGo` was written, ROM flow started, and AXI traffic included write
responses and read data. The final
trace checkpoint was cycle 58,500, `retired=18954`, `pc=0000e3ba`, with
`fatal=0`, `ready_mb=0`, and cumulative AXI counts `AR=37`, `AW=39`, `W=611`,
`B=39`, `R=595`. No testcase pass/fail marker or explicit simulator error was
present.

The PC maps to the `rand()` call in the pinned firmware's 512-word
`smoke_test_dma` payload-preparation loop (`MAX_FIFO_SIZE=1024`). The run had
not reached the following AHB FIFO send call when it timed out. This identifies
a long firmware workload under the interpreted full-top simulation; it does
not show an AHB DMA failure. The full test remains unverified.

The run used QD snapshot `72d965adc2d7e9bfdbadaa3348add9781319bd1c`, Caliptra
RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` with UVM
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. VPI source/plugin and compiled
VVP image hashes are retained separately; the large VVP binary is omitted.
