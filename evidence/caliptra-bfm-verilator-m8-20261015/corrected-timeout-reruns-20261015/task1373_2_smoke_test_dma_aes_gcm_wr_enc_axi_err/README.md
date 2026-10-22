# Corrected c339 AXI write baseline

The pinned c339 run reached its configured 7,628-second cap. The raw wrapper
status is `INFRA_ERROR` because runner exit 137 is mapped to a signal failure;
the timed command was `timeout --signal=INT --kill-after=60s 7628 ...`, and
`/usr/bin/time` records exactly 2:07:08. The last simulator heartbeat was at
wall 7,500 seconds, mcycle 55,863. There is no `result.json`, PASS/FAIL marker,
or finish marker, so this is a TIMEOUT with progress, while the raw status is
preserved unchanged.

The simulator log reports the one-shot AXI SLVERR range at `0x123460000`,
showing the corrected quoted YAML argument reached the test. The task ran on
DAN-DESKTOP with QD-BFM commit `dd6d43d`, Caliptra RTL `49370266`, Adams Bridge
`b77e3d8`, and pinned Icarus c339 binary SHA-256
`683c94313f596bba25aa4e6de37efb4e68bb5dadc37394a91a2a0e6078ac26cb`. The
copied simulation/build logs, resource data, versions, provenance, status, and
Slurm stdout all pass `remote.SHA256SUMS` verification. Disposable build and
firmware outputs are excluded.
