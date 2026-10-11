# Caliptra block-unit suite results — 2026-10-11

## Run conditions

The three pinned Caliptra v2.1.2 block benches below were compiled and run
serially on the local Mac, each under `~/codex-supervisor/localrun 1200`.
Slurm had no available node; the only jobs in `squeue -u dsell` were A1's
pending jobs. No Slurm run was submitted, and these local passes must not be
rerun on Slurm.

Icarus was built locally from clean source commit
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, with its pinned UVM submodule
commits. The first build attempt selected Apple Bison 2.3 and failed during
parser generation; the successful retry used Homebrew Bison 3.8.2. Compressed build logs, versions, host details, and tool binary hashes are in
[local-mac](local-mac/).
The successful local compiler reports Icarus Verilog 13.0 (devel).

Caliptra is pinned at
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge at
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and the QD-BFM checkout was
`cfac19fb9ae4acce570e9682488fe244dee3a672` (dirty only in an unrelated,
unsubmitted Slurm harness edit). The Caliptra source archive SHA-256 and exact
filelist/testbench hashes are retained under `local-mac/source/`.

## Results

| Top | Result | Runner exit | Pass / fail / error markers | Wall time | Peak RSS |
| --- | --- | ---: | --- | ---: | ---: |
| `hmac_ctrl_tb` | PASS | 0 | 1 / 0 / 0 | 48.24 s | 16,089,088 bytes |
| `sha256_ctrl_tb` | PASS | 0 | 1 / 0 / 0 | 0.48 s | 9,863,168 bytes |
| `sha512_ctrl_32bit_tb` | PASS | 0 | 1 / 0 / 0 | 6.10 s | 14,401,536 bytes |

Each pass requires simulator/runner exit 0, exactly one `* TESTCASE PASSED`,
no `* TESTCASE FAILED`, and no test error markers. Per-test commands, compile
and simulation logs, localrun resource output, and result summaries are in
`local-mac/tests/<top>/`.
