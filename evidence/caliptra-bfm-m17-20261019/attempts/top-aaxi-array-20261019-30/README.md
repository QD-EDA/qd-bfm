# Caliptra top AAXI rows 1–4

Job 2942 ran rows 1–4 at throttle 1, one CPU and 4 GiB each, with a 600 s per-row timeout. All four compiled for under 1 s and were `BLOCKED` before simulation. Each compile log starts with the pinned RTL wildcard-transition coverage syntax error at `src/soc_ifc/rtl/mbox_csr_covergroups.svh:64` (#661), followed later by a missing vendor `avery_defines.svh` include. The independent log triage initially called out the include; direct inspection confirms line 64 is the first error in all four logs.

The raw task archive is `raw/job-2942.tar.gz`, SHA-256 `17a8ea7fff3b35d105aeb32d7c46e63d7b6f6f7fc27353b40f811f5de2cbeb47`. It contains the per-row results, compile logs, commands, overlays, runner logs, resource records and job metadata; the pinned source snapshot and its checksum are stored beside this README. No simulation ran.
