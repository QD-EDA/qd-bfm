# Setup attempt 01

Build job 2078 failed before model compilation because the fresh build script did not create the required testbench C++ and VLT symlinks. The diagnostic RTL/filelist generator completed successfully; no simulation was submitted. Raw build output and resource records are preserved here. Retry uses a new run directory and adds those two symlink steps.
