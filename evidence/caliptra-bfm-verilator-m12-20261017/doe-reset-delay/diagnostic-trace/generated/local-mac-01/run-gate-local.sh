#!/bin/bash
set -euo pipefail
run=/tmp/a2-m12-doe-local-01
rtl=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl
qd_source=/tmp/a2-m12-local-source
model="$run/model/obj_dir/Vcaliptra_top_tb"
gcc_dir=/Users/danielellerbrock/projects/iverilog_uvm/evidence/caliptra-exact-riscv-toolchain-20260923/toolchain/bin
path="$gcc_dir:/opt/homebrew/opt/bison/bin:/opt/homebrew/opt/openssl@3/bin:/opt/homebrew/opt/mbedtls@3/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
output="$run/result-02"
test ! -e "$output"
printf 'host=%s\n' "$(hostname)" > "$run/gate-environment.txt"
sw_vers >> "$run/gate-environment.txt"
uname -a >> "$run/gate-environment.txt"
printf 'qd_bfm_source=' >> "$run/gate-environment.txt"
git -C "$qd_source" rev-parse HEAD >> "$run/gate-environment.txt"
printf 'caliptra_rtl=' >> "$run/gate-environment.txt"
git -C "$rtl" rev-parse HEAD >> "$run/gate-environment.txt"
/opt/homebrew/bin/python3.12 --version >> "$run/gate-environment.txt" 2>&1
"$gcc_dir/riscv-none-elf-gcc" --version | head -1 >> "$run/gate-environment.txt"
/opt/homebrew/opt/openssl@3/bin/openssl version >> "$run/gate-environment.txt"
brew list --versions mbedtls@3 openssl@3 >> "$run/gate-environment.txt"
printf 'verilator_model=' >> "$run/gate-environment.txt"
cat "$run/model.sha256" >> "$run/gate-environment.txt"
printf 'verilator_binary=' >> "$run/gate-environment.txt"
shasum -a 256 /tmp/a2-m12-local-tools/verilator-src/bin/verilator_bin >> "$run/gate-environment.txt"
printf 'verilator_build_patch=' >> "$run/gate-environment.txt"
shasum -a 256 /tmp/a2-m12-local-tools/verilator-build-compat.patch >> "$run/gate-environment.txt"
printf 'axi_overlay=' >> "$run/gate-environment.txt"
shasum -a 256 "$run/overlay/rtl/src/axi/rtl/axi_if.sv" >> "$run/gate-environment.txt"
printf 'doe_checker_overlay=' >> "$run/gate-environment.txt"
shasum -a 256 "$run/overlay/asserts/caliptra_top_sva.sv" >> "$run/gate-environment.txt"
printf 'cmd=run-verilator-top-case-local.py --case smoke_test_doe_scan --timeout 600\n' >> "$run/gate-environment.txt"
/Users/danielellerbrock/codex-supervisor/localrun 600 /usr/bin/env \
  "PATH=$path" \
  CALIPTRA_GCC_PREFIX=riscv-none-elf \
  /opt/homebrew/bin/python3.12 "$run/run-verilator-top-case-local.py" \
  --source "$qd_source" \
  --rtl "$rtl" \
  --model "$model" \
  --output "$output" \
  --case smoke_test_doe_scan \
  --case-yaml smoke_test_doe_scan/smoke_test_doe_scan.yml \
  --timeout 600 \
  --c339-outcome UNVERIFIED \
  --c339-mcycle NA \
  --c339-elapsed NA > "$run/task.resource" 2>&1
