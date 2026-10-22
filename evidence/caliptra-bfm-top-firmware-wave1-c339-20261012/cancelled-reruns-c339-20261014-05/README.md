# Post-reopen reruns of the maintenance-cancelled rows

This new array repeats source rows 37, 39, 43, and 44 (original array 799 tasks 28, 30, 34, and 35) after the supervisor's latest cancellation. Earlier fresh results from array 1015 remain preserved separately. This array is held behind `afterany:1043`, so it starts only after the current-main top-level comparison ends and does not overlap the M7 six-task wave. Each task uses the same pinned QD-BFM, Caliptra RTL, Adams Bridge, Icarus c339 build, original per-test timeout, 1 CPU, and 3 GiB; the array throttle is 6.

Remote build/output trees for this task were removed after evidence verification; 377301754 bytes of output/cache were deleted. See `task1110_4/cleanup.txt`.

Remote build/output trees for this task were removed after evidence verification; 377229440 bytes of output/cache were deleted. See `task1110_1/cleanup.txt`.

Remote build/output trees for this task were removed after evidence verification; 377439094 bytes of output/cache were deleted. See `task1110_2/cleanup.txt`.

All four fresh reruns are terminal: source row 44 (original 799_35) passed at mcycle 62472; rows 37, 39, and 43 (original 799_28, 799_30, and 799_34) reached their exact caps of 17281s, 17543s, and 18167s. They are recorded as TIMEOUT with raw exit 137 preserved. Checksummed evidence is retained and 1509283875 bytes of build/output/cache were removed.

Remote build/output trees for this task were removed after evidence verification; 377313587 bytes of output/cache were deleted. See `task1110_3/cleanup.txt`.
