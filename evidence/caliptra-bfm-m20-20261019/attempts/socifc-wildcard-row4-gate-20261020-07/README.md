# Wildcard coverage rerun with exact overlay validation

Job 3330 row 4 is terminal BLOCKED. Icarus reports that a 32,768-value alignment filter exceeds its 4,096-value limit, then compilation exits 137 after 78.654 seconds at 16,738,140 KiB peak RSS. The first remaining filter is in SHA-512 CSR coverage; the current overlay only shadows MBox and SoC-IFC register covergroups, plus the control transaction package. The compiler log also identified remaining status-byte filters and generated-package configuration syntax.

The archived runner result is raw/job-3330_4.tar.gz with a verified SHA-256 sidecar. This run used one CPU, 16 GiB, and a 3,600-second runner timeout. The suite at submission time had 88 tests passing; the current runner suite has 90 passing tests. This attempt did not produce a simulation result.
