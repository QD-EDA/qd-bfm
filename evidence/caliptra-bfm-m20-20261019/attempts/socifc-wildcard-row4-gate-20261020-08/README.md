# Expanded SoC-IFC overlay attempt: source-hash guard

Job 3338 row 4 terminated BLOCKED during overlay preparation after 0.179 seconds, before compilation. The strict guard rejected the pinned ss_mode_ctrl_configuration.svh source because the expected SHA-256 constant was malformed at 63 characters. The source itself was clean and pinned; its actual 64-character digest is recorded in the corrected next attempt. compile_exit is null and no simulation ran.

Raw archive raw/job-3338_4.tar.gz and its SHA-256 sidecar preserve the result. The attempt requested one CPU, 24 GiB, and a 3,600-second runner timeout.
