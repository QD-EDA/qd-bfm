# Expanded SoC-IFC overlay array: source-hash guard

Array job 3339 terminated before compilation. Rows 0, 1, 2, 3, 43, 44, and 45 all reported BLOCKED during overlay preparation in 0.152–0.217 seconds. The strict guard rejected the pinned ss_mode_ctrl_configuration.svh source because the expected SHA-256 constant was malformed at 63 characters. The source was clean and pinned; the actual 64-character digest is recorded in the corrected next attempt. compile_exit is null for every task and no simulation ran.

Each task's raw archive and SHA-256 sidecar preserve its result. The array requested one CPU and 24 GiB per task, with concurrency one and a 3,600-second runner timeout.
