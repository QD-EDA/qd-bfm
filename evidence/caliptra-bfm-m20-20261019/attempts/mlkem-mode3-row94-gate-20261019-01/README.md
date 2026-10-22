# ML-KEM row 94 mode-3 gate

The prior setup array's rows 94 and 100 failed before their intended crypto result because the run-local native helper accepted only operations 1 (keygen) and 2 (encapsulation), while the pinned sequence invokes operation 3 (decapsulation). Those attempts are preserved in `../mlkem-mode3-diagnostic-array-3255-20261019-01/raw/` and are not final row verdicts.

This one-row gate validates the source helper fix on row 94 before any rerun array: operation 3 imports the FIPS 203 decapsulation key, decapsulates the supplied ciphertext, and writes the pinned testbench file protocol. RTL, firmware, vectors, sequence, assertions, and pass criteria remain unchanged. The helper source and checker are staged as run-local BFM overlays over the M20 baseline snapshot.

The regression checker retains the pinned keygen and encapsulation known-answer checks, adds a deterministic encapsulate/decrypt round-trip, and rejects malformed hex. Local OpenSSL 3.6.3 checks pass; the Slurm gate uses the existing pinned Icarus c339 binary and the protected toolchain's Caliptra/Adams Bridge sources.
