# ML-KEM operation-3 reruns: rows 84, 85, and 100

Fresh array using the exact source snapshot, operation-3 helper, and setup runner that passed the row-94 full testcase gate. Rows 84 and 85 exercise randomized decapsulation and keygen-plus-decapsulation; row 100 exercises overwrite with operation 3.

Each task requests 1 CPU / 2 GiB, runs with the pinned c339 Icarus binary and the protected Caliptra/Adams Bridge pins, and has a 1,800-second runner timeout / 2,100-second Slurm limit. Array throttle is three. No RTL, firmware, vectors, sequence, assertions, or pass criteria are changed.

Terminal archives and SHA-256 sidecars will be copied here before remote run trees are cleaned.

The 84/85/100 array is job `3273` at `/home/dsell/slurm-runs/caliptra-bfm/a2/m20-mlkem-mode3-rerun-array-20261020-01`, submitted with throttle 3. Remote input hashes and the submitted script matched the staged manifest; the source snapshot had already been extracted at the recorded remote `source/` path before submission.

Terminal results (all used Icarus c339 `cae03564`, binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`; Caliptra and Adams Bridge pins are recorded in each result JSON):

- Row 84: PASS in 1,741.766 s, testcase pass marker, UVM_ERROR=0/UVM_FATAL=0. Archive `raw/job-3277-84.tar.gz`, SHA-256 `f112c959f56b17c3ea46799fa3e100fbe42b391afb6758b3d4a7b6e18921924a`.
- Row 85: TIMEOUT at 1,799.707 s after compile succeeded; the final log tail is in the K-match sequence, with no testcase marker. Archive `raw/job-3278-85.tar.gz`, SHA-256 `5fff3a609af6e775b1664cf3347a220b361e13d054b3bab901dc764661602b3f`.
- Row 100: TIMEOUT at 1,799.708 s after compile succeeded; the final log tail records the overwrite sequence triggering encapsulation, with no testcase marker. Archive `raw/job-3273-100.tar.gz`, SHA-256 `9b0a76606946c383328cf825f56f984692ebea759973b185c790477d39f2b70f`.

All three archives match their remote Slurm sidecars; both remote and local checksums are preserved in `raw/`. The fixed helper's pinned KAT and decapsulation round-trip checks passed in each run. Row 84 is PASS_OVERLAY. Rows 85 and 100 are TIMEOUT at the 1,800-second cap; fresh 3,600-second reruns are being staged. No RTL, firmware, vectors, assertions, or pass criteria changed.
