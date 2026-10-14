#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
evidence_dir="$repo_root/evidence/caliptra-bfm-generated-ecc-hdl-20261004"
diagnostic_log="$evidence_dir/keygen_diagnostic_2017.log"
runner_log=$(mktemp)
trap 'rm -f "$runner_log"' EXIT HUP INT TERM

set +e
ECC_KEYGEN_WATCHDOG_CLOCKS=1000 \
ECC_KEYGEN_LOG_PREFIX=keygen_diagnostic \
ECC_KEYGEN_TOP_SOURCE="$evidence_dir/top_keygen_diagnostic_probe.sv" \
  "$evidence_dir/verify_keygen_runtime.sh" > "$runner_log" 2>&1
runner_status=$?
set -e

if [ "$runner_status" -eq 0 ]; then
  echo "Key generation unexpectedly completed inside the 1,000-clock diagnostic window." >&2
  exit 1
fi
if ! grep -Fq 'single key-generation transaction exceeded 1000 clocks' "$diagnostic_log"; then
  cat "$runner_log" >&2
  echo "The run did not reach the expected diagnostic watchdog." >&2
  exit 1
fi
if ! grep -Fq 'ECC_AHB_TRACE_SUMMARY cycles=1000 transfers=475 status_polls=437' "$diagnostic_log" \
  || ! grep -Fq 'hready=1 hreadyout=1 htrans=00' "$diagnostic_log"; then
  cat "$diagnostic_log" >&2
  echo "The generated AHB trace did not confirm progress through the status polling phase." >&2
  exit 1
fi
if ! grep -E '^ECC_CORE_TRACE busy=1 ecc_ready=0 dsa_busy=1 .*keygen_process=1 kv_privkey_ready=1 kv_seed_ready=1 kv_write_ready=1' "$diagnostic_log" >/dev/null; then
  cat "$diagnostic_log" >&2
  echo "The ECC core trace did not show active key-generation processing with ready KV clients." >&2
  exit 1
fi

grep -E '^ECC_AHB_TRACE_SUMMARY|^ECC_CORE_TRACE|single key-generation transaction exceeded' "$diagnostic_log"
echo "PASS: bounded diagnostic classified the 1,000-clock key-generation state; this is not a key-generation result pass."
