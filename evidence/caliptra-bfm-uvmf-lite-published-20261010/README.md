# UVMF-lite base layer on clean published Icarus — 2026-10-10

Four focused UVMF-lite runners passed from a clean QD source archive on clean
published Icarus main `4b3f3424c440aca6af92153b6860a7253b925234`, with bundled
Accellera UVM 2020.3.1:

- Scoreboard behavior passed in IEEE 2017 and 2023. The directed mismatch and
  leftover controls reported exactly four UVM errors and zero fatals per run;
  the out-of-order scoreboard matched reordered transactions.
- Active/passive agent and factory behavior passed in both editions. Positive
  cases reported zero errors/fatals; mismatch controls reported one expected
  error and zero fatals.
- Transaction key and selected timestamp/payload recording passed in both
  editions, excluding `convert2string()` serialization.
- Default reset generation passed its IEEE 2012 timing check.

The QD sources are pinned at
`9ab26c499c9b4b974a28e8ee914a0000a42f1feb` in
[`qd-bfm-source.tar.gz`](qd-bfm-source.tar.gz). The Icarus executable hashes
match the earlier [published-main provenance](../caliptra-bfm-generated-ecc-published-20261009/README.md).
Commands, all runner outputs, and source hashes are retained here.

- [`logs/scoreboard.log.gz`](logs/scoreboard.log.gz) and
  [`logs/agent.log.gz`](logs/agent.log.gz) preserve the full formatted UVM
  reports losslessly; their uncompressed hashes are in
  [`logs/raw-log-sha256.txt`](logs/raw-log-sha256.txt).
- [`logs/transaction-key.log`](logs/transaction-key.log) and
  [`logs/default-reset.log`](logs/default-reset.log) preserve those runner
  results.
- [`logs/source-files.sha256`](logs/source-files.sha256),
  [`logs/iverilog-version.txt`](logs/iverilog-version.txt), and
  [`logs/vvp-version.txt`](logs/vvp-version.txt) pin the QD inputs and tools.

SSH to the Slurm host timed out, so these focused checks ran locally on Darwin
27.0.0 arm64 under the existing process-group guard. This verifies the
clean-room UVMF-lite foundation only. It does not prove compatibility with the
generated Caliptra ECC interfaces, full generated UVMF environments, or
full-top firmware; the current `c339b9f2` generated-interface compile failure
is recorded separately.
