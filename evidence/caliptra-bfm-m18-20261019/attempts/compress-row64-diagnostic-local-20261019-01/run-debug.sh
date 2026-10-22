#!/bin/bash
set -euo pipefail
export ADAMSBRIDGE_ROOT=/tmp/a2-m18-aaxi-row0-local-01/caliptra-rtl/submodules/adams-bridge
/tmp/a2-m18-iverilog-cae035642e056644274a01e98d4422ce286685b4-local-02/tool/bin/iverilog -g2017 -gassertions -s compress_tb -f /Users/danielellerbrock/projects/bfm-work/qd-bfm/evidence/caliptra-bfm-m18-20261019/attempts/compress-row64-diagnostic-local-20261019-01/raw/compress_tb.overlay.vf -o /Users/danielellerbrock/projects/bfm-work/qd-bfm/evidence/caliptra-bfm-m18-20261019/attempts/compress-row64-diagnostic-local-20261019-01/raw/test.vvp > raw/compile.log 2>&1
/tmp/a2-m18-iverilog-cae035642e056644274a01e98d4422ce286685b4-local-02/tool/bin/vvp -n /Users/danielellerbrock/projects/bfm-work/qd-bfm/evidence/caliptra-bfm-m18-20261019/attempts/compress-row64-diagnostic-local-20261019-01/raw/test.vvp +UVM_TESTNAME=compress_normal_test +ntb_random_seed=1 > raw/sim.log 2>&1
