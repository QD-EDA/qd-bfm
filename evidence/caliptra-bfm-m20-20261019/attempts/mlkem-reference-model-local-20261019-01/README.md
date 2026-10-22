# Local ML-KEM reference model check

Supplementary local check for the M20 ML-KEM setup investigation. It builds the existing QD-BFM native helper with Homebrew OpenSSL and checks deterministic ML-KEM-1024 keygen/encapsulation against the two KAT sequences copied from Caliptra pin 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e. It also checks malformed-input rejection through the existing checker.

This is generator evidence only, not an Icarus row result. The runtime row 95 gate remains on pinned c339 in Slurm. The input source hashes and tool versions are recorded alongside the local build, checker output, and binary hash.

Command: `localrun 180 /bin/bash run-local-check.sh`. Exit code 0; wall time 1.19 seconds; peak RSS 53,723,136 bytes. Host: MacBook-Air.local, macOS 27.0 ARM64; Python 3.14.7, Apple clang 21.0.3, OpenSSL 3.6.3. Both local KAT source hashes match the protected pinned files; the resulting native helper SHA-256 is `5f3d19de6796c3723298231a4336d3200761078c9d59bd8cc561580a05ef2789`.
