# Protected Slurm toolchain recovery

The user-approved cleanup removed shared, read-only firmware inputs that had been stored under disposable `slurm-runs` directories. The six already-running VVP simulations continued; the saved 09:20 process snapshot confirms they were still consuming CPU. Pending rows 8–51 in job 591 were canceled before launch and had no terminal test result. Their fresh array is prepared separately and will use a throttle of six.

Slurm job 609 rebuilds Icarus from c339 and restores the pinned Caliptra RTL, Adams Bridge, RISC-V compiler, Python environment, MbedTLS links, and JTAG VPI under `/home/dsell/toolchains/iverilog-c339/`. Per-test outputs remain in disposable run directories and will be copied into the repository as evidence.
