# Protected Slurm toolchain recovery

The user-approved cleanup removed shared, read-only firmware inputs that had been stored under disposable `slurm-runs` directories. The six already-running VVP simulations continued; the saved 09:20 process snapshot confirms they were still consuming CPU. Pending rows 8–51 in job 591 were canceled before launch and had no terminal test result. Their fresh array is prepared separately and will use a throttle of six.

Slurm job 609 built Icarus from c339 and restored the pinned Caliptra RTL, Adams Bridge, RISC-V compiler, Python environment, and MbedTLS links under `/home/dsell/toolchains/iverilog-c339/`. Its JTAG output-path check failed because `iverilog-vpi` wrote into the Slurm submit directory. Job 612 rebuilt JTAG under the protected root and produced the manifest, but exited on a grep for a macro absent from the pinned MbedTLS header. Job 613 reran the corrected finalization and completed with exit 0. The manifest records the old and new Icarus hashes and tool versions.

GCC reported an upstream warning in the pinned JTAG support source `tcp_server.c` about `ctx` being freed twice on an error path. The VPI build succeeded; the source was left unchanged. If a firmware test reaches that error path, its effect remains a risk to inspect in the test evidence.

Per-test outputs remain in disposable run directories and will be copied into the repository as evidence.
