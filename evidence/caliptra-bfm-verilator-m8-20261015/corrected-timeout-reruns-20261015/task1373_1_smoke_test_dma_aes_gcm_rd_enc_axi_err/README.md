# Corrected c339 AXI read baseline

The pinned c339 run reached its configured 7,628-second cap. The raw wrapper
status says `INFRA_ERROR` because it maps runner exit 137 to a signal failure;
the timed command itself was `timeout --signal=INT --kill-after=60s 7628 ...`,
and `/usr/bin/time` records exactly 2:07:08. The last simulator heartbeat was
at wall 7,500 seconds, mcycle 53,626. There is no `result.json`, pass/fail
marker, or finish marker. I classify this row as TIMEOUT, not as an
infrastructure loss, while retaining the raw status unchanged.

The simulator log also confirms the corrected YAML arguments took effect: the
one-shot AXI SLVERR range was active at `0x123440000`. The task ran on
DAN-DESKTOP with QD-BFM commit `dd6d43d`, Caliptra RTL
`49370266`, Adams Bridge `b77e3d8`, and pinned Icarus c339 binary SHA-256
`683c94313f596bba25aa4e6de37efb4e68bb5dadc37394a91a2a0e6078ac26cb`. Logs,
resource data, versions, and the task stdout are copied from array 1373 task 1;
all copied files passed `remote.SHA256SUMS` verification. The disposable VVP
build and firmware outputs are excluded from this archive.
