# Full-top random DMA bring-up

This run is **not a firmware or BFM qualification**. The pinned Caliptra RTL
top compiled successfully with the generated Icarus profile, including the DMA
generator overlay. Firmware generation then stopped before simulation because
the available RISC-V GCC 13.2 toolchain is x86_64 and depends on the missing
Intel Homebrew library `/usr/local/opt/isl/lib/libisl.23.dylib`.

- Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Case: `rand_test_dma`, stock `caliptra_top_tb.vf` profile
- Full-top compile: passed; see `compile.log`
- Firmware build: failed before producing images; see `firmware.log`
- Simulation: not run
- Memory guard: 73% minimum free, with a 60% floor
- Raw output directory: `/private/tmp/qd-bfm-rand-test-dma-20261006-retry3`
