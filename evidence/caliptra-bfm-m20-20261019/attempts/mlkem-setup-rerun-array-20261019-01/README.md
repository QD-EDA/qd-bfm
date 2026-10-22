# ML-KEM missing-setup rows, rerun array

Fresh reruns of rows 83, 84, 85, 88, 94, 98, and 100 after row 95 passed with the run-local native ML-KEM setup overlay. Row 95 is intentionally excluded and its PASS_OVERLAY evidence is already recorded separately.

Each task uses 1 CPU / 2 GiB, 1,800-second runner timeout, 2,100-second Slurm limit; array throttle is four. The overlay builds the existing native helper, checks pinned Adams Bridge keygen/encapsulation KATs, stages the helper, creates the expected tv/ directory, and maps the pinned python3.9 executable name. RTL, firmware, vectors, assertions, and pass criteria remain unchanged.

Evidence is archived per row with source and toolchain pins plus SHA-256.

Completed outcomes (pinned Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, pinned Icarus `cae035642e056644274a01e98d4422ce286685b4`):

- Row 83 compiles but times out at 1,800 s while writing encapsulation-key word 347; no testcase result. Archive SHA-256: `f9251ae128b3cad1ef0d15d4b53f3188d8558c5d652690a3f54afadb4302bc00`.
- Row 88 is PASS_OVERLAY in 1,066.033 s with UVM_ERROR=0/UVM_FATAL=0. Archive SHA-256: `c672c036f9815cef64ee68c1ff05749ab076e639ee5c9ad227003c0f2450ec95`.
- Row 98 is PASS_OVERLAY in 1,426.456 s with UVM_ERROR=0/UVM_FATAL=0. Archive SHA-256: `ffdd226b070643093c62e1bb235f1963ce89a007dbf46a99fa096c07896243cd`.

Each archive was copied from DAN-DESKTOP and matched its remote SHA-256 sidecar. Rows 84, 85, 94, and 100 used the earlier helper that lacked decapsulation mode 3; they remain setup-blocked until the fixed-helper row 94 gate completes and the remaining rows can be rerun.
