# Post-release reruns of the maintenance-cancelled rows

This fresh Slurm array reruns original tasks 799_28, 799_30, 799_34, and 799_35 (source rows 37, 39, 43, and 44). The earlier array 955 already produced a complete fresh baseline; this separate run follows the supervisor's post-release rerun request. Each task uses the same pinned QD-BFM, Caliptra RTL, Adams Bridge, Icarus c339 build, original timeout, 1 CPU, and 3 GiB. The array throttle is 6.

`selection.tsv` maps tasks. All four terminal outcomes are recorded in `results.tsv`, with copied, checksum-verified evidence. Three tasks timed out at their per-test caps and one passed. Output and cache cleanup removed 1,509,370,300 bytes across the four fresh runs; protected shared toolchains remain untouched.

Remote build/output trees for this task were removed after evidence verification; 377301701 bytes of output/cache were deleted. See `task1015_4/cleanup.txt`.

Remote build/output trees for this task were removed after evidence verification; 377229438 bytes of output/cache were deleted. See `task1015_1/cleanup.txt`.

Remote build/output trees for this task were removed after evidence verification; 377525574 bytes of output/cache were deleted. See `task1015_2/cleanup.txt`.

Remote build/output trees for this task were removed after evidence verification; 377313587 bytes of output/cache were deleted. See `task1015_3/cleanup.txt`.
