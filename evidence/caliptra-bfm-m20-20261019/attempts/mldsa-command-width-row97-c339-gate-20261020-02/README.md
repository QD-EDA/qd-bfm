# Row 97 combined ML-DSA command-width gate — local c339

The corrected one-row gate used the combined per-run predictor and sequence command-width overlay with the exact-source local c339 Icarus build. Caliptra pin: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge pin: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; source snapshot SHA-256: `352fddead2b8fa45be98b6916b77cccb5f2cc0cc05e0ea5117a30d49fa154ef9`.

The run compiled successfully (`iverilog` exit 0), then VVP reached its 1,800-second timeout (exit 124; 1,800.004 s; peak RSS 752,418,816 bytes). It wrote nonzero signature words through index 1156 and `MLDSA_CTRL=3` at 55,085 ns. There is no `MLDSA_VERIFY_RES` read, testcase marker, or UVM error/fatal before timeout. This confirms the command-width overlay gets past the prior keygen misdispatch, but does not establish a functional verdict for row 97.

Host: `MacBook-Air.local`, macOS 27.0 arm64. Icarus/VVP: 13.0 devel (`cae03564`); `iverilog` SHA-256 `0f6c688825ca70480510526384fc56365c5eb7ba3b4f5d1c5834489451eec2ea`; `vvp` SHA-256 `b5dd81144624fbd2ad81ceb406d04d7e4bce2250d43541e419ce898303a6129d`. The run was wrapped with `~/codex-supervisor/localrun 2100 ...`; resource output is `raw/localrun-row97-c339.log` (SHA-256 `55507716cd86023beab7d6edc8b8b36e21a78e53e2d0b1b7ce446f00b181caf7`).

Archived result, command, compile/simulation logs, and overlay manifests: `raw/row97-c339-gate-evidence.tar.gz` (SHA-256 `aba7e2eceaa628758c65704aba8a832f921454ae58a10cd5d4fc6a3992426c76`). The compiled `test.vvp` was left out of the evidence archive; the source snapshot, compile command, result, logs, and overlay manifests are retained.
