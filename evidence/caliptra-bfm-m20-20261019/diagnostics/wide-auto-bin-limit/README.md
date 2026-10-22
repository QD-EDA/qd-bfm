# M20-pinned Icarus wide auto-bin reproducer

`run.sh` compiles the same coverpoint with widths 64 and 512 using the M20 Icarus source pin `cae035642e056644274a01e98d4422ce286685b4`. The 64-bit case compiles and samples; the 512-bit case reproduces `automatic bins for a coverpoint wider than 64 bits are not represented` at `wide_auto_bin.sv:4`.

Run through `~/codex-supervisor/localrun 60 evidence/caliptra-bfm-m20-20261019/diagnostics/wide-auto-bin-limit/run.sh`. The successful check used Icarus SHA-256 `0f6c688825ca70480510526384fc56365c5eb7ba3b4f5d1c5834489451eec2ea` and VVP SHA-256 `b5dd81144624fbd2ad81ceb406d04d7e4bce2250d43541e419ce898303a6129d`; wall time was 0.32 s and peak RSS was 8,142,848 bytes. Its log is `raw/run-02-localrun.log`.

`raw/run-01-localrun.log` preserves the first attempt, which exited 141 because `iverilog -V | head -2` triggered `pipefail`; it did not compile the reproducer.

## PR #697 regression on main

The PR #697 build (`8c95b5cc`) passes its committed 512-bit regression `ivtest/ivltests/sv_covergroup_wide_auto_bins.v` with the regression's exact `-g2017 -gno-icarus-misc -gno-xtypes -s top` options. Compile and simulation exit 0 and print `PASSED`; the existing warning that the class-property sample is constant zero remains visible. Tool hashes are recorded in the matching M20b attempt's toolchain manifest; the transcript is `attempts/wide-bins-main-8c95b5cc-20261020-01/raw/run-main-8c95b5cc.log` (SHA-256 `d0fe55eccab4cdc67305d4f3e0fc046a6d75bce12027328372865de165d6cdab`).

An initial manual check reused the old `-g2012` module-level fixture and got the old width diagnostic. That check does not exercise the PR's 2017-mode regression or the Caliptra runner, which also compiles with `-g2017`; its log is preserved as `attempts/wide-bins-main-8c95b5cc-20261020-01/raw/run-main-2012-mode-check.log` and is not counted as a result.
