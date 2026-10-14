#!/bin/bash
set -euo pipefail
export PATH=/opt/homebrew/bin:/private/tmp/qd-bfm-icarus-c339-build-20261012-02/install/bin:/Users/danielellerbrock/projects/iverilog_uvm/evidence/caliptra-exact-riscv-toolchain-20260923/toolchain/bin:/usr/bin:/bin:/usr/sbin:/sbin
export DYLD_LIBRARY_PATH=/private/tmp/qd-bfm-icarus-c339-build-20261012-02/install/lib
export MAKEFLAGS=-j1
export CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl
export CALIPTRA_BFM_PROFILE=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/src/integration/config/caliptra_top_tb.vf
export CALIPTRA_JTAGDPI_VPI=/private/tmp/qd-bfm-localwave1-prep-20261012/jtagdpi/jtagdpi.vpi
export CALIPTRA_GCC_PREFIX=/Users/danielellerbrock/projects/iverilog_uvm/evidence/caliptra-exact-riscv-toolchain-20260923/toolchain/bin/riscv-none-elf-
export IVERILOG_BIN=/private/tmp/qd-bfm-icarus-c339-build-20261012-02/install/bin/iverilog
export VVP_BIN=/private/tmp/qd-bfm-icarus-c339-build-20261012-02/install/bin/vvp
export IVERILOG_VPI_BIN=/private/tmp/qd-bfm-icarus-c339-build-20261012-02/install/bin/iverilog-vpi
export PYTHONPYCACHEPREFIX=/private/tmp/qd-bfm-localwave1-c339-20261012-01/runs/0001-cptra_ss_test_rom-local-01/pycache
python3.12 /private/tmp/qd-bfm-localwave1-c339-20261012-01/source/qd-bfm/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py \
  --case cptra_ss_test_rom \
  --case-yaml cptra_ss_test_rom/cptra_ss_test_rom.yml \
  --output /private/tmp/qd-bfm-localwave1-c339-20261012-01/runs/0001-cptra_ss_test_rom-local-01/output \
  > /private/tmp/qd-bfm-localwave1-c339-20261012-01/runs/0001-cptra_ss_test_rom-local-01/runner.log 2>&1
